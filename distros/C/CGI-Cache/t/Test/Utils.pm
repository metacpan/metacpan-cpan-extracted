package Test::Utils;

use strict;
use Exporter;
use Test::More;
use FileHandle;
use Config;
use File::Temp;

# http://www.cpantesters.org/cpan/report/9373ce6a-e71a-11e4-9f23-cdc1e0bfc7aa
BEGIN {
  $SIG{__WARN__} = sub {
    my $warning = shift;
    warn $warning unless $warning =~ /Subroutine .* redefined at/;
  };
  use File::Slurp;
  $SIG{__WARN__} = undef;
};

use vars qw( @EXPORT @ISA $VERSION );

$VERSION = sprintf "%d.%02d%02d", q/0.10.1/ =~ /(\d+)/g;

@ISA = qw( Exporter );
@EXPORT = qw( Init_For_Run Run_Script Setup_Cache $set_env $single_quote
              $command_separator );

use vars qw( $single_quote $command_separator $set_env );

my $path_to_perl = $Config{perlpath};

if ($^O eq 'MSWin32')
{
  $set_env = 'set';
  $single_quote = '"';
  $command_separator = '&';
}
else
{
  $set_env = '';
  $single_quote = "'";
  $command_separator = '';
}

# ---------------------------------------------------------------------------

sub Init_For_Run
{
  my $test_script_name = shift;
  my $script = shift;
  my $clear_cache = shift;

  write_file($test_script_name, $script);
  Setup_Cache($test_script_name,$script,$clear_cache);
}

# ---------------------------------------------------------------------------

# This function executes three tests, one for each of the expected_ variables.
# If any of the expected_ variables are the string "<SKIP>", any value will be
# accepted.

sub Run_Script
{
  my $test_script_name = shift;
  my $expected_stdout = shift;
  my $expected_stderr = shift;
  my $expected_cached = shift;
  my $message = shift;

  local $Test::Builder::Level = 2;

  # Save STDERR and redirect temporarily to nothing. This will prevent the
  # test script from emitting output to STDERR
  my (undef, $stderr_redirected) = File::Temp::tempfile(UNLINK => 1);
  {
    my $oldstderr;
    open $oldstderr,">&STDERR" or die "Can't save STDERR: $!\n";
    open STDERR,">$stderr_redirected"
      or die "Can't redirect STDERR to $stderr_redirected: $!\n";

    my $script_results;
    
    {
      my @standard_inc = split /###/, `$path_to_perl -e '\$" = "###";print "\@INC"'`;
      my @extra_inc;
      foreach my $inc (@INC)
      {
        push @extra_inc, "$single_quote$inc$single_quote"
          unless grep { /^$inc$/ } @standard_inc;
      }

      if (@extra_inc)
      {
        local $" = ' -I';
        $script_results = `$path_to_perl -I@extra_inc $test_script_name`;
      }
      else
      {
        $script_results = `$path_to_perl $test_script_name`;
      }
    }
    
    unlink $test_script_name;

    open STDERR, '>&', $oldstderr or die "Can't restore STDERR: $!\n";

    # Check the answer that the test generated
    if (defined $expected_stdout)
    {
      if ($expected_stdout eq '<SKIP>')
      {
        $script_results = '<UNDEF>' unless defined $script_results;
        ok(1, "$message: Skipping results output check for string \"$script_results\"");
      }
      elsif (ref $expected_stdout eq 'Regexp')
      {
        like($script_results, $expected_stdout, "$message: Computing the right output");
      }
      else
      {
        is($script_results, $expected_stdout, "$message: Computing the right output");
      }
    }
    else
    {
      ok(!defined($script_results), "$message: Undefined results");
    }
  }

  {
    my $script_errors = read_file($stderr_redirected);

    if (defined $expected_stderr)
    {
      if ($expected_stderr eq '<SKIP>')
      {
        $script_errors = '<UNDEF>' unless defined $script_errors;
        ok(1, "$message: Skipping error output check for string \"$script_errors\"");
      }
      elsif (ref $expected_stderr eq 'Regexp')
      {
        like($script_errors, $expected_stderr, "$message: Computing the right errors");
      }
      else
      {
        is($script_errors, $expected_stderr, "$message: Computing the right errors");
      }
    }
    else
    {
      ok(!defined($script_errors), "$message: Undefined errors");
    }
  }

  {
    my $cached_results;
    $cached_results = $CGI::Cache::THE_CACHE->get($CGI::Cache::THE_CACHE_KEY)
      if defined $CGI::Cache::THE_CACHE;

    if (defined $expected_cached)
    {
      if ($expected_cached eq '<SKIP>')
      {
        $cached_results = '<UNDEF>' unless defined $cached_results;
        ok(1, "$message: Skipping cached output check for string \"$cached_results\"");
      }
      elsif (ref $expected_cached eq 'Regexp')
      {
        like($cached_results, $expected_cached, "$message: Correct cached data");
      }
      else
      {
        is($cached_results, $expected_cached, "$message: Correct cached data");
      }
    }
    else
    {
      ok(!defined($cached_results), "$message: Undefined cached data");
    }
  }

  unlink $test_script_name;
}

# ----------------------------------------------------------------------------

sub Setup_Cache
{
  my $test_script_name = shift;
  my $script = shift;
  my $clear_cache = shift;

  # Setup the CGI::Cache the same way the test script does so that we
  # can clear the cache and then look at the cached info after the run.
  my ($cache_options) = $script =~ /setup\((.*?)\)/s;
  my ($cache_key) = $script =~ /set_key\((.*?)\)/s;

  $ENV{SCRIPT_NAME} = $test_script_name;

  eval "CGI::Cache::setup($cache_options)";
  eval "CGI::Cache::set_key($cache_key)";

  # Clear the cache to start the test
  $CGI::Cache::THE_CACHE->clear() if defined($CGI::Cache::THE_CACHE) && $clear_cache;
}

# ----------------------------------------------------------------------------

1;

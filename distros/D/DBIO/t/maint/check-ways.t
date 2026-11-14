use strict;
use warnings;

use Test::More;

use File::Temp ();
use lib 't/lib';
use TestDBIO::Child;
use FindBin ();

use DBIO::Util qw(file_path slurp_file write_file);

# maint/test-runner/check-ways prints the DSN of every database it tries and the
# message of a connect that failed. Both are connect info and go through
# DBIO::Util::mask_connect_secrets, so a password in a DSN never reaches the
# terminal or a CI log. Where the masking cannot be loaded the connect part
# refuses to run -- it does not fall back to printing.
#
# The Perl part of the script (it runs in a container, fed on stdin) is lifted
# out and run on the host against a DSN without a "dbi:" prefix, which DBI
# rejects without any database or driver: it quotes the whole DSN in its error.

my $script = $ENV{CHECK_WAYS} || file_path($FindBin::Bin, '..', '..', 'maint', 'test-runner', 'check-ways');

plan skip_all => 'maint/test-runner/check-ways is a repository tool and not part of the shipped dist'
  unless -f $script;

my ($perl) = slurp_file($script) =~ /<<'PERL'\n(.*?)^PERL$/ms;
ok(defined $perl && length $perl, 'the Perl part of check-ways is found')
  or BAIL_OUT('no Perl part');

my $dir  = File::Temp->newdir;
my $prog = file_path("$dir", 'check-ways.pl');
write_file($prog, $perl);

my $lib = file_path($FindBin::Bin, '..', '..', 'lib');

sub run_ways {
  my (@inc) = @_;
  local $ENV{DBIO_TEST_X_DSN}  = 'host=h;password=geheim';
  local $ENV{DBIO_TEST_X_USER} = 'someone';
  local $ENV{DBIO_TEST_X_PASS} = 'geheim';
  my $run = TestDBIO::Child::run_perl(script => $prog, inc => \@inc, merge_stderr => 1, timeout => 60);
  return ($run->{output}, $run->{exit});
}

{
  my ($out) = run_ways($lib);
  my ($connect) = $out =~ /^== connect\n(.*)\z/ms;
  ok(defined $connect && $connect =~ /^DBIO_TEST_X\b/m, 'the connect part ran and tried the DSN')
    or diag $out;
  unlike($out, qr/geheim/, 'neither the printed DSN nor the connect failure shows the password');
  like($connect, qr/password=\*\*\*/, 'the password is masked, the key stays');
  like($connect, qr/FAIL/, 'the failed connect is still reported');
}

{
  my $stub = File::Temp->newdir;
  mkdir file_path("$stub", 'DBIO') or die $!;
  write_file(file_path("$stub", 'DBIO', 'Util.pm'), qq{die "stub: not loadable\\n";\n1;\n});
  my ($out, $exit) = run_ways("$stub", $lib);
  unlike($out, qr/geheim/, 'without the masking nothing of the password is printed');
  like($out, qr/FAIL DBIO::Util not loadable/, 'the missing masking is reported');
  isnt($exit, 0, 'and the run fails');
}

done_testing;

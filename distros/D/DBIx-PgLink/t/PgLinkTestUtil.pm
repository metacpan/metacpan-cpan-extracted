package PgLinkTestUtil;

=begin

Utility module for testing DBIx::PgLink

=cut

use strict;
use DBI;
use YAML;
use Cwd;
use Exporter;

use base 'Exporter';

our @EXPORT = qw/$Test $Trace_level/;

our $Test = load_conf();

our $Trace_level = defined $ENV{PGLINK_TRACE_LEVEL} ? $ENV{PGLINK_TRACE_LEVEL} : 0;

our $DBH;

sub load_conf {

  my $file = -f "t/test.conf.debug" ? "t/test.conf.debug" : "t/test.conf";
  my $s = YAML::LoadFile($file);

  my $cwd = Cwd::abs_path;

  for my $c (values %{$s}) {
    my %foo = %{$c};
    $c->{dsn} =~ s<\$\{(\w+)\}>
      <
        if ($1 eq 'examples') {
          "$cwd/examples"
        } else {
          $foo{$1}
        }
     >eg;
  }
  return $s;
}

use subs 'connect';

sub connect {
  my ($database) = @_;
  my $default_database = $database ? 0 : 1;
  return $DBH if $default_database && defined $DBH;
  my $ds = $Test->{TEST};
  $database ||= $ds->{database};
  my $dsn = $ds->{dsn};
  $dsn =~ s/;database=\w+/;database=$database/;
  my $dbh = DBI->connect($dsn, $ds->{user}, $ds->{password}, 
    {AutoCommit=>1, RaiseError=>1, PrintError=>0});
  $DBH = $dbh if $default_database;
  return $dbh;
}

sub connect_to {
  my ($db) = @_;
  my $ds = $Test->{$db};
  return DBI->connect($ds->{dsn}, $ds->{user}, $ds->{password}, 
    {AutoCommit=>1, RaiseError=>1, PrintError=>0});
}

sub init_test {
  die "can't connect" unless connect();

  $DBH->do(q{SET search_path to dbix_pglink, public});
  $DBH->do(q{SELECT public.plperl_use_blib()});
  $DBH->do(qq{SELECT trace_level($Trace_level)});
}

sub psql {
  my $ds = $Test->{TEST};
  my %args = (
    'database' => $ds->{database},
    'options'  => '',
    @_
  );
  die "psql() require 'file' parameter" unless $args{file};
  my $cmd = qq!psql -h $ds->{host} -p $ds->{port} -U $ds->{user} -f $args{file} $args{options} $args{database}!; 
  #warn "\nExecute $cmd\n";
  my $err = system($cmd);
  return $err == 0;
}

#BEGIN {
#  # pl/perl emulation
#
#  *main::elog    = sub { warn join(" : ", @_), "\n" };
#  # Note: plperl use numeric constants
#  *main::DEBUG   = sub { 'DEBUG' };
#  *main::LOG     = sub { 'LOG' };
#  *main::INFO    = sub { 'INFO' };
#  *main::NOTICE  = sub { 'NOTICE' };
#  *main::WARNING = sub { 'WARNING' };
#  *main::ERROR   = sub { 'ERROR' };
#
#  no strict 'refs';
#  for my $sub (qw/
#    spi_exec_query spi_query spi_fetchrow spi_prepare 
#    spi_exec_prepared spi_query_prepared spi_cursor_close spi_freeplan 
#    return_next
#  /) {
#    *{"main::$sub"} = sub { warn "\n$sub is not available"; "$sub: @_" };
#  }
#
#}

1;

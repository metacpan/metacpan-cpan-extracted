use strict;
use warnings;
use Test::More tests => 2;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.nothing_to_do.log', 
  'ignore-versions' => 1,
), 'created new reporter object';

sub test_make_report {
  fail 'make_report() should never be reached by the parser';
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};

pass 'parser runs on "empty" build.log';


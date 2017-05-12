use strict;
use warnings;
use Test::More tests => 3;
use App::cpanminus::reporter;
use Capture::Tiny qw( capture_stdout );

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force             => 1, # ignore mtime check on build.log
  build_logfile     => $dir . '/build.verbose_cpanm.log',
  'ignore-versions' => 1,
), 'created new reporter object';

sub test_make_report {
  fail 'make_report() should never be reached by the parser';
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;

  my $output = capture_stdout { $reporter->run; };
  is $output, "No test output found for 'Mojolicious-4.89'. Skipping...\nTo send test reports, please make sure *NOT* to pass '-v' to cpanm or your build.log will contain no output to send.\n", 'output complains about cpanm -v'
};

pass 'parser runs on "empty" build.log when cpanm is run with -v';


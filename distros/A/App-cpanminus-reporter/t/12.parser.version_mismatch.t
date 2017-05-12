use strict;
use warnings;
use Test::More tests => 2;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.version_mismatch.log',
), 'created new reporter object';

sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;
  fail 'perl versions mismatch! this should never be reached';
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;

  is($reporter->run, undef, "skipped due to version, undefined as expected");
};


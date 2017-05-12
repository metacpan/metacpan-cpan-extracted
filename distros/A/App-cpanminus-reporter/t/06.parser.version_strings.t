use strict;
use warnings;
use Test::More tests => 7;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.version_strings.log', 
  'ignore-versions' => 1,
), 'created new reporter object';

sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;
  is $reporter, $self, 'got the reporter object';
  is $resource, 'http://www.cpan.org/authors/id/B/BO/BOBW/X86-Udis86-1.7.2.3.tar.gz'
     => 'resource is properly set';

  is $dist, 'X86-Udis86-1.7.2.3' => 'dist is properly set';
  is $result, 'FAIL' => 'result is properly set';

  is $test_output[0], "Building and testing X86-Udis86-v1.7.2.3\n"
     => 'test output starts ok';

  is $test_output[-1], "Result: FAIL\n" => 'test output finishes ok';
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};


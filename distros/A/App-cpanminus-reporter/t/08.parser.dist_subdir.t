use strict;
use warnings;
use Test::More tests => 7;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.dist_subdir.log', 
  'ignore-versions' => 1,
), 'created new reporter object';

sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;
  is $reporter, $self, 'got the reporter object';
  is $resource, 'http://www.cpan.org/authors/id/I/IL/ILYAZ/modules/Term-ReadLine-Perl-1.0303.tar.gz'
     => 'resource is properly set';

  is $dist, 'Term-ReadLine-Perl-1.0303' => 'dist is properly set';
  is $result, 'PASS' => 'result is properly set';

  is $test_output[0], "Building and testing Term-ReadLine-Perl-1.0303\n"
     => 'test output starts ok';

  is $test_output[-1], "-> OK\n" => 'test output finishes ok';
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};


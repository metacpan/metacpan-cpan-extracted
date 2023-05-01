use strict;
use warnings;
use Test::More tests => 15;
use App::cpanminus::reporter;


my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.mixed_schema.log',
  'ignore-versions' => 1,
), 'created new reporter object';

my $current_report_id = 0;
my @reports = (
  {
    fetch    => 'http://www.cpan.org/authors/id/J/JK/JKEENAN/IO-Capture-Extended-0.13.tar.gz',
    resource => 'J/JK/JKEENAN/IO-Capture-Extended-0.13.tar.gz',
    dist     => 'IO-Capture-Extended-0.13',
    result   => 'PASS',
    output   => {
      total_lines => 12,
      first_line  => "Building and testing IO-Capture-Extended-0.13\n",
      last_line   => "Result: PASS\n",
    },
  },
  {
    fetch    => 'file:///home/username/minicpan/authors/id/J/JK/JKEENAN/Data-Presenter-1.03.tar.gz',
    resource => 'J/JK/JKEENAN/Data-Presenter-1.03.tar.gz',
    dist     => 'Data-Presenter-1.03',
    result   => 'PASS',
    output   => {
      total_lines => 21,
      first_line  => "Building and testing Data-Presenter-1.03\n",
      last_line   => "Result: PASS\n",
    },
  },
);


sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;
  return if $current_report_id >= @reports;

  my $current_report = $reports[$current_report_id++];

  is $reporter, $self, 'got the reporter object';
  is $resource, $current_report->{fetch}
     => "resource for $current_report->{dist} was properly fetched";

  is $dist, $current_report->{dist} => 'dist is properly set';
  is $result, $current_report->{result} => 'result is properly set';

  is scalar @test_output, $current_report->{output}{total_lines}
     => 'test output line count seems legit';

  is $test_output[0], $current_report->{output}{first_line}
     => 'test output starts ok';

  is $test_output[-1], $current_report->{output}{last_line}
     => 'test output finishes ok';
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};


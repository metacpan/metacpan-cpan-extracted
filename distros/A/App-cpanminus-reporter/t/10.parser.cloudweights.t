use strict;
use warnings;
use Test::More tests => 36;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.cloudweights.log', 
  'ignore-versions' => 1,
), 'created new reporter object';

my $current_report_id = 0;
my @reports = (
  {
    resource => 'R/RG/RGARCIA/Sub-Identify-0.04.tar.gz',
    dist     => 'Sub-Identify-0.04',
    result   => 'PASS',
    output   => {
      total_lines => 32,
      first_line  => "Building and testing Sub-Identify-0.04\n",
      last_line   => "Result: PASS\n",
    },
  },
  {
    resource => 'F/FR/FRIEDO/namespace-sweep-0.006.tar.gz',
    dist     => 'namespace-sweep-0.006',
    result   => 'PASS',
    output   => {
      total_lines => 18,
      first_line  => "Building and testing namespace-sweep-0.006\n",
      last_line   => "Result: PASS\n",
    },
  },
  {
    resource => 'T/TO/TOBYINK/Exporter-Tiny-0.036.tar.gz',
    dist     => 'Exporter-Tiny-0.036',
    result   => 'PASS',
    output   => {
      total_lines => 14,
      first_line  => "Building and testing Exporter-Tiny-0.036\n",
      last_line   => "Result: PASS\n",
    },
  },
  {
    resource => 'T/TO/TOBYINK/Type-Tiny-0.040.tar.gz',
    dist     => 'Type-Tiny-0.040',
    result   => 'PASS',
    output   => {
      total_lines => 237,
      first_line  => "Building and testing Type-Tiny-0.040\n",
      last_line   => "Result: PASS\n",
    },
  },
  {
    resource => 'P/PJ/PJFL/data-cloudweights/Data-CloudWeights-0.12.1.tar.gz',
    dist     => 'Data-CloudWeights-0.12.1',
    result   => 'PASS',
    output   => {
      total_lines => 36,
      first_line  => "Building and testing Data-CloudWeights-0.12.1\n",
      last_line   => "Result: PASS\n",
    },
  },
);


sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;
  return if $current_report_id >= @reports;

  my $current_report = $reports[$current_report_id++];

  is $reporter, $self, 'got the reporter object';
  is $resource, 'http://www.cpan.org/authors/id/' . $current_report->{resource}
     => "resource for $current_report->{dist} is properly set";

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


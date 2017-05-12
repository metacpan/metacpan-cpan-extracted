use strict;
use warnings;
use Test::More; # tests => 7;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.moose.log',
  'ignore-versions' => 1,
), 'created new reporter object';

my @parsed = (
    {
        author => 'LEONT',
        dist   => 'LEONT/ExtUtils-HasCompiler-0.013.tar.gz',
        result => 'UNKNOWN',
    },
    {
        author => 'PEVANS',
        dist   => 'PEVANS/Scalar-List-Utils-1.45.tar.gz',
        result => 'PASS',
    },
    {
        author => 'ETHER',
        dist   => 'ETHER/Moose-2.1705-TRIAL.tar.gz',
        result => 'PASS',
    },
    {
        author => 'RJBS',
        dist   => 'RJBS/App-Cmd-0.330.tar.gz',
        result => 'PASS',
    },
    {
        author => 'RJBS',
        dist   => 'RJBS/Dist-Zilla-5.044.tar.gz',
        result => 'PASS',
    },
);

my $i =0;
sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;

  $self->parse_uri($resource);

  is $self->author, $parsed[$i]->{author};
  is $self->distfile, $parsed[$i]->{dist};
  is $result, $parsed[$i]->{result};
  $i++;
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};

done_testing;

use strict;
use warnings;
use Test::More tests => 8;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.missing.log',
  'ignore-versions' => 1,
), 'created new reporter object';

my @parsed = (
    {
        author => 'FDALY',
        dist   => 'FDALY/Test-Tester-0.109.tar.gz',
        result => 'PASS',
    },
    {
        author => 'AUDREYT',
        dist   => 'AUDREYT/Test-use-ok-0.11.tar.gz',
        result => 'PASS',
    },
);

my $i = 0;
sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;

  $self->parse_uri($resource);
  is $self->author, $parsed[$i]->{author}, 'found the right author';
  is $self->distfile, $parsed[$i]->{dist}, 'found the right dist';
  is $result, $parsed[$i]->{result}, 'found the right result';
  $i++;
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};

pass 'parser runs on build.log where configure failed';


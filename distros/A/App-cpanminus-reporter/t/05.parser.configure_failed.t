use strict;
use warnings;
use Test::More tests => 7;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force             => 1, # ignore mtime check on build.log
  build_logfile     => $dir . '/build.configure_failed.log',
  'ignore-versions' => 1,
), 'created new reporter object';

sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;
  $self->parse_uri($resource);
  is $self->author, 'BOBW', 'found the right author';
  is(
    $self->distfile,
    'BOBW/X86-Udis86-1.7.2.3.tar.gz',
    'found the right dist'
  );
  is $result, 'NA', 'found the right result';
  is $test_output[0], "Running Makefile.PL\n";
  is $test_output[-1], "-> FAIL Configure failed for X86-Udis86-v1.7.2.3. See /Users/garu/.cpanm/work/1395033276.12482/build.log for details.\n";
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};

pass 'parser runs on build.log where configure failed';


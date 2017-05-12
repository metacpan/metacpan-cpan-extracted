use strict;
use warnings;
use Test::More tests => 3;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.module_dir.log', 
  'ignore-versions' => 1,
), 'created new reporter object';


sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;

  $self->parse_uri($resource);

  is $self->author, "AMBS";
  is $self->distfile, "AMBS/Lingua/Lingua-NATools-v0.7.8.tar.gz";
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};


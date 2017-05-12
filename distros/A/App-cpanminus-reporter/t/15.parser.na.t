use strict;
use warnings;
use Test::More tests => 5;
use App::cpanminus::reporter;

my $dir = -d 't' ? 't/data' : 'data';
ok my $reporter = App::cpanminus::reporter->new(
  force => 1, # ignore mtime check on build.log
  build_logfile => $dir . '/build.na.log',
  'ignore-versions' => 1,
), 'created new reporter object';


sub test_make_report {
  my ($self, $resource, $dist, $result, @test_output) = @_;

  $self->parse_uri($resource);

  is $self->author, 'ETHER', 'found the right author';
  is(
    $self->distfile,
    'ETHER/Dist-Zilla-Plugin-MungeFile-WithDataSection-0.007.tar.gz',
    'found the right dist'
  );
  is $result, 'NA', 'found the right result';
  is_deeply( \@test_output, [
    qq(Running Build.PL\n),
    qq(Perl v5.9.5 required--this is only v5.8.9, stopped at Build.PL line 2.\n),
    qq(BEGIN failed--compilation aborted at Build.PL line 2.\n),
    qq(Running Makefile.PL\n),
    qq(Perl v5.9.5 required--this is only v5.8.9, stopped at Makefile.PL line 64.\n),
    qq(BEGIN failed--compilation aborted at Makefile.PL line 64.\n),
    qq(Congratulations, your toolchain understands 'configure_requires'!\n),
    qq(-> N/A\n),
    qq(-> FAIL Configure failed for Dist-Zilla-Plugin-MungeFile-WithDataSection-0.007. See /Users/ether/.cpanm/work/1398728750.58077/build.log for details.\n),
  ],
  'NA test output');
}

{
  no warnings 'redefine';
  local *App::cpanminus::reporter::_check_cpantesters_config_data = sub { 1 };
  local *App::cpanminus::reporter::make_report = \&test_make_report;
  $reporter->run;
};


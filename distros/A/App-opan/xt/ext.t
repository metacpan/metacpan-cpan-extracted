use strictures 2;
use Test::More;
use File::chdir;
use File::Path qw(mkpath rmtree);
use Mojo::File qw(path);
use Capture::Tiny qw(capture_merged);

delete @ENV{qw(
  PERL_MM_OPT PERL_MB_OPT
  PASTHRU PASTHRU_DEFINE PASTHRU_INC
  PREFIX INSTALL_BASE
  PERL_LOCAL_LIB_ROOT
  PERL_CPANM_OPT
  MAKEFLAGS
)};

#use Data::Dumper; die Dumper \%ENV;

my $app = require "./script/opan";

my $orig_dir = $CWD;

{
  rmtree my $wdir = 'xt/scratch';
  mkpath $wdir;
  local $CWD = $wdir;
  $app->start('init');
  $app->start(add => $orig_dir.'/t/fix/M-1.tar.gz');
  $app->start('merge');
  diag(capture_merged { $app->start(cpanm => -L => 'cpanm' => -n => 'M') });
  path('cpanfile')->spurt("requires 'M';\n");
  diag(capture_merged { $app->start(carton => 'install') });

  ok(-d 'cpanm');
  ok(-d 'local');
  ok(-f 'cpanfile.snapshot');
}

done_testing;

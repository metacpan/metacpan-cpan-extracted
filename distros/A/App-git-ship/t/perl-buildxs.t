use lib '.';
use t::Util;
use App::git::ship::perl;

t::Util->goto_workdir('perl-build', 0);

my $fat_re = qr{\s+=>\s+};

my $app = App::git::ship::perl->new;
$app->start('Perl/Build.pm', 0);

touch(File::Spec->catfile($_)) for qw(Build.xs module.c);

my $main_module_path = $app->config('main_module_path');
$app->_render_makefile_pl;
t::Util->test_file(
  'Makefile.PL',
  qr/OBJECT${fat_re}'Build.o module.o'/m,
);

done_testing;

sub touch {
  open my $FH, '>>', shift;
}

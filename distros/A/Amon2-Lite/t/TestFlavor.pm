use strict;
use warnings;
use utf8;

package t::TestFlavor;
use parent qw(Exporter);
our @EXPORT = qw(test_flavor);
use File::Temp qw/tempdir/;
use App::Prove;
use File::Basename;
use Cwd;
use File::Spec;
use Plack::Util;
use Test::More;

sub test_flavor {
    my ($code, $flavor_class) = @_;

	local $ENV{PLACK_ENV} = 'development';
    $flavor_class = Plack::Util::load_class($flavor_class, 'Amon2::Setup::Flavor');

    my $libpath = File::Spec->rel2abs(File::Spec->catfile(dirname(__FILE__), '..', 'lib'));
    unshift @INC, $libpath;

    my $dir = tempdir(CLEANUP => $ENV{DEBUG} ? 0 : 1);
    my $cwd = Cwd::getcwd();
    chdir($dir);
    note $dir;

    {
        my $flavor = $flavor_class->new(module => 'My::App');
        $flavor->run;
        $code->($flavor);

        # run prove
        my $app = App::Prove->new();
        $app->process_args('--norc', '--exec', "$^X -Ilib -Mlib=$libpath", <t/*.t>);
        ok($app->run);
    }

    chdir($cwd);
}

1;


use warnings;
use Data::Dumper;
use Test::More qw/no_plan/;
use Cwd qw/fastcwd/;
use File::Spec;

BEGIN { use_ok('Bio::Grid::Run::SGE::Util', 'my_glob', 'expand_path'); }

my $d;
sub TEST { $d = $_[0]; }
{
    my $dir = fastcwd();
    diag $dir;

    my $fakedir = 'to/nirvana';

    is( expand_path($fakedir), File::Spec->catfile($dir, $fakedir));

    #diag expand_path('~/asdfasdf/asdfasdf/asdf');
}



#TESTS

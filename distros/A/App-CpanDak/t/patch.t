use Test2::V0;
use Cwd;
use App::CpanDak;
use Path::Tiny;

my $start_path = cwd();

$ENV{PERL_CPANDAK_SPECIALS_PATH} = Cwd::abs_path('t/specials');

my $cpan = App::CpanDak->new();
$cpan->{base} = Path::Tiny->tempdir;
$cpan->init_tools;

$cpan->{dak_dist} = [ {
    filename => 'test-dist.tar.gz',
    dist => 'test-dist',
    version => '1.2',
    source => 'local',
    uris => [ 'file://' . Cwd::abs_path('t/test-dist.tar.gz') ],
} ];

my ($dist, $dir) = $cpan->fetch_module($cpan->dak_dist);

my $readme = path($dir)->child('README.txt')->slurp;

like $readme, qr/modified/, 'patching should work';

chdir($start_path);

done_testing;

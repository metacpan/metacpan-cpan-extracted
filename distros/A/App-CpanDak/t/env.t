use Test2::V0;
use App::CpanDak;

my $env;
my $cpanm = mock 'App::cpanminus::script' => (
    override => [
        configure => sub {
            $env = { %ENV };
        },
    ],
);

$ENV{PERL_CPANDAK_SPECIALS_PATH} = 't/specials';

my $cpan = App::CpanDak->new();
$cpan->{dak_dist} = [ {
    filename => 'Dak-Test',
    dist => 'Dak-Test',
    version => '1.2',
    source => 'test',
} ];

$cpan->configure();

is $env,
    hash {
        field ADDED => 'something';
        field PERL_CPANDAK_SPECIALS_PATH => DNE();
        etc;
    },
    'env manipulation should work';

done_testing;

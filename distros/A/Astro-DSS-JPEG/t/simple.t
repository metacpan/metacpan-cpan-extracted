use Test2::V0;
use Test2::Mock;
use Test::MockObject;

use Astro::DSS::JPEG;
use LWP::UserAgent;

use utf8;

# The test won't actually fetch data over the internet. This is to ensure it will
# not fail even if the DSS & SIMBAD endpoints change - you can still use the module
# by passing the updated urls to the constructor.

my $dss = Astro::DSS::JPEG->new(
    dss_url    => 'xxx',
    simbad_url => 'xxx',
    ua         => LWP::UserAgent->new()
);

ok($dss, 'Object OK');

subtest '_convert_coordinates' => sub {
    my @test = (
        {
            ra  => '06 30 3.6',
            dec => '+15 45 36',
        },
        {
            ra  => '6h30m3.6s',
            dec => q{ +15d 45'36"},
        },
        {
            ra  => '6h30′3.6″',
            dec => '15°45′36″',
        },
        {
            ra  => '6.501',
            dec => '15.76',
        },
    );

    is({Astro::DSS::JPEG::_convert_coordinates(%$_)}, {ra => 6.501, dec => 15.76}, 'Converted coords')
        for @test;
    is(warnings {Astro::DSS::JPEG::_convert_coordinates()}, [], 'No warnings on undef');
    is({Astro::DSS::JPEG::_convert_coordinates(dec => '-15 45 36')}, {dec => -15.76}, 'Converted negative dec');
};

subtest '_process_options' => sub {
    my $default = {angular_size => 30, angular_size_y => 30, pixel_size => 1000, pixel_size_y => 1000};
    is({Astro::DSS::JPEG::_process_options()}, $default, 'Default options');
    is({Astro::DSS::JPEG::_process_options(angular_size => '0x0', pixel_size => '0x0')}, $default, 'Default options');
    is(
        { Astro::DSS::JPEG::_process_options(angular_size => '30x60', %$_) },
        { %$default, angular_size_y => 60, pixel_size_y => 2000 },
        'x,y sizes'
    ) for {pixel_size => '1000,2000'}, {pixel_size => '1000'};
    is(
        {
            Astro::DSS::JPEG::_process_options(
                angular_size => '120,60',
                pixel_size   => '12000,6000'
            )
        },
        {
            angular_size   => 120,
            angular_size_y => 60,
            pixel_size     => 4096,
            pixel_size_y   => 3600
        },
        'Limit pixel size'
    );

};

eval { $dss->get_image(target => 'M1') };
like( $@, qr/Could not access SIMBAD/, "Tried to access SIMBAD" );

eval { $dss->get_image(target => 'M1', ra => 1) };
like( $@, qr/Could not access SIMBAD/, "Tried to access SIMBAD" );

eval { $dss->get_image(target => 'M1', ra => 1, dec => 1) };
like( $@, qr/Could not access DSS/, "Tried to access DSS" );

$dss = Astro::DSS::JPEG->new();

my $mock_result = Test::MockObject->new();
$mock_result->set_true( 'is_success' );
$mock_result->set_true( 'decoded_content' );
my $mock = Test2::Mock->new(
    class => 'LWP::UserAgent',
    override => [
        get => sub { $mock_result },
    ],
);

eval { $dss->_get_simbad(target => 'M1') };
like( $@, qr/Could not parse SIMBAD/, "Tried to parse SIMBAD" );

my $SIMBAD = '
Coordinates(ICRS,ep=J2000,eq=2000): 06 43 14.6852097640  +65 40 38.949836611 (Opt ) C [1.5736 2.7083 90] 2018yCat.1345....0G
Coordinates(FK4,ep=B1950,eq=1950): 06 38 15.3137510911  +65 43 36.219401450
';

$mock_result->mock( 'decoded_content', sub { $SIMBAD } );
is(
    $dss->_get_simbad( target => 'M1' ),
    { ra => '06 43 14.6852097640', dec => '+65 40 38.949836611', target => 'M1' },
    'Parsed SIMBAD coordinates'
);

$SIMBAD .= 'Angular size: 0.417 0.317  30 (NIR )  C 2006AJ....131.1163S';
my $sim_result = { ra => '06 43 14.6852097640', dec => '+65 40 38.949836611', angular_size => 0.417*1.5, target => 'M1' };
$mock_result->mock( 'decoded_content', sub { $SIMBAD } );
is(
    $dss->_get_simbad( target => 'M1' ),
    $sim_result,
    'Parsed SIMBAD coordinates'
);

my $mock2 = Test2::Mock->new(
    class => 'Astro::DSS::JPEG',
    override => [
        _get_simbad => sub { $sim_result },
    ],
);

$mock_result->mock( 'decoded_content', sub { 'data' } );
my $img = $dss->get_image(target => 'M1', ra => 1);
is($img, 'data', 'Got image from decoded_content');
my $file = 'M1.jpg';
my $res = $dss->get_image(ra => 1, dec => 1, filename => $file);
is($res->is_success, T(), 'Got HTTP response');
unlink ($file) if -f $file;

# For Devel::Cover
$mock = Test2::Mock->new(
    class => 'LWP::UserAgent',
    override => [
        new => sub { undef },
    ],
);
$dss = Astro::DSS::JPEG->new();

done_testing;
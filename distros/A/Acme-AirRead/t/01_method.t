use strict;
use warnings;
use Test::More;
use Acme::AirRead;

subtest 'write and read air' => sub {
    write_air(
        air     => 'cant read air',
        declair => 'cant read near air',
        luft    => 'kann keine Luft lesen',
        kuuki   => 'yomenai',
    );

    my $air = read_air('air');
    ok( !defined $air, 'cant get air' );
    my $declair = read_air('declair');
    ok( !defined $declair, 'cant get declair' );
    my $luft = read_air('Luft');
    ok( !defined $luft, 'kann keine Luft lesen' );
    my $kuuki = read_air('kuuki');
    ok( defined $kuuki, 'get kuuki' );
    is( $kuuki, 'yomenai', 'kuuki yometa' );
};

subtest 'i want to read air' => sub {
    empty_air();
    my $del_kuuki = read_air('kuuki');
    ok( !defined $del_kuuki, 'kuuki kieta' );
    write_air(
        air   => 'cant air',
        kuuki => 'yomenai',
        tokyo => 'yomenai',
    );

    local $Acme::AirRead::NO_READ = qr{ky};
    my $air = read_air('air');
    ok( defined $air, 'i can read air' );
    is( $air, 'cant air', 'yometayo-' );
    my $kuuki = read_air('kuuki');
    ok( defined $kuuki, 'i can read kuuki' );
    my $ky = read_air('tokyo');
    ok( !defined $ky, 'cant read ky' );
};

done_testing;

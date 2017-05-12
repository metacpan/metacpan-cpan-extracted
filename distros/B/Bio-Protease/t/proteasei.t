use Test::More;
use Modern::Perl;
use Test::Exception;

{
    package My::Protease;
    use Moose;
    with qw(Bio::ProteaseI);

    sub _cuts {
        my ( $self, $substrate ) = @_;

        if ( $substrate eq 'MAELVIKP' ) { return 1 }
        else                            { return   }
    };

}

my $protease = My::Protease->new;

isa_ok( $protease, 'My::Protease' );

can_ok( $protease, qw(cut is_substrate digest cleavage_sites) );

my $seq = 'AAAAMAELVIKPYYYYYYY';

ok $protease->cut($seq, 8), 'Cut works';
throws_ok { $protease->cut            } qr/Incorrect substrate/;
throws_ok { $protease->cut(42)        } qr/Incorrect substrate/;
throws_ok { $protease->cut('foo')     } qr/Incorrect position/;
throws_ok { $protease->cut('foo', 42) } qr/Incorrect position/;
throws_ok { $protease->cut('foo', -1) } qr/Incorrect position/;

ok $protease->is_substrate($seq);
throws_ok { $protease->is_substrate     } qr/Incorrect substrate/;
throws_ok { $protease->is_substrate(42) } qr/Incorrect substrate/;

is_deeply [$protease->cleavage_sites($seq)], [8];
throws_ok { $protease->cleavage_sites     } qr/Incorrect substrate/;
throws_ok { $protease->cleavage_sites(42) } qr/Incorrect substrate/;

throws_ok { $protease->digest     } qr/Incorrect substrate/;
throws_ok { $protease->digest(42) } qr/Incorrect substrate/;

my @products = $protease->digest( 'AAAAMAELVIKPYYYYYYY' );

is_deeply(
    \@products, ["AAAAMAEL", "VIKPYYYYYYY"],
    "Subclassing works as expected"
);

done_testing();

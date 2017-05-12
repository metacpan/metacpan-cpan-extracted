use Modern::Perl;
use Test::Exception;
use Test::More;

{
    package My::Protease;
    use Moose;

    with qw(Bio::ProteaseI Bio::Protease::Role::Specificity::Regex);

    has '+regex' => ( init_arg => 'specificity' );
    has 'specificity' => ( is => 'ro', default => 'regex', init_arg => undef );
}

my $p;

lives_ok { $p = My::Protease->new( specificity => qr/AAA.{5}/ ) };

is_deeply( $p->regex, [ qr/AAA.{5}/ ] );

ok $p->cut('AAACCCCC', 4);

is_deeply( [ $p->digest( 'AAACCCCC' ) ], [ 'AAAC', 'CCCC' ] );

dies_ok { $p = My::Protease->new( specificity => 'foo' ) };

done_testing();

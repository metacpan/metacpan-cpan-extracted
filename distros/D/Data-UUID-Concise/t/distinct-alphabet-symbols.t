use strictures;
use Data::UUID::Concise;
use Test::More;

my $duc = Data::UUID::Concise->new;

{
    $duc->alphabet( 'aaaaabcdefgh1230123' );
    my $new_alphabet = $duc->alphabet;
    ok( $new_alphabet, '0123abcdefgh' );
}

done_testing;

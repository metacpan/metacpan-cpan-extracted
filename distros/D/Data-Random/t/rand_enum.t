use strict;
use warnings;

use Test::More;
use Data::Random qw( rand_enum );

my %charsets = (
    a => [],
    b => ['A'],
    c => [ 'A', 'B' ],
    d => [ 'A' .. 'Z' ],
);

my %valid_chars;

foreach my $charset ( keys %charsets ) {
    @{ $valid_chars{$charset} }{ @{ $charsets{$charset} } } = ();
}

# Test default w/ no params -- should return one entry
{
    my $pass = 1;

    foreach my $charset ( keys %charsets ) {

        my $num_chars = @{ $charsets{$charset} };

        my $i = 0;
        while ( $pass && $i < $num_chars ) {
            my @chars = rand_enum( set => $charsets{$charset} );

            $pass = 0
              unless ( @chars == 1
                && exists( $valid_chars{$charset}->{ $chars[0] } ) );

            $i++;
        }

    }

    ok($pass);
}

done_testing;

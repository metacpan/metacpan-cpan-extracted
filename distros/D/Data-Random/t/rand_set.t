use strict;
use warnings;

use Test::More;
use Data::Random qw( rand_set );

use vars qw( %charsets );

%charsets = (
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
            my @chars = rand_set( set => $charsets{$charset} );

            $pass = 0
              unless ( @chars == 1
                && exists( $valid_chars{$charset}->{ $chars[0] } ) );

            $i++;
        }

    }

    ok($pass);
}

# Test size option
{
    my $pass = 1;

    foreach my $charset ( keys %charsets ) {

        my $num_chars = @{ $charsets{$charset} };

        my $i = 0;
        while ( $pass && $i < $num_chars ) {
            my @chars = rand_set( set => $charsets{$charset}, size => $i + 1 );

            $pass = 0 unless @chars == ( $i + 1 );

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $i++;
        }

    }

    ok($pass);
}

# Test max/min option
{
    my $pass = 1;

    foreach my $charset ( keys %charsets ) {

        my $num_chars = @{ $charsets{$charset} };

        my $i = 0;
        while ( $pass && $i < $num_chars ) {
            my @chars = rand_set(
                set => $charsets{$charset},
                min => $i,
                max => $num_chars
            );

            $pass = 0 unless ( @chars >= $i && @chars <= $num_chars );

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $i++;
        }

    }

    ok($pass);
}

# Test size w/ min/max set
{
    my $pass = 1;

    foreach my $charset ( keys %charsets ) {

        my $num_chars = @{ $charsets{$charset} };

        my $i = 0;
        while ( $pass && $i < $num_chars ) {
            my @chars = rand_set(
                set  => $charsets{$charset},
                size => $i + 1,
                min  => $i,
                max  => $num_chars
            );

            $pass = 0 unless @chars == ( $i + 1 );

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $i++;
        }

    }

    ok($pass);
}

# Test w/ shuffle set to 0
{
    my $pass = 1;

    sub _get_index {
        my ( $charset, $char ) = @_;

        my $i = 0;
        while ( $charsets{$charset}->[$i] ne $char
            && $i < @{ $charsets{$charset} } )
        {
            $i++;
        }

        $i;
    }

    foreach my $charset ( keys %charsets ) {

        my $num_chars = @{ $charsets{$charset} };

        if ( $num_chars >= 2 ) {
            my $i = 0;
            while ( $pass && $i < $num_chars ) {
                my @chars = rand_set(
                    set     => $charsets{$charset},
                    size    => 2,
                    shuffle => 0
                );

                $pass = 0
                  unless ( @chars == 2
                    && _get_index( $charset, $chars[0] ) <
                    _get_index( $charset, $chars[1] ) );

                foreach (@chars) {
                    $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
                }

                $i++;
            }
        }

    }

    ok($pass);
}

done_testing;

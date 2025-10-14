use strict;
use warnings;

use Test::More;
use Data::Random qw( rand_chars );

use vars qw( %charsets );

%charsets = (
    all => [
        0 .. 9,
        'a' .. 'z',
        'A' .. 'Z',
        '#',
        ',',
        qw( ~ ! @ $ % ^ & * ( ) _ + = - { } | : " < > ? / . ' ; [ ] ` ),
        "\\",
    ],
    alpha      => [ 'a' .. 'z',  'A' .. 'Z' ],
    upperalpha => [ 'A' .. 'Z' ],
    loweralpha => [ 'a' .. 'z' ],
    numeric    => [ 0 .. 9 ],
    alphanumeric => [ 0 .. 9, 'a' .. 'z', 'A' .. 'Z' ],
    misc         => [
        '#',
        ',',
        qw( ~ ! @ $ % ^ & * ( ) _ + = - { } | : " < > ? / . ' ; [ ] ` ),
        "\\",
    ],
);

my %valid_chars;
my $string;

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
            my @chars = rand_chars( set => $charsets{$charset} );

            $pass = 0
              unless ( @chars == 1
                && exists( $valid_chars{$charset}->{ $chars[0] } ) );

            $string = rand_chars( set => $charsets{$charset} );
            if (length($string) != 1 || !valid_chars($string, $charset)) {
                $pass = 0;
            }

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
            my $expected_length = $i + 1;
            my @chars = rand_chars( set => $charsets{$charset},
                                   size => $expected_length);

            $pass = 0 unless @chars == $expected_length;

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $string = rand_chars( set => $charset, size => $expected_length );
            if (   length($string) != $expected_length
                || !valid_chars($string, $charset))
            {
                $pass = 0;
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
            my @chars = rand_chars(
                set => $charsets{$charset},
                min => $i,
                max => $num_chars
            );

            $pass = 0 unless ( @chars >= $i && @chars <= $num_chars );

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $string = rand_chars( set => $charsets{$charset},
                                  min => $i,
                                  max => $num_chars
                                );
            if (   length($string) < $i
                || length($string) > $num_chars
                || !valid_chars($string, $charset))
            {
                $pass = 0;
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
            my $expected_length = $i + 1;
            my @chars = rand_chars(
                set  => $charsets{$charset},
                size => $expected_length,
                min  => $i,
                max  => $num_chars
            );

            $pass = 0 unless @chars == $expected_length;

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $string = rand_chars( set  => $charsets{$charset},
                                  size => $i + 1,
                                  min  => $i,
                                  max  => $num_chars
                                );
            if (   length($string) != $expected_length
                || !valid_chars($string, $charset))
            {
                $pass = 0;
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

        my $i = 0;
        while ( $pass && $i < $num_chars ) {
            my $expected_length = 2;
            my @chars =
              rand_chars( set     => $charsets{$charset},
                          size    => $expected_length,
                          shuffle => 0 );

            $pass = 0
              unless ( @chars == $expected_length
                && _get_index( $charset, $chars[0] ) <
                _get_index( $charset, $chars[1] ) );

            foreach (@chars) {
                $pass = 0 unless exists( $valid_chars{$charset}->{$_} );
            }

            $string = rand_chars( set     => $charsets{$charset},
                                  size    => $expected_length,
                                  shuffle => 0,
                                );
            if (   length($string) != $expected_length
                || !valid_chars($string, $charset)
                || (  _get_index($charset, substr($string, 0, 1))
                    > _get_index($charset, substr($string, 1, 1))
                   )
               )
            {
                $pass = 0;
            }

            $i++;
        }

    }

    ok($pass);
}

sub valid_chars
{
    my $string  = shift;
    my $charset = shift;

    foreach my $char (split('', $string)) {
        return 0 if !exists($valid_chars{$charset}{$char});
    }

    return 1;
}

done_testing;

#!/usr/bin/perl -w

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Colon::Config;
use Benchmark;

our $DATA;

my $map = {
    read_xs => sub {
        return Colon::Config::read( $DATA );
    },
    read_pp => sub {
        return Colon::Config::read_pp( $DATA ); # limitation on \s+
    },
};

note "sanity check";

foreach my $method ( sort keys %$map ) {

    $DATA = <<EOS;
key1: value
key2: another value
EOS
    is $map->{$method}->(), [ 'key1' => 'value', 'key2' => 'another value' ], "sanity check: '$method'" or die;
}

note "Running benchmark";
for my $size ( 1, 4, 16, 64, 256, 1024 ) {
    note "Using $size key/value pairs\n";

    $DATA = '';
    foreach my $id ( 1..$size ) {
        $DATA .= "key$id: value is $id\n";
    }
    Benchmark::cmpthese( - 5 => $map );
    note "";
}

=pod

        # Using 1 key/value pairs
                     Rate read_pp read_xs
        read_pp  442226/s      --    -75%
        read_xs 1767796/s    300%      --
        #
        # Using 4 key/value pairs
                    Rate read_pp read_xs
        read_pp 172602/s      --    -68%
        read_xs 532991/s    209%      --
        #
        # Using 16 key/value pairs
                    Rate read_pp read_xs
        read_pp  52187/s      --    -64%
        read_xs 145873/s    180%      --
        #
        # Using 64 key/value pairs
                   Rate read_pp read_xs
        read_pp 13307/s      --    -66%
        read_xs 39519/s    197%      --
        #
        # Using 256 key/value pairs
                   Rate read_pp read_xs
        read_pp  3533/s      --    -65%
        read_xs 10228/s    189%      --
        #
        # Using 1024 key/value pairs
                  Rate read_pp read_xs
        read_pp  899/s      --    -60%
        read_xs 2265/s    152%      --

=cut

# checking field

$map = {
    split => sub {
        return { map { ( split(m{:}), 3 )[ 0, 2 ] } split( m{\n}, $DATA ) }
    },

    # colon => sub {
    #     my $a = Colon::Config::read( $DATA );
    #     for ( my $i = 1 ; $i < scalar @$a; $i += 2 ) {
    #         next unless defined $a->[ $i ];
    #         # preserve bogus behavior
    #         #do { $a->[ $i ] = 3; next } unless index( $a->[ $i ], ':' ) >= 0;
    #         # suggested fix
    #         #next unless index( $a->[ $i ], ':' ) >= 0;
    #         $a->[ $i ] = ( split(  ':', $a->[ $i ], 3 ) ) [ 1 ] // 3; # // 3 to preserve bogus behavior
    #     }

    #     return { @$a };
    # },

    field => sub {
        return Colon::Config::read_as_hash( $DATA, 2 );
    },
};

# sanity check
$DATA = <<EOS;
john:f1:f2:f3:f4
cena:f1:f2:f3:f4
EOS

foreach my $method ( sort keys %$map ) {
    is $map->{$method}->(), { john => 'f2', cena => 'f2' }, "testing $method";    
}

note "Running benchmark";
for my $size ( 1, 4, 16, 64, 256, 1024 ) {
    note "Using $size key/value pairs\n";

    $DATA = '';
    foreach my $id ( 1..$size ) {
        $DATA .= "key$id:f1:f2:f3:f4\n";
    }
    Benchmark::cmpthese( - 5 => $map );
    note "";
}

=pod

        # Using 1 key/value pairs
                  Rate split field
        split 563142/s    --   -9%
        field 617929/s   10%    --
        #
        # Using 4 key/value pairs
                  Rate split field
        split 183828/s    --  -30%
        field 261684/s   42%    --
        #
        # Using 16 key/value pairs
                 Rate split field
        split 49493/s    --  -39%
        field 81617/s   65%    --
        #
        # Using 64 key/value pairs
                 Rate split field
        split 12753/s    --  -45%
        field 23247/s   82%    --
        #
        # Using 256 key/value pairs
                Rate split field
        split 3041/s    --  -42%
        field 5237/s   72%    --
        #
        # Using 1024 key/value pairs
                Rate split field
        split  728/s    --  -41%
        field 1235/s   70%    --

=cut

done_testing;

__END__


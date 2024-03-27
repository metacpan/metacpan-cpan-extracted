#! perl

use Test2::V0;
use experimental 'declared_refs';

use CXC::Types::Astro::Coords::Util -all;

my @args;

my @flag_tests = ( {
        flags => [qw( -units -optws )],
        pass  => ['20d 20m 20s'],
        fail  => ['20:20:20'],
    },

    {
        flags => [qw( -optsep -optws )],
        pass  => ['20: 20: 20'],
        fail  => [],
    },

    {
        flags => [qw( -optsep -optws -optunits )],
        pass  => ['20:20 20s'],
        fail  => ['20:d 20m20'],
    },

    {
        flags => [qw( -sep )],
        pass  => ['20:20:20'],
        fail  => ['20d20m20s'],
    },
);

for my $test ( @flag_tests ) {

    my @flags = $test->{flags}->@*;
    my $label = join( q{, }, @flags );

    subtest $label => sub {

        my %pars = mkSexagesimal( @flags )->%*;
        my $qr   = qr/$pars{qr}/;

        if ( my @inputs = $test->{pass}->@* ) {
            subtest 'pass' => sub {
                ok( $_ =~ $qr, $_ ) for @inputs;
            };
        }

        if ( my @inputs = $test->{fail}->@* ) {
            subtest 'fail' => sub {
                ok( $_ !~ $qr, $_ ) for @inputs;
            };
        }
    };
}

subtest 'from_Degrees' => sub {

    subtest '-ra' => sub {
        is( from_Degrees( 60,  '-ra' ), [ 4, 0, 0 ] );
        is( from_Degrees( -60, '-ra' ), [ 4, 0, 0 ] );
    };

    subtest '-dec' => sub {
        like( dies { from_Degrees( -91, '-dec' ) }, qr/illegal/ );
        is( from_Degrees( 60,  '-dec' ), [ 60,  0, 0 ] );
        is( from_Degrees( -60, '-dec' ), [ -60, 0, 0 ] );
    };

    subtest '-deg' => sub {
        is( from_Degrees( 60,  '-dec' ), [ 60,  0, 0 ] );
        is( from_Degrees( -60, '-dec' ), [ -60, 0, 0 ] );
    };

};

done_testing;

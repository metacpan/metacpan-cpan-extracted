#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Trace;

plan( skip_all => "MAJOR UPDATE. Need to create new tests!!!" );
exit;

my @cases = (

    # Scalar
    {
        name         => "Scalar - not reference",
        expect_error => 1,
        action       => sub {
            my $var = 1;
            Data::Trace->Trace( $var );
        },
    },
    {
        name   => "Scalar - no change",
        action => sub {
            my $var = 1;
            Data::Trace->Trace( \$var );
        },
    },
    {
        name          => "Scalar - local change",
        expect_change => 1,
        action        => sub {
            my $var = 1;
            Data::Trace->Trace( \$var );
            $var = 2;
        },
    },
    {
        name          => "Scalar - anon sub change",
        expect_change => 1,
        action        => sub {
            my $var = 1;
            Data::Trace->Trace( \$var );
            my $sub = sub { $var = 2 };
            $sub->();
        },
    },

    # Array
    {
        name         => "Array - not reference",
        expect_error => 1,
        action       => sub {
            my @var = ( 1, 2, 3 );
            Data::Trace->Trace( @var );
        },
    },
    {
        name   => "Array - no change",
        action => sub {
            my @var = ( 1, 2, 3 );
            Data::Trace->Trace( \@var );
        },
    },
    {
        name          => "Array - local change - change existing",
        expect_change => 1,
        action        => sub {
            my @var = ( 1, 2, 3 );
            Data::Trace->Trace( \@var );
            $var[1] = 4;
        },
    },
    {
        name          => "Array - anon sub change - change existing",
        expect_change => 1,
        action        => sub {
            my @var = ( 1, 2, 3 );
            Data::Trace->Trace( \@var );
            my $sub = sub { $var[1] = 4 };
            $sub->();
        },
    },

    # TODO: Consider implementing watching of push, pop, shift, unshift.
    # {
    #     name          => "Array - local change - remove existing",
    #     expect_change => 1,
    #     action        => sub {
    #         my @var = (1,2,3);
    #         Data::Trace->Trace( \@var );
    #         pop @var;
    #     },
    # },
    # {
    #     name          => "Array - anon sub change - remove existing",
    #     expect_change => 1,
    #     action        => sub {
    #         my @var = (1,2,3);
    #         Data::Trace->Trace( \@var );
    #         my $sub = sub { pop @var };
    #         $sub->();
    #     },
    # },
    # {
    #     name          => "Array - local change - add new",
    #     expect_change => 1,
    #     action        => sub {
    #         my @var = (1,2,3);
    #         Data::Trace->Trace( \@var );
    #         push @var, 4;
    #     },
    # },
    # {
    #     name          => "Array - anon sub change - add new",
    #     expect_change => 1,
    #     action        => sub {
    #         my @var = (1,2,3);
    #         Data::Trace->Trace( \@var );
    #         my $sub = sub { push @var, 4 };
    #         $sub->();
    #     },
    # },

    # Hash
    {
        name         => "Hash - not reference",
        expect_error => 1,
        action       => sub {
            my %var = ( a => 1, b => 2, c => 3 );
            Data::Trace->Trace( %var );
        },
    },
    {
        name   => "Hash - no change",
        action => sub {
            my %var = ( a => 1, b => 2, c => 3 );
            Data::Trace->Trace( \%var );
        },
    },
    {
        name          => "Hash - local change - change existing",
        expect_change => 1,
        action        => sub {
            my %var = ( a => 1, b => 2, c => 3 );
            Data::Trace->Trace( \%var );
            $var{a} = 2;
        },
    },
    {
        name          => "Hash - anon sub change - change existing",
        expect_change => 1,
        action        => sub {
            my %var = ( a => 1, b => 2, c => 3 );
            Data::Trace->Trace( \%var );
            my $sub = sub { $var{a} = 2 };
            $sub->();
        },
    },

    # TODO: Consider implementing watching of delete.
    # {
    #     name          => "Hash - local change - remove existing",
    #     expect_change => 1,
    #     action        => sub {
    #         my %var = ( a => 1, b => 2, c => 3 );
    #         Data::Trace->Trace( \%var );
    #         delete $var{a};
    #     },
    # },
    # {
    #     name          => "Hash - anon sub change - remove existing",
    #     expect_change => 1,
    #     action        => sub {
    #         my %var = ( a => 1, b => 2, c => 3 );
    #         Data::Trace->Trace( \%var );
    #         my $sub = sub { delete $var{a} };
    #         $sub->();
    #     },
    # },
    {
        name          => "Hash - local change - add new",
        expect_change => 1,
        action        => sub {
            my %var = ( a => 1, b => 2, c => 3 );
            Data::Trace->Trace( \%var );
            $var{a2} = 4;
        },
    },
    {
        name          => "Hash - anon sub change - add new",
        expect_change => 1,
        action        => sub {
            my %var = ( a => 1, b => 2, c => 3 );
            Data::Trace->Trace( \%var );
            my $sub = sub { $var{a2} = 4 };
            $sub->();
        },
    },

    # AOA

    # AOH

    # HOA

    # HOH

    # Object
    {
        name          => "Object data",
        expect_change => 1,
        action        => sub {
            my $var = { a => 1, b => [ 5, { c => 3 } ] };
            bless $var, "MyPackage";
            Data::Trace->Trace( $var );
            $var->{b}[1]{c} = 4;
        },
    },

    # Complex
    {
        name          => "Complex data",
        expect_change => 1,
        action        => sub {
            my $var = { a => 1, b => [ 5, { c => 3 } ] };
            Data::Trace->Trace( $var );
            $var->{b}[1]{c} = 4;
        },
    },
);

for my $case ( @cases ) {
    last;    # TODO: Skipping for now.

    # Capture output.
    my $output = "";
    {
        local *STDOUT;
        local *STDERR;
        open STDOUT, ">",  \$output or die $!;
        open STDERR, ">>", \$output or die $!;
        eval { $case->{action}->() };
        if ( $@ ) {
            $output = $@;
            chomp $output;
        }
    }

    # Check if we are getting a output (stack trace)
    # we its expected.

    if ( $case->{expect_change} ) {
        like( $output, qr{ ^ Storing \s here:  }x, "$case->{name} - change" );
    }
    elsif ( $case->{expect_error} ) {
        ok( !!$output, "$case->{name} - error" );
    }
    else {
        is( $output, "", "$case->{name} - no change" );
    }
}

done_testing();


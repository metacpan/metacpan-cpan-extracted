#!/usr/bin/perl
use warnings;
use strict;

use Benchmark qw(:all);
use List::Util qw(shuffle);
use YAML qw(Dump Load DumpFile LoadFile);

use Set::IntSpan;
use Set::IntSpan::Fast;
use Set::IntSpan::Fast::PP;
use Set::IntSpan::Fast::XS;
use AlignDB::IntSpan;
use AlignDB::IntSpanXS;

#----------------------------------------------------------#
# Benchmark 1, including object startup
#----------------------------------------------------------#
{
    my @test_array = (
        1 .. 30,
        32 .. 149,
        153 .. 155,
        159 .. 247,
        250,
        253 .. 464,
        516 .. 518,
        520 .. 523,
        582 .. 585,
        595 .. 600,
        622 .. 1679,
    );

    my $test_si = sub {
        my $step = shift;
        my $set = Set::IntSpan->new if $step >= 1;
        if ( $step >= 2 ) {
            $set->insert($_) for @test_array;
        }
        $set = $set->union( 100 . '-' . 1_000_000 ) if $step >= 3;
        $set->run_list if $step >= 4;
    };

    my $test_sifp = sub {
        my $step = shift;
        my $set = Set::IntSpan::Fast::PP->new if $step >= 1;
        $set->add(@test_array) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    my $test_sifx = sub {
        my $step = shift;
        my $set = Set::IntSpan::Fast::XS->new if $step >= 1;
        $set->add(@test_array) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    my $test_ai = sub {
        my $step = shift;
        my $set = AlignDB::IntSpan->new if $step >= 1;
        $set->add(@test_array) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    my $test_aix = sub {
        my $step = shift;
        my $set = AlignDB::IntSpanXS->new if $step >= 1;
        $set->add_array( \@test_array ) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    for my $step ( 1 .. 4 ) {
        print '-' x 60, "\n";
        print "Benchmark 1, including object startup.\nStep $step: \n";
        cmpthese(
            -2,
            {   'SI'   => sub { $test_si->($step) },
                'SIFP' => sub { $test_sifp->($step) },
                'SIFX' => sub { $test_sifx->($step) },
                'AI'   => sub { $test_ai->($step) },
                'AIX'  => sub { $test_aix->($step) },
            }
        );
    }
}

#----------------------------------------------------------#
# Benchmark 2, excluding object startup
#----------------------------------------------------------#
{
    my @test_array = (
        1 .. 30,
        32 .. 149,
        153 .. 155,
        159 .. 247,
        250,
        253 .. 464,
        516 .. 518,
        520 .. 523,
        582 .. 585,
        595 .. 600,
        622 .. 1679,
    );

    my $set_si   = Set::IntSpan->new;
    my $set_sifp = Set::IntSpan::Fast::PP->new;
    my $set_sifx = Set::IntSpan::Fast::XS->new;
    my $set_ai   = AlignDB::IntSpan->new;
    my $set_aix  = AlignDB::IntSpanXS->new;

    my $test_si = sub {
        my $step = shift;
        my $set  = shift;
        if ( $step >= 2 ) {
            $set->insert($_) for (@test_array);
        }
        $set = $set->union( 100 . '-' . 1_000_000 ) if $step >= 3;
        $set->run_list if $step >= 4;
    };

    my $test_sifp = sub {
        my $step = shift;
        my $set  = shift;
        $set->add(@test_array) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    my $test_sifx = sub {
        my $step = shift;
        my $set  = shift;
        $set->add(@test_array) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    my $test_ai = sub {
        my $step = shift;
        my $set  = shift;
        $set->add(@test_array) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    my $test_aix = sub {
        my $step = shift;
        my $set  = shift;
        $set->add_array( \@test_array ) if ( $step >= 2 );
        $set->add_range( 100, 1_000_000 ) if $step >= 3;
        $set->as_string if $step >= 4;
    };

    for my $step ( 2 .. 4 ) {
        print '-' x 60, "\n";
        print "Benchmark 2, excluding object startup.\nStep $step: \n";
        cmpthese(
            -2,
            {   'SI'   => sub { $test_si->( $step,   $set_si ) },
                'SIFP' => sub { $test_sifp->( $step, $set_sifp ) },
                'SIFX' => sub { $test_sifx->( $step, $set_sifx ) },
                'AI'   => sub { $test_ai->( $step,   $set_ai ) },
                'AIX'  => sub { $test_aix->( $step,  $set_aix ) },
            }
        );
    }
}

#----------------------------------------------------------#
# Benchmark 3, incremental insertion
#----------------------------------------------------------#
{
    my @test_array = ( 1 .. 500, 800 .. 1000 );

    my $test_si = sub {
        my $set = Set::IntSpan->new;
        $set->insert($_) for (@test_array);
    };

    my $test_sifp = sub {
        my $set = Set::IntSpan::Fast::PP->new;
        $set->add(@test_array);
    };

    my $test_sifx = sub {
        my $set = Set::IntSpan::Fast::XS->new;
        $set->add(@test_array);
    };

    my $test_ai = sub {
        my $set = AlignDB::IntSpan->new;
        $set->add(@test_array);
    };

    my $test_aix = sub {
        my $set = AlignDB::IntSpanXS->new;
        $set->add(@test_array);
    };

    my $test_aix2 = sub {
        my $set = AlignDB::IntSpanXS->new;
        $set->add_array( \@test_array );
    };

    print '-' x 60, "\n";
    print "Benchmark 3, incremental insertion.\n";
    cmpthese(
        -2,
        {   'SI'   => sub { $test_si->() },
            'SIFP' => sub { $test_sifp->() },
            'SIFX' => sub { $test_sifx->() },
            'AI'   => sub { $test_ai->() },
            'AIX'  => sub { $test_aix->() },
            'AIX2' => sub { $test_aix2->() },
        }
    );
}

#----------------------------------------------------------#
# Benchmark 4, incremental union
#----------------------------------------------------------#
{
    my @runlists = map { 5 * $_ . '-' . 10 * $_ } ( 1 .. 100 );
    @runlists = shuffle @runlists;

    my $test_si = sub {
        my $set = Set::IntSpan->new;
        $set->U($_) for @runlists;
    };

    my $test_sifp = sub {
        my $set = Set::IntSpan::Fast::PP->new;
        for (@runlists) {
            my $rset = Set::IntSpan::Fast::PP->new($_);
            $set->merge($rset);
        }
    };

    my $test_sifx = sub {
        my $set = Set::IntSpan::Fast::XS->new;
        for (@runlists) {
            my $rset = Set::IntSpan::Fast::XS->new($_);
            $set->merge($rset);
        }
    };

    my $test_ai = sub {
        my $set = AlignDB::IntSpan->new;
        $set->merge($_) for @runlists;
    };

    my $test_aix = sub {
        my $set = AlignDB::IntSpanXS->new;
        $set->merge($_) for @runlists;
    };

    print '-' x 60, "\n";
    print "Benchmark 4, incremental union.\n";
    cmpthese(
        -2,
        {   'SI'   => sub { $test_si->() },
            'SIFP' => sub { $test_sifp->() },
            'SIFX' => sub { $test_sifx->() },
            'AI'   => sub { $test_ai->() },
            'AIX'  => sub { $test_aix->() },
        }
    );
}

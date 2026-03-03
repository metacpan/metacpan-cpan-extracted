# $Id: 06refcnt.t,v 0.22 2007/07/25 03:41:06 ray Exp $
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

my $HAS_WEAKEN;

BEGIN {
    $| = 1;
    my $plan = 25;

    eval 'use Scalar::Util qw( weaken isweak );';
    if ($@) {
        $HAS_WEAKEN = 0;
        $plan       = 15;
    }
    else {
        $HAS_WEAKEN = 1;
    }

    print "1..$plan\n";
}
END { print "not ok 1\n" unless $loaded; }
use Clone qw( clone );
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# code to test for memory leaks

## use Benchmark;
## use Data::Dumper;
# use Storable qw( dclone );

$^W   = 1;
$test = 2;

use strict;

package Test::Hash;

@Test::Hash::ISA = qw( Clone );

sub new() {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;
}

my $ok = 0;
END { $ok = 1; }

sub DESTROY {
    my $self = shift;
    printf("not ") if $ok;
    printf( "ok %d - DESTROY\n", $::test++ );
}

package main;

{
    my $a = Test::Hash->new();
    my $b = $a->clone;

    # my $c = dclone($a);
}

# benchmarking bug
{
    my $a = Test::Hash->new();
    my $sref = sub { my $b = clone($a) };
    $sref->();
}

# test for cloning unblessed ref
{
    my $a = {};
    my $b = clone($a);
    bless $a, 'Test::Hash';
    bless $b, 'Test::Hash';
}

# test for cloning unblessed ref
{
    my $a = [];
    my $b = clone($a);
    bless $a, 'Test::Hash';
    bless $b, 'Test::Hash';
}

# test for cloning ref that was an int(IV)
{
    my $a = 1;
    $a = [];
    my $b = clone($a);
    bless $a, 'Test::Hash';
    bless $b, 'Test::Hash';
}

# test for cloning ref that was a string(PV)
{
    my $a = '';
    $a = [];
    my $b = clone($a);
    bless $a, 'Test::Hash';
    bless $b, 'Test::Hash';
}

# test for cloning ref that was a magic(PVMG)
{
    my $a = *STDOUT;
    $a = [];
    my $b = clone($a);
    bless $a, 'Test::Hash';
    bless $b, 'Test::Hash';
}

# test for cloning weak reference
if ($HAS_WEAKEN) {
    {
        my $a = Test::Hash->new;
        my $b = { r => $a };
        $a->{r} = $b;
        weaken( $b->{'r'} );
        my $c = clone($a);
    }

    # another weak reference problem, this one causes a segfault in 0.24
    {
        my $a = Test::Hash->new;
        {
            my $b = [ $a, $a ];
            $a->{r} = $b;
            weaken( $b->[0] );
            weaken( $b->[1] );
        }

        my $c = clone($a);

        # check that references point to the same thing
        is( $c->{'r'}[0], $c->{'r'}[1], "references point to the same thing" );
        isnt( $c->{'r'}[0], $a->{'r'}[0], "a->{r}->[0] ne c->{r}->[0]" );

        require B;
        my $c_obj = B::svref_2object($c);
        is( $c_obj->REFCNT, 1, 'c REFCNT = 1' )
          or diag( "refcnt is ", $c_obj->REFCNT );

        my $cr_obj = B::svref_2object( $c->{'r'} );
        is( $cr_obj->REFCNT, 1, 'cr REFCNT = 1' )
          or diag( "refcnt is ", $cr_obj->REFCNT );

        my $cr_0_obj = B::svref_2object( $c->{'r'}->[0] );
        is( $cr_0_obj->REFCNT, 1, 'c->{r}->[0] REFCNT = 1' )
          or diag( "refcnt is ", $cr_0_obj->REFCNT );

        my $cr_1_obj = B::svref_2object( $c->{'r'}->[1] );
        is( $cr_1_obj->REFCNT, 1, 'c->{r}->[1] REFCNT = 1' )
          or diag( "refcnt is ", $cr_1_obj->REFCNT );

    }
}

exit;

sub diag {
    my (@msg) = @_;

    print STDERR join( ' ', '#', @msg, "\n" );
    return;
}

sub ok {
    my $msg = shift;
    $msg = '' unless defined $msg;
    $msg = ' - ' . $msg if length $msg;
    printf( "ok %d%s\n", $::test++, $msg );

    return 1;
}

sub not_ok {
    my $msg = shift;
    $msg = '' unless defined $msg;

    printf( "not ok %d %s\n", $::test++, $msg );

    return;
}

sub is {
    my ( $x, $y, $msg ) = @_;

    # dumb for now
    $x = 'undef' if !defined $x;
    $y = 'undef' if !defined $y;

    if ( !defined $x && !defined $y ) {
        return ok($msg);
    }

    if ( !defined $x || !defined $y ) {
        return not_ok($msg);
    }

    if ( $x eq $y ) {
        return ok($msg);
    }
    else {
        return not_ok($msg);
    }
}

sub isnt {
    my ( $x, $y, $msg ) = @_;

    # dumb for now
    $x = 'undef' if !defined $x;
    $y = 'undef' if !defined $y;

    if ( !defined $x && !defined $y ) {
        return no_ok($msg);
    }

    if ( !defined $x || !defined $y ) {
        return ok($msg);
    }

    if ( $x eq $y ) {
        return not_ok($msg);
    }
    else {
        return ok($msg);
    }
}


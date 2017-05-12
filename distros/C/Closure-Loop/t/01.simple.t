use Test::More tests => 6;

package Iter;
use Closure::Loop;

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub forAll {
    my $self = shift;
    my $cb   = pop || die "No callback";

    for my $i (@_) {
        eval {
            $self->yield($cb, $i);
        };
        last if $self->is_last;
        die $@ if $@;
    }
}

package IterB;
use base qw(Iter);

package main;

my $iter = Iter->new();

my @in  = ( 1, 2, 3 );
my @out = ( );

$iter->forAll(@in, sub {
    my $i = shift;
    push @out, $i;
});

is_deeply(\@out, \@in, 'uninterupted loop');

@out = ( );
$iter->forAll(@in, sub {
    my $i = shift;
    $iter->last if $i > 2;
    push @out, $i;
});

is_deeply(\@out, [ 1, 2 ], 'interupted loop');

@out = ( );
$iter->forAll(@in, sub {
    my $i = shift;
    $iter->next if $i == 2;
    push @out, $i;
});

is_deeply(\@out, [ 1, 3 ], 'skipped value');

@in  = ( [ 1 ], [ 2 ], [ 3 ] );
@out = ( );
my $count = 0;
$iter->forAll(@in, sub {
    my $i = shift;
    $count++;
    if ($i->[0] == 2) {
        $i->[0] = 0;
        $iter->redo;
    }
    push @out, $i;
});

is_deeply(\@out, [ [ 1 ], [ 0 ], [ 3 ] ], 'redo values');
is($count, 4, 'redo count');

my $ib = IterB->new();
@in  = ( 1, 2, 3 );
@out = ( );
$ib->forAll(@in, sub {
    my $i = shift;
    $ib->last if $i > 2;
    push @out, $i;
});

is_deeply(\@out, [ 1, 2 ], 'subclass');

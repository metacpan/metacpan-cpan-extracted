#! perl

use v5.20;
use Test2::V0;

use CXC::Data::Visitor '-all';
use Ref::Util 'is_hashref', 'is_arrayref';
use experimental 'signatures', 'postderef';
use Data::Dump 'pp';

sub myhash {
    (
        a => 1,
        b => [ 2, 3, 4 ],
        c => {
            d => [ 5, 6, 7 ],
            e => 8,
        },
    );
}

subtest 'default' => sub {
    my %hash = myhash;
    my @order;
    visit(
        \%hash,
        sub ( $kydx, $vref, @ ) {
            push @order, $vref->$*;
            return RESULT_CONTINUE;
        },
        visit => VISIT_LEAF,
    );
    is( \@order, [ 1 .. 8 ] ) or diag pp @order;
};

subtest 'key_sort => true' => sub {

    my %hash = myhash;

    my @keys_a  = keys %hash;
    my @keeys_c = keys $hash{c}->%*;

    my @input = ( \%hash );
    my @expected;
    while ( @input ) {
        my $element = shift @input;
        if ( is_arrayref $element ) {
            unshift @input, $element->@*;
        }
        elsif ( is_hashref $element ) {
            unshift @input, values $element->%*;
        }
        else {
            push @expected, $element;
        }
    }

    my @order;
    visit(
        \%hash,
        sub ( $kydx, $vref, @ ) {
            push @order, $vref->$*;
            return RESULT_CONTINUE;
        },
        visit    => VISIT_LEAF,
        key_sort => !!1,
    );
    is( \@order, [ 1 .. 8 ] ) or diag pp @order;
};

subtest 'key_sort => false' => sub {
    my %hash = myhash;

    # track the actual returned order
    my @input = ( \%hash );
    my @expected;
    while ( @input ) {
        my $element = shift @input;
        if ( is_arrayref $element ) {
            unshift @input, $element->@*;
        }
        elsif ( is_hashref $element ) {
            unshift @input, values $element->%*;
        }
        else {
            push @expected, $element;
        }
    }

    my @order;
    visit(
        \%hash,
        sub ( $kydx, $vref, @ ) {
            push @order, $vref->$*;
            return RESULT_CONTINUE;
        },
        visit    => VISIT_LEAF,
        key_sort => !!0,
    );
    is( \@order, \@expected ) or diag pp @order;
};


subtest 'custom' => sub {
    my %hash = myhash;
    my @order;
    visit(
        \%hash,
        sub ( $kydx, $vref, @ ) {
            push @order, $kydx;
            return RESULT_CONTINUE;
        },
        visit => VISIT_ALL,
        ## no critic (ReverseSortBlock)
        key_sort => sub ( $array ) { [ reverse sort $array->@* ] },
        idx_sort => sub ( $n ) { [ reverse 0 .. $n - 1 ] },
    );

    is( \@order, [qw( c e d 2 1 0 b 2 1 0 a )] )
      or diag pp @order;
};

subtest 'backcompat' => sub {
    my %hash = myhash;
    my @order;
    visit(
        \%hash,
        sub ( $kydx, $vref, @ ) {
            push @order, $kydx;
            return RESULT_CONTINUE;
        },
        visit     => VISIT_ALL,
        sort_keys => sub { $_[1] cmp $_[0] },
    );

    is( \@order, [qw( c e d 0 1 2 b 0 1 2 a )] )
      or diag pp @order;
};

done_testing;

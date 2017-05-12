#!/usr/bin/env perl

use strict;
use warnings;

use constant {
    EMPTY      => [],
    OPTIMIZING => [
        'accessor: inside test',
        'accessor: op_spare: 0',
        'accessor: optimizing entersub',
    ],
    OPTIMIZED => [
        'entersub: inside optimized entersub',
        'accessor: inside test',
        'accessor: op_spare: 0',
        'accessor: entersub has been optimized'
    ],
    # XXX not used: not sure we want to trigger this internal error
    DISABLING_NOT_DEFINED => [
        'entersub: inside optimized entersub',
        'entersub: disabling optimization: SV is null'
    ],
    DISABLING_NOT_CV => [
        'entersub: inside optimized entersub',
        'entersub: disabling optimization: SV is not a CV'
    ],
    DISABLING_NOT_SAME_ACCESSOR => [
        'entersub: inside optimized entersub',
        'entersub: disabling optimization: SV is not test'
    ],
    DISABLED => [
        'accessor: inside test',
        'accessor: op_spare: 1',
        'accessor: entersub optimization has been disabled'
    ],
};

use Class::XSAccessor {
    __tests__ => [ qw(foo bar) ],
    getters   => [ 'quux' ],
};

BEGIN {
    unless (Class::XSAccessor::__entersub_optimized__()) {
        print "1..0 # Skip entersub optimization not enabled", $/;
        exit;
    }
}

use Data::Dumper;
use Test::More tests => 68;

our @MESSAGES = ();

sub is_debug ($) {
    my $want = shift;

    # report errors with the caller's line number
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $got = [ splice @MESSAGES ];

    unless (is_deeply($got, $want)) {
        local ($Data::Dumper::Terse, $Data::Dumper::Indent) = (1, 1);
        print STDERR $/, 'unmatched messages: ', Dumper($got), $/;
    }
}

local $SIG{__WARN__} = sub {
    my $warning = join '', @_;

    if ($warning =~ m{^cxah: (.+?) at \Q$0\E}) {
        push @MESSAGES, $1;
    } else {
        warn @_; # from perldoc -f warn: "__WARN__ hooks are not called from inside one"
    }
};

sub baz {
    my $self = shift;
    @_ ? $self->{baz} = shift : $self->{baz};
}

# XXX debugging note: change if/else branches to separate
# statements to debug/troubleshoot, otherwise the error will appear
# to come from the first line of the if/else statement i.e. change:
#
#     1: if ($_ == 1) {
#     2:     is_debug ...
#     3: } else {
#     4:     is_debug ... # error
#     5: }
#
#     # error at line 1
#
# to:
#
#     1: if ($_ == 1) {
#     2:     is_debug ...
#     3: }
#     4:
#     5: if ($_ == 2) {
#     6:     is_debug ... # error
#     7: }
#
#     # error at line 5

my $SELF = bless {
    foo  => 'Foo',
    bar  => 'Bar',
    baz  => 'Baz',
    quux => 'Quux'
};

# standard: verify that the accessors work as expected
for (1 .. 3) {
    is $SELF->foo, 'Foo';
    is_debug ($_ == 1 ? OPTIMIZING : OPTIMIZED);

    is $SELF->bar, 'Bar';
    is_debug ($_ == 1 ? OPTIMIZING : OPTIMIZED);

    is $SELF->baz, 'Baz';
    is_debug EMPTY;
}

# changing the CV at a call site is OK (i.e. doesn't disable
# the entersub optimization) if both CVs are the same type of
# Class::XSAccessor accessor: foo (test) -> bar (test)
for (1 .. 4) {
    my $name = [ qw(foo bar foo bar) ]->[$_ - 1];
    is $SELF->$name, ucfirst($name);

    if ($_ == 1) {
        is_debug OPTIMIZING;
    } else {
        is_debug OPTIMIZED;
    }
}

# disable the entersub optimization (method 1):
# change it to a different type of Class::XSAccessor accessor:
# foo (test) -> quux (getter)
for (1 .. 4) {
    my $name = [ qw(foo quux foo quux) ]->[$_ - 1];
    is $SELF->$name, ucfirst($name);

    if ($_ == 1) {
        is_debug OPTIMIZING;
    } elsif ($_ == 2) {
        is_debug DISABLING_NOT_SAME_ACCESSOR;
    } elsif ($_ == 3) {
        is_debug DISABLED;
    } else {
        is_debug EMPTY;
    }
}

# disable the entersub optimization (method 2):
# change it to a non-Class::XSAccessor CV: foo (test) -> baz
for (1 .. 4) {
    my $name = [ qw(foo baz foo baz) ]->[$_ - 1];
    is $SELF->$name, ucfirst($name);

    if ($_ == 1) {
        is_debug OPTIMIZING;
    } elsif ($_ == 2) {
        is_debug DISABLING_NOT_SAME_ACCESSOR;
    } elsif ($_ == 3) {
        is_debug DISABLED;
    } else {
        is_debug EMPTY;
    }
}

# if the SV passed to entersub is not a CV, disable the optimisation.
# note: the invalid type is detected in the optimised entersub,
# *not* in the accessor.
for (1 .. 4) {
    # when entersub is called in this way, the SV is a GV
    # rather than a CV
    is foo($SELF), 'Foo';

    if ($_ == 1) {
        # in the accessor (test)
        is_debug OPTIMIZING;
    } elsif ($_ == 2) {
        # the optimized entersub backs itself out
        # because the SV is a GV rather than a CV
        is_debug [ @{DISABLING_NOT_CV()}, @{DISABLED()} ];
    } else {
        # in the accessor (test)
        is_debug DISABLED;
    }
}

# confirm we haven't pessimized other call sites
for (1 .. 3) {
    is $SELF->foo, 'Foo';
    is_debug ($_ == 1 ? OPTIMIZING : OPTIMIZED);

    is $SELF->bar, 'Bar';
    is_debug ($_ == 1 ? OPTIMIZING : OPTIMIZED);

    is $SELF->baz, 'Baz';
    is_debug EMPTY;
}

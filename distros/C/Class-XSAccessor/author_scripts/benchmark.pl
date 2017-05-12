#!/usr/bin/env perl

use strict;
use warnings;

printf STDOUT 'perl: %s, Class::XSAccessor: %s%s', $], Class::XSAccessor->VERSION, $/;

package WithClassXSAccessor;

use blib;

use Class::XSAccessor
    constructor      => 'new',
    accessors        => { myattr => 'myattr' },
    getters          => { get_myattr => 'myattr' },
    setters          => { set_myattr => 'myattr' },
    lvalue_accessors => { lv_myattr => 'myattr' },
;

package WithStdClass;

sub new { my $c = shift; bless {@_}, ref($c) || $c }

sub myattr {
    my $self = shift;

    if (@_) {
        return $self->{myattr} = shift;
    } else {
        return $self->{myattr};
    }
}

package WithStdClassFast;

sub new { my $c = shift; bless {@_}, ref($c) || $c }

sub myattr { (@_ > 1) ?  $_[0]->{myattr} = $_[1] : $_[0]->{myattr} }

package main;

use Benchmark qw(cmpthese timethese :hireswallclock);
# use Benchmark qw(cmpthese timethese);

my $class_xs_accessor = WithClassXSAccessor->new;
my $std_class         = WithStdClass->new;
my $std_class_fast    = WithStdClassFast->new;
my $direct_hash       = {};
my $count             = shift || -2;

$direct_hash->{myattr} = 42;
$class_xs_accessor->myattr(42);
$std_class->myattr(42);
$std_class_fast->myattr(42);

=for comment
    direct_hash => sub {
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        $direct_hash->{myattr} = $direct_hash->{myattr};
        die unless ($direct_hash->{myattr} == 42);
    },
=cut

cmpthese(timethese($count, {
    class_xs_accessor_getset => sub {
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        $class_xs_accessor->set_myattr($class_xs_accessor->get_myattr);
        die unless ($class_xs_accessor->myattr == 42);
    },
    class_xs_accessor => sub {
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        $class_xs_accessor->myattr($class_xs_accessor->myattr);
        die unless ($class_xs_accessor->myattr == 42);
    },
    std_class => sub {
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        $std_class->myattr($std_class->myattr);
        die unless ($std_class->myattr == 42);
    },
    std_class_fast => sub {
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        $std_class_fast->myattr($std_class_fast->myattr);
        die unless ($std_class_fast->myattr == 42);
    },
    class_xs_accessor_lvalue => sub {
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->myattr;
        die unless ($class_xs_accessor->myattr == 42);
    },
    class_xs_accessor_lvalue_double => sub {
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        $class_xs_accessor->lv_myattr = $class_xs_accessor->lv_myattr;
        die unless ($class_xs_accessor->myattr == 42);
    },
}));

print "Constructor benchmark:\n";
cmpthese(timethese($count, {
    class_xs_accessor => sub {
        my $obj;
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
        $obj = WithClassXSAccessor->new();
    },
    std_class => sub {
        my $obj;
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
        $obj = WithStdClass->new();
    },
}));

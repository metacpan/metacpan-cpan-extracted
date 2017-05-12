#!/usr/bin/perl -w                                         # -*- perl -*-
#========================================================================
#
# test.pl
#
# Test the Class::Facade.pm module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#========================================================================

use strict;
use warnings;
use lib qw( ./lib );
use Class::Facade;


local $" = ', ';

#------------------------------------------------------------------------
# mini test harness
#------------------------------------------------------------------------

print "1..30\n";
my $n = 0;

sub ok {
    my $flag = shift;
    print(($flag ? 'ok ' : 'not ok '), ++$n, "\n");
    return $flag;
}

sub is {
    ok( $_[0] eq $_[1] ) || warn "match failed:\n  GOT: $_[0]\n  NOT: $_[1]\n";
}

sub assert {
    ok( @_ ) || die "assertion failed\n";
}


#------------------------------------------------------------------------
# delegate class
#------------------------------------------------------------------------

package My::Delegate::Class;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub name {
    my $self = shift;
    return "name: $self->{ name } [@_]";
}

sub holler {
    my $class = shift;
    return "$class holler [@_]";
}


#------------------------------------------------------------------------

package main;

my $delegate = My::Delegate::Class->new( name => 'fred' );

assert( $delegate );

my $facade = Class::Facade->new(
    bad => { },
);

is(  Class::Facade->error(), "bad: no 'class' or 'object' specified" );			    
is( $Class::Facade::ERROR,   "bad: no 'class' or 'object' specified" );			    
    

$facade = Class::Facade->new({
    foo => sub { "this is foo [@_]" },
    bar => [ 'My::Delegate::Class', 'holler', 2, 3, 5 ],
    baz => [ $delegate, 'name' ],
    boz => [ $delegate, 'name', 17, 19, 23 ],
    wiz => { 
	class  => 'My::Delegate::Class', 
	method => 'holler',
	args   => [ 27, 29, 31 ],
    },
    waz => {
	object => $delegate, 
	method => 'name', 
	args   => [ 37, 41, 43 ],
    },
});

ok( $facade ) || die "facade error: $Class::Facade::ERROR\n";
assert( $facade );

is( $facade->foo, 'this is foo []' );
is( $facade->foo(10, 20), 'this is foo [10, 20]' );
is( $facade->bar(), 'My::Delegate::Class holler [2, 3, 5]' );
is( $facade->bar(7, 11, 13), 'My::Delegate::Class holler [2, 3, 5, 7, 11, 13]' );
is( $facade->baz(), 'name: fred []' );
is( $facade->boz(7, 11, 13), 'name: fred [17, 19, 23, 7, 11, 13]' );
is( $facade->wiz(), 'My::Delegate::Class holler [27, 29, 31]' );
is( $facade->wiz(10, 20, 30), 'My::Delegate::Class holler [27, 29, 31, 10, 20, 30]' );
is( $facade->waz(), 'name: fred [37, 41, 43]' );
is( $facade->waz(10, 20, 30), 'name: fred [37, 41, 43, 10, 20, 30]' );


#------------------------------------------------------------------------
# test subclass
#------------------------------------------------------------------------

package My::Facade;
use base qw( Class::Facade );
our $ERROR;

package main;

$delegate = My::Delegate::Class->new( name => 'tommy' );

assert( $delegate );

$facade = My::Facade->new(
    bad => { },
);

is(  My::Facade->error(), "bad: no 'class' or 'object' specified" );			    
is( $My::Facade::ERROR,   "bad: no 'class' or 'object' specified" );			    

$facade = My::Facade->new({
    oof => sub { "this is oof [@_]" },
    rab => [ 'My::Delegate::Class', 'holler', 5, 3, 2 ],
    zab => [ $delegate, 'name' ],
    zob => [ $delegate, 'name', 23, 19, 17 ],
    ziw => { 
	class  => 'My::Delegate::Class', 
	method => 'holler',
	args   => [ 31, 29 ],
    },
    zaw => {
	object => $delegate, 
	method => 'name', 
	args   => [ 43, 41, 37 ],
    },
});

ok( $facade ) || die "facade error: $My::Facade::ERROR\n";
assert( $facade );

is( $facade->oof, 'this is oof []' );
is( $facade->oof(10, 20), 'this is oof [10, 20]' );
is( $facade->rab(), 'My::Delegate::Class holler [5, 3, 2]' );
is( $facade->rab(7, 11, 13), 'My::Delegate::Class holler [5, 3, 2, 7, 11, 13]' );
is( $facade->zab(), 'name: tommy []' );
is( $facade->zob(7, 11, 13), 'name: tommy [23, 19, 17, 7, 11, 13]' );
is( $facade->ziw(), 'My::Delegate::Class holler [31, 29]' );
is( $facade->ziw(10, 20, 30), 'My::Delegate::Class holler [31, 29, 10, 20, 30]' );
is( $facade->zaw(), 'name: tommy [43, 41, 37]' );
is( $facade->zaw(10, 20, 30), 'name: tommy [43, 41, 37, 10, 20, 30]' );

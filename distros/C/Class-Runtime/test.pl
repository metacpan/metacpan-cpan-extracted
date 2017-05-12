#########################
## Copyright (C) 2002 Stathy G. Touloumis
## This is free software; you can redistribute it and/or modify it under
## the same terms as Perl itself.
##
use Test;
use strict;

use constant PATH_S=>		'/var/tmp/lib';
use constant PATH_A=>		[ qw(
	/var/tmp/lib
	/var/tmp/lib2
	/var/tmp/lib3 )
];
use constant DEBUG=>		0;
use constant TEST_CLASS=>	'Pod::Text::Color';

BEGIN { plan tests => 11 };

#1
eval "use Class::Runtime";
if ( $@ ) {
	ok(0);
	warn $@, "\n\n";
} else {
	ok(1);
}

#2
my $obj = Class::Runtime->new( class=> TEST_CLASS );
if ( !defined $obj ) {
	ok(0);
} else {
	ok(1);
}

#3
my $var = $obj->addPath( path=> PATH_S );
if ( !defined $var ) {
	ok(0);
} else {
	ok(1);
}
warn "$var", "\n" if DEBUG;

#4
$var = $obj->addPath( path=> PATH_A );
if ( !defined $var ) {
	ok(0);
} else {
	ok(1);
}
warn "$var", "\n" if DEBUG;

#5
$var = $obj->dropPath( path=> PATH_S );
if ( !defined $var ) {
	ok(0);
} else {
	ok(1);
}
warn "$var", "\n" if DEBUG;

#6
$var = $obj->dropPath( path=> PATH_A );
if ( !defined $var ) {
	ok(0);
} else {
	ok(1);
}
warn "$var", "\n" if DEBUG;

#7
$var = $obj->load;
if ( !defined $var ) {
	ok(0);
} else {
	ok(1);
}
warn "$@", "\n" if DEBUG;

#8
$var = $obj->isLoaded;
if ( $var == 0 ) {
	ok(0);
} else {
	ok(1);
}
warn "$var", "\n" if DEBUG;

#9
$var = $obj->invoke( 'new', sentence=> 0, width=> 0 );
if ( $var->isa('Pod::Text::Color') ) {
	ok(1);
} else {
	ok(0);
}
warn "$var", "\n" if DEBUG;

#10
$var = $obj->unload;
if ( !defined $var || $var == 0 ) {
	ok(0);
} else {
	ok(1);
}
warn "$@", "\n" if DEBUG;

#11
$var = $obj->isLoaded;
if ( $var != 0 ) {
	ok(0);
} else {
	ok(1);
}
warn "$var", "\n" if DEBUG;

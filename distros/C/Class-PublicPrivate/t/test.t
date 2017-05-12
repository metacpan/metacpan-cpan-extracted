#!/usr/bin/perl -w
use strict;
use lib '../../';
use Class::PublicPrivate;
use Test::More;

# debugging tools
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;


# plan tests
plan tests => 4;


###############################################################################
# ExtendedClass
#
package ExtendedClass;
use strict;
use base 'Class::PublicPrivate';

#------------------------------------------------------------------------------
# new
#
sub new {
	my $class = shift;
	my $self = $class->SUPER::new();
	return $self;
}
#
# new
#------------------------------------------------------------------------------


#
# ExtendedClass
###############################################################################


###############################################################################
# main
#
package main;
use strict;

# variables
my ($ob, $private);

# create PublicPrivate object
$ob = ExtendedClass->new();
ok ($ob, 'create PublicPrivate object');

# get private hash
$private = $ob->private;
ok ($private, 'get private hash');

# store something in private hash
$private->{'a'} = 1;

# should have valuie in private
ok($ob->private->{'a'} == 1, 'should have valuie in private');

# store something in object
$ob->{'b'} = 2;

# $ob should have exactly one key
ok(keys(%$ob) == 1, '$ob should have exactly one key');

#
# main
###############################################################################

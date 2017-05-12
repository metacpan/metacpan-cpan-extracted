#!/usr/bin/perl

use warnings;
use strict;
use Test;

BEGIN { plan tests => 4 }

use Attribute::Util;

sub nothere : Abstract;

eval { nothere() };
print "not " unless $@ =~ /call to abstract method/;
print "ok 1\n";

my $obj = MyObj->new;
eval { $obj->somesub() };
print "not " unless $@ =~ /call to abstract method/;
print "ok 2\n";

my $obj2 = MyObj::Better->new;
eval { $obj2->somesub() };
print "not " if $@ =~ /call to abstract method/;
print "ok 3\n";

# rebless to make somesub() work
bless $obj, 'MyObj::Better';
eval { $obj->somesub() };
print "not " if $@ =~ /call to abstract method/;
print "ok 4\n";

package MyObj;
sub new { bless {}, shift }
sub somesub: Abstract;

package MyObj::Better;
use base 'MyObj';
sub somesub { return "I'm implemented!" }

#!/usr/bin/perl -w
use strict;

my $f = Fruit->new({name=>"strawberry"});
$f->guess_color("the devil");
print "My ". $f->name. " is ". $f->color. ".\n\n";

print "\nReference gotten by refaccessor: ". $f->_ref_color;
print "\nReference gotten by generic (symbolic) reference accessor ", $f->get_ref('color');
print "\n(They should be the same.)\n\n";

exit 0;


package Fruit;
use base 'Class::Accessor::Ref';
use lib '.';
use API;

BEGIN {
	Fruit->mk_accessors(qw(name color));
	Fruit->mk_refaccessors(qw(color));
}

# guess the color of a fruit with the help of an external library.
# The name of the fruit will figure as a hint, as well as any
# optional parameters.
sub guess_color {
	my($self, @more_hints) = @_;
	API::find_color_by_hints($self->_ref_color, $self->name, @more_hints) or
		warn "uh, oh! I can't guess what my color is. Please set it!\n";
}

1;


#!perl
use strict;
use warnings;
use Test::More;
use Acme::Cat::Schroedinger;
use Data::Dumper;

sub kitty {
	Acme::Cat::Schroedinger->new(@_);
}

my $cat = kitty;

ok (!ref (kitty.''), "Stringification works");

ok (ref ($cat), 'Cat is an object');

my $nvm = $cat.'dog';
ok (!ref ($cat), "stringification modifies the cat") or diag Dumper [$cat];

$cat = kitty;

eval {
	$nvm = $cat->[0];
};
if ($@) {
	fail ($@);
}
else {
	pass('Can call as arrayref');
	ok (!defined $nvm, 'empty arrayref');
}

eval {
	$nvm = ${&kitty};
};
if ($@) {
	fail ($@);
}
else {
	pass('Can call as scalar ref');
}

eval {
	$nvm = &kitty->();
};
if ($@) {
	fail ($@);
}
else {
	pass('Can call as code ref');
	is($nvm->(), 'meow', 'Can meow as code ref');
}


eval {
	$nvm = {%{&kitty}};
};
if ($@) {
	fail ($@);
}
else {
	pass('Can call as hash ref');
	ok (!keys %$nvm ,'empty hashref');
}

sub perverse_kitty {kitty(temperament=>'perverse',@_)}
eval {
	$nvm = perverse_kitty.''
};
if ($@) {
	pass ('A properly perverse cat cannot be concatenated');
}
else {
	fail('A properly perverse cat cannot be concatenated');
	diag Dumper [$nvm];
}
eval {
	$nvm = perverse_kitty->{temperament}
};
if ($@) {
	pass ('A properly perverse cat cannot be dereferenced');
}
else {
	fail('A properly perverse cat cannot be dereferenced');
}


# write more tests!

done_testing;

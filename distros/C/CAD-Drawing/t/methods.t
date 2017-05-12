#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(
	no_plan
	);

my $sublist = 't/data/sublist';
my @parts = qw(-main -graphics -defined);
foreach my $part (@parts) {
	(-e "$sublist$part") or die "missing $sublist$part";
}

use_ok('CAD::Drawing');

my @subs;
@subs = load_list("$sublist-main");
@subs or die;

foreach my $sub (@subs) {
	ok(CAD::Drawing->can($sub), "CAD::Drawing->$sub");
}

@subs = load_list("$sublist-defined");
@subs or die;

foreach my $sub (@subs) {
	ok(CAD::Drawing::Defined->can($sub), "...Defined::$sub");
}


use_ok('CAD::Drawing::Manipulate::Graphics');

@subs = load_list("$sublist-graphics");
@subs or die;

foreach my $sub (@subs) {
	ok(CAD::Drawing->can($sub), "...Graphics::$sub");
}

########################################################################
sub load_list {
	my $f = shift;
	my $fh;
	open($fh, $f) or die;
	local $/ = undef;
	return(split(/\n/, <$fh>));
}

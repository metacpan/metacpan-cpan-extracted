#!perl -T

# this tests whether the subs depending on sub2perl which
# eval's a perl data structure as a string
# are not exported by default (after v0.28)
# but require explicit import by the caller

use 5.008;
use strict;
use warnings;

use utf8;

our $VERSION='0.30';

use Test::More;
use Test2::Plugin::UTF8;

# the default is to permanently overwrite dumper's qquote()
# and permanently add a filter to Dump.
use Data::Roundtrip qw/:all/;

my @dumps = qw/dump2perl dump2json dump2yaml dump2dump/;

for my $as (@dumps){
	ok(! main->can($as), "Checked that sub '$as' is not visible without explicit importing.") or BAIL_OUT;
}

for my $as (@dumps){
	ok(defined eval { Data::Roundtrip->import($as)}, "imported sub '$as'") or BAIL_OUT("failed to import '$as' because : $@");
	ok(main->can($as), "Checked that sub '$as' is now visible without explicit importing.") or BAIL_OUT;
}

done_testing();

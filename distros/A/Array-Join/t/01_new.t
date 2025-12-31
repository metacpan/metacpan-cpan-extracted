use Array::Join::OO;
use Test::More;
use Data::Dumper;
use List::MoreUtils qw/uniq/;

use strict;

$\ = "\n"; $, = "\t";

isa_ok(Array::Join::OO->new([],[], { on => [ sub { $_->{a} }, sub { $_->{a} } ] }), "Array::Join::OO", "new");

done_testing()

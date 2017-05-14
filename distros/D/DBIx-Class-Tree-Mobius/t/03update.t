#! /usr/bin/perl -w
# Test adapted from DBIx-Class-EncodedColumn-0.00006

use strict;
use warnings;

use Test::More;

use File::Spec;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');

my $tests = 1;

plan tests => $tests;

#1
use_ok("CdbiTreeTest");

my $schema = CdbiTreeTest->init_schema;
my $rs     = $schema->resultset('Test');

sub ids_list {
    my $rs = shift;
    my @ids = ();
    while (my $rec = $rs->next) { push(@ids, $rec->id) }
    return join(',', @ids);
}

my $root = $rs->create({ data => 'root' });

for ('1' .. '9') {
    $root->attach_child( $rs->create({ data => $_ }) );
}

foreach my $data (qw/9 /) {
    $rs->search({ data => $data })->first->delete();
}

my $children = $root->children();
while (my $child = $children->next) {
    print $child->data."\n";
}

$root->available_mobius_index;

exit();

$children = $root->children();
for ('A' .. 'Z') {
    my $rec = $children->next;
    is($rec->data, $_, "check data rec $_");

    print $rec->mobius_path."\n";

    #is($id3->child_encoding(2), '(9x + 4) / (2x + 1)', 'check encoding rec id 3');
    #print 
}


END {
    # In the END section so that the test DB file gets closed before we attempt to unlink it
    CdbiTreeTest::clear($schema);
}

1;

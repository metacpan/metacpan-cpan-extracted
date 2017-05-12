use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FrozenTest;

plan tests => 13;

my $schema = FrozenTest->init;
my $rs     = $schema->resultset('Source');
my ($row, $row2);
my $id = 0;

$row = $rs->create({id => ++$id});

foreach my $t (qw/frozen dumped/) {
    my $acc = "ccc_$t";
    $row->$acc("recursive_$t");
    is $row->$acc, "recursive_$t", "$t: set";
    is $row->get_column("cc_$t")->{"ccc_$t"}, "recursive_$t", "$t: set 2";
}

$row->update;
$row = $rs->find({id => $id});
$rs->create({
    id         => ++$id,
    ccc_frozen => "recursive frozen fly",
    ccc_dumped => "recursive dumped fly",
}); 
$row2 = $rs->find({id => $id});

foreach my $t (qw/frozen dumped/) {
    is $row->get_column("ccc_$t"), "recursive_$t", "$t: after fetch";
    is $row2->get_column("ccc_$t"), "recursive $t fly", "$t: on fly";

    my %data = $row2->get_columns;
    is $data{"ccc_$t"}, "recursive $t fly", "$t: get_columns";

    is $data{id}, $id, "classic is in hash" if $t =~ /^d/;
}

foreach my $t (qw/frozen dumped/) {
    is $row->has_column_loaded($t) && 
       $row->has_column_loaded("c_$t") && 
       $row->has_column_loaded("cc_$t") &&
       $row->has_column_loaded("ccc_$t"),
      1, "$t: has_column_loaded"; 
}

1;

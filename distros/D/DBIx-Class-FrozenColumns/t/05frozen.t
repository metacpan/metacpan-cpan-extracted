use strict;
use warnings;
use Test::More;

use lib 't/lib';
use FrozenTest;

plan tests => 27;

my $schema = FrozenTest->init;
my $rs     = $schema->resultset('Source');
my ($row, $row2);
my $id = 0;

$row = $rs->create({id => ++$id});

foreach my $t (qw/frozen dumped/) {
    $row->set_column("a_$t" => "init_$t");
    is $row->get_column("a_$t"), "init_$t", "$t: set/get column";

    my $acc = "b_$t";
    $row->$acc("acc_$t");
    is $row->$acc, "acc_$t", "$t: accessor";
}
ok $row->is_changed;
$row->update;
ok !$row->is_changed;
$row = $rs->find({id => $id});
$rs->create({
    id       => ++$id,
    a_frozen => "frozen fly",
    a_dumped => "dumped fly",
}); 
$row2 = $rs->find({id => $id});

foreach my $t (qw/frozen dumped/) {
    is $row->get_column("b_$t"), "acc_$t", "$t: after fetch";
    is $row2->get_column("a_$t"), "$t fly", "$t: on fly";

    my %data = $row2->get_columns;
    is $data{"a_$t"}, "$t fly", "$t: get_columns";

    is $data{id}, $id, "classic is in hash" if $t =~ /^d/;
}

$row->update;

foreach my $t (qw/frozen dumped/) {
    $row->set_column("a_$t" => "lalala_$t");
    my %dirty = $row->get_dirty_columns;
    is $dirty{"a_$t"} &&
       $dirty{$t} && 
       $dirty{"a_$t"} eq "lalala_$t" &&
       scalar(keys %dirty) == 2,
     1, "$t: dirty columns 1"; 

    is $row->is_column_changed("a_$t") && $row->is_column_changed($t), 1, "$t: is column changed";

    my %changed = map {$_ => 1} $row->is_changed;
    is $changed{"a_$t"} && $changed{$t} && scalar(keys %changed) == 2, 1, "$t: is_changed";

    is !$dirty{id}, 1, "$t: classic not dirty";
    $row->update;

    is !$row->get_dirty_columns, 1, "$t: dirty columns 2";

    $row->store_column("b_$t", "hahaha_$t");
    is !$row->get_dirty_columns, 1, "$t: dirty and store_column";
}

foreach my $t (qw/frozen dumped/) {
    is $row->has_column_loaded($t) && $row->has_column_loaded("a_$t") && $row->has_column_loaded("b_$t"), 1, "$t: has_column_loaded"; 
}



1;

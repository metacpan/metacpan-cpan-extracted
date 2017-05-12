#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Data::Transpose::Group;
use Data::Transpose::Field;

my @objects;
foreach my $value ('a', 'b') {
    my $field = Data::Transpose::Field->new(name => $value);
    $field->value($value);
    push @objects, $field;
}


my $group = Data::Transpose::Group->new(name => 'mygroup',
                                        objects => \@objects);

is ($group->join, ' ', "join ok");
is ($group->name, 'mygroup', "name ok");
ok ($group->name('Test')->join('x')->target('pippo')->objects, "chaining works");
is ($group->name, 'Test', "New name set");
is ($group->join, 'x', "New join set");
is ($group->target, 'pippo');





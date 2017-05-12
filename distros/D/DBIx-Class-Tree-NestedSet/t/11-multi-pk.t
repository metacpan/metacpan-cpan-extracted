#!/usr/bin/env perl
#
# $Id: $
# $Revision: $
# $Author: $
# $Source:  $
#
# $Log: $
#
use strict;
use warnings;
use Test::More;
use DBICx::TestDatabase;
use Data::Dumper;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

BEGIN { use_ok('TestSchema') }

my $schema = DBICx::TestDatabase->new('TestSchema');
isa_ok($schema, 'DBIx::Class::Schema');

my $trees = $schema->resultset('MultiPK');
isa_ok($trees, 'DBIx::Class::ResultSet');
my $index = 1;

my $tree1 = $trees->create({ id => $index++, id2 => 'one', content => 'tree1 root', root_id => 10});
my $tree2 = $trees->create({ id => $index++, id2 => 'two', content => 'tree2 root', root_id => 20});

throws_ok(sub {
    my $tree3 = $trees->create({ id => $index++, id2 => 'three', content => 'tree3 root'});
}, qr/Only single column primary keys are supported/, 'Cannot create a tree in a multi-pk schema');


done_testing();
exit;


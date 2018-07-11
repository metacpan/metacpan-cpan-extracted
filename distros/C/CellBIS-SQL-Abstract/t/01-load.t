#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CellBIS::SQL::Abstract;

my $sql_abstract = CellBIS::SQL::Abstract->new;
ok(defined $sql_abstract, 'Module CellBIS::SQL::Abstract can loaded');
ok($sql_abstract->isa('CellBIS::SQL::Abstract'), 'Modules can be used.');

done_testing();

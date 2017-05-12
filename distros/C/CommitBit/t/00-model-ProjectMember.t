#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the ProjectMember model.

=cut

use Jifty::Test;# tests => 11;
plan skip_all => 'the developers suck';

# Make sure we can load the model
use_ok('CommitBit::Model::ProjectMember');

# Grab a system user
my $system_user = CommitBit::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = CommitBit::Model::ProjectMember->new(current_user => $system_user);
my ($id) = $o->create();
ok($id, "ProjectMember create returned success");
ok($o->id, "New ProjectMember has valid id set");
is($o->id, $id, "Create returned the right id");

# And another
$o->create();
ok($o->id, "ProjectMember create returned another value");
isnt($o->id, $id, "And it is different from the previous one");

# Searches in general
my $collection =  CommitBit::Model::ProjectMemberCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 2, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

# Delete one of them
$o->delete;
$collection->redo_search;
is($collection->count, 0, "Deleted row is gone");

# And the other one is still there
$collection->unlimit;
is($collection->count, 1, "Still one left");


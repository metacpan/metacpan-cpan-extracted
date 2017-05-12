#!/usr/bin/env perl
use warnings;
use strict;

=head1 DESCRIPTION

A basic test harness for the Repository model.

=cut

use CommitBit::Test ;# tests => 9;
plan skip_all => 'the developers suck';

# Make sure we can load the model
use_ok('CommitBit::Model::Repository');

# Grab a system user
my $system_user = CommitBit::CurrentUser->superuser;
ok($system_user, "Found a system user");

# Try testing a create
my $o = CommitBit::Model::Repository->new(current_user => $system_user);
my ($id) = $o->create( name => 'test');
ok($id, "Repository create returned success");
ok($o->id, "New Repository has valid id set");
is($o->id, $id, "Create returned the right id");
ok(-e "repos-test/test/format", 'svn repository created');

# And another
($id) = $o->create( name => 'test');
ok(!$id, 'distinct');

# Searches in general
my $collection =  CommitBit::Model::RepositoryCollection->new(current_user => $system_user);
$collection->unlimit;
is($collection->count, 1, "Finds two records");

# Searches in specific
$collection->limit(column => 'id', value => $o->id);
is($collection->count, 1, "Finds one record with specific id");

#!/usr/bin/perl
use strict;
use warnings;

# Example of a table with a primary key
package TPub;

require DBIx::SQLite::Simple::Table;
our @ISA = qw(DBIx::SQLite::Simple::Table);

our @AS = qw(
   idPub
   pub
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

# 'our $Id' and 'our @Fields' are named Id and Fields for a good
# reason, so do not name these variables by another name.
our $Id     = $AS[0];
our @Fields = @AS[1..$#AS];

1;

# Example of a table with no key at all
package TBeer;

require DBIx::SQLite::Simple::Table;
our @ISA = qw(DBIx::SQLite::Simple::Table);

our @AS = qw(
   beer
   country
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

our @Fields = @AS;

1;

# Now, we have two tables, we can play with the database
package main;

require DBIx::SQLite::Simple;
my $db = DBIx::SQLite::Simple->new(db => 'sqlite.db');

# Create to object to play with the two tables
my $tPub = TPub->new;
my $tBeer = TBeer->new;

# Create tables
$tPub->create  unless $tPub->exists;
$tBeer->create unless $tBeer->exists;

# Create some entries
my @pubEntries;
push @pubEntries, TPub->new(pub => $_) for (qw(corner friends));

my @beerEntries;
push @beerEntries, TBeer->new(beer => $_, country => 'BE')
   for (qw(grim leffe bud));

# Now insert those entries;
$tPub->insert(\@pubEntries);
$tBeer->insert(\@beerEntries);

# Get friends pub
my $friends = $tPub->select(pub => 'friends');

# Lookup id
my $id = $tPub->lookupId(pub => 'friends');

# Lookup string
my $str = $tPub->lookupString('pub', idPub => $id);

# Add a beer from 'chez moi'
my $dremmwel = TBeer->new(beer => 'Dremmwel', country => '?');
$tBeer->insert([ $dremmwel ]);

$tPub->commit;
$tBeer->commit;

# Update Dremmwel
my $dremmwelOld = $dremmwel->cgClone;
$dremmwel->country('BZH');
$tBeer->update([ $dremmwel ], $dremmwelOld);
$tBeer->commit;

# Delete all pubs
$tPub->delete(\@pubEntries);

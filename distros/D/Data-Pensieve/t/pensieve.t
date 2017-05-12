#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use FindBin;
use lib "$FindBin::Bin/lib";

use DBI;
use DBICTest::Schema;
use Data::Pensieve;

my $dsn = "dbi:SQLite:dbname=:memory:";
my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });

$dbh->do(qq|
    CREATE TABLE revisions(
        revision_id INTEGER PRIMARY KEY,
        grouping    varchar(255),
        identifier  varchar(255),
        recorded    datetime,
        metadata    varchar(255)
    );
|) or die $!;

$dbh->do(qq|
    CREATE TABLE revision_data(
        revision_data_id INTEGER PRIMARY KEY,
        revision_id      integer,
        datum            varchar(255),
        datum_value      varchar(255)
    );
|) or die $!;

my $schema = DBICTest::Schema->connect(sub {});
$schema->storage->connect_info([{ dbh_maker => sub { $dbh }}]);

$schema->resultset('Revision')->search->delete;
$schema->resultset('RevisionData')->search->delete;

my $pensieve = Data::Pensieve->new(
    revision_rs      => $schema->resultset('Revision'),
    revision_data_rs => $schema->resultset('RevisionData'),
);

$pensieve->store_revision(lolcats => 1, { name => 'dumb george', age => 1 });
$pensieve->store_revision(lolcats => 1, { name => 'dumb george', age => 2 });

my @revisions = $pensieve->get_revisions(lolcats => 1);
my ($rev1, $rev2) = @revisions;

is_deeply( $rev1->data, { name => 'dumb george', age => 1 } );
is_deeply( $rev2->data, { name => 'dumb george', age => 2 } );

my $comparison = $pensieve->compare_revisions($rev1, $rev2);

is_deeply( $comparison, { age => [ 1, 2 ] } );

$pensieve->store_revision(lolcats => 1, { name => 'dumber george' }, { author => 'waffle wizard' });

$rev2 = $pensieve->get_last_revision( lolcats => 1 );

is_deeply($rev2->metadata, { author => 'waffle wizard' });

# age is gone completely, because there's no definition
is_deeply( $rev2->data, { name => 'dumber george' } );

$_->delete for $schema->resultset('RevisionData')->search({ revision_id => $rev2->row->revision_id })->all;
$rev2->row->delete;

$pensieve = Data::Pensieve->new(
    revision_rs      => $schema->resultset('Revision'),
    revision_data_rs => $schema->resultset('RevisionData'),
    definitions      => {
        lolcats => [qw/ name age /],
    },
);

$pensieve->store_revision(lolcats => 1, { name => 'dumber george' });

$rev2 = $pensieve->get_last_revision(lolcats => 1);

is_deeply( $rev2->data, { name => 'dumber george', age => 2 } );

$pensieve->store_revision(lolcats => 2, Lolcat::Magical->new( name => 'rick', age => 201 ) );

$rev1 = $pensieve->get_last_revision(lolcats => 2);

is_deeply( $rev1->data, { name => 'rick', age => 201 } );

$pensieve->store_revision(lolcats => 2, Lolcat::Magical->new( name => 'ricky', age => 201 ) );

$rev2 = $pensieve->get_last_revision(lolcats => 2);

is_deeply($rev2->metadata, { } );

is_deeply( $rev2->data, { name => 'ricky', age => 201 } );

$comparison = $pensieve->compare_revisions($rev2, $rev1);

is_deeply($comparison, { name => [qw/rick ricky/] });

$comparison = $pensieve->diff_revisions($rev2, $rev1);

is_deeply($comparison, { name => qq|<div class="file"><span class="fileheader"></span><div class="hunk"><span class="hunkheader">@@ -1 +1 @@
</span><del>- rick</del><ins>+ ricky</ins><span class="hunkfooter"></span></div><span class="filefooter"></span></div>| });

package Lolcat::Magical;

sub name { shift->{name} }
sub age  { shift->{age}  }
sub new  { my $c = shift; my %p = @_; my $s = \%p; bless $s, $c; return $s; }

1;


# Note:
#
# I am using DebugObject in t/lib to catch the DBIC debug output
# and regexes to check the messages in order to find out what RU
# really did.
#
# I think that this is a bad Idea. If the queries produced by
# DBIC change in the future, these tests might fail even though
# DBIC and RU still behave the same.
#
# I currently have no better idea how to find out weather RU
# called set_$rel for M2Ms or not.
# (It shouldn't if IntrospectableM2M is in use)
#
# I prefered this solution over monkeypatching DBIC, which was my
# second idea. Any hints are highly welcome!
#
# - lukast


use strict;
use warnings;

use Test::More;
use DBIx::Class::ResultSet::RecursiveUpdate;

use lib 't/lib';
use DBSchema;
use DebugObject;

my $schema = DBSchema->get_test_schema();
my $storage = $schema->storage;
isa_ok $schema, "DBIx::Class::Schema";
isa_ok $storage, "DBIx::Class::Storage";

my $dbic_trace = DebugObject->new;
$storage->debug(1);
$storage->debugcb(sub { $dbic_trace->print($_[1]) });

my $dvd_rs  = $schema->resultset('Dvd');
my $tag_rs = $schema->resultset('Tag');

ok $dvd_rs->result_class->can("_m2m_metadata"), "dvd-rs has m2m metadata";
ok ! $tag_rs->result_class->can("_m2m_metadata"), "tag-rs has no m2m metadata";

##############################################
# testing m2m updates with IntrospectableM2M #
##############################################

my $dvd_item = $dvd_rs->first;


#
# adding one
#

my $tag_ids = [$dvd_item->tags_rs->get_column("id")->all];

push @$tag_ids, 1;


my %updates = (
	dvd_id => $dvd_item->id,
	tags => $tag_ids,
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "add one: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add one: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 1, "add one: update executed one insert";

is $dvd_item->tags_rs->count, 3, "add one: DVD item has 3 tags";

#
# removing one
#

shift @$tag_ids;

%updates = (
	dvd_id => $dvd_item->id,
	tags => $tag_ids,
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "remove one: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "remove one: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "remove one: update executed no insert";

is $dvd_item->tags_rs->count, 2, "remove one: DVD item has 2 tags";


#
# adding recursive
#

#push @$tag_ids, ( 4, 5, 6 );

%updates = (
	dvd_id => $dvd_item->id,
	tags => [
            (map { { name => $_->name, id => $_->id } } $dvd_item->tags->all) ,
            { name => "winnie" },
            { name => "fanny" },
            { name => "sammy" },
    ],
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "add several: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 3, "add several: update executed three inserts in dvdtag";
is $dbic_trace->count_messages("^INSERT INTO tag "), 3, "add several: update executed three inserts in tag";

is $dvd_item->tags_rs->count, 5, "add several: DVD item has 5 tags";

#
# updating recursive
#

#push @$tag_ids, ( 4, 5, 6 );

%updates = (
	dvd_id => $dvd_item->id,
	tags => [
            (map { { name => $_->name."_Changed", id => $_->id } } $dvd_item->tags->all) ,
    ],
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "add several: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "add several: update executed no inserts in dvdtag";
is $dbic_trace->count_messages("^UPDATE tag "), 5, "add several: update executed five updates in tag";

is $dvd_item->tags_rs->count, 5, "add several: DVD item has 5 tags";


#
# updating and removing
#


%updates = (
	dvd_id => $dvd_item->id,
	tags => [
            (map { { name => $_->name."More", id => $_->id } } $dvd_item->tags->all) ,
    ],
);

$updates{tags} = [splice @{$updates{tags}}, 2, 3];

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "add several: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "add several: update executed no inserts in dvdtag";
is $dbic_trace->count_messages("^UPDATE tag "), 3, "add several: update executed three updates in tag";

is $dvd_item->tags_rs->count, 3, "add several: DVD item has 3 tags";


#
# updating and adding
#


%updates = (
	dvd_id => $dvd_item->id,
	tags => [
            (map { { name => $_->name."More", id => $_->id } } $dvd_item->tags->all) ,
            { name => "rob" },
            { name => "bot" },
    ],
);


$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "add several: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "add several: update executed two inserts in dvdtag";
is $dbic_trace->count_messages("^UPDATE tag "), 3, "add several: update executed three updates in tag";

is $dvd_item->tags_rs->count, 5, "add several: DVD item has 5 tags";


#
# removing several
#

$tag_ids = [4,5];
%updates = (
	dvd_id => $dvd_item->id,
	tags => $tag_ids,
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "remove several: update did not remove all tags'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "remove several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "remove several: update executed no insert";

is $dvd_item->tags_rs->count, 2, "remove several: DVD item has 2 tags";


#
# empty arrayref
#

$tag_ids = [];
%updates = (
	dvd_id => $dvd_item->id,
	tags => $tag_ids,
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates);

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "remove all: update did remove all tags'";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "remove all: update executed no insert";

is $dvd_item->tags_rs->count, 0, "remove all: DVD item has no tags";

#
# old set_$rel behaviour
#

$tag_ids = [2,4];
%updates = (
	dvd_id => $dvd_item->id,
	tags => $tag_ids,
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates, {m2m_force_set_rel => 1});

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "remove several: update did remove all tags'";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "remove several: update executed 2 insert";

is $dvd_item->tags_rs->count, 2, "remove several: DVD item has 2 tags";

# doint this 2 times to test identical behaviour
$tag_ids = [2,4];
%updates = (
	dvd_id => $dvd_item->id,
	tags => $tag_ids,
);

$dbic_trace->clear;

$dvd_rs->recursive_update(\%updates, {m2m_force_set_rel => 1});

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "remove several: update did remove all tags'";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "remove several: update executed 2 insert";

is $dvd_item->tags_rs->count, 2, "remove several: DVD item has 2 tags";

#################################################
# testing m2m updates without IntrospectableM2M #
#################################################

my $tag_item = $tag_rs->first;


#
# adding one
#

my $dvd_ids = [$tag_item->dvds_rs->get_column("dvd_id")->all];

push @$dvd_ids, 1;


%updates = (
	id => $tag_item->id,
	dvds => $dvd_ids,
);

$dbic_trace->clear;

$tag_rs->recursive_update(\%updates);

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "add one: update did remove all dvds'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add one: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 3, "add one: update executed three insert";

is $tag_item->dvds_rs->count, 3, "add one: tag item has 3 dvds";

#
# removing one
#

shift @$dvd_ids;

%updates = (
	id => $tag_item->id,
	dvds => $dvd_ids,
);

$dbic_trace->clear;

$tag_rs->recursive_update(\%updates);

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "remove one: update did remove all dvds'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "remove one: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "remove one: update executed two insert";

is $tag_item->dvds_rs->count, 2, "remove one: tag item has 2 dvds";


#
# adding recursive
#

#push @$dvd_ids, ( 4, 5, 6 );

%updates = (
	id => $tag_item->id,
	dvds => [
            (map { { name => $_->name, dvd_id => $_->id } } $tag_item->dvds->all) ,
            { name => "winnie", owner => 1 },
            { name => "fanny" , owner => 1},
            { name => "sammy" , owner => 1},
    ],
);

$dbic_trace->clear;

$tag_rs->recursive_update(\%updates);

ok  $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "add several: update did remove all dvds'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "add several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 5, "add several: update executed five inserts in dvdtag";
is $dbic_trace->count_messages("^INSERT INTO dvd "), 3, "add several: update executed three inserts in dvd";

is $tag_item->dvds_rs->count, 5, "add several: tag item has 5 dvds";


#
# removing several
#

$dvd_ids = [3,5];
%updates = (
	id => $tag_item->id,
	dvds => $dvd_ids,
);

$dbic_trace->clear;

$tag_rs->recursive_update(\%updates);

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "remove several: update did remove all dvds'";
is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "remove several: update executed one delete";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "remove several: update executed two insert";

is $tag_item->dvds_rs->count, 2, "remove several: tag item has 2 dvds";


#
# empty arrayref
#

$dvd_ids = [];
%updates = (
	id => $tag_item->id,
	dvds => $dvd_ids,
);

$dbic_trace->clear;

$tag_rs->recursive_update(\%updates);

ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "remove all: update did remove all dvds'";
is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "remove all: update executed no insert";

is $tag_item->dvds_rs->count, 0, "remove all: tag item has no dvds";

done_testing;

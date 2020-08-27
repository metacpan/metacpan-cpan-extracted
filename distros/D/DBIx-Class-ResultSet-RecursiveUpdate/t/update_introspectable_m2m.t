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

subtest 'testing m2m updates with IntrospectableM2M' => sub {
    ok $dvd_rs->result_class->can("_m2m_metadata"), "dvd rs has m2m metadata";
    my $dvd_item = $dvd_rs->first;

    # wrap subtest in a transaction
    $schema->txn_begin;

    subtest 'relationship name = foreign key column name' => sub {
        my $tag_ids = [$dvd_item->tags_rs->get_column('id')->all];
        is_deeply([sort @$tag_ids], [2, 3], "dvd has tags 2 and 3");

        subtest 'add one' => sub {
            push @$tag_ids, 1;

            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => $tag_ids,
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 1, "update executed one insert";

            is $dvd_item->tags_rs->count, 3, "DVD item has 3 tags";
        };

        subtest 'no changes' => sub {
            $dbic_trace->clear;

            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => $tag_ids,
            );

            $dvd_rs->recursive_update(\%updates);

            is $dbic_trace->count_messages, 2, "two queries executed";
            is $dbic_trace->count_messages("^SELECT"), 2, "update executed two select queries";

            is $dvd_item->tags_rs->count, 3, "DVD item still has 3 tags";
        };

        subtest 'remove one' => sub {
            shift @$tag_ids;

            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => $tag_ids,
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";
        };

        subtest 'add recursive' => sub {
            #push @$tag_ids, ( 4, 5, 6 );

            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags => [
                    (map { { name => $_->name, id => $_->id } }
                        $dvd_item->tags->all),
                    { name => "winnie" },
                    { name => "fanny" },
                    { name => "sammy" },
                ],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 3, "update executed three inserts in dvdtag";
            is $dbic_trace->count_messages("^INSERT INTO tag "), 3, "update executed three inserts in tag";

            is $dvd_item->tags_rs->count, 5, "DVD item has 5 tags";
        };

        subtest 'update recursive' => sub {
            #push @$tag_ids, ( 4, 5, 6 );

            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => [(
                    map { { name => $_->name.'_Changed', id => $_->id } }
                        $dvd_item->tags->all
                )],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no inserts in dvdtag";
            is $dbic_trace->count_messages("^UPDATE tag "), 5, "update executed five updates in tag";

            is $dvd_item->tags_rs->count, 5, "DVD item has 5 tags";
        };

        subtest 'update and remove' => sub {
            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => [(
                    map { { name => $_->name.'More', id => $_->id } }
                        $dvd_item->tags->all
                )],
            );

            $updates{tags} = [splice @{$updates{tags}}, 2, 3];

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no inserts in dvdtag";
            is $dbic_trace->count_messages("^UPDATE tag "), 3, "update executed three updates in tag";

            is $dvd_item->tags_rs->count, 3, "DVD item has 3 tags";
        };

        subtest 'update and add' => sub {
            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags => [
                    (map { { name => $_->name.'More', id => $_->id } }
                        $dvd_item->tags->all),
                    { name => "rob" },
                    { name => "bot" },
                ],
            );


            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed two inserts in dvdtag";
            is $dbic_trace->count_messages("^UPDATE tag "), 3, "update executed three updates in tag";

            is $dvd_item->tags_rs->count, 5, "DVD item has 5 tags";
        };

        subtest 'remove several' => sub {
            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => [4,5],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";
        };

        subtest 'remove all' => sub {
            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => [],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did remove all tags";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

            is $dvd_item->tags_rs->count, 0, "DVD item has no tags";
        };

        subtest 'old set_$rel behaviour' => sub {
            my %updates = (
            	dvd_id => $dvd_item->id,
            	tags   => [2,4],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates, {m2m_force_set_rel => 1});

            ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did remove all tags";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed 2 insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";

            # doing this two times to test identical behaviour
            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates, {m2m_force_set_rel => 1});

            ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did remove all tags";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed 2 insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";
        };

        # rollback all changes to keep the database in the same state it was
        # at the beginning of the subtest
        $schema->txn_rollback;
    };

    subtest 'relationship name != foreign key column name' => sub {
        my $tag_ids = [$dvd_item->tags_rs->get_column('id')->all];
        is_deeply([sort @$tag_ids], [2, 3], "dvd has tags 2 and 3");

        # wrap subtest in a transaction
        $schema->txn_begin;

        subtest 'add one' => sub {
            push @$tag_ids, 1;

            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => $tag_ids,
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 1, "update executed one insert";

            is $dvd_item->tags_rs->count, 3, "DVD item has 3 tags";
        };

        subtest 'no changes' => sub {
            $dbic_trace->clear;

            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => $tag_ids,
            );

            $dvd_rs->recursive_update(\%updates);

            is $dbic_trace->count_messages, 2, "two queries executed";
            is $dbic_trace->count_messages("^SELECT"), 2, "update executed two select queries";

            is $dvd_item->tags_rs->count, 3, "DVD item still has 3 tags";
        };

        subtest 'remove one' => sub {
            shift @$tag_ids;

            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => $tag_ids,
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";
        };

        subtest 'add recursive' => sub {
            #push @$tag_ids, ( 4, 5, 6 );

            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [
                    (map { { name => $_->name, id => $_->id } }
                        $dvd_item->rel_tags->all),
                    { name => "winnie" },
                    { name => "fanny" },
                    { name => "sammy" },
                ],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 3, "update executed three inserts in dvdtag";
            is $dbic_trace->count_messages("^INSERT INTO tag "), 3, "update executed three inserts in tag";

            is $dvd_item->tags_rs->count, 5, "DVD item has 5 tags";
        };

        subtest 'update recursive' => sub {
            #push @$tag_ids, ( 4, 5, 6 );

            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [(
                    map { { name => $_->name.'_Changed', id => $_->id } }
                        $dvd_item->rel_tags->all
                )],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no inserts in dvdtag";
            is $dbic_trace->count_messages("^UPDATE tag "), 5, "update executed five updates in tag";

            is $dvd_item->tags_rs->count, 5, "DVD item has 5 tags";
        };

        subtest 'update and remove' => sub {
            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [(
                    map { { name => $_->name.'More', id => $_->id } }
                        $dvd_item->rel_tags->all
                )],
            );

            $updates{rel_tags} = [splice @{$updates{rel_tags}}, 2, 3];

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no inserts in dvdtag";
            is $dbic_trace->count_messages("^UPDATE tag "), 3, "update executed three updates in tag";

            is $dvd_item->tags_rs->count, 3, "DVD item has 3 tags";
        };

        subtest 'update and add' => sub {
            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [
                    (map { { name => $_->name.'More', id => $_->id } }
                        $dvd_item->rel_tags->all),
                    { name => "rob" },
                    { name => "bot" },
                ],
            );


            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 0, "update executed no delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed two inserts in dvdtag";
            is $dbic_trace->count_messages("^UPDATE tag "), 3, "update executed three updates in tag";

            is $dvd_item->tags_rs->count, 5, "DVD item has 5 tags";
        };

        subtest 'remove several' => sub {
            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [4,5],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok ! $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did not remove all tags";
            is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";
        };

        subtest 'remove all' => sub {
            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates);

            ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did remove all tags";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

            is $dvd_item->tags_rs->count, 0, "DVD item has no tags";
        };

        subtest 'old set_$rel behaviour' => sub {
            my %updates = (
            	dvd_id     => $dvd_item->id,
            	rel_tags   => [2,4],
            );

            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates, {m2m_force_set_rel => 1});

            ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did remove all tags";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed 2 insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";

            # doing this two times to test identical behaviour
            $dbic_trace->clear;

            $dvd_rs->recursive_update(\%updates, {m2m_force_set_rel => 1});

            ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( dvd = \? \)'), "update did remove all tags";
            is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed 2 insert";

            is $dvd_item->tags_rs->count, 2, "DVD item has 2 tags";
        };

        # rollback all changes to keep the database in the same state it was
        # at the beginning of the subtest
        $schema->txn_rollback;
    };
};

subtest 'testing m2m updates without IntrospectableM2M' => sub {
    ok ! $tag_rs->result_class->can("_m2m_metadata"), "tag rs has no m2m metadata";
    my $tag_item = $tag_rs->first;
    my $dvd_ids = [$tag_item->dvds_rs->get_column("dvd_id")->all];

    subtest 'add one' => sub {
        push @$dvd_ids, 1;

        my %updates = (
        	id     => $tag_item->id,
        	dvds   => $dvd_ids,
        );

        $dbic_trace->clear;

        $tag_rs->recursive_update(\%updates);

        ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "update did remove all dvds";
        is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
        is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 3, "update executed three insert";

        is $tag_item->dvds_rs->count, 3, "tag item has 3 dvds";
    };

    subtest 'no changes' => sub {
        $dbic_trace->clear;

        my %updates = (
        	id     => $tag_item->id,
        	dvds   => $dvd_ids,
        );

        $tag_rs->recursive_update(\%updates);

        is $dbic_trace->count_messages, 8, "eight queries executed";
        is $dbic_trace->count_messages("^SELECT"), 4, "update executed two select queries";
        is $dbic_trace->count_messages("^DELETE"), 1, "update executed one delete query";
        is $dbic_trace->count_messages("^INSERT"), 3, "update executed three insert queries";

        is $tag_item->dvds_rs->count, 3, "tag item still has 3 dvds";
    };

    subtest 'remove one' => sub {
        shift @$dvd_ids;

        my %updates = (
        	id     => $tag_item->id,
        	dvds   => $dvd_ids,
        );

        $dbic_trace->clear;

        $tag_rs->recursive_update(\%updates);

        ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "update did remove all dvds";
        is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
        is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed two insert";

        is $tag_item->dvds_rs->count, 2, "tag item has 2 dvds";
    };

    subtest 'add recursive' => sub {
        #push @$dvd_ids, ( 4, 5, 6 );

        my %updates = (
        	id     => $tag_item->id,
        	dvds   => [
                (map { { name => $_->name, dvd_id => $_->id } }
                    $tag_item->dvds->all),
                { name => "winnie", owner => 1 },
                { name => "fanny" , owner => 1},
                { name => "sammy" , owner => 1},
            ],
        );

        $dbic_trace->clear;

        $tag_rs->recursive_update(\%updates);

        ok  $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "update did remove all dvds";
        is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
        is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 5, "update executed five inserts in dvdtag";
        is $dbic_trace->count_messages("^INSERT INTO dvd "), 3, "update executed three inserts in dvd";

        is $tag_item->dvds_rs->count, 5, "tag item has 5 dvds";
    };

    subtest 'remove several' => sub {
        my %updates = (
        	id     => $tag_item->id,
        	dvds   => [3,5],
        );

        $dbic_trace->clear;

        $tag_rs->recursive_update(\%updates);

        ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "update did remove all dvds";
        is $dbic_trace->count_messages("^DELETE FROM dvdtag "), 1, "update executed one delete";
        is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 2, "update executed two insert";

        is $tag_item->dvds_rs->count, 2, "tag item has 2 dvds";
    };

    subtest 'remove all' => sub {
        my %updates = (
        	id     => $tag_item->id,
        	dvds   => [],
        );

        $dbic_trace->clear;

        $tag_rs->recursive_update(\%updates);

        ok $dbic_trace->count_messages('^DELETE FROM dvdtag WHERE \( tag = \? \)'), "update did remove all dvds";
        is $dbic_trace->count_messages("^INSERT INTO dvdtag "), 0, "update executed no insert";

        is $tag_item->dvds_rs->count, 0, "tag item has no dvds";
    };
};

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

require Catmandu::Store::Hash;
require Catmandu::Store::Solr;

my $solr_url       = $ENV{T_SOLR_URL};
my $solr_bag       = $ENV{T_SOLR_BAG} || "data";
my $solr_id_field  = $ENV{T_SOLR_ID_FIELD} || "_id";
my $solr_bag_field = $ENV{T_SOLR_BAG_FIELD} || "_bag";

unless (defined($solr_url) && $solr_url ne "") {

    plan skip_all => "no environment variable T_SOLR_URL found";

}
else {

    my $store;
    my $bag;

    lives_ok(
        sub {

            $store = Catmandu::Store::Solr->new(
                url       => $solr_url,
                id_field  => $solr_id_field,
                bag_field => $solr_bag_field
            );

        },
        "store created"
    );

    lives_ok(
        sub {

            $bag = $store->bag($solr_bag);

        },
        "bag created"
    );

    my $record = {_id => "test"};

    #delete all
    lives_ok(sub {$bag->delete_all; $bag->commit();}, "bag delete all");

    #bag add
    lives_ok(sub {$bag->add($record); $bag->commit();}, "bag add");

    #bag get
    my $new_record;
    lives_ok(sub {$new_record = $bag->get($record->{_id});}, "bag get");
    is_deeply($record, $new_record, "retrieved record equal");

    #bag delete
    lives_ok(sub {$bag->delete($record->{_id}); $bag->commit();},
        "bag delete");
    is($bag->get($record->{_id}), undef, "record deleted");

    #bag add_many
    my @records;
    for (1 .. 10) {
        push @records, {_id => "test-$_"};
    }
    lives_ok(sub {$bag->add_many(\@records); $bag->commit();},
        "bag add_many");

    my $num = 0;

    lives_ok(sub {$num = $bag->count();}, "bag count");

    is($num, scalar(@records), "bag count");

    #bag delete_all
    lives_ok(sub {$bag->delete_all(); $bag->commit();}, "bag delete");
    is($bag->count(), 0, "all records deleted");

    #transactions
    dies_ok(
        sub {
            $bag->store->transaction(
                sub {
                    $bag->add({_id => "a"});
                    $bag->add({_id => "b"});
                    die("failed");
                }
            );
        },
        "bag transaction must die"
    );

    is($bag->count(), 0, "bag transaction had no effect");

    #reify
    my $reify;
    lives_ok(sub {$reify = Catmandu::Store::Hash->new()->bag();},
        "reify created");

    #add many
    lives_ok(
        sub {
            for (1 .. 10) {
                $reify->add({_id => "test-$_", title => "test-$_"});
                $reify->commit();
            }
        },
        "added many records to reify"
    );

    #copy to solr without title
    lives_ok(
        sub {
            $bag->add_many(
                $reify->map(
                    sub {
                        +{_id => $_[0]->{_id}};
                    }
                )
            );
            $bag->commit();
        },
        "copied reify to solr bag"
    );

    #reify records
    my $reified_records;
    lives_ok(
        sub {
            $reified_records = $bag->searcher(fl => $solr_id_field)->map(
                sub {
                    $reify->get($_[0]->{_id});
                }
            )->to_array();
        },
        "retrieved reified records"
    );

    #compare
    my $from = [sort {$a->{_id} cmp $b->{_id}} @$reified_records];
    my $to   = [sort {$a->{_id} cmp $b->{_id}} @{$reify->to_array()}];
    is_deeply($from, $to, "all records equal");

    done_testing 20;

}

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);

require Catmandu::Store::DBI;

my $driver_found = 1;
{
    local $@;
    eval {require DBD::SQLite;};
    if ($@) {
        $driver_found = 0;
    }
}

if (!$driver_found) {

    plan skip_all => "database driver DBD::SQLite not found";

}
else {

    my ($fh, $file);
    lives_ok(
        sub {
            #avoid exclusive lock on BSD
            ($fh, $file) = tempfile(UNLINK => 1, EXLOCK => 0);
        },
        "database file created"
    );

    my $bag;

    lives_ok(
        sub {
            $bag = Catmandu::Store::DBI->new(
                data_source => "dbi:SQLite:dbname=$file")->bag();
        },
        "bag created"
    );

    my $record
        = {_id => "test", title => "my little pony", author => "no idea"};

    #bag add
    lives_ok(sub {$bag->add($record)}, "bag add successfull");

    #bag get
    my $new_record;
    lives_ok(sub {$new_record = $bag->get($record->{_id});},
        "bag get successfull");
    is_deeply($record, $new_record, "retrieved record equal");

    #bag delete
    lives_ok(sub {$bag->delete($record->{_id})}, "bag delete");
    is($bag->get($record->{_id}), undef, "record deleted successfully");

    #bag add_many
    my @records;
    for (1 .. 10) {
        push @records, {_id => "test-$_", test => $_};
    }
    lives_ok(sub {$bag->add_many(\@records)}, "bag add_many successfull");

    my $num = 0;

    lives_ok(sub {$num = $bag->count();}, "bag count successfully");

    is($num, scalar(@records), "bag count equal");

    #bag delete_all
    lives_ok(sub {$bag->delete_all();}, "bag delete successfully");
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
        "bag transactions"
    );

    is($bag->count(), 0, "bag transactions");

    done_testing 14;

}

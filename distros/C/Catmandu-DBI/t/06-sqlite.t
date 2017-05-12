#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;

require Catmandu::Store::DBI;
require Catmandu::Serializer::json;

my $driver_found = 1;
{
    local $@;
    eval {
        require DBD::SQLite;
    };
    if($@){
        $driver_found = 0;
    }
}


if(!$driver_found){

    plan skip_all => "database driver DBD::SQLite not found";

}else{
    sub get {
        my($dbh,$table,$id_field,$id)=@_;
        my $sql = "SELECT * FROM ".$dbh->quote_identifier($table)." WHERE ".$dbh->quote_identifier($id_field)."=?";
        my $sth = $dbh->prepare_cached($sql) or die($dbh->errstr);
        $sth->execute($id) or die($sth->errstr);
        $sth->fetchrow_hashref;
    }

    my $record = {
        _id => "mylittlepony",
        title => "My little pony",
        author => "unknown"
    };
    my $serializer = Catmandu::Serializer::json->new();

    #impliciet mapping (old behaviour) => except for the _id that is not stored anymore in 'data'
    {
        my $bag;
        lives_ok(sub { $bag = Catmandu::Store::DBI->new( data_source => "dbi:SQLite:dbname=:memory:" )->bag(); },"no mapping - bag created");

        lives_ok(sub{ $bag->add($record); },"no mapping - add record");

        my $row = get( $bag->store->dbh , "data" , "id" , $record->{_id} );
        $row->{data} = $serializer->deserialize($row->{data});

        my $expected = +{ id => $record->{_id}, data => { %$record } };
        delete $expected->{data}->{_id};

        is_deeply( $row, $expected , "expected fields created" );
    }

    #explicit mapping (no double field _id anymore)
    {
        my $bag;
        lives_ok(sub {
            $bag = Catmandu::Store::DBI->new(
                data_source => "dbi:SQLite:dbname=:memory:",
                bags => {
                    data => {
                        mapping => {
                            _id => {
                                column => "_id",
                                type => "string",
                                index => 1,
                                required => 1,
                                unique => 1
                            },
                            title => {
                                column => "title",
                                type => "string"
                            },
                            author => {
                                column => "author",
                                type => "string"
                            }
                        }
                    }
                }
            )->bag();
        },"mapping given - bag created");

        lives_ok(sub{ $bag->add($record); },"mapping given - add record");

        my $row = get( $bag->store->dbh , "data" , "_id" , $record->{_id} );
        is_deeply $row,$record,"mapping given - expected fields created";

        lives_ok(sub { $bag->count },"mapping given - count successfull");
    }
    {
        my $bag;
        lives_ok(sub {
            $bag = Catmandu::Store::DBI->new(
                data_source => "dbi:SQLite:dbname=:memory:",
                bags => {
                    data => {
                        mapping => {
                            _id => {
                                column => "_id",
                                type => "string",
                                index => 1,
                                required => 1,
                                unique => 1
                            },
                            title => {
                                column => "title",
                                type => "string"
                            },
                            author => {
                                column => "author",
                                type => "string"
                            }
                        }
                    }
                }
            )->bag();
        },"iterator - bag created");
        my @d_records = map { +{ author => "Dostoyevsky" } } 1..10;
        my @t_records = map { +{ author => "Tolstoj" } } 1..15;

        $bag->add_many([@d_records,@t_records],"iterator - added many records");

        #iterator select
        my $iterator;

        lives_ok(sub{ $iterator = $bag->select(author => "Tolstoj"); },"iterator - select(key => value) created");
        cmp_ok($iterator->count,"==",scalar(@t_records),"iterator - select(key => value) contains correct number of records");

        #iterator slice(start)
        lives_ok(sub{ $iterator = $bag->select(author => "Dostoyevsky")->slice(5); },"iterator - select(key => value)->slice(start) created");
        cmp_ok($iterator->count,"==",5,"iterator - select(key => value)->slice(start) contains correct number of records");

        #iterator slice(start,limit)
        lives_ok(sub{ $iterator = $bag->select(author => "Dostoyevsky")->slice(5,1); },"iterator - select(key => value)->slice(start,limit) created");
        cmp_ok($iterator->count,"==",1,"iterator - select(key => value)->slice(start,limit) contains correct number of records");

        #first
        my $r;
        lives_ok(sub{ $r = $bag->select(author => "Dostoyevsky")->first; },"iterator - select(key => value)->first created");
        isnt($r,undef,"iterator - select(key => value)->first contains one record");

    }

    done_testing 16;

}

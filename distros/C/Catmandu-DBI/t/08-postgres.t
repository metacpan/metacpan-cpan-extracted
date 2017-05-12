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
        require DBD::Pg;
    };
    if($@){
        $driver_found = 0;
    }
}
my %store_args = (
    data_source => $ENV{CATMANDU_DBI_TEST_PG_DSN},
    username => $ENV{CATMANDU_DBI_TEST_PG_USERNAME},
    password => $ENV{CATMANDU_DBI_TEST_PG_PASSWORD}
);

if(!$driver_found){

    plan skip_all => "database driver DBD::Pg not found";

}
elsif(!(
    $ENV{CATMANDU_DBI_TEST_PG_DSN} || $ENV{CATMANDU_DBI_TEST_PG_USERNAME} || $ENV{CATMANDU_DBI_TEST_PG_PASSWORD}
)){

    plan skip_all => "not all postgres connection details are set";

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

    #impliciet mapping (old behaviour)
    {
        my $bag;
        my $bag_name = "data1";
        lives_ok(sub { $bag = Catmandu::Store::DBI->new( %store_args )->bag($bag_name); },"no mapping - bag $bag_name created");
        lives_ok(sub { $bag->delete_all; },"no mapping - bag $bag_name cleared");

        lives_ok(sub{ $bag->add($record); },"no mapping - add record");

        my $row = get( $bag->store->dbh , $bag_name , "id" , $record->{_id} );
        $row->{data} = $serializer->deserialize($row->{data});

        my $expected = +{ id => $record->{_id}, data => { %$record } };
        delete $expected->{data}->{_id};

        is_deeply( $row, $expected , "no mapping - expected fields created" );
    }

    #explicit mapping
    {
        my $bag;
        my $bag_name = "data2";
        lives_ok(sub {
            $bag = Catmandu::Store::DBI->new(
                %store_args,
                bags => {
                    $bag_name => {
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
            )->bag($bag_name);
        },"mapping given - bag $bag_name created");
        lives_ok(sub { $bag->delete_all; },"mapping given - bag $bag_name cleared");

        lives_ok(sub{ $bag->add($record); },"mapping given - record added to bag $bag_name");

        my $row = get( $bag->store->dbh , $bag_name , "_id" , $record->{_id} );
        is_deeply $row,$record,"mapping given - expected fields created";

        lives_ok(sub { $bag->count },"mapping given - count ok");
    }
    {
        my $bag;
        my $bag_name = "data3";
        lives_ok(sub {
            $bag = Catmandu::Store::DBI->new(
                %store_args,
                bags => {
                    $bag_name => {
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
            )->bag($bag_name);
        },"iterator - bag $bag_name created");
        lives_ok(sub { $bag->delete_all; },"iterator - bag $bag_name cleared");

        my @d_records = map { +{ author => "Dostoyevsky" } } 1..10;
        my @t_records = map { +{ author => "Tolstoj" } } 1..15;

        $bag->add_many([@d_records,@t_records]);

        #iterator select
        my $iterator;

        lives_ok(sub{ $iterator = $bag->select(author => "Tolstoj"); },"iterator - select(key => value) created");
        cmp_ok($iterator->count,"==",scalar(@t_records),"iterator - count contains correct number of records");

        #iterator slice(start)
        lives_ok(sub{ $iterator = $bag->select(author => "Dostoyevsky")->slice(5); },"iterator - slice(start) created");
        cmp_ok($iterator->count,"==",5,"slice(start)->count contains correct number of records");

        #iterator slice(start,limit)
        lives_ok(sub{ $iterator = $bag->select(author => "Dostoyevsky")->slice(5,1); },"iterator - slice(start,limit) created");
        cmp_ok($iterator->count,"==",1,"slice(start,limit)->count contains correct number of records");

        #first
        my $r;
        lives_ok(sub{ $r = $bag->select(author => "Dostoyevsky")->first; },"iterator - select(key => value)->first created");
        isnt($r,undef,"iterator - select(key => value)->first contains one record");

    }

    done_testing 19;
}

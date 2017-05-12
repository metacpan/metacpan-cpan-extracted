#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);

sub r { int(rand(100)); }

use DBI;
use Catmandu::Importer::DBI;

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

    my @fields = qw(name first_name street street_nr postal_code place);
    my @people;
    for(1..100){
        my $record = {};
        $record->{$_} = r() for @fields;
        $record->{id} = int($_);
        push @people,$record;
    }
    @people = sort { $a->{id} <=> $b->{id} } @people;


    my($fh,$file);
    lives_ok(sub {
      #avoid exclusive lock on BSD
      ($fh,$file) = tempfile(UNLINK => 1,EXLOCK => 0);
    }, "database file created");

    #connect
    my $dbh;
    lives_ok(sub{

        $dbh = DBI->connect("dbi:SQLite:dbname=$file","","",{ AutoCommit => 1, RaiseError => 1 });
        $dbh or die($DBI::errstr);

    },"dbh created");

    #create table
    {
        my $sql = "create table people (id integer not null primary key,".join(',',map { "$_ varchar(255)" } @fields).")";
        lives_ok(sub{

            $dbh->do($sql) or die($dbh->errstr);

        },"table created");
    }
    #insert data
    {
        my $sql  = "insert into people(id,".join(',',@fields).") values(?,".join(',',("?") x (scalar(@fields))).")";
        my $sth;
        lives_ok(sub{

            $sth = $dbh->prepare($sql) or die($dbh->errstr);
            for my $p(@people){
                my @values = @{$p}{"id",@fields};
                $sth->execute(@values) or die($sth->errstr);
            }
            $sth->finish;

        },"data added");

    }

    #import data
    my $importer;

    #create importer
    lives_ok(sub{

        $importer = Catmandu::Importer::DBI->new(
            dsn => "dbi:SQLite:dbname=$file",
            user => "",
            password => "",
            query => "select * from people order by id asc"
        );

    },"importer created");

    is_deeply $importer->to_array,\@people,"imported data equal to inserted data";

    done_testing 6;

}

use strict;
use warnings;

use Test::More;

use DBI;
use DBI::Profile;
use Test::Requires qw/DBD::SQLite/;

use DBIx::ProfileManager;
use File::Temp qw(tempfile);

local $DBI::Profile::ON_DESTROY_DUMP = undef;

our %sql = (
    'create_table_foo' => q|CREATE TABLE foo (id int primary key, name varchar(32) )|,
    'insert_foo' => q|INSERT INTO foo(id, name) VALUES(?, ?)|,
    'create_table_bar' => q|CREATE TABLE bar (id int primary key, name varchar(32) )|,
    'insert_bar' => q|INSERT INTO bar(id, name) VALUES(?, ?)|,
    'select_bar' => q|SELECT * FROM bar WHERE id = ?|,
);

sub generate_temp_db {
    my ( $fh, $filename ) = tempfile;

    my $dsn = sprintf( 'dbi:SQLite:dbname=%s', $filename );
    my $dbh = DBI->connect( $dsn, '', '', );
    return ( $dbh, $dsn );
}

subtest 'single db handle' => sub {
    my ( $dbh, $dsn ) = generate_temp_db;
    isa_ok( $dbh, 'DBI::db' );
    is( $dbh->{Profile}, undef, 'Profile parameter is undef' );

    my $pm = DBIx::ProfileManager->new( config => '!Statement' );
    $pm->profile_start;

    is_deeply( $pm->path, [ qw/!Statement/ ], 'path attr' );
    
    isa_ok( $dbh->{Profile}, 'DBI::Profile' );

    $dbh->do($sql{create_table_foo});
    ok(
        exists $dbh->{Profile}{Data}{$sql{create_table_foo}},
        'create table sql is existed in profile data'
    );

    my $sth = $dbh->prepare($sql{insert_foo});
    for ( my $i = 1 ; $i < 10 ; $i++ ) {
        $sth->execute( $i, sprintf( 'id:%d', $i ) );
    }
    $sth->finish;

    ok(
        exists $dbh->{Profile}{Data}{$sql{insert_foo}},
        'insert sql is existed in profile data'
    );

    $pm->profile_stop;

    is( $dbh->{Profile}{Data}, undef, 'DBI::Profile Data attr is undef' );

    my $data = $pm->data;

    ok( exists $data->{$dsn}, 'profile data by dsn is existed' );
    ok(
        exists $data->{$dsn}{$sql{create_table_foo}},
        'create table sql is existed in profile data'
    );
    ok(
        exists $data->{$dsn}{$sql{insert_foo}},
        'insert sql is existed in profile data'
    );

    my @results = $pm->data_formatted( '%{statement}' );
    is_deeply( [ sort { $a cmp $b } @results ], [
        $sql{create_table_foo},
        $sql{insert_foo},
    ], 'formatted data' );
    
    done_testing;
};

subtest 'multi db handle and multi path' => sub {
    my ( $dbh1, $dsn1 ) = generate_temp_db;
    my ( $dbh2, $dsn2 ) = generate_temp_db;
    
    isa_ok( $dbh1, 'DBI::db' );
    isa_ok( $dbh2, 'DBI::db' );
    
    is( $dbh1->{Profile}, undef, 'dbh1 Profile parameter is undef' );
    is( $dbh2->{Profile}, undef, 'dbh2 Profile parameter is undef' );

    my $pm = DBIx::ProfileManager->new( config => '!Statement:!MethodName' );
    $pm->profile_start;

    is_deeply( $pm->path, [ qw/!Statement !MethodName/ ], 'path attr' );
    
    isa_ok( $dbh1->{Profile}, 'DBI::Profile' );
    isa_ok( $dbh2->{Profile}, 'DBI::Profile' );

    $dbh1->do($sql{create_table_foo});
    
    ok(
        exists $dbh1->{Profile}{Data}{$sql{create_table_foo}},
        'dbh1 create table sql is existed in profile data'
    );

    $dbh2->do($sql{create_table_bar});

    ok(
        exists $dbh2->{Profile}{Data}{$sql{create_table_bar}},
        'dbh2 create table sql is existed in profile data'
    );
    
    my $sth1 = $dbh1->prepare($sql{insert_foo});
    for ( my $i = 1 ; $i < 10 ; $i++ ) {
        $sth1->execute( $i, sprintf( 'id:%d', $i ) );
    }
    $sth1->finish;

    ok(
        exists $dbh1->{Profile}{Data}{$sql{insert_foo}},
        'dbh1 insert sql is existed in profile data'
    );

    my $sth2 = $dbh2->prepare($sql{insert_bar});
    for ( my $j = 1 ; $j < 10 ; $j++ ) {
        $sth2->execute( $j, sprintf( 'id:%d', $j ) );
    }
    $sth2->finish;

    ok(
        exists $dbh2->{Profile}{Data}{$sql{insert_bar}},
        'dbh2 insert sql is existed in profile data'
    );

    for ( my $j = 1; $j < 10; $j++ ) {
        $dbh2->selectrow_arrayref( $sql{select_bar}, undef, $j );
    }

    ok(
        exists $dbh2->{Profile}{Data}{$sql{select_bar}},
        'dbh2 select sql is existed in profile data'
    );
    
    $pm->profile_stop;

    is( $dbh1->{Profile}{Data}, undef, 'DBI::Profile Data attr is undef' );

    my $data = $pm->data;

    ok( exists $data->{$dsn1}, 'profile data by dsn is existed' );
    ok(
        exists $data->{$dsn1}{$sql{create_table_foo}},
        'create table sql is existed in profile data'
    );
    ok(
        exists $data->{$dsn1}{$sql{insert_foo}},
        'insert sql is existed in profile data'
    );

    my @structured_data =
        grep { $_->{method_name} =~ m/^(do|execute|fetch|select)/; }
        $pm->data_structured;

    my @results = $pm->data_formatted( '%{statement}', @structured_data );

    is( @results, 5, 'executed queries' );

    is_deeply( [ sort { $a cmp $b } @results ], [
        $sql{create_table_bar},
        $sql{create_table_foo},
        $sql{insert_bar},        
        $sql{insert_foo},
        $sql{select_bar},
    ], 'formatted data' );
    
    done_testing;
};

done_testing;

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:

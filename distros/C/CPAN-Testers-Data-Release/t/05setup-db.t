#!/usr/bin/perl -w
use strict;

$|=1;

#----------------------------------------------------------------------------
# Library Modules

use CPAN::Testers::Common::DBUtils;
use File::Basename;
use File::Path;
use Test::More;

#----------------------------------------------------------------------------
# Variables

# sql> select * from release_summary limit 10;;
# dist|version|id|guid|oncpan|distmat|perlmat|patched|pass|fail|na|unknown

my @ROWS = (
    q{Crypt-Salt|0.01|9348320|94812eb8-e604-11df-b986-f0a4f41852f9|1|1|1|1|132|0|0|1},
    q{Tk-CursorControl|0.3|115449|00115449-b19f-3f77-b713-d32bba55d77f|2|1|1|1|3|0|0|0},
    q{Tk-CursorControl|0.2|102862|00102862-b19f-3f77-b713-d32bba55d77f|2|1|1|1|2|0|0|0},
    q{Tk-CursorControl|0.4|9333853|93d9dbcc-e541-11df-8d4f-a0612a1db272|1|1|1|1|62|177|1|2},
    q{Tk-CursorControl|0.4|6876196|00134933-b19f-3f77-b713-d32bba55d77f|1|1|2|1|6|11|0|0},
    q{Chess-PGN-Filter|0.11|148342|00148342-b19f-3f77-b713-d32bba55d77f|2|1|1|1|2|1|0|0},
    q{Chess-PGN-Filter|0.06|36333|00036333-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Chess-PGN-Filter|0.09|651577|00036397-b19f-3f77-b713-d32bba55d77f|2|1|1|1|1|1|0|0},
    q{Chess-PGN-Filter|0.07|36360|00036360-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Chess-PGN-Filter|0.05|36251|00036251-b19f-3f77-b713-d32bba55d77f|2|1|1|1|0|1|0|0},
    q{Crypt-Salt|0.01|9348321|94812eb9-e604-11df-b986-f0a4f41852f9|1|1|1|1|132|0|0|1},
);

#----------------------------------------------------------------------------
# Tests

mkpath( 't/_DBDIR' );

eval "use Test::Database";
plan skip_all => "Test::Database required for DB testing" if($@);

plan tests => 2;

my $td;
if($td = Test::Database->handle( 'mysql' )) {
    create_mysql_databases($td);
} elsif($td = Test::Database->handle( 'SQLite' )) {
    create_sqlite_databases($td);
}

SKIP: {
    skip "No supported databases available", 21  unless($td);

    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %options = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    #diag(Dumper(\%options));
    create_config(\%options);

    # create new instance from Test::Database object
    my $ct = CPAN::Testers::Common::DBUtils->new(%options);
    isa_ok($ct,'CPAN::Testers::Common::DBUtils');

    # insert records
    my $sql = 'INSERT INTO release_summary (dist,version,id,guid,oncpan,distmat,perlmat,patched,pass,fail,na,unknown) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)';
    for(@ROWS) {
        $ct->do_query( $sql, split(/\|/,$_) );
    }

    my @rows = $ct->get_query('hash','select count(*) as count from release_summary');
    is($rows[0]->{count}, 11, "row count for release_summary");
}

sub create_config {
    my $options = shift;

    # main config
    my $f = 't/_DBDIR/test-config.ini';
    unlink $f if -f $f;

    my $dbcfg = join("\n", map { "$_=$options->{$_}" } grep { $options->{$_}} qw(driver database dbfile dbhost dbport dbuser dbpass) );

    my $fh = IO::File->new($f,'w+') or return;
    print $fh <<PRINT;
[MASTER]
logfile=t/_DBDIR/release.log
logclean=1


; database configuration

[CPANSTATS]
$dbcfg

[RELEASE]
driver=SQLite
database=t/_DBDIR/release.db

PRINT

    $fh->close;


    # attribute test config
    $f = 't/_DBDIR/10attributes.ini';
    unlink $f if -f $f;

    $fh = IO::File->new($f,'w+') or return;
    print $fh <<PRINT;
[MASTER]
idfile=t/_DBDIR/idfile.txt

; database configuration

[CPANSTATS]
$dbcfg

[RELEASE]
driver=SQLite
database=t/_DBDIR/release.db

PRINT

    $fh->close;
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_cpanstats = (
        'PRAGMA auto_vacuum = 1',
	    'DROP TABLE IF EXISTS release_summary',
        'CREATE TABLE release_summary (
            dist        TEXT,
            version     TEXT,
            id          INTEGER,
            guid        TEXT,
            oncpan      INTEGER,
            distmat     INTEGER,
            perlmat     INTEGER,
            patched     INTEGER,
            pass        INTEGER,
            fail        INTEGER,
            na          INTEGER,
            unknown     INTEGER,
            PRIMARY KEY (id,guid)
        )'
    );

    dosql($db,\@create_cpanstats);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_cpanstats = (
	    'DROP TABLE IF EXISTS release_summary',
        'CREATE TABLE release_summary (
            dist        varchar(255) NOT NULL,
            version     varchar(255) NOT NULL,
            id          int(10) unsigned NOT NULL,
            guid        char(36) NOT NULL,
            oncpan      tinyint(4) default 0,
            distmat     tinyint(4) default 0,
            perlmat     tinyint(4) default 0,
            patched     tinyint(4) default 0,
            pass        int(10) default 0,
            fail        int(10) default 0,
            na          int(10) default 0,
            unknown     int(10) default 0,
            PRIMARY KEY (id,guid),
            INDEX (dist,version)
        )',
    );

    dosql($db,\@create_cpanstats);
}

sub dosql {
    my ($db,$sql) = @_;

    for(@$sql) {
        #diag "SQL: [$db] $_";
        eval { $db->dbh->do($_); };
        if($@) {
            diag $@;
            return 1;
        }
    }

    return 0;
}

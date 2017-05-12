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

# sql> select * from cpanstats where id in (104440,1396564,1544358,1587804,1717321,1994346,2538246,2549071,2603754,2613077,2725989,2959417,2964284,2964285,2964537,2964541,2965412,2965930,2965931,2966360,2966429,2966541,2966560,2966567,2966771,2967174,2967432,2967647,2969433,2969661,2969663,2970367,2975969) order by id;
# id|guid|state|postdate|tester|dist|version|platform|perl|osname|osvers|fulldate,type

my @CPANSTATS = (
    q{104440|00104440-b19f-3f77-b713-d32bba55d77f|unknown|200310|kriegjcb@mi.ruhr-uni-bochum.de (Jost Krieger)|AI-NeuralNet-Mesh|0.44|sun4-solaris|5.8.1|solaris|2.8|200310061151|2},
    q{1396564|01396564-b19f-3f77-b713-d32bba55d77f|unknown|200805|srezic@cpan.org|Acme-Buffy|1.5|i386-freebsd|5.5.5|freebsd|6.1-release|200805022114|2},
    q{1544358|01544358-b19f-3f77-b713-d32bba55d77f|na|200805|"JJ" <jj@jonallen.info>|AI-NeuralNet-SOM|0.07|darwin-2level|5.8.3|darwin|7.9.0|200805290833|2},
    q{1587804|01587804-b19f-3f77-b713-d32bba55d77f|na|200806|"JJ" <jj@jonallen.info>|AI-NeuralNet-SOM|0.07|darwin-2level|5.8.1|darwin|7.9.0|200806030648|2},
    q{1717321|01717321-b19f-3f77-b713-d32bba55d77f|na|200806|srezic@cpan.org|Abstract-Meta-Class|0.10|i386-freebsd|5.5.5|freebsd|6.1-release|200806171653|2},
    q{1994346|01994346-b19f-3f77-b713-d32bba55d77f|unknown|200808|srezic@cpan.org|AI-NeuralNet-SOM|0.02|i386-freebsd|5.6.2|freebsd|6.1-release|200808062212|2},
    q{2538246|02538246-b19f-3f77-b713-d32bba55d77f|fail|200811|bingos@cpan.org|Acme-CPANAuthors-French|0.06|i386-freebsd-thread-multi-64int|5.8.8|freebsd|6.2-release|200811021014|2},
    q{2549071|02549071-b19f-3f77-b713-d32bba55d77f|fail|200811|bingos@cpan.org|Acme-CPANAuthors-French|0.07|OpenBSD.i386-openbsd-thread-multi-64int|5.8.8|openbsd|4.2|200811042025|2},
    q{2603754|02603754-b19f-3f77-b713-d32bba55d77f|fail|200811|"Josts Smokehouse" <JOST@cpan.org>|AI-NeuralNet-SOM|0.02|i86pc-solaris-64int|5.8.8 patch 34559|solaris|2.11|200811122105|2},
    q{2613077|02613077-b19f-3f77-b713-d32bba55d77f|fail|200811|srezic@cpan.org|Acme-Buffy|1.5|i386-freebsd|5.8.9|freebsd|6.1-release-p23|200811132053|2},
    q{2725989|02725989-b19f-3f77-b713-d32bba55d77f|pass|200812|stro@cpan.org|Acme-CPANAuthors-Canadian|0.0101|MSWin32-x86-multi-thread|5.10.0|mswin32|5.00|200812011303|2},
    q{2959417|02959417-b19f-3f77-b713-d32bba55d77f|pass|200812|Ulrich Habel <rhaen@cpan.org>|Abstract-Meta-Class|0.11|MSWin32-x86-multi-thread|5.10.0|mswin32|5.1|200812301529|2},
    q{2964284|02964284-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|Acme|1.11111|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010443|2},
    q{2964285|02964285-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|Acme-Buffy|1.5|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010443|2},
    q{2964537|02964537-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|Acme-CPANAuthors-CodeRepos|0.080522|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010609|2},
    q{2964541|02964541-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|Acme-CPANAuthors-Japanese|0.080522|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010611|2},
    q{2965412|02965412-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|Acme-Brainfuck|1.1.1|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901010929|2},
    q{2965930|02965930-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|AI-NeuralNet-BackProp|0.89|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011103|2},
    q{2965931|02965931-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|AI-NeuralNet-Mesh|0.44|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011103|2},
    q{2966360|02966360-b19f-3f77-b713-d32bba55d77f|pass|200901|"Oliver Paukstadt" <cpan@sourcentral.org>|AI-NeuralNet-SOM|0.07|s390x-linux|5.10.0|linux|2.6.16.60-0.31-default|200901010542|2},
    q{2966429|02966429-b19f-3f77-b713-d32bba55d77f|pass|200901|"Oliver Paukstadt" <cpan@sourcentral.org>|Acme-BOPE|0.01|s390x-linux|5.8.8|linux|2.6.16.60-0.31-default|200901010558|2},
    q{2966541|02966541-b19f-3f77-b713-d32bba55d77f|pass|200901|"Oliver Paukstadt" <cpan@sourcentral.org>|Acme-CPANAuthors-Canadian|0.0101|s390x-linux-thread-multi|5.8.8|linux|2.6.18-92.1.18.el5|200901010628|2},
    q{2966560|02966560-b19f-3f77-b713-d32bba55d77f|fail|200901|"Oliver Paukstadt" <cpan@sourcentral.org>|Acme-CPANAuthors-French|0.07|s390x-linux-thread-multi|5.8.8|linux|2.6.18-92.1.18.el5|200901010635|2},
    q{2966567|02966567-b19f-3f77-b713-d32bba55d77f|pass|200901|"Oliver Paukstadt" <cpan@sourcentral.org>|Acme-CPANAuthors-CodeRepos|0.080522|s390x-linux|5.10.0|linux|2.6.16.60-0.31-default|200901010638|2},
    q{2966771|02966771-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|AEAE|0.02|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011502|2},
    q{2967174|02967174-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|AOL-TOC|0.340|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011645|2},
    q{2967432|02967432-b19f-3f77-b713-d32bba55d77f|fail|200901|andreas.koenig.gmwojprw@franz.ak.mind.de|Acme-CPANAuthors-French|0.07|x86_64-linux|5.10.0|linux|2.6.24-1-amd64|200901011038|2},
    q{2967647|02967647-b19f-3f77-b713-d32bba55d77f|pass|200901|imacat@mail.imacat.idv.tw|Acme-Anything|0.02|x86_64-linux-thread-multi-ld|5.10.0|linux|2.6.24-etchnhalf.1-amd64|200901011830|2},
    q{2969433|02969433-b19f-3f77-b713-d32bba55d77f|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|200901010115|2},
    q{2969661|02969661-b19f-3f77-b713-d32bba55d77f|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|200901010303|2},
    q{2969663|02969663-b19f-3f77-b713-d32bba55d77f|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.10.0|linux|2.6.24-19-generic|200901010303|2},
    q{2970367|02970367-b19f-3f77-b713-d32bba55d77f|pass|200901|CPAN.DCOLLINS@comcast.net|Abstract-Meta-Class|0.11|i686-linux-thread-multi|5.11.0 patch GitLive-blead-163-g28b1dae|linux|2.6.24-19-generic|200901010041|2},
    q{2975969|02975969-b19f-3f77-b713-d32bba55d77f|pass|200901|Ulrich Habel <rhaen@cpan.org>|Acme-CPANAuthors-Japanese|0.090101|MSWin32-x86-multi-thread|5.10.0|mswin32|5.1|200901021220|2},
);

my @TESTERS = (
    q{1,kriegjcb@mi.ruhr-uni-bochum.de ((Jost Krieger)),kriegjcb@mi.ruhr-uni-bochum.de,1,Jost Krieger,JOST},
    q{2,srezic@cpan.org,srezic@cpan.org,2,Slaven Rezi&#x0107;,SREZIC},
    q{3,jj@jonallen.info ("JJ"),jj@jonallen.info,3,Jon Allen,JONALLEN},
    q{4,bingos@cpan.org,bingos@cpan.org,4,Chris Williams,BINGOS},
);


#----------------------------------------------------------------------------
# Tests

eval "use Test::Database";
if($@)  { plan skip_all => "Test::Database required for DB testing"; }
else    { plan tests => 4; }

my $td;
if($td = Test::Database->handle( 'mysql' )) {
    create_mysql_databases($td);
} elsif($td = Test::Database->handle( 'SQLite' )) {
    create_sqlite_databases($td);
}

SKIP: {
    skip "No supported databases available", 4  unless($td);

    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %options = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    create_config(\%options);

#diag(Dumper(\%options));

    # create new instance from Test::Database object
    my $ct = CPAN::Testers::Common::DBUtils->new(%options);
    isa_ok($ct,'CPAN::Testers::Common::DBUtils');

    # insert records
    my $sql = 'INSERT INTO cpanstats ( id, guid, state, postdate, tester, dist, version, platform, perl, osname, osvers, fulldate, type) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)';
    for(@CPANSTATS) {
        $ct->do_query( $sql, split(/\|/,$_) );
    }

    for(@TESTERS) {
        my ($addressid,$address,$email,$testerid,$name,$pause) = split(',');
        #diag("addressid=$addressid, address=$address, email=$email, testerid=$testerid, name=$name, pause=$pause");
        $ct->do_query('INSERT INTO tester_address ( addressid, testerid, address, email ) VALUES (?,?,?,?)', $addressid, $testerid, $address, $email );
        $ct->do_query('INSERT INTO tester_profile ( testerid, name, pause ) VALUES (?,?,?)', $testerid, $name, $pause );
    }

    my @rows = $ct->get_query('hash','select count(*) as count from cpanstats');
    is($rows[0]->{count}, 33, "row count for cpanstats");

    my @rows1 = $ct->get_query('hash','select count(*) as count from tester_address');
    my @rows2 = $ct->get_query('hash','select count(*) as count from tester_profile');
    is($rows1[0]->{count}, 4, "row count - address");
    is($rows2[0]->{count}, 4, "row count - profile");
}

sub create_config {
    my $options = shift;

    # main config
    my $f = 't/_DBDIR/test-config.ini';
    unlink $f if -f $f;
    mkpath( dirname($f) );

    my $dbcfg = join("\n", map { "$_=$options->{$_}" } grep { $options->{$_}} qw(driver database dbfile dbhost dbport dbuser dbpass) );

    my $fh = IO::File->new($f,'w+') or return;
    print $fh <<PRINT;
[MASTER]
mailrc=t/data/01mailrc.txt
logfile=t/_DBDIR/cpanstats-address.log
logclean=0
lastfile=t/_DBDIR/lastid.txt


; database configuration

[CPANSTATS]
$dbcfg

[BACKUPS]
drivers=<<EOT
BOGUS
SQLite
CSV
EOT

[BOGUS]
driver=BOGUS
database=t/_DBDIR/address.bogus

[SQLite]
driver=SQLite
database=t/_DBDIR/address.db

[CSV]
driver=CSV
dbfile=t/_DBDIR/address.csv

PRINT

    $fh->close;

    # logging test config
    $f = 't/_DBDIR/50logging.ini';
    unlink $f if -f $f;

    $fh = IO::File->new($f,'w+') or return;
    print $fh <<PRINT;
[MASTER]
mailrc=t/data/01mailrc.txt
logfile=t/_DBDIR/50logging.log
lastfile=t/_DBDIR/lastid.txt

; database configuration

[CPANSTATS]
$dbcfg

PRINT

    $fh->close;
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_cpanstats = (
        'PRAGMA auto_vacuum = 1',
        'DROP TABLE IF EXISTS cpanstats',
        'CREATE TABLE cpanstats (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            guid        TEXT,
            state       TEXT,
            postdate    TEXT,
            tester      TEXT,
            dist        TEXT,
            version     TEXT,
            platform    TEXT,
            perl        TEXT,
            osname      TEXT,
            osvers      TEXT,
            fulldate    TEXT,
            type        INTEGER)',

        'CREATE INDEX distverstate ON cpanstats (dist, version, state)',
        'CREATE INDEX ixguid ON cpanstats (guid)',
        'CREATE INDEX ixperl ON cpanstats (perl)',
        'CREATE INDEX ixplat ON cpanstats (platform)',
        'CREATE INDEX ixdate ON cpanstats (postdate)',

        'DROP TABLE IF EXISTS ixaddress',
        'DROP TABLE IF EXISTS tester_address',
        'DROP TABLE IF EXISTS tester_profile',

        'CREATE TABLE ixaddress (
            id          INTEGER NOT NULL,
            guid        TEXT,
            addressid   INTEGER NOT NULL,
            fulldate    TEXT
        )',

        'CREATE TABLE tester_address (
            addressid   INTEGER PRIMARY KEY AUTOINCREMENT,
            testerid    INTEGER DEFAULT 0,
            address     text NOT NULL,
            email	    text DEFAULT NULL
        )',

        'CREATE TABLE tester_profile (
            testerid    INTEGER PRIMARY KEY AUTOINCREMENT,
            name	    text DEFAULT NULL,
            pause	    text DEFAULT NULL
        )',
    );

    dosql($db,\@create_cpanstats);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_cpanstats = (
        'DROP TABLE IF EXISTS cpanstats',

        q{CREATE TABLE `cpanstats` (
            `id`        int(10) unsigned    NOT NULL AUTO_INCREMENT,
            `guid`      varchar(64)         NOT NULL DEFAULT '',
            `state`     varchar(32)         DEFAULT NULL,
            `postdate`  varchar(8)          DEFAULT NULL,
            `tester`    varchar(255)        DEFAULT NULL,
            `dist`      varchar(255)        DEFAULT NULL,
            `version`   varchar(255)        DEFAULT NULL,
            `platform`  varchar(255)        DEFAULT NULL,
            `perl`      varchar(255)        DEFAULT NULL,
            `osname`    varchar(255)        DEFAULT NULL,
            `osvers`    varchar(255)        DEFAULT NULL,
            `fulldate`  varchar(32)         DEFAULT NULL,
            `type`      int(2)              DEFAULT '0',
            PRIMARY KEY (`id`)
        )},

        'CREATE INDEX distverstate ON cpanstats (dist, version, state)',
        'CREATE INDEX ixguid ON cpanstats (guid)',
        'CREATE INDEX ixperl ON cpanstats (perl)',
        'CREATE INDEX ixplat ON cpanstats (platform)',
        'CREATE INDEX ixdate ON cpanstats (postdate)',

        'DROP TABLE IF EXISTS ixaddress',
        'DROP TABLE IF EXISTS tester_address',
        'DROP TABLE IF EXISTS tester_profile',

        q{CREATE TABLE ixaddress (
            id          int(10) unsigned    NOT NULL,
            guid        varchar(40)         NOT NULL DEFAULT '',
            addressid   int(10) unsigned    NOT NULL,
            fulldate    varchar(32)         DEFAULT ''
        )},

        q{CREATE TABLE tester_address (
            addressid   int(10) unsigned    NOT NULL AUTO_INCREMENT,
            testerid    int(10) unsigned    DEFAULT 0,
            address     varchar(255)        NOT NULL,
            email	    varchar(255)        DEFAULT '',
            PRIMARY KEY (addressid)
        )},

        q{CREATE TABLE tester_profile (
            testerid    int(10) unsigned    NOT NULL AUTO_INCREMENT,
            name	    varchar(255)        DEFAULT '',
            pause	    varchar(255)        DEFAULT '',
            PRIMARY KEY (testerid)
        )},
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

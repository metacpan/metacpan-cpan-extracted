#!/usr/bin/perl -w
use strict;

#----------------------------------------------------------------------------
# Library Modules

use CPAN::Testers::Common::DBUtils;
use File::Path;
use Test::More;

#----------------------------------------------------------------------------
# Tests

mkpath( 't/_DBDIR' );

eval "use Test::Database";
if($@)  { plan skip_all => "Test::Database required for DB testing"; }
else    { plan tests    => 2 }

my $td;
if($td = Test::Database->handle( 'mysql' )) {
    create_mysql_databases($td);
} elsif($td = Test::Database->handle( 'SQLite' )) {
    create_sqlite_databases($td);
}

SKIP: {
    skip "No supported databases available", 2  unless($td);

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

    # create new instance from Test::Database object
    my $ct = CPAN::Testers::Common::DBUtils->new(%options);
    isa_ok($ct,'CPAN::Testers::Common::DBUtils');

    # insert records
    my $sql = 'INSERT INTO uploads (type,author,dist,version,filename,released) VALUES (?,?,?,?,?,?)';
    while(<DATA>){
        s/\s+$//;
        $ct->do_query( $sql, split(/\|/,$_) );
    }

    my @rows = $ct->get_query('hash','select count(*) as count from uploads');
    is($rows[0]->{count}, 63, "row count for uploads");
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
lastfile=t/_DBDIR/lastid.txt
BACKPAN=t/_DBDIR/BACKPAN/authors/id
CPAN=t/_DBDIR/CPAN/authors/id
journal=t/_DBDIR/journal.sql
logfile=t/_DBDIR/upload.log
logclean=1

; database configuration

[UPLOADS]
$dbcfg

[BACKUPS]
drivers=<<EOT
SQLite
CSV
EOT

[SQLite]
driver=SQLite
database=t/_DBDIR/uploads.db

[CSV]
driver=CSV
dbfile=t/_DBDIR/uploads.csv

PRINT

    $fh->close;
}

sub create_sqlite_databases {
    my $db = shift;

    my @create_cpanstats = (
        'PRAGMA auto_vacuum = 1',
	    'DROP TABLE IF EXISTS `uploads`',
        'CREATE TABLE `uploads` (
            `type`      text    NOT NULL,
            `author`    text    NOT NULL,
            `dist`      text    NOT NULL,
            `version`   text    NOT NULL,
            `filename`  text    NOT NULL,
            `released`  int     NOT NULL,
            PRIMARY KEY  (`author`,`dist`,`version`)
        )',
	    'DROP TABLE IF EXISTS `uploads_failed`',
        'CREATE TABLE `uploads_failed` (
            `source`    text    NOT NULL,
            `type`      text,
            `dist`      text,
            `version`   text,
            `file`      text,
            `pause`     text,
            `created`   int,
            PRIMARY KEY  (`source`)
        )',
	    'DROP TABLE IF EXISTS `ixlatest`',
        'CREATE TABLE `ixlatest` (
            `dist`      text    NOT NULL,
            `version`   text    NOT NULL,
            `released`  int     NOT NULL,
            `author`    text    NOT NULL,
            `oncpan`    int     DEFAULT 0,
            PRIMARY KEY (`dist`,`author`)
        )',
	    'DROP TABLE IF EXISTS `page_requests`',
        'CREATE TABLE `page_requests` (
            `type`      text        NOT NULL,
            `name`      text        NOT NULL,
            `weight`    int         NOT NULL,
            `created`   timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `id`        int         DEFAULT 0
        )'
    );

    dosql($db,\@create_cpanstats);
}

sub create_mysql_databases {
    my $db = shift;

    my @create_cpanstats = (
	    'DROP TABLE IF EXISTS `uploads`',
        'CREATE TABLE `uploads` (
            `type`      varchar(10)         NOT NULL,
            `author`    varchar(32)         NOT NULL,
            `dist`      varchar(255)        NOT NULL,
            `version`   varchar(255)        NOT NULL,
            `filename`  varchar(255)        NOT NULL,
            `released`  int(16)             NOT NULL,
            PRIMARY KEY (`author`,`dist`,`version`)
        )',
	    'DROP TABLE IF EXISTS `uploads_failed`',
        'CREATE TABLE `uploads_failed` (
            `source`    varchar(255)        NOT NULL,
            `type`      varchar(255)        DEFAULT NULL,
            `dist`      varchar(255)        DEFAULT NULL,
            `version`   varchar(255)        DEFAULT NULL,
            `file`      varchar(255)        DEFAULT NULL,
            `pause`     varchar(255)        DEFAULT NULL,
            `created`   int(11) unsigned    DEFAULT NULL,
            PRIMARY KEY (`source`)
        )',
	    'DROP TABLE IF EXISTS `ixlatest`',
        'CREATE TABLE `ixlatest` (
            `dist`      varchar(255)        NOT NULL,
            `version`   varchar(255)        NOT NULL,
            `released`  int(16)             NOT NULL,
            `author`    varchar(32)         NOT NULL,
            `oncpan`    tinyint(4)          DEFAULT 0,
            PRIMARY KEY (`dist`,`author`),
            KEY `IXDISTX` (`dist`),
            KEY `IXAUTHX` (`author`)
        )',
	    'DROP TABLE IF EXISTS `page_requests`',
        'CREATE TABLE `page_requests` (
            `type`      varchar(8)          NOT NULL,
            `name`      varchar(255)        NOT NULL,
            `weight`    int(2) unsigned     NOT NULL,
            `created`   timestamp           NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `id`        int(10) unsigned    DEFAULT 0,
            KEY `IXNAME` (`name`),
            KEY `IXTYPE` (`type`),
            KEY `IXID` (`id`)
        )'
    
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


#select * from uploads where dist in ('AEAE', 'AI-NeuralNet-BackProp', 'AI-NeuralNet-Mesh', 'AI-NeuralNet-SOM', 'AOL-TOC', 'Abstract-Meta-Class', 'Acme', 'Acme-Anything', 'Acme-BOPE', 'Acme-Brainfuck', 'Acme-Buffy', 'Acme-CPANAuthors-Canadian', 'Acme-CPANAuthors-CodeRepos', 'Acme-CPANAuthors-French', 'Acme-CPANAuthors-Japanese');
#type|author|dist|version|filename|released
__DATA__
cpan|LBROCARD|Acme-Buffy|1.3|Acme-Buffy-1.3.tar.gz|1017236268
cpan|LBROCARD|Acme-Buffy|1.5|Acme-Buffy-1.5.tar.gz|1177769034
cpan|LBROCARD|Acme-Buffy|1.4|Acme-Buffy-1.4.tar.gz|1157733085
backpan|LBROCARD|Acme-Buffy|1.1|Acme-Buffy-1.1.tar.gz|990548103
backpan|LBROCARD|Acme-Buffy|1.2|Acme-Buffy-1.2.tar.gz|997617194
cpan|DRRHO|AI-NeuralNet-SOM|0.04|AI-NeuralNet-SOM-0.04.tar.gz|1182080003
cpan|DRRHO|AI-NeuralNet-SOM|0.06|AI-NeuralNet-SOM-0.06.tar.gz|1211531083
cpan|DRRHO|AI-NeuralNet-SOM|0.05|AI-NeuralNet-SOM-0.05.tar.gz|1200513667
cpan|DRRHO|AI-NeuralNet-SOM|0.01|AI-NeuralNet-SOM-0.01.tar.gz|1181057025
cpan|DRRHO|AI-NeuralNet-SOM|0.03|AI-NeuralNet-SOM-0.03.tar.gz|1181848391
cpan|DRRHO|AI-NeuralNet-SOM|0.07|AI-NeuralNet-SOM-0.07.tar.gz|1211612835
cpan|DRRHO|AI-NeuralNet-SOM|0.02|AI-NeuralNet-SOM-0.02.tar.gz|1181487612
cpan|VOISCHEV|AI-NeuralNet-SOM|0.01|AI-NeuralNet-SOM-0.01.tar.gz|970252633
cpan|VOISCHEV|AI-NeuralNet-SOM|0.02|AI-NeuralNet-SOM-0.02.tar.gz|970684892
cpan|INGY|Acme|1.11111|Acme-1.11111.tar.gz|1137626100
backpan|INGY|Acme|1.111|Acme-1.111.tar.gz|1079905156
backpan|INGY|Acme|1.11|Acme-1.11.tar.gz|1079870865
backpan|INGY|Acme|1.00|Acme-1.00.tar.gz|1079868743
backpan|INGY|Acme|1.1111|Acme-1.1111.tar.gz|1111906013
cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.071226|Acme-CPANAuthors-Japanese-0.071226.tar.gz|1198658704
cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.080522|Acme-CPANAuthors-Japanese-0.080522.tar.gz|1211389830
cpan|ISHIGAKI|Acme-CPANAuthors-CodeRepos|0.080522|Acme-CPANAuthors-CodeRepos-0.080522.tar.gz|1211390902
cpan|SAPER|Acme-CPANAuthors-French|0.04|Acme-CPANAuthors-French-0.04.tar.gz|1221955693
backpan|SAPER|Acme-CPANAuthors-French|0.01|Acme-CPANAuthors-French-0.01.tar.gz|1221268256
cpan|SAPER|Acme-CPANAuthors-French|0.05|Acme-CPANAuthors-French-0.05.tar.gz|1222119306
backpan|SAPER|Acme-CPANAuthors-French|0.02|Acme-CPANAuthors-French-0.02.tar.gz|1221355420
backpan|SAPER|Acme-CPANAuthors-French|0.03|Acme-CPANAuthors-French-0.03.tar.gz|1221696260
cpan|SAPER|Acme-CPANAuthors-French|0.06|Acme-CPANAuthors-French-0.06.tar.gz|1225315698
upload|SAPER|Acme-CPANAuthors-French|0.07|Acme-CPANAuthors-French-0.07.tar.gz|1225662681
upload|ZOFFIX|Acme-CPANAuthors-Canadian|0.0101|Acme-CPANAuthors-Canadian-0.0101.tar.gz|1225664601
cpan|GARU|Acme-BOPE|0.01|Acme-BOPE-0.01.tar.gz|1222060546
backpan|JESSE|Acme-Buffy|1.3|Acme-Buffy-1.3.tar.gz|1065349193
cpan|JETEVE|AEAE|0.02|AEAE-0.02.tar.gz|1139566791
cpan|JETEVE|AEAE|0.01|AEAE-0.01.tar.gz|1138724959
backpan|JJORE|Acme-Anything|0.01|Acme-Anything-0.01.tar.gz|1186005823
cpan|JJORE|Acme-Anything|0.02|Acme-Anything-0.02.tar.gz|1194827066
cpan|JBRYAN|AI-NeuralNet-Mesh|0.43|AI-NeuralNet-Mesh-0.43.zip|968921615
cpan|JBRYAN|AI-NeuralNet-BackProp|0.40|AI-NeuralNet-BackProp-0.40.zip|964250318
cpan|JBRYAN|AI-NeuralNet-Mesh|0.31|AI-NeuralNet-Mesh-0.31.zip|967191936
cpan|JBRYAN|AI-NeuralNet-BackProp|0.77|AI-NeuralNet-BackProp-0.77.zip|966067868
cpan|JBRYAN|AI-NeuralNet-BackProp|0.42|AI-NeuralNet-BackProp-0.42.zip|964604318
cpan|JBRYAN|AI-NeuralNet-Mesh|0.44|AI-NeuralNet-Mesh-0.44.zip|968964981
cpan|JBRYAN|AI-NeuralNet-BackProp|0.89|AI-NeuralNet-BackProp-0.89.zip|966496907
cpan|JBRYAN|AI-NeuralNet-Mesh|0.20|AI-NeuralNet-Mesh-0.20.zip|967009309
backpan|JALDHAR|Acme-Brainfuck|1.1.0|Acme-Brainfuck-1.1.0.tar.gz|1081229428
cpan|JALDHAR|Acme-Brainfuck|1.1.1|Acme-Brainfuck-1.1.1.tar.gz|1081268735
backpan|JALDHAR|Acme-Brainfuck|1.0.0|Acme-Brainfuck-1.0.0.tar.gz|1031080554
cpan|JHARDING|AOL-TOC|0.32|AOL-TOC-0.32.tar.gz|962207388
cpan|JHARDING|AOL-TOC|0.340|AOL-TOC-0.340.tar.gz|966917420
cpan|JHARDING|AOL-TOC|0.33|AOL-TOC-0.33.tar.gz|962694743
cpan|ADRIANWIT|Abstract-Meta-Class|0.09|Abstract-Meta-Class-0.09.tar.gz|1212364076
backpan|ADRIANWIT|Abstract-Meta-Class|0.07|Abstract-Meta-Class-0.07.tar.gz|1212267288
backpan|ADRIANWIT|Abstract-Meta-Class|0.04|Abstract-Meta-Class-0.04.tar.gz|1211589222
cpan|ADRIANWIT|Abstract-Meta-Class|0.08|Abstract-Meta-Class-0.08.tar.gz|1212345949
backpan|ADRIANWIT|Abstract-Meta-Class|0.01|Abstract-Meta-Class-0.01.tar.gz|1210001395
backpan|ADRIANWIT|Abstract-Meta-Class|0.05|Abstract-Meta-Class-0.05.tar.gz|1211645127
cpan|ADRIANWIT|Abstract-Meta-Class|0.10|Abstract-Meta-Class-0.10.tar.gz|1212962154
cpan|ADRIANWIT|Abstract-Meta-Class|0.12|Abstract-Meta-Class-0.12.tar.gz|1224423414
cpan|ADRIANWIT|Abstract-Meta-Class|0.11|Abstract-Meta-Class-0.11.tar.gz|1220826243
backpan|ADRIANWIT|Abstract-Meta-Class|0.03|Abstract-Meta-Class-0.03.tar.gz|1210105676
backpan|ADRIANWIT|Abstract-Meta-Class|0.06|Abstract-Meta-Class-0.06.tar.gz|1211732184
upload|ADRIANWIT|Abstract-Meta-Class|0.13|Abstract-Meta-Class-0.13.tar.gz|1227483540
cpan|ISHIGAKI|Acme-CPANAuthors-Japanese|0.090101|Acme-CPANAuthors-Japanese-0.090101.tar.gz|1230748955

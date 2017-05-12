#!/usr/bin/perl -w
use strict;

#----------------------------------------------------------------------------
# Libraries

use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use File::Path;
use IO::File;
use JSON;
use Test::More;

use lib qw(t/lib);
use Fake::Loader;

#----------------------------------------------------------------------------
# Test Variables

my $TESTS       = 3;
my $config      = 't/_DBDIR/test-config.ini';

#----------------------------------------------------------------------------
# Tests

# prep test directory
my $directory = 't/_DBDIR';
rmtree($directory);
mkpath($directory) or die "cannot create directory";

eval "use Test::Database";
if($@)  { plan skip_all => "Test::Database required for DB testing"; }
else    { plan tests    => $TESTS }

my ($td1,$td2);
if($td1 = Test::Database->handle( 'mysql' )) {
    $td2 = Test::Database->handle( 'mysql' );
    create_mysql_databases($td1,$td2);
}

SKIP: {
    skip "No supported databases available", $TESTS  unless($td1);

    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td1->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %cpanstats = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    %opts = ();
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $td2->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %metabase = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    create_config(\%cpanstats,\%metabase);

    ok(-f $config);

    my $loader = Fake::Loader->new();

    SKIP: {
        skip "Cannot create access to fake databases", 2 unless($loader);

        $loader->create_uploads();
        $loader->create_cpanstats();
        $loader->create_metabase();

        is($loader->count_cpanstats(),5,'.. test cpanstats table loaded');
        is($loader->count_metabase(),5,'.. test metabase table loaded');
    }
}

sub create_config {
    my ($cpanstats,$metabase) = @_;

    # main config
    unlink $config if -f $config;

    my $dbcfg1 = join("\n", map { "$_=$cpanstats->{$_}" } grep { $cpanstats->{$_}} qw(driver database dbfile dbhost dbport dbuser dbpass) );
    my $dbcfg2 = join("\n", map { "$_=$metabase->{$_}"  } grep { $metabase->{$_} } qw(driver database dbfile dbhost dbport dbuser dbpass) );

    my $fh = IO::File->new($config,'w+') or return;
    print $fh <<PRINT;
[MAIN]
logfile=./test/cpanstats.log
poll_limit=1

aws_bucket=cpantesters
aws_namespace=beta6


; database configuration

[CPANSTATS]
$dbcfg1

[METABASE]
$dbcfg2

[ADMINISTRATION]
admins=<<LIST
barbie\@example.com
LIST

PRINT

    $fh->close;
}

#----------------------------------------------------------------------------
# Test Data

sub create_mysql_databases {
    my ($db1,$db2) = @_;

    my @create_mysql = (
            'DROP TABLE IF EXISTS cpanstats',
            'CREATE TABLE cpanstats (
                id         int(10) unsigned NOT NULL AUTO_INCREMENT,
                type       tinyint(4) default 0,
                guid       char(36),
                state      varchar(32),
                postdate   varchar(8),
                tester     varchar(255),
                dist       varchar(255),
                version    varchar(255),
                platform   varchar(255),
                perl       varchar(255),
                osname     varchar(255),
                osvers     varchar(255),
                fulldate   varchar(32),
                uploadid    int(10) unsigned NOT NULL,
                PRIMARY KEY (id))',

            'DROP TABLE IF EXISTS page_requests',
            'CREATE TABLE page_requests (
                type        varchar(8)   NOT NULL,
                name        varchar(255) NOT NULL,
                weight      int(2)  unsigned NOT NULL,
                id          int(10) unsigned default 0
            )',

            'DROP TABLE IF EXISTS release_data',
            'CREATE TABLE release_data (
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
                uploadid    int(10) unsigned NOT NULL,
                PRIMARY KEY (id,guid),
                INDEX (dist,version)
            )',

            'DROP TABLE IF EXISTS release_summary',
            'CREATE TABLE release_summary (
                dist        varchar(255) NOT NULL,
                version     varchar(255) NOT NULL,
                id          int(10) unsigned NOT NULL,
                oncpan      tinyint(4) default 0,
                distmat     tinyint(4) default 0,
                perlmat     tinyint(4) default 0,
                patched     tinyint(4) default 0,
                pass        int(10)    default 0,
                fail        int(10)    default 0,
                na          int(10)    default 0,
                unknown     int(10)    default 0,
                uploadid    int(10) unsigned NOT NULL
            )',

            'DROP TABLE IF EXISTS uploads',
            'CREATE TABLE uploads (
                uploadid    int(10) unsigned NOT NULL auto_increment,
                type        varchar(10)  NOT NULL,
                author      varchar(32)  NOT NULL,
                dist        varchar(100) NOT NULL,
                version     varchar(100) NOT NULL,
                filename    varchar(255) NOT NULL,
                released    int(16)	     NOT NULL,
                PRIMARY KEY (uploadid)
            )',

            'DROP TABLE IF EXISTS ixlatest',
            'CREATE TABLE ixlatest (
                dist        varchar(100) NOT NULL,
                version     varchar(100) NOT NULL,
                released    int(16)		 NOT NULL,
                author      varchar(32)  NOT NULL,
                uploadid    int(10) unsigned NOT NULL,
                PRIMARY KEY (dist)
            )',

            'DROP TABLE IF EXISTS osname',
            'CREATE TABLE osname (
                id          int(10) unsigned NOT NULL auto_increment,
                osname      varchar(255) NOT NULL,
                ostitle     varchar(255) NOT NULL,
                PRIMARY KEY (id)
            )',

            "INSERT INTO osname VALUES (1,'aix','AIX')",
            "INSERT INTO osname VALUES (2,'bsdos','BSD/OS')",
            "INSERT INTO osname VALUES (3,'cygwin','Windows(Cygwin)')",
            "INSERT INTO osname VALUES (4,'darwin','MacOSX')",
            "INSERT INTO osname VALUES (5,'dec_osf','Tru64')",
            "INSERT INTO osname VALUES (6,'dragonfly','DragonflyBSD')",
            "INSERT INTO osname VALUES (7,'freebsd','FreeBSD')",
            "INSERT INTO osname VALUES (8,'gnu','GNUHurd')",
            "INSERT INTO osname VALUES (9,'haiku','Haiku')",
            "INSERT INTO osname VALUES (10,'hpux','HP-UX')",
            "INSERT INTO osname VALUES (11,'irix','IRIX')",
            "INSERT INTO osname VALUES (12,'linux','Linux')",
            "INSERT INTO osname VALUES (13,'macos','MacOSclassic')",
            "INSERT INTO osname VALUES (14,'midnightbsd','MidnightBSD')",
            "INSERT INTO osname VALUES (15,'mirbsd','MirOSBSD')",
            "INSERT INTO osname VALUES (16,'mswin32','Windows(Win32)')",
            "INSERT INTO osname VALUES (17,'netbsd','NetBSD')",
            "INSERT INTO osname VALUES (18,'openbsd','OpenBSD')",
            "INSERT INTO osname VALUES (19,'os2','OS/2')",
            "INSERT INTO osname VALUES (20,'os390','OS390/zOS')",
            "INSERT INTO osname VALUES (21,'osf','OSF')",
            "INSERT INTO osname VALUES (22,'sco','SCO')",
            "INSERT INTO osname VALUES (24,'vms','VMS')",
            "INSERT INTO osname VALUES (23,'solaris','SunOS/Solaris')",
            "INSERT INTO osname VALUES (25,'beos','BeOS')",

            'DROP TABLE IF EXISTS perl_version',
            'CREATE TABLE perl_version (
              version	    varchar(255) default NULL,
              perl	        varchar(32)  default NULL,
              patch	        tinyint(1)   default 0,
              devel	        tinyint(1)   default 0,
              PRIMARY KEY  (version)
            )',

            "INSERT INTO perl_version VALUES ('5.10.0','5.10.0',0,0)",
            "INSERT INTO perl_version VALUES ('5.11.0','5.11.0',0,1)",
            "INSERT INTO perl_version VALUES ('v5.10.0','5.10.0',0,0)",
            "INSERT INTO perl_version VALUES ('5.12.0 RC1','5.12.0',1,0)",

        'DROP TABLE IF EXISTS passreports',
        'CREATE TABLE passreports (
            platform   varchar(255),
            osname     varchar(255),
            perl       varchar(255),
            postdate   varchar(8),
            dist       varchar(255),
            KEY PLATFORMIX (platform),
            KEY OSNAMEIX (osname),
            KEY PERLIX (perl),
            KEY DATEIX (postdate)
        )',
    );

    my @create_meta_mysql = (
            'DROP TABLE IF EXISTS metabase',
            'CREATE TABLE metabase (
                id          int(10) unsigned NOT NULL,
                guid        char(36) NOT NULL,
                updated     varchar(32) default NULL,
                report      longblob NOT NULL,
                fact        longblob NOT NULL,
                PRIMARY KEY (id),
                INDEX guid (guid)
            )',

            'DROP TABLE IF EXISTS `testers_email`',
            'CREATE TABLE `testers_email` (
              id            int(10) unsigned NOT NULL auto_increment,
              resource      varchar(64) NOT NULL,
              fullname      varchar(255) NOT NULL,
              email         varchar(255) default NULL,
              PRIMARY KEY  (id),
              KEY resource (resource)
            )'
    );

    dosql($db1,\@create_mysql);
    dosql($db2,\@create_meta_mysql);
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

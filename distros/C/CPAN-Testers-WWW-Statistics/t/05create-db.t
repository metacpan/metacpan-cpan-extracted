#!/usr/bin/perl -w
use strict;

#----------------------------------------------------------------------------
# Libraries

use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use File::Path;
use JSON;
use Test::More;

use lib qw(t/lib);
use Fake::Loader;

#----------------------------------------------------------------------------
# Test Variables

my $TESTS       = 3;
my $config      = 't/_DBDIR/test-config.ini';
my $dbconfig    = 't/_DBDIR/databases.ini';

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
    my %testers = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    create_config(\%cpanstats,\%testers);

    ok(-f $config);

    my $loader = Fake::Loader->new();

    SKIP: {
        skip "Cannot create access to fake databases", 2 unless($loader);

        $loader->create_cpanstats();
        $loader->create_testers();

        is($loader->count_cpanstats_table('cpanstats'), 33,'.. test cpanstats.cpanstats table loaded');
        is($loader->count_testers_table('profile'),     9 ,'.. test testers.profile table loaded');
    }
}

sub create_config {
    my ($cpanstats,$testers) = @_;

    # main config
    unlink $config if -f $config;

    my $dbcfg1 = join("\n", map { "$_=$cpanstats->{$_}" } grep { $cpanstats->{$_} } qw(driver database dbfile dbhost dbport dbuser dbpass) );
    my $dbcfg2 = join("\n", map { "$_=$testers->{$_}"   } grep { $testers->{$_}   } qw(driver database dbfile dbhost dbport dbuser dbpass) );

    my $fh = IO::File->new($config,'w+') or return;
    print $fh <<PRINT;
[MASTER]
mainstore=t/_TMPDIR/storage/cpanstats-%s.json

address=t/data/addresses.txt
templates=templates
builder=t/_TMPDIR/log-parser.txt
missing=t/data/missing-in-action.txt
mailrc=t/data/01mailrc.txt

#logfile=t/_TMPDIR/cpanstats-test.log
#logclean=0

dir_cpan=lib
dir_backpan=lib
dir_reports=lib

directory=t/_TMPDIR/cpanstats

copyright=&#169; 1999-2014 CPAN Testers.

; database configuration

[CPANSTATS]
$dbcfg1

[TESTERS]
$dbcfg2

; Files to copy into live site directory

[TOCOPY]
LIST=<<HERE
cgi-bin/cpanmail.cgi
cgi-bin/cpanmail.ini
cgi-bin/uploads.cgi
cgi-bin/uploads.html
cgi-bin/uploads.sh
favicon.ico
css/layout-min.css
css/layout-setup.css
css/layout-setup-min.css
css/layout-text.css
css/layout-text-min.css
css/layout-wide.css
css/layout-wide-min.css
js/iheart.js
js/sorttable.js
HERE

[TOLINK]
cgi-bin/response.html=response.html

; Date Ranges for graphs

[TEST_RANGES]
LIST=<<HERE
199901-200412
200301-200712
200601-201012
200901-201312
201201-201612
HERE

[CPAN_RANGES]
LIST=<<HERE
199501-199812
199901-200412
200301-200712
200601-201012
200901-201312
201201-201612
HERE


; List of Distributions to ignore the No Reports list

[NOREPORTS]
list=<<HERE
perl                    # the perl binary
sqlperl                 # special perl binary release
perl[-_].*              # special perl binary release
perl542b                # special perl binary release
dbgui.*                 # application
.*\.(pl|gz|tar|pm)      # source/package files
.*-bin-.*               # binary release
-withoutworldwriteables # broken name parser
manish-total-scripts    # ?
manish-db               # ?
OS2-ExtAttr             # now in CORE
OS2-PrfDB               # now in CORE
perltk.*                # see Tk distribution
TdP                     # not indexed - script/program
5foldCV                 # not indexed - script/program
Prolog-alpha            # not indexed - script/program
cshar                   # C library distribution!
apache.authnetldap      # repackaged as Apache-AuthNetLDAP
apache.authznetldap     # repackaged as Apache-AuthzNetLDAP
vms-queue               # repackaged as VMS-Queue
vms-device              # repackaged as VMS-Device
vms-librarian           # repackaged as VMS-Librarian
perlpalmdoc.*           # special perl binary release
bundle-parrot           # bundle module (badly packaged) - Bundle::Parrot
scripts-perl            # Perl scripts
app-xlstar-1            # Perl scripts
examples                # data files
dvb-t                   # data files
MPI                     # repackaged as Language-MPI
finance-yahooquote      # repackaged as Finance-YahooQuote
jeffrey.perl            # Perl scripts
makeManPg               # Perl scripts
wxkeyring               # Perl scripts
Wiimote                 # repackaged as Linux-Input-Wiimote
HERE
PRINT

    $fh->close;

    $fh = IO::File->new($dbconfig,'w+') or return;
    print $fh <<PRINT;
; database configuration

[CPANSTATS]
$dbcfg1

[TESTERS]
$dbcfg2
PRINT

    $fh->close;
}

#----------------------------------------------------------------------------
# Test Data

sub create_mysql_databases {
    my ($db1,$db2) = @_;

    my @create_cpanstats = (
        'DROP TABLE IF EXISTS cpanstats',
        'CREATE TABLE cpanstats (
            id         int(10) unsigned NOT NULL,
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
            PRIMARY KEY (id))',

        'DROP TABLE IF EXISTS ixlatest',
        'CREATE TABLE ixlatest (
            dist        varchar(100) NOT NULL,
            version     varchar(100) NOT NULL,
            released    int(16)		 NOT NULL,
            author      varchar(32)  NOT NULL,
            oncpan      tinyint(4)   DEFAULT 0,
            PRIMARY KEY (dist)
        )',

        'DROP TABLE IF EXISTS leaderboard',
        'CREATE TABLE leaderboard (
            postdate    varchar(8)      NOT NULL,
            osname      varchar(255)    NOT NULL,
            tester      varchar(255)    NOT NULL,  
            score       int(10)         DEFAULT 0,
            testerid    int(10) unsigned NOT NULL DEFAULT 0,
            addressid   int(10) unsigned NOT NULL DEFAULT 0,
            PRIMARY KEY (postdate,osname,tester),
            KEY IXOS   (osname),
            KEY IXTEST (tester),
            KEY IXPROFILE (testerid),
            KEY IXADDRESS (addressid)
        )',

        'DROP TABLE IF EXISTS noreports',
        'CREATE TABLE noreports (
             dist       varchar(255),
             version    varchar(255),
             osname     varchar(255),
             KEY NRIX (dist,version,osname),
             KEY OSIX (osname)
        )',

        'DROP TABLE IF EXISTS osname',
        'CREATE TABLE osname (
            id          int(10) unsigned    NOT NULL auto_increment,
            osname      varchar(255)        NOT NULL,
            ostitle     varchar(255)        NOT NULL,
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

        'DROP TABLE IF EXISTS release_summary',
        'CREATE TABLE release_summary (
            dist    varchar(255) NOT NULL,
            version varchar(255) NOT NULL,
            id      int(10) unsigned NOT NULL,
            guid    char(36) NOT NULL,
            oncpan  tinyint(4) DEFAULT 0,
            distmat tinyint(4) DEFAULT 0,
            perlmat tinyint(4) DEFAULT 0,
            patched tinyint(4) DEFAULT 0,
            pass    int(10) DEFAULT 0,
            fail    int(10) DEFAULT 0,
            na      int(10) DEFAULT 0,
            unknown int(10) DEFAULT 0,
            KEY dist (dist,version),
            KEY ident (id,guid),
            KEY summary (dist,version,oncpan,distmat,perlmat,patched),
            KEY maturity (perlmat)
        )',

        'DROP TABLE IF EXISTS uploads',
        'CREATE TABLE uploads (
            type        varchar(10)  NOT NULL,
            author      varchar(32)  NOT NULL,
            dist        varchar(100) NOT NULL,
            version     varchar(100) NOT NULL,
            filename    varchar(255) NOT NULL,
            released    int(16)	     NOT NULL,
            PRIMARY KEY (author,dist,version)
        )',

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

    my @create_testers = (
        'DROP TABLE IF EXISTS address',
        'CREATE TABLE address (
          addressid     int(10) unsigned    NOT NULL AUTO_INCREMENT,
          testerid      int(10) unsigned    NOT NULL DEFAULT 0,
          address       varchar(255)        NOT NULL,
          email         varchar(255)        DEFAULT NULL,
          PRIMARY KEY (addressid),
          KEY IXTESTER (testerid),
          KEY IXADDRESS (address)
        )',

        'DROP TABLE IF EXISTS ixreport',
        'CREATE TABLE ixreport (
          id            int(10) unsigned    NOT NULL,
          guid          varchar(40)         NOT NULL DEFAULT "",
          addressid     int(10) unsigned    NOT NULL,
          fulldate      varchar(32)         DEFAULT NULL,
          PRIMARY KEY (id,guid),
          KEY IXGUID (guid),
          KEY IXADDR (addressid)
        )',

        'DROP TABLE IF EXISTS profile',
        'CREATE TABLE profile (
          testerid      int(10) unsigned    NOT NULL AUTO_INCREMENT,
          name          varchar(255)        DEFAULT NULL,
          pause         varchar(255)        DEFAULT NULL,
          PRIMARY KEY (testerid),
          KEY IXNAME (name),
          KEY IXPAUSE (pause)
        )',
    );

    dosql($db1,\@create_cpanstats);
    dosql($db2,\@create_testers);
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

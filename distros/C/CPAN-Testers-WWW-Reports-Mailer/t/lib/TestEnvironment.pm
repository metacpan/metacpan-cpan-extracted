package TestEnvironment;

use strict;
use warnings;

#----------------------------------------------------------------------------
# Libraries

use Config::IniFiles;
use CPAN::Testers::Common::DBUtils;
use File::Path;
use File::Slurp;
use IO::File;

#----------------------------------------------------------------------------
# Variables

my %tables = (
    'cpanstats'             => { db => 'cpanstats', sql => 'INSERT INTO cpanstats ( id,guid,state,postdate,tester,dist,version,platform,perl,osname,osvers,fulldate ) VALUES ( ?,?,?,?,?,?,?,?,?,?,?,? )' },
    'uploads'               => { db => 'cpanstats', sql => 'INSERT INTO uploads ( type,author,dist,version,filename,released ) VALUES ( ?,?,?,?,?,? )' },
    'ixlatest'              => { db => 'cpanstats', sql => 'INSERT INTO ixlatest ( dist,version,released,author ) VALUES ( ?,?,?,? )' },
    
    'testers_email'         => { db => 'metabase',  sql => 'INSERT INTO testers_email ( id,resource,fullname,email ) VALUES ( ?,?,?,? )' },

    'articles'              => { db => 'articles',  sql => 'INSERT INTO articles ( id,article ) VALUES ( ?,? )' },

    'prefs_authors'         => { db => 'cpanprefs', sql => 'INSERT INTO prefs_authors ( pauseid,active,lastlogin ) VALUES ( ?,?,? )' },
    'prefs_distributions'   => { db => 'cpanprefs', sql => 'INSERT INTO prefs_distributions ( pauseid,distribution,ignored,report,grade,tuple,version,patches,perl,platform ) VALUES ( ?,?,?,?,?,?,?,?,?,? )' },
    
);

my ($testdb,%handles);
my $DBPATH  = 't/_DBDIR';
my $TMPPATH = 't/_TMPDIR';
my $CONFIG  = 't/_DBDIR/preferences.ini';
my $CONFIG2 = 't/_DBDIR/logging.ini';
my $CONFIG3 = 't/_DBDIR/preferences-daily.ini';
my $CONFIG4 = 't/_DBDIR/preferences-reports.ini';

#----------------------------------------------------------------------------
# Create Environment

sub Create {
    mkpath( $DBPATH );
    mkpath( $TMPPATH );

    eval "use Test::Database";
    return  if($@);

    #my @drivers1 = Test::Database->list_drivers();
    #my @drivers2 = Test::Database->list_drivers('available');
    #my @drivers3 = Test::Database->list_drivers('all');
    #print STDERR "# listed drivers = @drivers1\n";
    #print STDERR "# available drivers = @drivers2\n";
    #print STDERR "# all drivers = @drivers3\n";

    if( $testdb = Test::Database->handle( { dbd => 'mysql' } )) {
        create_mysql_databases();
        create_configs();
        return 1;
    }

    return 0;
}

sub Handles {
    return  unless(-f $CONFIG);

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $CONFIG );

    # configure databases
    for my $db (qw(CPANPREFS)) {
        die "No configuration for $db database\n"   unless($cfg->SectionExists($db));
        my %opts;
        for my $key (qw(driver database dbfile dbhost dbport dbuser dbpass)) {
            my $val = $cfg->val($db,$key);
            $opts{$key} = $val  if(defined $val);
        }
        $handles{$db} = CPAN::Testers::Common::DBUtils->new(%opts);
        die "Cannot configure $db database\n" unless($handles{$db});
    	$handles{$db}->{mysql_auto_reconnect} = 1	if($opts{driver} =~ /mysql/i);
    }

    return \%handles    if(keys %handles);
    return;
}

sub LoadData {
    my $prefix = shift;

    ResetAll();

    # load data into tables
    for my $table (keys %tables) {
        my $file = sprintf "t/data/%sdata-db-%s.txt", $prefix, $table;
        next    unless(-f $file);

        my $fh = IO::File->new($file) or next;
        while(<$fh>){
          s/\s+$//;
          next  unless($_);

          $handles{ CPANPREFS }->do_query( $tables{$table}->{sql}, split(/\|/,$_) );
        }
        $fh->close;
    }
}

sub ResetAll {
    my @sql = (
        "DELETE FROM cpanstats",
        "DELETE FROM page_requests",
        "DELETE FROM release_data",
        "DELETE FROM release_summary",
        "DELETE FROM ixlatest",
        "DELETE FROM uploads",
        "DELETE FROM articles",
        "DELETE FROM metabase",
        "DELETE FROM testers_email",
        "DELETE FROM prefs_authors",
        "DELETE FROM prefs_distributions"
    );
    dosql( \@sql );
}

sub ResetPrefs {
    my $data = shift;

    # reset databases
    my @sql = (
        "DELETE FROM prefs_authors",
        "DELETE FROM prefs_distributions"
    );
    dosql( \@sql );

    # load data into tables
    for(@$data){
        s/\s+$//;
        my ($type,@values) = split(/\|/,$_);
        my $table = $type eq 'auth' ? 'prefs_authors' : 'prefs_distributions';
        $handles{CPANPREFS}->do_query( $tables{$table}->{sql}, @values );
    }

    my @pa = $handles{CPANPREFS}->get_query('array','select count(*) from prefs_authors');
    my @pd = $handles{CPANPREFS}->get_query('array','select count(*) from prefs_distributions');

    return($pa[0]->[0],$pd[0]->[0]);
}

sub LoadArticles {
    my @articles = @_;

    for my $id (@articles) {
        my $text = read_file('t/samples/'.$id);
        $handles{CPANPREFS}->do_query('INSERT INTO articles ( id, article ) VALUES ( ?, ? )', $id, $text );
    }
}

#----------------------------------------------------------------------------
# Create Databases and Tables

sub create_mysql_databases {
    my $dbs = shift;

    my @create_cpanstats = (
            'DROP TABLE IF EXISTS cpanstats',
            'CREATE TABLE cpanstats (
                id         int(10) unsigned NOT NULL,
                type       tinyint(4) default 0,
                guid       varchar(64),
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
                unknown     int(10)    default 0
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

            'DROP TABLE IF EXISTS ixlatest',
            'CREATE TABLE ixlatest (
                dist        varchar(100) NOT NULL,
                version     varchar(100) NOT NULL,
                released    int(16)		 NOT NULL,
                author      varchar(32)  NOT NULL,
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
            "INSERT INTO perl_version VALUES ('5.12.0 RC1','5.12.0',1,0)"
    );

    my @create_metabase = (
            'DROP TABLE IF EXISTS metabase',
            'CREATE TABLE metabase (
                id          int(10) unsigned NOT NULL,
                guid        varchar(64) NOT NULL,
                updated     varchar(32) default NULL,
                report      longblob NOT NULL,
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

    my @create_articles = (
            'DROP TABLE IF EXISTS articles',
            'CREATE TABLE articles (
                id         int(10) unsigned NOT NULL,
                article    longblob
            )'
    );

    my @create_cpanprefs = (
            'DROP TABLE IF EXISTS `prefs_authors`',
            q{CREATE TABLE `prefs_authors` (
                pauseid     varchar(255) NOT NULL,
                active      int(2) DEFAULT '0',
                lastlogin   varchar(255) DEFAULT NULL,
                PRIMARY KEY (pauseid),
                KEY IXACTIVE (active)
            )},

            'DROP TABLE IF EXISTS prefs_distributions',
            q{CREATE TABLE prefs_distributions (
                pauseid         varchar(255) NOT NULL,
                distribution    varchar(255) NOT NULL,
                ignored         int(1)          DEFAULT '0',
                report          int(2)          DEFAULT '0',
                grade           varchar(32)     DEFAULT 'FAIL',
                tuple           varchar(32)     DEFAULT 'FIRST',
                version         varchar(1000)   DEFAULT 'LATEST',
                patches         int(1)          DEFAULT '0',
                perl            varchar(1000)   DEFAULT 'ALL',
                platform        varchar(1000)   DEFAULT 'ALL',
                PRIMARY KEY (pauseid,distribution),
                KEY IXDIST (distribution)
            )}
    );

    dosql( \@create_cpanstats );
    dosql( \@create_metabase  );
    dosql( \@create_articles  );
    dosql( \@create_cpanprefs );
}

sub dosql {
    my $sql = shift;

    if($testdb) {
        for(@$sql) {
            #diag "SQL: [$db] $_";
            eval { $testdb->dbh->do($_); };
            if($@) {
                #diag $@;
                return 1;
            }
        }
    } elsif($handles{CPANPREFS}) {
        for(@$sql) {
            #diag "SQL: [$db] $_";
            eval { $handles{CPANPREFS}->do_query($_); };
            if($@) {
                #diag $@;
                return 1;
            }
        }
    }

    return 0;
}

sub create_configs {
    # main config
    unlink $CONFIG if -f $CONFIG;
    
    my %opts;
    ($opts{dsn}, $opts{dbuser}, $opts{dbpass}) =  $testdb->connection_info();
    ($opts{driver})    = $opts{dsn} =~ /dbi:([^;:]+)/;
    ($opts{database})  = $opts{dsn} =~ /database=([^;]+)/;
    ($opts{database})  = $opts{dsn} =~ /dbname=([^;]+)/     unless($opts{database});
    ($opts{dbhost})    = $opts{dsn} =~ /host=([^;]+)/;
    ($opts{dbport})    = $opts{dsn} =~ /port=([^;]+)/;
    my %cpanprefs = map {my $v = $opts{$_}; defined($v) ? ($_ => $v) : () }
                        qw(driver database dbfile dbhost dbport dbuser dbpass);

    my $dbcfg = join("\n", map { "$_=$cpanprefs{$_}" } grep { $cpanprefs{$_}} qw(driver database dbfile dbhost dbport dbuser dbpass) );

    my $fh = IO::File->new($CONFIG,'w+') or return;
    print $fh <<PRINT;
[SETTINGS]
mailrc=t/data/01mailrc.txt
verbose=1
nomail=1
logfile=t/_TMPDIR/cpanreps.log
logclean=1

[CPANPREFS]
$dbcfg
PRINT

    $fh->close;

    $fh = IO::File->new($CONFIG2,'w+') or return;
    print $fh <<PRINT;
[SETTINGS]
mailrc=t/data/01mailrc.txt
verbose=1
nomail=1
logfile=t/_TMPDIR/logging.log

[CPANPREFS]
$dbcfg
PRINT

    $fh->close;

    $fh = IO::File->new($CONFIG3,'w+') or return;
    print $fh <<PRINT;
[SETTINGS]
mailrc=t/data/01mailrc.txt
debug=1
logfile=t/_TMPDIR/test-daily.log
logclean=1
mode=daily
lastmail=t/_TMPDIR/test-lastmail.txt
nomail=1

[CPANPREFS]
$dbcfg
PRINT

    $fh->close;

    $fh = IO::File->new($CONFIG4,'w+') or return;
    print $fh <<PRINT;
[SETTINGS]
mailrc=t/data/01mailrc.txt
debug=1
logfile=t/_TMPDIR/test-reports.log
logclean=1
mode=reports
lastmail=t/_TMPDIR/test-lastmail.txt

[CPANPREFS]
$dbcfg
PRINT

    $fh->close;
}

1;

#----------------------------------------------------------------------------
# Notes

#select * from cpanstats where state='cpan' and dist in ('AEAE', 'AI-NeuralNet-BackProp', 'AI-NeuralNet-Mesh', 'AI-NeuralNet-SOM', 'AOL-TOC', 'Abstract-Meta-Class', 'Acme', 'Acme-Anything', 'Acme-BOPE', 'Acme-Brainfuck', 'Acme-Buffy', 'Acme-CPANAuthors-Canadian', 'Acme-CPANAuthors-CodeRepos', 'Acme-CPANAuthors-French', 'Acme-CPANAuthors-Japanese');
# sqlite> select * from cpanstats where postdate=200901 order by dist limit 20;
# id|guid|state|postdate|tester|dist|version|platform|perl|osname|osvers|date

#select * from prefs_authors where pauseid in ('JHARDING','JBRYAN','VOISCHEV','LBROCARD','JALDHAR','JESSE','INGY','JETEVE','DRRHO','JJORE','ISHIGAKI','ADRIANWIT','SAPER','GARU','ZOFFIX');
#select * from prefs_distributions where pauseid in ('JHARDING','JBRYAN','VOISCHEV','LBROCARD','JALDHAR','JESSE','INGY','JETEVE','DRRHO','JJORE','ISHIGAKI','ADRIANWIT','SAPER','GARU','ZOFFIX');
# pauseid|active|lastlogin
# pauseid|distribution|ignored|report|grade|tuple|version|patches|perl|platform

#select * from uploads where dist in ('AEAE', 'AI-NeuralNet-BackProp', 'AI-NeuralNet-Mesh', 'AI-NeuralNet-SOM', 'AOL-TOC', 'Abstract-Meta-Class', 'Acme', 'Acme-Anything', 'Acme-BOPE', 'Acme-Brainfuck', 'Acme-Buffy', 'Acme-CPANAuthors-Canadian', 'Acme-CPANAuthors-CodeRepos', 'Acme-CPANAuthors-French', 'Acme-CPANAuthors-Japanese');
# type|author|dist|version|filename|released

#select * from ixlatest where author in ('LBROCARD', 'DRRHO', 'VOISCHEV', 'INGY', 'ISHIGAKI', 'SAPER', 'ZOFFIX', 'GARU', 'JESSE', 'JETEVE', 'JJORE', 'JBRYAN', 'JALDHAR', 'JHARDING', 'ADRIANWIT');
#dist|version|released|author

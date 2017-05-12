package CPAN::Testers::Data::Uploads;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.21';
$|++;

#----------------------------------------------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use CPAN::DistnameInfo;
use CPAN::Testers::Common::DBUtils;
use CPAN::Testers::Common::Article;
use Config::IniFiles;
use DBI;
use File::Basename;
use File::Find::Rule;
use File::Path;
use File::Slurp;
use Getopt::Long;
use IO::AtomicFile;
use IO::File;
use Net::NNTP;

#----------------------------------------------------------------------------
# Variables

my (%backups);
use constant    LASTMAIL    => '_lastmail';
use constant    LOGFILE     => '_uploads.log';
use constant    JOURNAL     => '_journal.sql';

my %phrasebook = (
    'FindAuthor'        => 'SELECT * FROM ixlatest WHERE author=?',

    'FindDistVersion'   => 'SELECT type FROM uploads WHERE author=? AND dist=? AND version=?',
    'InsertDistVersion' => 'INSERT INTO uploads (type,author,dist,version,filename,released) VALUES (?,?,?,?,?,?)',
    'UpdateDistVersion' => 'UPDATE uploads SET type=? WHERE author=? AND dist=? AND version=?',
    'FindDistTypes'     => 'SELECT * FROM uploads WHERE type=?',
    'DeleteAll'         => 'DELETE FROM uploads',
    'SelectAll'         => 'SELECT * FROM uploads',

    'DeleteAllIndex'    => 'DELETE FROM ixlatest',
    'DeleteIndex'       => 'DELETE FROM ixlatest WHERE dist=? AND author=?',
    'FindIndex'         => 'SELECT * FROM ixlatest WHERE dist=? AND author=?',
    'InsertIndex'       => 'INSERT INTO ixlatest (oncpan,author,version,released,dist) VALUES (?,?,?,?,?)',
    'AmendIndex'        => 'UPDATE ixlatest SET oncpan=? WHERE author=? AND version=? AND dist=?',
    'UpdateIndex'       => 'UPDATE ixlatest SET oncpan=?,version=?,released=? WHERE dist=? AND author=?',
    'BuildAuthorIndex'  => 'SELECT x.author,x.version,x.released,x.dist,x.type FROM (SELECT dist, MAX(released) AS mv FROM uploads WHERE author=? GROUP BY dist) AS y INNER JOIN uploads AS x ON x.dist=y.dist AND x.released=y.mv ORDER BY released',
    'GetAllAuthors'     => 'SELECT distinct(author) FROM uploads',

    'InsertRequest'     => 'INSERT INTO page_requests (type,name,weight) VALUES (?,?,5)',

    'ParseFailed'       => 'REPLACE INTO uploads_failed (source,type,dist,version,file,pause,created) VALUES (?,?,?,?,?,?,?)',

    # SQLite backup
    'CreateTable'       => 'CREATE TABLE uploads (type text, author text, dist text, version text, filename text, released int)',
);

my $extn = qr/\.(tar\.(gz|bz2)|tgz|zip)$/;

my %oncpan = (
    'backpan'   => 2,
    'cpan'      => 1,
    'upload'    => 1
);

#----------------------------------------------------------------------------
# The Application Programming Interface

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->_init_options(@_);
    return $self;
}

sub DESTROY {
    my $self = shift;
}

__PACKAGE__->mk_accessors(
    qw( uploads backpan cpan logfile logclean lastfile journal
        mgenerate mupdate mbackup mreindex ));

sub process {
    my $self = shift;
    $self->generate()       if($self->mgenerate);
    $self->reindex()        if($self->mreindex);
    $self->update()         if($self->mupdate);
    $self->backup()         if($self->mbackup);
}

sub generate {
    my $self = shift;
    my $db = $self->uploads;

    $self->_log("Restarting uploads database");
    $db->do_query($phrasebook{'DeleteAll'});

    $self->_log("Creating BACKPAN entries");
    my @files = File::Find::Rule->file()->name($extn)->in($self->backpan);
    $self->_parse_archive('backpan',$_)   for(@files);

    $self->_log("Creating CPAN entries");
    @files = File::Find::Rule->file()->name($extn)->in($self->cpan);
    $self->_parse_archive('cpan',$_)   for(@files);
}

sub reindex {
    my $self = shift;
    my $db = $self->uploads;

    $self->_log("Reindexing by author");

    my $next = $db->iterator('hash',$phrasebook{'GetAllAuthors'});
    while(my $author = $next->()) {
        $self->_log(".. author = $author->{author}");
        my @rows = $db->get_query('hash',$phrasebook{'BuildAuthorIndex'},$author->{author});
        for my $row (@rows) {
        $self->_log(".... dist = $row->{dist}, latest = $row->{version}");
            $db->do_query($phrasebook{'DeleteIndex'},$row->{dist},$row->{author});
            $db->do_query($phrasebook{'InsertIndex'},$oncpan{$row->{type}},$row->{author},$row->{version},$row->{released},$row->{dist});
        }
    }

    $self->_log("Reindexing authors done");
}

sub update {
    my $self = shift;
    my $db = $self->uploads;

    $self->_open_journal();

    # get list of db known CPAN distributions
    my @rows = $db->get_query('hash',$phrasebook{'FindDistTypes'},'cpan');
    my %cpan = map {$_->{filename} => $_} @rows;

    # get currently mirrored CPAN entries
    $self->_log("Updating CPAN entries");
    my @files = File::Find::Rule->file()->name($extn)->in($self->cpan);
    for(@files) {
        if(my $file = $self->_parse_archive('cpan',$_,1)) {
            delete $cpan{$file};
        } else {
            #$self->_log(".. cannot parse: $_");
        }
    }

    # demote any distributions no longer on CPAN
    $self->_log("Updating BACKPAN entries");
    for my $file (keys %cpan) {
        #$self->_log("backpan => $cpan{$file}->{dist} => $cpan{$file}->{version} => $cpan{$file}->{author} => $cpan{$file}->{released}");
        $self->_write_journal('UpdateDistVersion','backpan',$cpan{$file}->{author},$cpan{$file}->{dist},$cpan{$file}->{version});
        $db->do_query($phrasebook{'AmendIndex'},2,$cpan{$file}->{author},$cpan{$file}->{version},$cpan{$file}->{dist});
    }

    # read NNTP
    $self->_log("Updating NNTP entries");
    my ($nntp,$num,$first,$last) = $self->_nntp_connect();
    my $lastid = $self->_lastid();
    return    if($last <= $lastid);

    $self->_log(".. from $lastid to $last");
    for(my $id = $lastid+1; $id <= $last; $id++) {
        #$self->_log("NNTP ID = $id");
        my $article = join "", @{$nntp->article($id) || []};
        next    unless($article);
        my $object = CPAN::Testers::Common::Article->new($article);
        next    unless($object);
        $self->_log("... [$id] subject=".($object->subject()));

        my ($name,$version,$cpanid,$date,$filename);
        if($object->parse_upload()) {
            $name      = $object->distribution;
            $version   = $object->version;
            $cpanid    = $object->author;
            $date      = $object->epoch;
            $filename  = $object->filename;
        }

        #$self->_log("... name=$name");
        #$self->_log("... version=$version");
        #$self->_log("... cpanid=$cpanid");
        #$self->_log("... date=$date");

        next  unless($name && $version && $cpanid && $date);
        #$self->_log("upload => $name => $version => $cpanid => $date");

        $self->_update_index($cpanid,$version,$date,$name,1);
        my @rows = $db->get_query('array',$phrasebook{'FindDistVersion'},$cpanid,$name,$version);
        next    if(@rows);
        $self->_write_journal('InsertDistVersion','upload',$cpanid,$name,$version,$filename,$date);
    }

    $self->_lastid($last);
    $self->_close_journal();
}

sub backup {
    my $self = shift;
    my $db = $self->uploads;

    if(my @journals = $self->_find_journals()) {
        for my $driver (keys %backups) {
            if($driver =~ /(CSV|SQLite)/i && !$backups{$driver}{'exists'}) {
                $backups{$driver}{db}->do_query($phrasebook{'CreateTable'});
                $backups{$driver}{'exists'} = 1;
            }
        }
        
        for my $journal (@journals) {
            next    if($journal =~ /TMP$/); # don't process active journals
            $self->_log("Processing journal $journal");
            my $lines = $self->_read_journal($journal);
            for my $line (@$lines) {
                my ($phrase,@args) = @$line;
                for my $driver (keys %backups) {
                    $backups{$driver}{db}->do_query($phrasebook{$phrase},@args);
                }
            }

           $self->_done_journal($journal);
        }
        $self->_log("Processed journals");
    } else {
        for my $driver (keys %backups) {
            if($backups{$driver}{'exists'}) {
                $backups{$driver}{db}->do_query($phrasebook{'DeleteAll'});
            } elsif($driver =~ /(CSV|SQLite)/i) {
                $backups{$driver}{db}->do_query($phrasebook{'CreateTable'});
                $backups{$driver}{'exists'} = 1;
            }
        }

        $self->_log("Backup via DBD drivers");

        my $rows = $db->iterator('array',$phrasebook{'SelectAll'});
        while(my $row = $rows->()) {
            for my $driver (keys %backups) {
                $backups{$driver}{db}->do_query($phrasebook{'InsertDistVersion'},@$row);
            }
        }
    }

    # handle the CSV exception
    if($backups{CSV}) {
        $self->_log("Backup to CSV file");
        $backups{CSV}{db} = undef;  # close db handle
        my $fh1 = IO::File->new('uploads','r') or die "Cannot read temporary database file 'uploads'\n";
        my $fh2 = IO::File->new($backups{CSV}{dbfile},'w+') or die "Cannot write to CSV database file $backups{CSV}{dbfile}\n";
        while(<$fh1>) { print $fh2 $_ }
        $fh1->close;
        $fh2->close;
        unlink('uploads');
    }
}

sub help {
    my ($self,$full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print <<HERE;

Usage: $0 --config=<file> [-g] [-r] [-u] [-b] [-h] [-v]
        [--logfile=<file>] [--logclean] 
        [--lastmail=<file>] [--journal=<file>]

  --config=<file>   database configuration file
  -g                generate new database
  -r                reindex database (*)
  -u                update existing database
  -b                backup database to portable files
  -h                this help screen
  -v                program version
  --logfile=<file>  trace log file
  --logclean        overwrite exisiting log file
  --lastmail=<file> last id file
  --journal=<file>  SQL journal file path

Notes:
  * A generate request automatically includes a reindex.

HERE

    }

    print "$0 v$VERSION\n\n";
    exit(0);
}

#----------------------------------------------------------------------------
# Private Methods

sub _parse_archive {
    my ($self,$type,$file,$update) = @_;
    my $db = $self->uploads;
    my $dist = CPAN::DistnameInfo->new($file);

    my $name      = $dist->dist;      # "CPAN-DistnameInfo"
    my $version   = $dist->version;   # "0.02"
    my $cpanid    = $dist->cpanid;    # "GBARR"
    my $filename  = $dist->filename;  # "CPAN-DistnameInfo-0.02.tar.gz"
    my $date      = (stat($file))[9];

    unless($name && defined $version && $cpanid && $date) {
    	#$self->_log("PARSE: FAIL file=$file, $type => $name => $version => $cpanid => $date => $filename");
        $file =~ s!/opt/projects/CPAN/!!;
        $db->do_query($phrasebook{'ParseFailed'},$file,$type,$name,$version,$filename,$cpanid,$date);
    	return;
    }
    #$self->_log("$type => $name => $version => $cpanid => $date");

    my @rows = $db->get_query('array',$phrasebook{'FindDistVersion'},$cpanid,$name,$version);
    if(@rows) {
        if($type ne $rows[0]->[0]) {
            $db->do_query($phrasebook{'UpdateDistVersion'},$type,$cpanid,$name,$version);
            $self->_update_index($cpanid,$version,$date,$name,$oncpan{$type})
                if($update && $type ne 'backpan');
        }
    } else {
        $db->do_query($phrasebook{'InsertDistVersion'},$type,$cpanid,$name,$version,$filename,$date);
        $self->_update_index($cpanid,$version,$date,$name,$oncpan{$type})   if($update);
    }

    return $filename;
}

sub _update_index {
    my ($self,$author,$version,$date,$name,$oncpan) = @_;
    my $db = $self->uploads;

    my @index = $db->get_query('hash',$phrasebook{'FindIndex'},$name,$author);
    if(@index) {
        if($date > $index[0]->{released}) {
            $db->do_query($phrasebook{'UpdateIndex'},$oncpan,$version,$date,$name,$author);
            $self->_log("... index update [$author,$version,$date,$name,$oncpan]");
        }
    } else {
        $db->do_query($phrasebook{'InsertIndex'},$oncpan,$author,$version,$date,$name);
        $self->_log("... index insert [$author,$version,$date,$name,$oncpan]");
    }

    # add to page_requests table to update letter index pages and individual pages
    $db->do_query($phrasebook{'InsertRequest'},'ixauth',substr($author,0,1));
    $db->do_query($phrasebook{'InsertRequest'},'ixdist',substr($name,0,1));
    $db->do_query($phrasebook{'InsertRequest'},'author',$author);
    $db->do_query($phrasebook{'InsertRequest'},'distro',$name);
}

sub _nntp_connect {
    # connect to NNTP server
    my $nntp = Net::NNTP->new("nntp.perl.org") or die "Cannot connect to nntp.perl.org";
    my ($num,$first,$last) = $nntp->group("perl.cpan.uploads");

    return ($nntp,$num,$first,$last);
}

sub _lastid {
    my ($self,$id) = @_;
    my $f = $self->lastfile;

    unless( -f $f) {
        mkpath(dirname($f));
        overwrite_file( $f, 0 );
        $id ||= 0;
    }

    if($id) { overwrite_file( $f, $id ); }
    else    { $id = read_file($f); }

    return $id;
}

# generate atomic journal file name
sub _open_journal {
    my $self = shift;
    my @now  = localtime(time);
    my $file = sprintf "%s.%04d%02d%02d%02d%02d%02d", $self->journal, $now[5]+1900,$now[4]+1,$now[3],$now[2],$now[1],$now[0];
    $self->{current} = IO::AtomicFile->new($file,'w+') or die "Cannot write to journal file [$file]: $!\n";
}

sub _write_journal {
    my ($self,$phrase,@args) = @_;
    my $fh = $self->{current};

    print $fh "$phrase," . join(',',@args) . "\n";

    my $db = $self->uploads;
    $db->do_query($phrasebook{$phrase},@args);
}

sub _close_journal {
    my $self = shift;
    $self->{current}->close;
}

sub _find_journals {
    my $self = shift;
    my @files = glob($self->journal . '.*');
    return @files;
}

sub _read_journal {
    my ($self,$journal) = @_;
    my @lines;

    my $fh = IO::File->new($journal,'r') or die "Cannot read journal file [$journal]: $!\n";
    while(<$fh>) {
        my @fields = split(/,/);
        push @lines, \@fields;
    }
    $fh->close;
    return \@lines;
}

sub _done_journal {
    my ($self,$journal) = @_;
    my $cmd = "mv $journal logs";
    system($cmd);
}

sub _init_options {
    my $self = shift;
    my %hash  = @_;
    my %options;

    GetOptions( \%options,
        'config=s',
        'generate|g',
        'update|u',
        'reindex|r',
        'backup|b',
        'journal|j=s',
        'logfile|l=s',
        'logclean=s',
        'lastfile=s',
        'help|h',
        'version|v'
    );

    # default to API settings if no command line option
    for(qw(config generate update reindex fast backup help version)) {
        $options{$_} ||= $hash{$_}  if(defined $hash{$_});
    }

    $self->help(1)  if($options{help});
    $self->help(0)  if($options{version});

    $self->help(1,"Must specify at least one option from 'generate' (-g), 'reindex' (-r),\n'update' (-u)  and/or 'backup' (-b)")
                                                                        unless($options{generate} || $options{update} || $options{backup} || $options{reindex});
    $self->help(1,"Must specific the configuration file")               unless(   $options{config});
    $self->help(1,"Configuration file [$options{config}] not found")    unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    # configure sources
    if($options{generate}) {
        my $dir = $cfg->val('MASTER','BACKPAN');
        $self->help(1,"No source location for 'BACKPAN' in config file")    if(!   $dir);
        $self->help(1,"Cannot find source location for 'BACKPAN': [$dir]")  if(!-d $dir);
        $self->backpan($dir);
        $self->mgenerate(1);
        $self->mreindex(1);
    }
    if($options{generate} || $options{update}) {
        my $dir = $cfg->val('MASTER','CPAN');
        $self->help(1,"No source location for 'CPAN' in config file")   if(!   $dir);
        $self->help(1,"Cannot find source location for 'CPAN': [$dir]") if(!-d $dir);
        $self->cpan($dir);
    }
    if($options{reindex}) {
        $self->mreindex(1);
    }

    $self->mupdate(1)   if($options{update});
    $self->logfile(  $hash{logfile}  || $options{logfile}  || $cfg->val('MASTER','logfile'  ) || LOGFILE  );
    $self->logclean( $hash{logclean} || $options{logclean} || $cfg->val('MASTER','logclean' ) || 0        );
    $self->lastfile( $hash{lastfile} || $options{lastfile} || $cfg->val('MASTER','lastfile' ) || LASTMAIL );
    $self->journal(  $hash{journal}  || $options{journal}  || $cfg->val('MASTER','journal'  ) || JOURNAL  );

    # configure upload DB
    $self->help(1,"No configuration for UPLOADS database") unless($cfg->SectionExists('UPLOADS'));
    my %opts = map {$_ => ($cfg->val('UPLOADS',$_) || undef)} qw(driver database dbfile dbhost dbport dbuser dbpass);
    my $db = CPAN::Testers::Common::DBUtils->new(%opts);
    $self->help(1,"Cannot configure UPLOADS database") unless($db);
    $self->uploads($db);

    # configure backup DBs
    if($options{backup}) {
        $self->help(1,"No configuration for BACKUPS with backup option")    unless($cfg->SectionExists('BACKUPS'));

        my %available_drivers = map { $_ => 1 } DBI->available_drivers;
        my @drivers = $cfg->val('BACKUPS','drivers');
        for my $driver (@drivers) {
            unless($available_drivers{$driver}) {
                warn "No DBI support for '$driver', ignoring\n";
                next;
            }

            $self->help(1,"No configuration for backup option '$driver'")   unless($cfg->SectionExists($driver));

            my %opt = map {$_ => ($cfg->val($driver,$_) || undef)} qw(driver database dbfile dbhost dbport dbuser dbpass);
            $backups{$driver}{'exists'} = $driver =~ /SQLite/i ? -f $opt{database} : 1;

            # CSV is a bit of an oddity!
            if($driver =~ /CSV/i) {
                $backups{$driver}{'exists'} = 0;
                $backups{$driver}{'dbfile'} = $opt{dbfile};
                $opt{dbfile} = 'uploads';
                unlink($opt{dbfile});
            }

            $backups{$driver}{db} = CPAN::Testers::Common::DBUtils->new(%opt);
            $self->help(1,"Cannot configure BACKUPS database for '$driver'")   unless($backups{$driver}{db});
        }

        $self->mbackup(1)   if(keys %backups);
    }
}

sub _log {
    my $self = shift;
    my $log = $self->logfile or return;
    mkpath(dirname($log))   unless(-f $log);

    my $mode = $self->logclean ? 'w+' : 'a+';
    $self->logclean(0);

    my @dt = localtime(time);
    my $dt = sprintf "%04d/%02d/%02d %02d:%02d:%02d", $dt[5]+1900,$dt[4]+1,$dt[3],$dt[2],$dt[1],$dt[0];

    my $fh = IO::File->new($log,$mode) or die "Cannot write to log file [$log]: $!\n";
    print $fh "$dt ", @_, "\n";
    $fh->close;
}

q!Will code for a damn fine Balti!;

__END__

#----------------------------------------------------------------------------

=head1 NAME

CPAN::Testers::Data::Uploads - CPAN Testers Uploads Database Generator

=head1 SYNOPSIS

  perl uploads.pl --config=<file> [--generate] [--reindex] [--update] [--backup]

=head1 DESCRIPTION

This program allows the user to create, update and backup the uploads database,
either as separate commands, or a combination of all three. The process order
will always be CREATE->UPDATE->BACKUP, regardless of the order the options
appear on the command line.

The Uploads database contains basic information about the history of CPAN. It
records the release dates of everything that is uploaded to CPAN, both within
a BACKPAN repository, a current CPAN repository and the latest uploads posted
by PAUSE, which may not have yet reached the CPAN mirrors.

A simple schema for the MySQL database is below:

  CREATE TABLE `uploads` (
    `type`      varchar(10)     NOT NULL,
    `author`    varchar(32)     NOT NULL,
    `dist`      varchar(100)    NOT NULL,
    `version`   varchar(100)    NOT NULL,
    `filename`  varchar(255)    NOT NULL,
    `released`  int(16)         NOT NULL,
    PRIMARY KEY  (`author`,`dist`,`version`)
  ) ENGINE=MyISAM;

The 'type' field can be one of three values, 'backpan', 'cpan' or 'upload',
which incates whether the release has been archived to BACKPAN, currently on
CPAN or has recently been uploaded and may not have reached the CPAN mirrors
yet.

The 'author', 'dist', 'version' and 'filename' fields contain the breakdown of
the distribution component parts used to locate the distribution. Although in
most cases the filename could be considered a primary key, it is possible that
two or more authors could upload a distribution with the same name.

The 'released' field holds the date of the distribution release as the number
of seconds since the epoch. This is extremely useful for sorting distributions
based on their release date rather than the version string. Due to many authors
having different version schemes, this is perhaps the only reliable method with
which to sort distribution releases.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::Testers::Data::Uploads:

  my $obj = CPAN::Testers::Data::Uploads->new();

=back

=head2 Public Methods

=over

=item * process

Based on accessor settings will run the appropriate methods for the current
execution.

=item * generate

Generates a new uploads and ixlatest database.

=item * reindex

Rebuilds the ixlatest table for all entries.

=item * update

Updates the uploads and ixlatest databases.

=item * backup

Provides backup files of the uploads database.

=item * help

Provides a help screen.

=back

=head2 Accessor Methods

=over

=item * uploads

Database handle to the uploads database.

=item * backpan

Path to the BACKPAN archive directory.

=item * cpan

Path to the CPAN archive directory.

=item * logfile

Path to output log file for progress and debugging messages.
Default file: '_uploads.log'.

=item * logclean

If set to a true value will create/overwrite the logfile, otherwise will
append any messages.

=item * lastfile

Path to the file containing the last NNTPID processed. 
Default file: '_lastmail'.

=item * journal

Path to the journal file. 
Default file: '_journal.sql'.

=item * mgenerate

If set to a true value runs in generate mode for the process method().

=item * mupdate

If set to a true value runs in update mode for the process method().

=item * mbackup

If set to a true value runs in backup mode for the process method().

=item * mreindex

If set to a true value runs in reindex mode for the process method().

=back

=head2 Private Methods

=over

=item * _parse_archive

Parses the given article from the NNTP feed.

=item * _update_index

Updates the ixlatest table and pushes requests to the page_request table.

=item * _nntp_connect

Sets up the connection to the NNTP server.

=item * _lastid

Sets or returns the last NNTPID processed.

=item * _init_options

Initialises internal configuration settings based on command line options, API
options and configuration file settings.

=back

=head1 BECOME A TESTER

Whether you have a common platform or a very unusual one, you can help by
testing modules you install and submitting reports. There are plenty of
module authors who could use test reports and helpful feedback on their
modules and distributions.

If you'd like to get involved, please take a look at the CPAN Testers Wiki,
where you can learn how to install and configure one of the recommended
smoke tools.

For further help and advice, please subscribe to the the CPAN Testers
discussion mailing list.

  CPAN Testers Wiki
    - http://wiki.cpantesters.org
  CPAN Testers Discuss mailing list
    - http://lists.cpan.org/showlist.cgi?name=cpan-testers-discuss

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send an email to barbie@cpan.org. However, it would help
greatly if you are able to pinpoint problems or even supply a patch.

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT Queue -
http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Data-Uploads

=head1 SEE ALSO

L<CPAN::Testers::Data::Generate>
L<CPAN::Testers::WWW::Statistics>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2008-2014 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut

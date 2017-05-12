package CPAN::Testers::Data::Release;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.06';

#----------------------------------------------------------------------------
# Library Modules

use base qw(Class::Accessor::Fast);

use CPAN::Testers::Common::DBUtils;
use Config::IniFiles;
use File::Basename;
use File::Path;
use Getopt::Long;
use IO::File;

#----------------------------------------------------------------------------
# Variables

my %phrasebook = (
    # MySQL database
    'SelectAll'         => 'SELECT dist,version,pass,fail,na,unknown,id FROM release_summary WHERE perlmat=1 ORDER BY dist',
    'SelectRows'        => 'SELECT * FROM release_summary ORDER BY dist',
    'DelRows'           => 'DELETE FROM release_summary WHERE dist=?',
    'AddRow'            => 'INSERT INTO release_summary (dist,version,id,guid,oncpan,distmat,perlmat,patched,pass,fail,na,unknown) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',

    'SelectDists'       => 'SELECT dist,version FROM release_summary WHERE id > ?',
    'SelectDist'        => 'SELECT dist,version,id,pass,fail,na,unknown FROM release_summary WHERE perlmat=1 AND dist=? AND version=?',

    # SQLite database
    'DeleteTable'       => 'DROP TABLE IF EXISTS release',
    'CreateTable'       => 'CREATE TABLE release (dist text not null, version text not null, pass integer not null, fail integer not null, na integer not null, unknown integer not null)',
    'CreateDistIndex'   => 'CREATE INDEX release__dist ON release ( dist )',
    'CreateVersIndex'   => 'CREATE INDEX release__version ON release ( version )',

    'DeleteAll'         => 'DELETE FROM release',
    'InsertRelease'     => 'INSERT INTO release (dist,version,pass,fail,na,unknown) VALUES (?,?,?,?,?,?)',
    'UpdateRelease'     => 'UPDATE release SET pass=?,fail=?,na=?,unknown=? WHERE dist=? AND version=?',
    'SelectRelease'     => 'SELECT * FROM release WHERE dist=? AND version=?',
    'DeleteRelease'     => 'DELETE FROM release WHERE dist=? AND version=?',
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

__PACKAGE__->mk_accessors(qw( idfile logfile logclean ));

sub process {
    my $self = shift;
    if($self->{clean}) 		        { $self->clean() }
    elsif($self->{RELEASE}{exists}) { $self->backup_from_last() }
    else               		        { $self->backup_from_start() }
}

sub backup_from_last {
    my $self = shift;

    $self->_log("Find new start");

    my $lastid = 0;
    my $idfile = $self->idfile();
    if($idfile && -f $idfile) {
        if(my $fh = IO::File->new($idfile,'r')) {
            my @lines = <$fh>;
            ($lastid) = $lines[0] =~ /(\d+)/;
            $fh->close;
        }
    }

    $lastid ||= 0;
    $self->_log("Starting from $lastid");

    # retrieve data from master database
    my $rows = $self->{CPANSTATS}{dbh}->iterator('hash',$phrasebook{'SelectDists'},$lastid);
    while(my $row = $rows->()) {
        $self->_log("... dist=$row->{dist}, version=$row->{version}");
        my $next = $self->{CPANSTATS}{dbh}->iterator('hash',$phrasebook{'SelectDist'},$row->{dist},$row->{version});
        my ($pass,$fail,$na,$unknown) = (0,0,0,0);
        while(my $rs = $next->()) {
            $pass    += $rs->{pass};
            $fail    += $rs->{fail};
            $na      += $rs->{na};
            $unknown += $rs->{unknown};
            $lastid = $rs->{id} if($lastid < $rs->{id});
        }

        $self->{RELEASE}{dbh}->do_query($phrasebook{'DeleteRelease'},$row->{dist},$row->{version});
        $self->{RELEASE}{dbh}->do_query($phrasebook{'InsertRelease'},$row->{dist},$row->{version},$pass,$fail,$na,$unknown);
    }

    $self->_log("Writing lastid=$lastid");

    if($idfile) {
        if(my $fh = IO::File->new($idfile,'w+')) {
            print $fh "$lastid\n";
            $fh->close;
        }
    }

    $self->_log("Backup completed");
}

sub backup_from_start {
    my $self = shift;
    my $lastid = 0;

    $self->_log("Create backup database");

    # start with a clean slate
    $self->{RELEASE}{dbh}->do_query($phrasebook{'DeleteTable'});
    $self->{RELEASE}{dbh}->do_query($phrasebook{'CreateTable'});
    $self->{RELEASE}{dbh}->do_query($phrasebook{'CreateDistIndex'});
    $self->{RELEASE}{dbh}->do_query($phrasebook{'CreateVersIndex'});

    $self->_log("Generate backup data");

    # store data from master database
    my %data;
    my $dist = '';
    my $rows = $self->{CPANSTATS}{dbh}->iterator('hash',$phrasebook{'SelectAll'});
    while(my $row = $rows->()) {
        if($dist && $dist ne $row->{dist}) {
            $self->_log("... dist=$dist");
            for my $vers (keys %data) {
                $self->{RELEASE}{dbh}->do_query($phrasebook{'InsertRelease'},@{ $data{$vers} });
            }

            %data = ();
        }

        $dist = $row->{dist};

        if($data{$row->{version}}) {
            $data{$row->{version}}->[2] += $row->{pass};
            $data{$row->{version}}->[3] += $row->{fail};
            $data{$row->{version}}->[4] += $row->{na};
            $data{$row->{version}}->[5] += $row->{unknown};
        } else {
            $data{$row->{version}} = [ map { $row->{$_} } qw(dist version pass fail na unknown) ];
        }

        $lastid = $row->{id} if($lastid < $row->{id});
    }

    if($dist) {
        $self->_log("... dist=$dist");
        for my $vers (keys %data) {
            $self->{RELEASE}{dbh}->do_query($phrasebook{'InsertRelease'},@{ $data{$vers} });
        }
    }

    $self->{RELEASE}{exists} = 1;

    my $idfile = $self->idfile();
    if($idfile) {
        if(my $fh = IO::File->new($idfile,'w+')) {
            print $fh "$lastid\n";
            $fh->close;
        }
    }

    $self->_log("Backup completed");
}

# sub to remove duplicates in the matser database.
sub clean {
    my $self = shift;

    $self->_log("Clean master database");

    my %data;
    my $dist = '';
    my $rows = $self->{CPANSTATS}{dbh}->iterator('hash',$phrasebook{'SelectRows'});
    while(my $row = $rows->()) {
        if($dist && $dist ne $row->{dist}) {
    	    $self->{CPANSTATS}{dbh}->do_query($phrasebook{'DelRows'},$dist);
            $self->_log("DelRows: $dist");
	        for my $vers (keys %data) {
		        for my $code (keys %{$data{$vers}}) {
        		    my $rowx = $data{$vers}{$code};
	                $self->{CPANSTATS}{dbh}->do_query($phrasebook{'AddRow'},$dist,$vers,
                        $rowx->{id},$rowx->{guid},
                        $rowx->{oncpan},$rowx->{distmat},$rowx->{perlmat},$rowx->{patched},
                        $rowx->{pass},$rowx->{fail},$rowx->{na},$rowx->{unknown});
                    $self->_log('AddRow: ' . join(', ',
                        $dist,$vers,
                        $rowx->{id},$rowx->{guid},
                        $rowx->{oncpan},$rowx->{distmat},$rowx->{perlmat},$rowx->{patched},
                        $rowx->{pass},$rowx->{fail},$rowx->{na},$rowx->{unknown}) );
		        }
	        }

            %data = ();
        }

        $dist = $row->{dist};
        my $code = join(':',$row->{oncpan},$row->{distmat},$row->{perlmat},$row->{patched});
        $data{$row->{version}}{$code} = $row;
    }

    if($dist) {
        $self->{CPANSTATS}{dbh}->do_query($phrasebook{'DelRows'},$dist);
        $self->_log("DelRows: $dist");
        for my $vers (keys %data) {
            for my $code (keys %{$data{$vers}}) {
                my $rowx = $data{$vers}{$code};
                    $self->{CPANSTATS}{dbh}->do_query($phrasebook{'AddRow'},$dist,$vers,
                        $rowx->{id},$rowx->{guid},
                        $rowx->{oncpan},$rowx->{distmat},$rowx->{perlmat},$rowx->{patched},
                        $rowx->{pass},$rowx->{fail},$rowx->{na},$rowx->{unknown});
                    $self->_log('AddRow: ' . join(', ',
                        $dist,$vers,
                        $rowx->{id},$rowx->{guid},
                        $rowx->{oncpan},$rowx->{distmat},$rowx->{perlmat},$rowx->{patched},
                        $rowx->{pass},$rowx->{fail},$rowx->{na},$rowx->{unknown}) );
            }
        }
    }

    $self->_log("Clean completed");
}

sub help {
    my ($self,$full,$mess) = @_;

    print "\n$mess\n\n" if($mess);

    if($full) {
        print <<HERE;

Usage: $0 --config=<file> [--clean] [-h] [-v]

  --config=<file>   database configuration file
  --clean           clean master database of duplicates
  -h                this help screen
  -v                program version

HERE

    }

    print "$0 v$VERSION\n\n";
    exit(0);
}


#----------------------------------------------------------------------------
# Internal Methods

sub _init_options {
    my $self = shift;
    my %hash  = @_;
    my %options;

    GetOptions( \%options,
        'clean',
        'config=s',
        'help|h',
        'version|v'
    ) or help(1);

    # default to API settings if no command line option
    for(qw(config help version)) {
        next    unless(!defined $options{$_} && defined $hash{$_});
        $options{$_} = $hash{$_};
    }

    $self->help(1)  if($options{help});
    $self->help(0)  if($options{version});

    $self->help(1,"Must specific the configuration file")               unless(   $options{config});
    $self->help(1,"Configuration file [$options{config}] not found")    unless(-f $options{config});

    # load configuration
    my $cfg = Config::IniFiles->new( -file => $options{config} );

    $self->idfile(   $cfg->val('MASTER','idfile'   ) );
    $self->logfile(  $cfg->val('MASTER','logfile'  ) );
    $self->logclean( $cfg->val('MASTER','logclean' ) || 0 );

    # configure upload DB
    for my $dbname (qw(CPANSTATS RELEASE)) {
        $self->help(1,"No configuration for $dbname database") unless($cfg->SectionExists($dbname));
        my %opts = map {$_ => ($cfg->val($dbname,$_) || undef);} qw(driver database dbfile dbhost dbport dbuser dbpass);
        $self->{$dbname}{exists} = $opts{driver} =~ /SQLite/i ? -f $opts{database} : 1;
        $self->{$dbname}{dbh} = CPAN::Testers::Common::DBUtils->new(%opts);
        $self->help(1,"Cannot configure $dbname database") unless($self->{$dbname}{dbh});
    }

    $self->{clean} = 1 if($options{clean});
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

q{Written to the tune of Release by Pearl Jam :)};

__END__

=head1 NAME

CPAN::Testers::Data::Release - CPAN Testers Release database generator

=head1 SYNOPSIS

  perl release.pl --config=<file>

=head1 DESCRIPTION

This distribution contains the code that extracts the data from the 
release_summary table in the cpanstats database. The data extracted represents 
the data relating to the public releases of Perl, i.e. no patches and official 
releases only.

=head1 SQLite DATABASE

The database created uses the following schema:

  CREATE TABLE release (
      dist    text    not null,
      version text    not null,
      pass    integer not null,
      fail    integer not null,
      na      integer not null,
      unknown integer not null
  );

  CREATE INDEX release__dist ON release ( dist );
  CREATE INDEX release__version ON release ( version );

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Instatiates the object CPAN::Testers::Data::Release:

  my $obj = CPAN::Testers::Data::Release->new();

=back

=head2 Public Methods

=over

=item * process

Shorthand function to run methods based on command line options.

=item * backup_from_last

Run backup processes from the last known update.

=item * backup_from_start

Run backup processes recreating the complete backup database from scratch.

=item * clean

Run database table clean processes.

=item * help

Provides basic help screen.

=back

=head2 Private Methods

=over

=item * _init_options

Extracts the command line options and performs basic validation.

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

  CPAN Testers Wiki - http://wiki.cpantesters.org
  CPAN Testers Discuss mailing list
    - http://lists.cpan.org/showlist.cgi?name=cpan-testers-discuss

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

Fixes are dependent upon their severity and my availability. Should a fix not
be forthcoming, please feel free to (politely) remind me.

RT: http://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Testers-Data-Release

=head1 SEE ALSO

L<CPAN::Testers::Data::Generator>
L<CPAN::Testers::Data::Uploads>

F<http://www.cpantesters.org/>,
F<http://stats.cpantesters.org/>,
F<http://wiki.cpantesters.org/>,
F<http://blog.cpantesters.org/>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut

#!/usr/bin/perl

use strict;

use Getopt::Std;
use DBD::SQLite;
use IO::File;
use File::Path;
use File::NCopy;
use Text::CSV::Simple;
use Cwd;
use Template;

my $args = { };
getopts('vh', $args);
usage() if $args->{ h };

my $verbose = $args->{ v };

my $rootdir = shift || usage();
$rootdir =~ s/^\~/$ENV{HOME}/;
$rootdir = "/$rootdir" unless $rootdir =~ /^\//;

my $url = shift || 'localhost';
$url =~ s/^http:\/\///i;

my $port = shift || 80;
my $cwd = getcwd;

die "This script must be run from the root of the CDF distribution\n" unless -d "$cwd/cdfdemo";
chdir 'cdfdemo';

print <<"EOM" if $verbose;

*** INSTALLING CDF DEMO ***

The Class::DBI::Factory demo requires various perl modules. We assume that 
you have installed them, having made it this far. It also requires a working 
Apache/mod_perl installation: see the README file in ./cdf_demo/ for more 
information about how to integrate the demo into your Apache setup. A brief 
version of those instructions will be printed at the end of this script for 
the impatient.

Installing to directory '$rootdir' and url '$url:$port'

EOM

if ( -e $rootdir) {
    die ("'$rootdir' exists and is not a directory") unless -d $rootdir;
    die ("'$rootdir' exists and is not writable") unless -r $rootdir;
} else {
    eval { File::Path::mkpath($rootdir); };	
    die ("create_path failed for '$rootdir': $@") if $@;
}	

print "* copying templates to $rootdir/templates\n" if $verbose;
dcopy("./templates", $rootdir);

print "* copying data classes to $rootdir/lib\n" if $verbose;
dcopy("./lib", $rootdir);

print "* copying css and index page to $rootdir/public_html\n" if $verbose;
dcopy("./public_html", $rootdir);

print "* creating directory $rootdir/conf\n" if $verbose;
mkdir "$rootdir/conf" || die $!;

print "* creating directory $rootdir/scripts\n" if $verbose;
mkdir "$rootdir/scripts" || die $!;

print "* creating directory $rootdir/data\n" if $verbose;
mkdir "$rootdir/data" || die $!;

my $tt = Template->new( INCLUDE_PATH => '.' );
my $parameters = { 
	demo_root => $rootdir, 
	demo_url => $url,
	demo_port => $port,
};

for ('conf/cdf.conf', 'conf/site.conf', 'conf/site_mp2.conf', 'scripts/startup.pl', 'scripts/startup_mp2.pl') {
    print "* processing $_\n" if $verbose;
    my $output;
    $tt->process($_, $parameters, \$output);
    write_file("$rootdir/$_", $output);
}

my $dbfile = "cdfdemo.sdb";
print <<"EOM" if $verbose;
* creating sample database

The SQLite data file will be at $dbfile. For updates and inserts to work, 
both this file and the directory that contains it must be writable by your
apache user (which is probably 'nobody').

PS. Sorry about the silly sample data.

EOM

create_database($dbfile);

print "\n* Installation complete\n\n";

print <<"EOM" if $verbose;
All that remains is to include the newly created host in your Apache 
configuration. Unless you've got a very esoteric setup, it's probably as simple
as making sure that this line (or an equivalent) is in your httpd.conf:\n");
	
	NameVirtualHost *:$port

And adding this one beneath it:

	Include $rootdir/conf/site.conf

Or for Apache 2:

	Include $rootdir/conf/site_mp2.conf
	
(and hope for the best).

Restart the Apache you just modified and you should be able to see the demo 
site - such as it is - at http://${url}:${port}

For more documentation, please look in the README included in the same directory 
as this installer, and in the POD in Class::DBI::Factory. Fuller docs for the 
demo will follow if anyone seems interested.

EOM








sub dcopy {
    my ($from, $to) = @_;
    File::NCopy->new( recursive => 1 )->copy( $from, $to ) || die $!;
}

sub write_file {
	my ($file, $content) = @_;
	my $fh = new IO::File "> $file";
	if (defined $fh) {
		print $fh $content;
		$fh->close;
	}
}

sub create_database {
    my $filename = shift || return;
    my $dbfile = "${rootdir}/data/${filename}";
    my $dsn = "dbi:SQLite:dbname=$dbfile";
	my $dbh;
    unlink $dbfile if -e $dbfile;

	eval { $dbh = DBI->connect($dsn,"",""); };
    die "connecting to (and creating) SQLite database '$dbfile' failed: $!" if $@;

	$dbh->do('create table tracks (
		id integer primary key,
		album integer,
		duration integer,
		position integer,
		miserableness integer,
		title varchar(255),
		description text);
	');
	
	$dbh->do('create table albums (
		id integer primary key,
		artist integer,
		genre integer,
		title varchar(255),
		description text);
	');
	
	$dbh->do('create table artists (
		id integer primary key,
		title varchar(255),
		description text);
	');
	
	$dbh->do('create table genres (
		id integer primary key,
		title varchar(255),
		description text);
	');
	
	for ('genres', 'artists', 'albums', 'tracks' ) {
	    print "* loading sample $_\n" if $verbose;
        my $parser = Text::CSV::Simple->new;
        my @data = $parser->read_file("data/${_}.csv");
        my $cols = shift @data;
        my $statement = "INSERT INTO $_ (" . join(',', @$cols) . ") VALUES (" . join(',', (map { '?' } @$cols)) . ");";
        my $sth = $dbh->prepare($statement);
        $sth->execute( @$_ ) for @data;
    }    
}
        
sub usage {
    print STDERR <<EOM;
cdf_demo/install.pl: installation script for optional 
Class::DBI::Factory demonstration site.

usage: install.pl [ -v | -h ] path [demo_site_url] [demo_site_port]

    -v	verbose mode
    -h	this help
    
The url defaults to 'localhost' and the port to '80', so those can be omitted. 
The installation directory must be specified in full. ~ is allowed.

EOM
    exit();
}

#!/usr/bin/perl

use strict;
use Getopt::Std;
use Apache::SdnFw::lib::Core;
use Apache::SdnFw::lib::DB;
use Data::Dumper;
use Carp;

my %args;
getopts('vd:',\%args);

unless($args{d}) {
	print STDERR "run_sql.pl -v -d database <command.sql\n";
	exit;
}

my $query;
while (<STDIN>) {
	$query .= $_;
}

my $s = Apache::SdnFw::lib::Core->new(
	uri => 'commandline',
	content_type => 'text/plain',
	env => {
		DOCUMENT_ROOT => 'commandline',
		DB_STRING => "dbname=$args{d}",
		DB_USER => 'sdnfw',
		BASE_URL => "/$args{d}",
		OBJECT_BASE => $args{d},
		},
	);

$s->{dbh} = db_connect($s->{env}{DB_STRING},'postgres');

my $start;
if ($args{v}) {
	print "Starting query to $args{d}\n";
	$start = time;
}

$s->{dbh}->begin_work;

$s->db_q($query,undef);

$s->{dbh}->commit;

if ($args{v}) {
	my $time = time-$start;
	print "Complete: $time seconds\n";
}

#!/usr/bin/perl

use warnings;
use strict;

use Data::Dump qw(dump);
use Getopt::Long;
use lib 'lib';
use Biblio::RFID::Reader;
use Biblio::RFID::RFID501;

my $loop = 0;
my $reader;
my $debug = 0;

GetOptions(
	'loop!'     => \$loop,
	'reader=s', => \$reader,
	'debug+'    => \$debug,
) || die $!;

my $rfid = Biblio::RFID::Reader->new( $reader );
$Biblio::RFID::debug = $debug;

sub tag {
	my $tag = shift;
	return $tag
		, " AFI: "
		, uc unpack('H2', $rfid->afi($tag))
		, " "
		, dump( Biblio::RFID::RFID501->to_hash( $rfid->blocks($tag) ) )
		, $/
		;
}

do {
	my @visible = $rfid->tags(
		enter => sub {
			my $tag = shift;
			print localtime()." enter ", tag($tag);

		},
		leave => sub {
			my $tag = shift;
			print localtime()." leave ", tag($tag);
		},
	);

	warn localtime()." visible: ",join(' ',@visible),"\n";

	sleep 1;

} while $loop;

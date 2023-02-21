#!/usr/bin/perl

use warnings;
use strict;

use Data::Dump qw(dump);
use Getopt::Long;
use lib 'lib';
use Biblio::RFID::Reader;
use Biblio::RFID::RFID501;

my $reader;
my $afi = 0x00;
my $debug = 0;
my $hash;
my $blank;

GetOptions(
	'reader=s', => \$reader,
	'afi=i',    => \$afi,
	'debug+',   => \$debug,
	'set=i'		=> \$hash->{set},
	'total=i',	=> \$hash->{total},
	'type=i',	=> \$hash->{type},
	'branch=i',	=> \$hash->{branch},
	'library=i'	=> \$hash->{library},
	'3mblank'	=> \$blank->{blank_3m},
	'blank'		=> \$blank->{blank},
) || die $!;

my ( $sid, $content ) =  @ARGV;
if ( $sid =~ m/.+,.+/ && ! defined $content ) {
	( $sid, $content ) = split(/,/, $sid);
}

die "usage: $0 [--reader regex_filter] [--afi 214] [--type 1] E0_RFID_SID [barcode]\n" unless $sid && ( $content || $afi || $blank );

$hash->{content} = $content if defined $content;

my $rfid = Biblio::RFID::Reader->new( $reader );
$Biblio::RFID::debug = $debug;

foreach my $tag ( $rfid->tags, $sid ) {
	warn "visible $tag\n";
	next unless $tag eq $sid;
	if ( grep { defined $_ } values %$blank ) {
		my $type = ( grep { $blank->{$_} } keys %$blank )[0];
		warn "BLANK $type $tag\n";
		$rfid->write_blocks( $tag => Biblio::RFID::RFID501->$type );
	} elsif ( $content ) {
		warn "PROGRAM $tag with $content\n";
		$rfid->write_blocks( $tag => Biblio::RFID::RFID501->from_hash($hash) );
	}
	if ( $afi ) {
		warn "AFI $tag with $afi\n";
		$rfid->write_afi( $tag => chr($afi) );
	}
}


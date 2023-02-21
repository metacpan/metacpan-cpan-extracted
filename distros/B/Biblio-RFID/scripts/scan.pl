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
my $log;

GetOptions(
	'loop!'     => \$loop,
	'reader=s', => \$reader,
	'debug+'    => \$debug,
	'log=s'     => \$log,
) || die $!;

my $rfid = Biblio::RFID::Reader->new( $reader );
$Biblio::RFID::debug = $debug;

sub tag {
	my $tag = shift;
	return $tag
		, " AFI: "
		, uc unpack('H2', $rfid->afi($tag))
		, " "
		, dump( $rfid->to_hash( $tag ) )
		, $/
		;
}

my $saved;

sub iso_date {
	my @t = localtime(time);
	return sprintf "%04d-%02d-%02dT%02d:%02d:%02d", $t[5]+1900,$t[4]+1,$t[3],$t[2],$t[1],$t[0];
}

sub log_tag {
	my $tag = shift;
	return if $saved->{tag} or ! $log;
	my $hash = $rfid->to_hash( $tag );
	open(my $fh, '>>', $log) || die "$log: $!";
	print $fh iso_date,",$tag,", $hash->{content}, "\n";
	close($fh);
}

do {
	my @visible = $rfid->tags(
		enter => sub {
			my $tag = shift;
			print iso_date," reader ", $rfid->from_reader($tag), " enter ", tag($tag);
			log_tag $tag;
		},
		leave => sub {
			my $tag = shift;
			print iso_date," leave ", tag($tag);
		},
	);

	warn iso_date," visible: ",join(' ',@visible),"\n";

	sleep 1;

} while $loop;

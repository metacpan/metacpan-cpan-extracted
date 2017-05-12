#!/usr/bin/perl

use warnings;
use strict;

use Data::Dump qw(dump);
use Getopt::Long;
use lib 'lib';
use Biblio::RFID::Reader;
use Biblio::RFID::RFID501;
use Storable;

my $evolis_dir = '/home/dpavlin/klin/Printer-EVOLIS'; # FIXME
use lib '/home/dpavlin/klin/Printer-EVOLIS/lib';
use Printer::EVOLIS::Parallel;

my $loop = 1;
my $reader = '3M';
my $debug = 0;
my $afi   = 0x00; # XXX
my $test  = 0;

my $log_print = 'log.print';
mkdir $log_print unless -d $log_print;

GetOptions(
	'loop!'     => \$loop,
	'reader=s', => \$reader,
	'debug+'    => \$debug,
	'test+'     => \$test,
) || die $!;

die "Usage: $0 print.txt\n" unless @ARGV;

my $persistant_path = '/tmp/programmed.storable';
my $programmed;
my $numbers;
if ( -e $persistant_path ) {
	$programmed = retrieve($persistant_path);
	warn "# loaded ", scalar keys %$programmed, " programmed cards\n";
	foreach my $tag ( keys %$programmed ) {
		$numbers->{ $programmed->{$tag} } = $tag;
	}
}

my @queue;
my @done;
warn "# reading tab-delimited input: number login\@domain name surname\n";
while(<>) {
	chomp;
	my @a = split(/\t/,$_);
	die "invalid: @a in line $_" if $a[0] !~ m/\d{12}/ && $a[1] !~ m/\@/;
	push @queue, [ @a ] if ! $numbers->{ $a[0] };
}

print "# queue ", dump @queue;

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

sub iso_date {
	my @t = localtime(time);
	return sprintf "%04d-%02d-%02dT%02d:%02d:%02d", $t[5]+1900,$t[4]+1,$t[3],$t[2],$t[1],$t[0];
}

sub print_card;

my $log_path = "$log_print/" . iso_date . ".txt";
die "$log_path exists" if -e $log_path;
open(my $log, '>', $log_path) || die "$log_path: $!";

while ( $rfid->tags ) {
	print "ERROR: remove all tags from output printer tray\n";
	sleep 1;
}

print_card;

do {
	my @visible = $rfid->tags(
		enter => sub {
			my $tag = shift;
			print localtime()." enter ", eval { tag($tag) };
			return if $@;

			if ( ! $programmed->{$tag} ) {
				my $card = shift @queue;
				my $number = $card->[0];
				print "PROGRAM $tag $number\n";
				$rfid->write_blocks( $tag => Biblio::RFID::RFID501->from_hash({ content => $number }) );
				$rfid->write_afi( $tag => chr($afi) ) if $afi;

				$programmed->{$tag} = $number;
				store $programmed, $persistant_path;

				print $log iso_date, ",$tag,$number\n";
			}

		},
		leave => sub {
			my $tag = shift;

			print_card if $programmed->{$tag};
		},
	);

	warn localtime()." visible: ",join(' ',@visible),"\n";

	sleep 1;
} while $loop;

sub print_card {

	if ( ! @queue ) {
		print "QUEUE EMPTY - printing finished\n";
		close($log);
		print "$log_path ", -s $log_path, " bytes created\n";
		exit;
	}

	my @data = @{$queue[0]};
	print "XXX print_card @data\n";

	if ( $test ) {

		my $p = Printer::EVOLIS::Parallel->new( '/dev/usb/lp0' );
		print "insert card ", $p->command( 'Si' ),$/;
		sleep 1;
		print "eject card ", $p->command( 'Ser' ),$/;

	} else {

		system "$evolis_dir/scripts/inkscape-render.pl", "$evolis_dir/card/ffzg-2010.svg", @data;
		my $nr = $data[0];
		system "$evolis_dir/scripts/evolis-driver.pl out/$nr.front.pbm out/$nr.back.pbm > /dev/usb/lp0";

	}

}


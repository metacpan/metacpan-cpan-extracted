#!/usr/bin/perl
#
# madjack-remote.pl
# Perl based Terminal interface for MadJACK
#
# Nicholas J. Humfrey <njh@aelius.com>
#

use Audio::MadJACK;
use Term::ReadKey;
use POSIX qw/floor/;
use strict;

# Create MadJACK object for talking to the deck
my $madjack = new Audio::MadJACK(@ARGV);
exit(-1) unless (defined $madjack);

# Display the URL of the MadJACK deck we connected to
print "URL of madjack server: ".$madjack->get_url()."\n";
print "MadJACK server version: ".$madjack->get_version()."\n";


my $duration = $madjack->get_duration();

# Change terminal mode
ReadMode(3);
$|=1;

my $running = 1;
while( $running ) {
	# Get player state
	my $state = $madjack->get_state();
	#last unless (defined $state);

	# Wait for 1/5 second for key-press
	my $key = ReadKey( 0.2 );
	if (defined $key) {
		if ($key eq 'q') {
			$running=0;
		} elsif ($key eq 'l') {
			ReadMode(0);
			print "Enter name of file to load: ";
			my $filepath = <STDIN>;
			chomp($filepath);
			$madjack->load( $filepath );
			ReadMode(3);
		} elsif ($key eq 's') {
			$madjack->stop()
		} elsif ($key eq 'f') {
			print "Filepath: ".$madjack->get_filepath()."\n";
		} elsif ($key eq 'c') {
			$madjack->cue()
		} elsif ($key eq 'C') {
			ReadMode(0);
			print "Enter cue point (in seconds): ";
			my $cuepoint = <STDIN>;
			chomp($cuepoint);
			$madjack->cue( $cuepoint );
			ReadMode(3);
		} elsif ($key eq 'e') {
			$madjack->eject()
		} elsif ($key eq 'p') {
			if ($state eq 'PLAYING') { $madjack->pause(); }
			else { $madjack->play(); }
		} else {
			warn "Unknown key command ('$key')\n";
		}
		
		$duration = $madjack->get_duration();
	}
	
	# Display state and time
	my $pos = $madjack->get_position();
	printf("%s [%s/%s]                  \r", $state, min_sec($pos), min_sec($duration));
}


# Restore terminate settings
ReadMode(0);


sub min_sec {
	my ($secs) = @_;
	
	my $min = floor($secs / 60);
	my $sec = ($secs - ($min*60));
	
	return sprintf("%d:%1.1f", $min, $sec);
}


#!/usr/bin/perl

use strict;
use warnings;
use Aspect;

aspect Wormhole => 'Printer::print', 'SpamDocument::spool';

my $printer = Printer->new("TheBigOneOnTheSecondFloor");
my $job = SpamPrintJob->new;
$printer->print($job);

# -----------------------------------------------------------------------------

package Printer;

sub new { bless {name => pop}, shift }

sub print {
	my ($self, $job) = @_;
	$job->spool;
}

sub get_name { shift->{name} }

# -----------------------------------------------------------------------------

package SpamPrintJob;

sub new { bless {}, shift }

sub spool { SpamDocument->new->spool }

# -----------------------------------------------------------------------------

package SpamDocument;

sub new { bless {}, shift }

sub spool {
	my ($self, $printer) = @_;
	my $printerName = $printer->get_name;

	# run system print command on spam postscript file
	print "SpamDocument has been spooled to: $printerName.\n";
}



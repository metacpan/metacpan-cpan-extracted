#!/usr/bin/perl

use strict;
use warnings;

my $printer = Printer->new;
my $job = SpamPrintJob->new;
$printer->print($job);

# -----------------------------------------------------------------------------

package Printer;

sub new { bless {}, shift }

sub print {
	my ($self, $job) = @_;
	$job->spool;
}

# -----------------------------------------------------------------------------

package SpamPrintJob;

sub new { bless {}, shift }

sub spool { SpamDocument->new->spool }

# -----------------------------------------------------------------------------

package SpamDocument;

sub new { bless {}, shift }

sub spool {
	# run system print command on spam postscript file
	print "SpamDocument has been spooled.\n";
}


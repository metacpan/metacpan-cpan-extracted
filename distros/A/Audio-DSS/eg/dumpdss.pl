#!/usr/bin/perl

#dumpdss.pl - extract DSS - Digital Sound Standard meta data from one or more 
# files passed on the command line.  Adding option for how to dump the 
# data would make sense, but is just too annoying to contemplate for a 
# quick and dirty utility...

# Warning: this tool is really stupid about format, so you could easily have 
# delimiters in a comment that break the output of this.  Sorry.

use Audio::DSS;

my @fields = qw(file create_date complete_date length comments);
print (join "|", @fields) ;
print "\n";
foreach my $file (@ARGV) {
	my $dss = Audio::DSS->new($file);
	foreach my $field (@fields) {
		print $dss->{$field} . '|';
	}
	print "\n";
}


use ExtUtils::MakeMaker;

# Complication is that we would like to install default letter
# frequency file. Simplest if we run this module to generate the
# file and then install it as a module.

use strict;
use lib ".";
use PassGen; # Note that we cant address it as Crypt::PassGen yet


# The source of the letter count
# Please edit if you are not on a unix system
# Complication is that currently this location is hard-wired
# into the perl module if anyone tries to regenerate 
# a file later without overriding it - this is why the software is
# alpha at the moment

# If this is difficult the module could contain the dictionary
# since it is only about 200kB

# Look for /usr/dict/words and /usr/share/dict/words
my $dictionary;
my @dicts = qw| /usr/dict/words /usr/share/dict/words |;

for (@dicts) {
  if (-e $_) {
    $dictionary = $_;
    last;
  }
}

die "Can not find a default dictionary. Please edit Makefile.PL"
  unless defined $dictionary;

$|=1;
print "Generating letter frequency from $dictionary .....";
Crypt::PassGen::ingest(DICT => $dictionary,
		       FILE => 'PassGenWordFreq.dat',
		       APPEND => 0
		      )
 or die "Error generating frequency table:  $Crypt::PassGen::ERRSTR";
print "Done\n";


WriteMakefile(
	      'NAME'      => 'Crypt::PassGen',
	      'VERSION_FROM'   => 'PassGen.pm',
	      'PREREQ_PM' => {
			      'Test' => 0,
			      'Storable' => 0,
			      'File::Spec' => 0,
			     },
	      'PM'        => {
			      'PassGenWordFreq.dat' => '$(INST_LIBDIR)/PassGenWordFreq.dat',
			      'PassGen.pm' => '$(INST_LIBDIR)/PassGen.pm',
			     },
	      'dist'      => { COMPRESS => "gzip -9f"},
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM => 'PassGen.pm',
		AUTHOR     => 'Tim Jenness <tjenness@cpan.org>') : ()),
	     );


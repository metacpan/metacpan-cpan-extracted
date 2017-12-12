#!/usr/bin/perl -w


use Test::More tests => 6;

use BibTeX::Parser;
use IO::File;


my $fh = new IO::File "t/bibs/14-extratext.bib", "r" ;

my $parser = new BibTeX::Parser $fh;




while (my $entry = $parser->next) {

    if($entry->key eq 'Partridge') {
	my $result1= '@BOOK{Partridge,
    author = {Partridge, Eric},
    title = {Use and Abuse: a Guide to Good {E}nglish},
    publisher = {Hamish Hamilton},
    edition = {4},
    year = {1970},
}';
	my $result2 = "First published in 1947\n$result1";
	is($entry->to_string,$result1);
	is($entry->to_string(print_pre=>1),$result2);
    }
	    
    if ($entry->key eq 'Cooper') {
	my $result1 = '@BOOK{Cooper,
    author = {Cooper, Bruce M.},
    title = {Writing Technical Reports},
    publisher = {Penguin},
    year = {1964},
}';
	my $result2 = "\n\n$result1";
	is($entry->to_string,$result1);
	is($entry->to_string(print_pre=>1),$result2);
    }


    if ($entry->key eq 'Fowler-ModernEnglish') {

	my $result1 = '@BOOK{Fowler-ModernEnglish,
    author = {Fowler, H. W.},
    title = {[A Dictionary of] Modern {E}nglish Usage},
    publisher = {Oxford University Press},
    edition = {2},
    year = {1965},
}';
	my $result2 = '


First published in 1926
'. $result1;
	is($entry->to_string,$result1);
	is($entry->to_string(print_pre=>1),$result2);
    }
}

done_testing();


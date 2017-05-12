#!/usr/bin/perl -w

use Test::More;

use BibTeX::Parser;
use IO::File;


my $fh = new IO::File "t/bibs/01.bib", "r" ;

my $parser = new BibTeX::Parser $fh;




while (my $entry = $parser->next) {
    if($entry->key eq 'key01') {
	my $result1='@ARTICLE{key01,
    year = {1950},
    author = {Duck, Donald and Else, Someone},
    editor = {Itor, E. D. and Other, A. N.},
    title = {Title text},
    month = {January~1},
}';
	my $result2='@ARTICLE{key01,
    year = {1950},
    author = {Donald Duck and Someone Else},
    editor = {E. D. Itor and A. N. Other},
    title = {Title text},
    month = {January~1},
}';
    is($entry->to_string,$result1);
    is($entry->to_string(canonize_names=>0),$result2);
    }

}

done_testing();


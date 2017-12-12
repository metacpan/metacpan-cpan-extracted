#!/usr/bin/perl -w

use Test::More tests=>7;

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
    YEAR = {1950},
    AUTHOR = {Duck, Donald and Else, Someone},
    EDITOR = {Itor, E. D. and Other, A. N.},
    TITLE = {Title text},
    MONTH = {January~1},
}';
	my $result3='@ARTICLE{key01,
    Year = {1950},
    Author = {Duck, Donald and Else, Someone},
    Editor = {Itor, E. D. and Other, A. N.},
    Title = {Title text},
    Month = {January~1},
}';
	my $result4='@article{key01,
    year = {1950},
    author = {Duck, Donald and Else, Someone},
    editor = {Itor, E. D. and Other, A. N.},
    title = {Title text},
    month = {January~1},
}';
	my $result5='@Article{key01,
    year = {1950},
    author = {Duck, Donald and Else, Someone},
    editor = {Itor, E. D. and Other, A. N.},
    title = {Title text},
    month = {January~1},
}';
    is($entry->to_string,$result1);	
    is($entry->to_string(field_capitalization=>'Lowercase'),
			 $result1);	
    is($entry->to_string(field_capitalization=>'Uppercase'),
			 $result2);	
    is($entry->to_string(field_capitalization=>'Titlecase'),
			 $result3);	

    is($entry->to_string(type_capitalization=>'Lowercase'),
			 $result4);	
    is($entry->to_string(type_capitalization=>'Uppercase'),
			 $result1);	
    is($entry->to_string(type_capitalization=>'Titlecase'),
			 $result5);	
    }

}

done_testing();


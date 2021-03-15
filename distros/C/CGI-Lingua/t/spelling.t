#!perl -wT

use strict;
use warnings;
use Test::More;

if($ENV{AUTHOR_TESTING}) {
	eval 'use Test::Spelling';
	if($@) {
		plan(skip_all => 'Test::Spelling required for testing POD spelling');
	} else {
		add_stopwords(<DATA>);
		all_pod_files_spelling_ok();
	}
} else {
	plan(skip_all => 'Author tests not required for installation');
}

__END__
AnnoCPAN
CGI
CPAN
GPL
RT
Sublanguages
Whois
en
sublanguage
IP
gb
lookup
lookups

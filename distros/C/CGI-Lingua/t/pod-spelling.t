#!perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Needs 'Test::Spelling';

Test::Spelling->import();

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

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
CLDR
CPANTS
Cloudflare
Dhivehi
IANA
LTR
MaxMind
MetaCPAN
PSEUDOCODE
Pashto
RTL
Uyghur
VWF
api
dir
fallbacks
geo
geoplugin
ip
irresolvable
lang
loopback
subnet
unresolvable
subtags

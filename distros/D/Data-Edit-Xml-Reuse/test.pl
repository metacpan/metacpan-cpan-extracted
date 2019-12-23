#!/usr/bin/perl -I/home/phil/r/salesForce/perl/ -I/home/phil/perl/cpan/DataEditXml/lib  -I/home/phil/perl/cpan/DataTableText/lib -I/home/phil/perl/cpan/DitaGBStandard/lib -I/home/phil/perl/cpan/DataEditXmlToDita/lib -I/home/phil/perl/cpan/DataEditXmlXref/lib -I/home/phil/perl/cpan/DataEditXmlLint/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/DitaPCD/lib/ -I/home/phil/perl/cpan/FlipFlop/lib/ -I/home/phil/perl/cpan/DataEditXmlReuse/lib/
#-------------------------------------------------------------------------------
# Test Data::Edit::Xml::Reuse
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------

use warnings FATAL => qw(all);
use strict;
use Data::Edit::Xml::Reuse;
Data::Edit::Xml::Reuse::test();

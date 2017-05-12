#!/usr/bin/perl -w
use lib qw{ .. ../.. ../../.. };
use Biblio::Thesaurus;
use Data::Dumper;

print $INC{ "Thesaurus.pm"} ;

$thesaurus = thesaurusLoad('animal.the');

print Dumper($thesaurus->depth_first("animal",1,"NT","USE","HAS"));
print Dumper($thesaurus->depth_first("_top_",1,"NT","USE","HAS"));
print Dumper($thesaurus->depth_first("_top_",2,"NT","USE","HAS"));
print Dumper($thesaurus->depth_first("_top_",3,"NT","USE","HAS"));

#print Dumper($thesaurus->jjdt({},"_top_"));

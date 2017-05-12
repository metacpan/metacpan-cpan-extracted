#!/usr/local/bin/perl

# This example will pull some information on various authors
# from the C. Elegans ACEDB.

use lib '../blib/lib','../blib/arch';
use Ace;
use strict vars;

use constant HOST => $ENV{ACEDB_HOST} || 'stein.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 200005;

$|=1;

print "Opening the database....";
my $db = Ace->connect(-host=>HOST,-port=>PORT) || die "Connection failure: ",Ace->error;
print "done.\n";

my @authors = $db->list('Author','S*');
print "There are ",scalar(@authors)," Author objects starting with the letter \"S\".\n";
print "The first one's name is ",$authors[0],"\n";
print "His mailing address is ",join(',',$authors[0]->Mail),"\n";
my @papers = $authors[0]->Paper;
print "He has published ",scalar(@papers)," papers.\n";
my $paper = $papers[$#papers]->pick;
print "The title of his most recent paper is ",$paper->Title,"\n";
print "The coauthors were ",join(", ",$paper->Author->col),"\n";
print "Here is all the information on the first coauthor:\n";
print (($paper->Author)[0]->fetch->asString);


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
print "Address: ",join "\n\t",$authors[0]->Address(2),"\n";

#!/usr/bin/perl

# test DBIx::TextSearch with X-Fur/text for vxn
use lib 'lib';
use DBIx::TextSearch;
use DBIx::TextSearch::mysql;

my $dbh = DBI->connect("dbi:mysql:dbname=test",
		       { RaiseError => 1,
			 PrintError => 1}) or die DBI::errstr;

#my $index = DBIx::TextSearch->new($dbh, 'stories');

my $index = DBIx::TextSearch->open($dbh, 'stories', debug => 1) || die;
#$index->FlushIndex;

my $rtn = $index->index_document(uri => 'http://seagoon/X-Fur/text/2wolves1.htm');
#my $rtn = $index->index_document(uri => 'http://search.cpan.org/author/SRPATT/DBIx-TextSearch-0.1/lib/DBIx/TextSearch.pm');
print "return stat of index_document: $rtn\n";

print "Running query\n";
my $results = $index->find_document(query  => 'wolf',
				    parser => 'simple');

print scalar(@$results), " document(s) found\n";

foreach my $doc (@$results) {
    print "Title       :  ", $doc->{title}, "\n";
    print "Description :  ", $doc->{description}, "\n";
    print "Location    :  ", $doc->{uri}, "\n";
}

$dbh->disconnect;



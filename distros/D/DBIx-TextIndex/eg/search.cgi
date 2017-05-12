#!/usr/local/bin/perl

use strict;

use CGI;
use DBI;
use DBIx::TextIndex;

my $DB = 'DBI:mysql:test';
my $DBAUTH = ':';

my $q = CGI->new;

print $q->header, $q->start_html('DBIx::TextIndex sample CGI');

print $q->start_form, 'Search ', $q->textfield('query'), $q->submit, $q->end_form;

my $doc_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;
my $index_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;

my $index = DBIx::TextIndex->new({
    doc_dbh => $doc_dbh,
    index_dbh => $index_dbh,
    collection => 'encantadas',
});

my $query = $q->param('query');

if ($q->param()) {
    my $results;
    eval {
	$results = $index->search({doc => $query});
    };
    if ($@) {
	if ( $@->isa('DBIx::TextIndex::Exception::Query') ) {
	    print $@->error;
	}
    } else {
	my $highlight = $index->highlight;

	my @doc_ids = keys %$results;

	my $ids = join ',', @doc_ids;

	my $sql = qq(select doc_id, doc from textindex_doc
		     where doc_id in ($ids));

	my $sth = $doc_dbh->prepare($sql);

	my %doc;

	$sth->execute;

	while (my $row = $sth->fetchrow_arrayref) {
	    my $doc = $row->[1];
	    $doc =~ s[\b($highlight)
		      (?=\"|\,|-|\'|\s|\.|\;|\!|\?)
		      ][
			<b><u>$1</u></b>
			]igox;
	    $doc{$row->[0]} = $doc;
	}

	$sth->finish;

	foreach my $doc_id(sort {$$results{$b} <=> $$results{$a}} keys %$results) {
	    print "Paragraph: $doc_id  Score: $$results{$doc_id}<br><p>$doc{$doc_id}</p>\n";
	}
    }


}

$index_dbh->disconnect;
$doc_dbh->disconnect;

print $q->end_html;

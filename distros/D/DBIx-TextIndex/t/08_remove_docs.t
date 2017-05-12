use strict;
use warnings;

use Test::More;
use DBI;
use DBIx::TextIndex;

if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
    plan tests => 5;
} else {
    plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
}

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

ok( defined $dbh && $dbh->ping );

my ($max_doc_id) = $dbh->selectrow_array(qq(SELECT MAX(doc_id) FROM textindex_doc));

ok( $max_doc_id == 226 );

my $index = DBIx::TextIndex->new({
    doc_dbh => $dbh,
    index_dbh => $dbh,
    collection => 'encantadas',
});

ok( ref $index eq 'DBIx::TextIndex' );

$index->remove_doc(2,3,76,105);

my $results;

my @top_docs  = (154, 0, 0, 0, 154, 0, 0);

my @terms = ('isle',
	     'greedy',
	     'ferryman',
	     'aardvark',
	     '+isle',
	     '"captain he said"',
	     'unweeting hap fordonne isle');

my @result_docs;

foreach my $term (@terms) {
    my $top_doc;
    eval {
	$results = $index->search({ doc => $term });
    };
    if ($@) {
	if (ref $@ && $@->isa('DBIx::TextIndex::Exception::Query') ) {
	    $top_doc = 0;
	} else {
	    die $@;
	}
    } else {
	my @results;
	foreach my $doc_id (sort {$results->{$b} <=> $results->{$a}} keys %$results) {
	    push @results, $doc_id;
	}
	$top_doc = $results[0];
    }
    push @result_docs, $top_doc;
}

is_deeply(\@result_docs, \@top_docs);

ok( (! $index->indexed(105)) );

$dbh->disconnect;

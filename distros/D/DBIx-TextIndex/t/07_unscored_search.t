use strict;
use warnings;

use Test::More;

BEGIN {
    if (defined $ENV{DBIX_TEXTINDEX_DSN}) {
        plan tests => 6;
    } else {
        plan skip_all => '$ENV{DBIX_TEXTINDEX_DSN} must be defined to run tests.';
    }

    use_ok('DBI');
    use_ok('DBIx::TextIndex');
}

my $dbh = DBI->connect($ENV{DBIX_TEXTINDEX_DSN}, $ENV{DBIX_TEXTINDEX_USER}, $ENV{DBIX_TEXTINDEX_PASS}, { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

ok( defined $dbh && $dbh->ping, 'Got DB connection' );

my ($max_doc_id) = $dbh->selectrow_array(qq(SELECT MAX(doc_id) FROM textindex_doc));

ok( $max_doc_id == 226, 'Sample text is in storage' );

my $index = DBIx::TextIndex->new({
    index_dbh => $dbh,
    collection => 'encantadas_named_keys',
});

ok( ref $index eq 'DBIx::TextIndex', 'New instance is correct type' );

my $results;

my @first_docs  = qw(doc_11 doc_3 doc_2 0 doc_11 doc_105 doc_2 doc_2 doc_2
        doc_13 0 doc_13 doc_6 doc_6 doc_6 0 0);

my @terms = ('isle',
	     'greedy',
	     'ferryman',
	     'aardvark',
	     '+isle',
	     '"captain he said"',
	     'unweeting hap fordonne isle',
	     'unweet*',
             'plot+',
	     '"light winds"~3',
	     '"light winds"~2',
             '"LIGHT WINDS"~3',
	     '"Lake Erie"~1',
	     '"LAKE ERIE"~1',
	     '"lake erie"~1',
	     '-isle',
	     '-isle',
             );

my @result_docs;

foreach my $term (@terms) {
    my $first_doc;
    eval {
	$results = $index->unscored_search({ doc => $term });
    };
    if ($@) {
	if (ref $@ && $@->isa('DBIx::TextIndex::Exception::Query') ) {
	    $first_doc = 0;
	} else {
	    die $@ . "\n\n" . $@->trace;
	}
    } else {
	$first_doc = $results->[0];
    }
    push @result_docs, $first_doc;

}

is_deeply(\@result_docs, \@first_docs,
        'Unscored searches matched expected results');

$dbh->disconnect;

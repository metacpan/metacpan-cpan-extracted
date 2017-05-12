#!/usr/bin/perl

use strict;

use CGI;
use DBI;
use DBIx::TextIndex;
use HTML::Highlight;

my $DB = 'DBI:mysql:test';
my $DBAUTH = ':';

my $q = CGI->new;

# NOTE: CGI.pm produces headers that mangle czech characters badly

print "Content-Type: text/html\n\n";

print <<EOT;
<html>
<head>
<title>html_search</title>
</head>
<body>
EOT

print $q->start_form, 'Search ',
	$q->textfield('query'),
    $q->br,
    'Context size',
    $q->textfield(-size => 3, -name => 'context_size'),
    $q->br,
    $q->submit,
    $q->end_form;

my $doc_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;
my $index_dbh = DBI->connect($DB, split(':', $DBAUTH, 2)) or die $DBI::errstr;

my $index = DBIx::TextIndex->new({
    doc_dbh => $doc_dbh,
    index_dbh => $index_dbh,
    collection => 'encantadas'
});

my $query = $q->param('query');

if ($q->param()) {
    my $results = $index->search({doc => $query});

    if (ref $results) {

        my ($hl_words, $hl_wildcards) = $index->html_highlight;
        my $hl = new HTML::Highlight (
            words => $hl_words,
            wildcards => $hl_wildcards,
            czech_language => 0
        );

        my @doc_ids = keys %$results;
        my $ids = join ',', @doc_ids;

        my $sql = qq(select doc_id, doc from textindex_doc
                where doc_id in ($ids));

        my $sth = $doc_dbh->prepare($sql);
        my %doc;
        my %context;
        $sth->execute;
		my $context_size = $q->param('context_size') ? $q->param('context_size') : 240;
        while (my $row = $sth->fetchrow_arrayref) {
            $doc{$row->[0]} = $hl->highlight($row->[1]);
            $context{$row->[0]} = $hl->preview_context($row->[1], $context_size);
        }

        $sth->finish;

        print "<hr />\n";
        print "<h1>Context of the query words in resulting docs:</h1>\n";

        foreach my $doc_id(sort {$$results{$b} <=> $$results{$a}} keys %$results) {
            print "Paragraph: $doc_id  Score: $$results{$doc_id}<br>\n";
            print "<ul>\n";
            foreach my $word_context (@{$context{$doc_id}}) {
                my $hl_context = $hl->highlight($word_context);
                print "<li>$hl_context</li>\n";
            }
            print "</ul>\n";
        }

        print "<hr />\n";
        print "<h1>Content of resulting docs:</h1>\n";

        print "<ul>\n";
        foreach my $doc_id(sort {$$results{$b} <=> $$results{$a}} keys %$results) {
            print "<li>Paragraph: $doc_id  Score: $$results{$doc_id}<br><p>$doc{$doc_id}</p><br></li>\n";
        }
        print "</ul>\n";

    }
    else {
		# Search error
		print "\n$results\n\n";
    }
}
$index_dbh->disconnect;
$doc_dbh->disconnect;

print $q->end_html;

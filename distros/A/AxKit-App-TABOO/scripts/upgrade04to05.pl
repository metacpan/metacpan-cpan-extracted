#!/usr/bin/perl -w

# This script updates the stories and comments from the 0.4 database,
# which used Textile, to 0.5, that uses TinyMCE, i.e. HTML.
# It doesn't do articles.

# It works directly against the database, not using the data objects of TABOO.

my $dsn = 'dbi:Pg:dbname=taboodemo';
my $pguser = 'taboodemo';
my $pgpassword ='hk987JKBgui';


# Here begins the code.

use DBI;
use Formatter::HTML::Textile;
use Encode;
use HTML::Entities;

my $dbh = DBI->connect($dsn, $pguser, $pgpassword);

my $all  = $dbh->selectall_hashref('SELECT storyname,minicontent,content FROM stories;', 'storyname');

foreach my $story (values(%{$all})) {
  my $formatter1 = Formatter::HTML::Textile->format(encode_entities(decode_utf8(${$story}{content})));
  $formatter1->charset('utf-8');
  $formatter1->char_encoding(0);
  my $content = $formatter1->fragment;
  
  my $formatter2 = Formatter::HTML::Textile->format(encode_entities(decode_utf8(${$story}{minicontent})));
  $formatter2->charset('utf-8');
  $formatter2->char_encoding(0);
  my $minicontent = $formatter2->fragment;
  
  $dbh->do("UPDATE stories SET minicontent=?,content=? WHERE storyname=?", {}, ($minicontent,$content,${$story}{storyname}));
}


my $allc  = $dbh->selectall_arrayref('SELECT content FROM comments;');
foreach my $comment (@{$allc}) {
  my $formatter1 = Formatter::HTML::Textile->format(encode_entities(decode_utf8(${$comment}[0])));
  $formatter1->charset('utf-8');
  $formatter1->char_encoding(0);
  my $content = $formatter1->fragment;
  $dbh->do("UPDATE comments SET content=? WHERE content=?", {}, ($content,${$comment}[0]));
}

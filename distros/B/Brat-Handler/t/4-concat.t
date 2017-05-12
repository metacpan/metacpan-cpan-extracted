use strict;
use warnings;

use Test::More tests => 11;

use Brat::Handler;

my $brat = Brat::Handler->new();
ok( defined($brat) && ref $brat eq 'Brat::Handler',     'Brat::Handler->new() works' );

$brat->loadDir('examples');

my $concatAnn = $brat->concat();
ok(ref($concatAnn) eq "Brat::Handler::File", "concat returns correct object");
# warn "term: " . $concatAnn->_maxTermId . "\n";
ok($concatAnn->_maxTermId == (21+36+26), "new max term Id ok");
# warn "attr: " . $concatAnn->_maxAttributeId . "\n";
ok($concatAnn->_maxAttributeId == (1+1), "new max attribute Id ok");
# warn "rel: " . $concatAnn->_maxRelationId . "\n";
ok($concatAnn->_maxRelationId == (1+11), "new max relation Id ok");

my $ann = $concatAnn->getAnnotationList;
# warn "$ann\n";
# warn scalar(split /\n/, $ann) . "\n";
ok((defined $ann) && (scalar(split /\n/, $ann) == (21+48+28)), "concat works");

# warn $concatAnn->_textSize . "\n";
ok($concatAnn->_textSize == 2970, 'text size ok');

$ann = $concatAnn->getAnnotationList;
# print STDERR "\n$ann\n" . scalar(split /\n/, $ann) . "\n";
ok((defined $ann) && (scalar(split /\n/, $ann) == 97), "getAnnotationList works");
# $bratfile->print('-');


my $termList = $concatAnn->getTermList;
ok((defined $termList) && (scalar(split /\n/, $termList) == 21+36+26), "getTermList works");
# $concatAnn->printTermList("-");

my $relationList = $concatAnn->getRelationList;
ok((defined $relationList) && (scalar(split /\n/, $relationList) == 11+1), "getRelationList works");
# $concatAnn->printRelationList("-");

my $stats = $concatAnn->getStats;
ok((defined $stats) && (scalar(split /\n/, $stats) == 6), "getStats works");
# $concatAnn->printStats("-");

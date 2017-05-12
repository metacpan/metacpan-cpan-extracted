use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 14;
}
use XML::NestArray qw(:all);
use XML::NestArray::ITextParser;
use XML::NestArray::Base;
use Bio::XML::Sequence::Transform;

use FileHandle;
use strict;
use Data::Dumper;

my $game = xml2tree(@ARGV);
print "parsed!\n";
my $nudata = Node(top=>[[blah=>1]]);
my $T = Bio::XML::Sequence::Transform->new();
$T->data($nudata);

$T->from_game($game);
my @sfgenes = grep { $_->sget_ftype eq "gene" } narr_findnode($nudata, "feature");
my @sftrs = grep { $_->sget_ftype eq "transcript" } narr_findnode($nudata, "feature");
map {$T->get_loc($_)} @sfgenes;
map {my @utr = $T->implicit_utr_from_transcript($_);map {print tree2xml($_)} @utr} @sftrs;
print tree2xml($nudata);
die;

my $p = XML::NestArray::ITextParser->new;
my $h = XML::NestArray::Base->new;
$p->handler($h);

my $fn = "t/data/bf.txt";
$p->parse($fn);

my $data = $h->tree;
$T->data($data);

my $B = "bio";

#my ($pp) = narr_tmatch($data, "feature", "dbxref", "FBpp5");
#my @subjfeatures = $T->get_subjfeatures("", $pp);
#print tree2xml($subjfeatures[0]);die;

my ($gene) = narr_tmatch($data, "feature", "dbxref", "FBal99");
print tree2xml($gene);
$T->get_loc($gene);
print tree2xml($gene);
my ($tr) = narr_tmatch($data, "feature", "dbxref", "FBsf203");
$T->get_loc($tr);
print tree2xml($tr);

($tr) = narr_tmatch($data, "feature", "dbxref", "FBtr15");
print "getting UTR..\n";
my @utr = $T->implicit_utr_from_transcript($tr);
map {print tree2xml($_)} @utr;
ok(1);
$T->mk_all($gene);
#my ($nu) = $T->tf_features($gene);
my ($gene_ent) = narr_findnode($data, "gene");
my ($nu) = $T->tf_gene($gene_ent);
print tree2xml($nu);




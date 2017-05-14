# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Chromosome.t'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..31\n"; }
END {print "not ok 1\n" unless $loaded;}
# use Carp;
use blib;

use lib 't';
use TestDB qw($ECOLI_SPECIES $ECOLI_CHROM $TEST_USERSEC $TEST_GROUPSEC
	      $TEST_CONTACT $TEST_USF $TEST_DB $TEST_BLAST result);
use Bio::Genex;
use Bio::Genex::Chromosome;
use Bio::Genex::BlastHits;
use Bio::Genex::ExternalDatabase;
use Bio::Genex::Contact;
use Bio::Genex::Species;
use Bio::Genex::UserSec;
use Bio::Genex::GroupSec;
use Bio::Genex::UserSequenceFeature;
use Bio::Genex::ControlledVocab;
use Bio::Genex::XMLUtils;
use XML::DOM;
$loaded = 1;
my $i = 1;
print "ok ", $i++, "\n";

######################### End of black magic.

my $doc;
my @a;
# test creating a empty document
$doc = Bio::Genex::GeneXML->new(empty=>1);
result(!scalar (@a = $doc->getElementsByTagName('header')) &&
       $doc->getDocumentElement->getAttribute('cvs_id') &&
       !defined $doc->getDoctype, $i); $i++;

# use Bio::Genex::GeneXML to create a full document
$doc = Bio::Genex::GeneXML->new();
my $version = $doc->getEntity('VERSION');
result(defined $version && $version->getValue() =~ /genexml\.dtd/, $i); $i++;

# test creating a document without the DTD in the DOCTYPE
# but with the rest of the structure filled in
$doc = Bio::Genex::GeneXML->new(no_dtd=>1);
result(scalar (@a = $doc->getElementsByTagName('header')) &&
       scalar (@a = $doc->getElementsByTagName('misc_list')) &&
       scalar (@a = $doc->getElementsByTagName('controlled_vocabulary_list')) &&
       scalar (@a = $doc->getElementsByTagName('genex_info')) &&
       $doc->getDocumentElement->getAttribute('cvs_id') &&
       !defined $doc->getDoctype, $i); $i++;

# ensure the XML::DOM::Document is in ->_doc()
result(ref($doc) && 
       ref($doc->_doc) && 
       $doc->_doc->isa('XML::DOM::Document'), $i); $i++;

# ensure the XML::DOM::Parser is in ->_parser()
result(ref($doc) && 
       ref($doc->_parser) && 
       $doc->_parser->isa('XML::DOM::Parser'), $i); $i++;

# ensure it's a Bio::Genex::GeneXML
result(ref($doc) && $doc->isa('Bio::Genex::GeneXML'), $i); $i++;

#ensure we can get the <GENEXML> node
my $node;
eval {
  $node = $doc->get_genexml_node();
  $doc->assert_element($node,'GENEXML');
};
result(!$@,$i); $i++;

#ensure we can get the <header> node
eval {
  $node = $doc->get_header_node();
  $doc->assert_element($node,'header');
};
result(!$@,$i); $i++;

#ensure we can get the <misc_list> node
eval {
  $node = $doc->get_misc_list_node();
  $doc->assert_element($node,'misc_list');
};
result(!$@,$i); $i++;

#ensure we can get the <genex_info> node
eval {
  $node = $doc->get_genex_info_node();
  $doc->assert_element($node,'genex_info');
};
result(!$@,$i); $i++;

#ensure we can get the <controlled_vocabulary_list> node
eval {
  $node = $doc->get_vocabulary_list_node();
  $doc->assert_element($node,'controlled_vocabulary_list');
};
result(!$@,$i); $i++;

#ensure we can get the <header> *_list sub-node
eval {
  $node = $doc->create_element('foo_list');
  my $header = $doc->get_header_node();
  $header->appendChild($node);
  $node = $doc->get_header_list_node('foo_list');
  $doc->assert_element($node,'foo_list');
};
result(!$@,$i); $i++;

#ensure we can get the <genex_info> *_list sub-node
eval {
  $node = $doc->create_element('bar_list');
  my $genex_info = $doc->get_genex_info_node();
  $genex_info->appendChild($node);
  $node = $doc->get_genex_info_list_node('bar_list');
  $doc->assert_element($node,'bar_list');
};
result(!$@,$i); $i++;

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $s = Bio::Genex::Chromosome->new(id=>$ECOLI_CHROM);
eval {
  my $n = $s->db2xml(undef);
};

# make sure we die if not passed a XML::DOM::Document handle
result($@, $i); $i++;

# make sure this is valid
my $n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;
# print STDERR $n->toString(), "\n";
# print STDERR $doc->toString(), "\n";

# ensure we can create multiple elements from the same doc handle
$n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;

$s = Bio::Genex::Species->new(id=>$ECOLI_SPECIES);
$n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;

# we test writing a usf file
my $usf_file_name = './.foo.xml';
END {unlink $usf_file_name}
$doc->directory('./');		# tell the $doc where to create
$doc->file_name_prefix('.foo');

# only do a debug run
$Bio::Genex::XMLUtils::DEBUG = 1;
$n = $s->db2xml($doc, $usf_file_name);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;

Bio::Genex::Contact->all2xml($doc);
($n) = $doc->getElementsByTagName('contact_list');
my (@contacts) = $doc->getElementsByTagName('contact');
result(defined $n && 
       ref($n) && 
       $n->isa('XML::DOM::Element') &&
       $n->getTagName() eq 'contact_list' &&
       scalar @contacts > 1, $i); $i++;

$s = Bio::Genex::Contact->new(id=>$TEST_CONTACT);
$n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;
# print STDERR "\n", $n->toString(), "\n";

$s = Bio::Genex::UserSec->new(id=>$TEST_USERSEC);
$n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;

$s = Bio::Genex::GroupSec->new(id=>$TEST_GROUPSEC);
$n = $s->db2xml($doc);
result(defined $n && 
       ref($n) && 
       $n->isa('XML::DOM::Element'), $i); $i++;

# ensure there are user sub-elements
my @users = $n->getElementsByTagName('user');
result(scalar @users == 1, $i); $i++;
print STDERR "\n", $n->toString(), "\n";

# ensure we return undef on an unimplemented class
$s = Bio::Genex::UserSequenceFeature->new(id=>$TEST_USF);
result(!defined $s->db2xml($doc), $i); $i++;

#test a single vocab
my @vocabs = Bio::Genex::ControlledVocab->get_vocabs();
$n = Bio::Genex::ControlledVocab->db2xml($doc,$vocabs[0]);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;

# test all vocabs
Bio::Genex::ControlledVocab->all2xml($doc,$vocabs[0]);
my (@cv_nodes) = $doc->getElementsByTagName('controlled_vocabulary');
result(defined $n && 
       ref($n) && 
       $n->isa('XML::DOM::Element') &&
       $n->getTagName() eq 'controlled_vocabulary' &&
       scalar @cv_nodes == scalar @vocabs, $i); $i++;

# print STDERR "\n", $doc->toString(), "\n";

$s = Bio::Genex::ExternalDatabase->new(id=>$TEST_DB);
$n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;


$s = Bio::Genex::BlastHits->new(id=>$TEST_BLAST);
$n = $s->db2xml($doc);
result(defined $n && ref($n) && $n->isa('XML::DOM::Element'), $i); $i++;

# test creating an empty USF document
$doc = Bio::Genex::GeneXML::USF->new(empty=>1);
result(!defined $doc->getDoctype &&
       $doc->getDocumentElement->getAttribute('cvs_id') &&
       !defined $doc->getDoctype, $i); $i++;

# use Bio::Genex::GeneXML::USF to create a full document
$doc = Bio::Genex::GeneXML::USF->new();
$version = $doc->getEntity('VERSION');
result(defined $version && $version->getValue() =~ /usf\.dtd/, $i); $i++;

__END__
package Bio::Genex::GroupLink;
package Bio::Genex::USF_ExternalDBLink;

package Bio::Genex::AL_Spots;
package Bio::Genex::AM_FactorValues;
package Bio::Genex::AM_Spots;
package Bio::Genex::AM_SuspectSpots;
package Bio::Genex::ArrayLayout;
package Bio::Genex::ArrayMeasurement;
package Bio::Genex::Citation;
package Bio::Genex::ControlledVocab;
package Bio::Genex::ExperimentFactors;
package Bio::Genex::ExperimentSet;
package Bio::Genex::HotSpots;
package Bio::Genex::Protocol;
package Bio::Genex::Sample;
package Bio::Genex::SampleProtocols;
package Bio::Genex::Scanner;
package Bio::Genex::Software;
package Bio::Genex::SpotLink;
package Bio::Genex::Spotter;
package Bio::Genex::TL_FactorValues;
package Bio::Genex::TreatmentLevel;
package Bio::Genex::Treatment_AMs;

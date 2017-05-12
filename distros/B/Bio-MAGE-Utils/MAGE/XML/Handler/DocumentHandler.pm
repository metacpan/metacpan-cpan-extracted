###############################################################################
# Bio::MAGE::XML::Handler::DocumentHandler package: Callbacks to process elements as they come
#                           from the SAX parser
###############################################################################
package Bio::MAGE::XML::Handler::DocumentHandler;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlDocumentHandler Bio::MAGE::XML::Handler);

sub start_element {
  my ($self,$localname,$attrs) = @_;
  my %attrs = $attrs->to_hash();
  Bio::MAGE::XML::Handler::start_element($self,$localname,\%attrs);
}

sub end_element {
  Bio::MAGE::XML::Handler::end_element(@_);
}

sub characters {
  Bio::MAGE::XML::Handler::characters(@_);
}

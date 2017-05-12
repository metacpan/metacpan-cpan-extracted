###############################################################################
# ContentHandler package: Callbacks to process elements as they come
#                           from the SAX2 parser
###############################################################################
package Bio::MAGE::XML::Handler::ContentHandler;
use strict;
use vars qw(@ISA);
@ISA = qw(XML::Xerces::PerlContentHandler Bio::MAGE::XML::Handler);

sub start_element {
  my ($self,$uri,$localname,$qname,$attrs) = @_;

  my %attrs = $attrs->to_hash();
  foreach my $key (keys %attrs) {
    $attrs{$key} = $attrs{$key}->{value};
  }
  Bio::MAGE::XML::Handler::start_element($self,$localname,\%attrs);
}

sub end_element {
  my ($self,$uri,$localname,$qname) = @_;
  Bio::MAGE::XML::Handler::end_element($self,$localname);
}

sub characters {
  Bio::MAGE::XML::Handler::characters(@_);
}

1;

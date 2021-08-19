package Catmandu::AlephX::XPath::Helper;
use Catmandu::Sane;
use XML::LibXML;
use XML::LibXML::XPathContext;
use Catmandu::Util qw(:is io);
use Exporter qw(import);
our @EXPORT_OK=qw(get_children xpath);
our %EXPORT_TAGS = (all=>[@EXPORT_OK]);

our $VERSION = "1.073";

sub get_children {
  my($xpath,$is_hash) = @_;

  my $hash = {};

  if($xpath){
    for my $child($xpath->find('child::*')->get_nodelist()){
      my $name = $child->nodeName();
      my $value = $child->textContent();
      if($is_hash){
        $hash->{ $name } = $value;
      }else{
        $hash->{$name} //= [];
        push @{ $hash->{$name} },$value if is_string($value);
      }
    }
  }

  $hash;
}

sub xpath {
  my $str = $_[0];
  my $xpath;
  if(is_scalar_ref($str)){
    my $xml = XML::LibXML->load_xml(IO => io($str));
    $xpath = XML::LibXML::XPathContext->new($xml);
  }elsif(-f $str){
    my $xml = XML::LibXML->load_xml(location => $str);
    $xpath = XML::LibXML::XPathContext->new($xml);
  }elsif(is_glob_ref($str)){
    my $xml = XML::LibXML->load_xml(IO => io($str));
    $xpath = XML::LibXML::XPathContext->new($xml);
  }
  return $xpath;
}

1;

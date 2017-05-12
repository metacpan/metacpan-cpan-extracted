package App::CSE::File::ApplicationXml;
$App::CSE::File::ApplicationXml::VERSION = '0.012';
use Moose;
extends qw/App::CSE::File/;

use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

sub _build_content{
  my ($self) = @_;
  my $raw_content = $self->raw_content();
  unless( defined($raw_content) ){ return undef; }

  my $dom = eval{ $self->cse()->xml_parser()->load_xml( string => $raw_content,
                                                        load_ext_dtd => 0,
                                                        validation => 0
                                                      );
                };
  unless( $dom ){
    $LOGGER->debug($self->file_path()." is not a valid XML file (XML ERROR is $@). Indexing as standard content");
    return $self->next::method();
  }
  # We need a string, not bytes.
  $dom->setEncoding('UTF-8');
  my $bytes = $dom->toString();
  return Encode::decode($dom->actualEncoding(), $dom->toString());
}


__PACKAGE__->meta->make_immutable();

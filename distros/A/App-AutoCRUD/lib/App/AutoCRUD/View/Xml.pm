package App::AutoCRUD::View::Xml;

use 5.010;
use strict;
use warnings;

use Moose;
extends 'App::AutoCRUD::View';

use XML::Simple qw/XMLout/;
use Encode      qw/encode_utf8/;

use namespace::clean -except => 'meta';

has 'xml_options' => ( is => 'bare', isa => 'HashRef',
                       default => sub {{
   KeepRoot => 1,
   XMLDecl  => "<?xml version='1.0' encoding='UTF-8'?>",
 }} );

sub render {
  my ($self, $data, $context) = @_;

  my $xml = XMLout({data => $data}, %{$self->{xml_options}});

  return [200, ['Content-type' => 'text/xml'], [encode_utf8($xml)] ];
}

1;


__END__




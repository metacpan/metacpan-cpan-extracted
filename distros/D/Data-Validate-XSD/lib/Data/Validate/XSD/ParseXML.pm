package Data::Validate::XSD::ParseXML;

use strict;

=head1 NAME

Data::Validate::XSD::ParseXML - Parse an XML file into a data structure for validation

=head1 DESCRIPTION

  Please install XML::SAX to use this module.

  Used internally by Data::Validate::XSD to load xml files for both xsd definitions
  and xml data. For the xml data we use a simple conversion metric which treats each
  tag level as an hash reference and multiple tags witht he same name as an array reference.

  For the xsd defininitions we use the same method as the data to aquire the data but then
  It's converted into a simpler format and any features which arn't available will produce
  warnings.

=cut

use XML::SAX::ParserFactory;

=head2 I<$parser>->new( $xml_string )

  Create a new parser object to parse xml files.

=cut
sub new {
	my ($class, $xml) = @_;
	return bless { xml => $xml }, $class;
}

=head2 I<$parser>->data( )

  Return the parsed data structure.

=cut
sub data {
	my ($self) = @_;

	my $handler = Data::Validate::XSD::ParseXML::Parser->new();
	my $parser = XML::SAX::ParserFactory->parser( Handler => $handler );
	$parser->parse_string( $self->{'xml'} );

	return $handler->{'root'};
}

=head2 I<$parser>->definition( )

  Convert the data into a definition, assume it's in xsd format.

=cut
sub definition {
	my ($self) = @_;
	my $data   = $self->data();
	my $result = {};

	if($data) {
		$data = $data->{'schema'};
		$self->_decode_complexes( $data->{'complexType'}, $result );
		$self->_decode_simples( $data->{'simpleType'}, $result );

		$result->{'root'} = $self->_decode_elements($data->{'element'}, $result);
	}

	return $result;
}

sub _decode_complexes {
	my ($self, $data, $result) = @_;

	$data = [ $data ] if ref($data) ne 'ARRAY';

	foreach my $d (@{$data}) {
		my $name = $d->{'_name'};
		$self->_decode_complex( $name, $d, $result );
	}
}

sub _decode_complex {
	my ($self, $name, $data, $result) = @_;

	my $elements;
	if($data->{'element'}) {
		$elements = $self->_decode_elements( $data->{'element'}, $result );
	}

	if($data->{'or'}) {
		
	}

	$result->{'complexTypes'}->{$name} = $elements;

}

sub _decode_elements {
	my ($self, $data, $result) = @_;

	$data = [ $data ] if ref($data) ne 'ARRAY';
	my @els;

	foreach my $element (@{$data}) {
		push @els, $self->_decode_element( $element, $result );
	}

	return \@els;
}

sub _decode_simples {
	my ($self, $data, $result) = @_;
	foreach my $d (@{$data}) {
		#my $name = '';
		#$self->_decode_simple( $name, $d, $data );
	}
}

sub _decode_element {
	my ($self, $data, $result) = @_;
	my $element = {};

	if($data->{'complexType'}) {
		my $name = $self->_random_name;
		$element->{'type'} = $name;
		$self->_decode_complex( $name, delete($data->{'complexType'}), $result );
	} elsif($data->{'_type'}) {
		my ($ns, $type) = split(':', delete($data->{'_type'}));
		$element->{'type'} = $type ? $type : $ns;
	}

	foreach my $key (keys(%{$data})) {
		if($key =~ /^\_(.+)$/) {
			$element->{$1} = $data->{$key};
		}
	}

	return $element;
}

sub _random_name {
	my ($self) = @_;
	my @charset = ( 0 .. 9, 'a' .. 'z', 'A' .. 'Z' );

	my $result = '';

	$result .= $charset[int(rand() * @charset)] for(1..10);

	return $result;
}

package Data::Validate::XSD::ParseXML::Parser;

use base qw(XML::SAX::Base);

=head2 $parser->new( )

  Create a new parser object.

=cut
sub new
{
	my ($class) = @_;
	my $root = {};
	my $self = bless {
		root    => $root,
		current => $root,
		parents => [ ],
		count   => 0,
	}, $class;
	return $self;
}

=head1 SAX PARSING

=head2 $parser->start_element( $node )

  Start a new xml element

=cut
sub start_element
{
	my ($self, $node) = @_;

	my $name = $node->{'LocalName'};
	my $atrs = $node->{'Attributes'};
	my $ns   = $node->{'Prefix'};
	my $c    = $self->{'current'};
	my $new  = {};

	if(not $c->{$name}) {
		$c->{$name} = $new;
	} else {
		if(ref($c->{$name}) eq 'ARRAY') {
			push @{$c->{$name}}, $new;
		} else {
			$c->{$name} = [ $c->{$name}, $new ];
		}
	}
	push @{$self->{'parents'}}, $c;
	$self->{'count'}++;
	$self->{'name'} = $name;
	$self->{'parent'} = $c;
	$self->{'current'} = $new;

	foreach my $a (keys(%{$atrs})) {
		my $attribute = $atrs->{$a};
		if($attribute->{'Name'} ne 'xmlns') {
			$self->{'current'}->{'_'.$attribute->{'LocalName'}} = $attribute->{'Value'};
		}
	}

}

=head2 $parser->end_element( $element )

  Ends an xml element

=cut
sub end_element
{
	my ($self, $element) = @_;
	$self->{'count'}++;
	$self->{'current'} = $self->{'parent'};
	pop @{$self->{'parents'}};
	$self->{'parent'} = $self->{'parents'}->[$#{$self->{'parents'}}];
}

=head2 $parser->characters()

  Handle part of a cdata by concatination

=cut
sub characters
{
	my ($self, $text) = @_;
	my $t = $text->{'Data'};
	if($t =~ /\S/) {
		my $p = $self->{'parent'};
		my $c = $p->{$self->{'name'}};
		if(ref($c) eq 'HASH') {
			if(%{$c}) {
				if($c->{'+data'}) {
					$c->{'+data'} .= $t;
				} else {
					$c->{'+data'} = $t;
				}
			} else {
				$p->{$self->{'name'}} = $t;
			}
		} elsif(ref($c) eq 'ARRAY') {
			pop @{$c} if ref($c->[$#{$c}]) eq 'HASH' and not %{$c->[$#{$c}]};
			push @{$c}, $t;
		} else {
			$p->{$self->{'name'}} .= $t;
		}
	}
}


=head1 COPYRIGHT

 Copyright, Martin Owens 2007-2008, Affero General Public License (AGPL)

 http://www.fsf.org/licensing/licenses/agpl-3.0.html

=head1 SEE ALSO

L<Data::Validate::XSD>,L<XML::SAX>

=cut
1;

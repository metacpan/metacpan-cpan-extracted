package Data::AMF::Parser::AMF3;
use strict;
use warnings;

use Data::AMF::IO;
use UNIVERSAL::require;

# ----------------------------------------------------------------------
# Class Constants
# ----------------------------------------------------------------------

use constant AMF3_TYPES =>
[
	'undefined',
	'null',
	'false',
	'true',
	'integer',
	'number',
	'string',
	'xml_document',
	'date',
	'array',
	'object',
	'xml',
	'byte_array',
];

use constant AMF3_INTEGER_MAX => "268435455";

# ----------------------------------------------------------------------
# Class Methods
# ----------------------------------------------------------------------

sub parse
{
	my ($class, $data) = @_;
	
	my $self = $class->new;
	$self->{'io'} = Data::AMF::IO->new(data => $data);
	
	return $self->read;
}

# ----------------------------------------------------------------------
# Constructor
# ----------------------------------------------------------------------

sub new
{
	my $class = shift;
	my $self = bless {
		io => undef,
		class_member_defs => {},
		stored_strings => [],
		stored_objects => [],
		stored_defs => [],
		@_
	}, $class;
	return $self;
}

# ----------------------------------------------------------------------
# Properties
# ----------------------------------------------------------------------

sub io { return $_[0]->{'io'} }

# ----------------------------------------------------------------------
# Methods
# ----------------------------------------------------------------------

sub read
{
	my $self = shift;
	
	my @res;
	
	while (defined(my $marker = $self->io->read_u8))
	{
		my $method = 'read_' . AMF3_TYPES->[$marker] or die;
		push @res, $self->$method();
	}
	
	@res;
}

sub read_one
{
	my $self = shift;

	my $marker = $self->io->read_u8;
	return unless defined $marker;
	
	my $method = 'read_' . AMF3_TYPES->[$marker] or die;
	return $self->$method();
}

sub read_undefined
{
	return undef;
}

sub read_null
{
	Data::AMF::Type::Null->require;
	return Data::AMF::Type::Null->new;
}

sub read_false
{
	Data::AMF::Type::Boolean->require;
	return Data::AMF::Type::Boolean->new(0);
}

sub read_true
{
	Data::AMF::Type::Boolean->require;
	return Data::AMF::Type::Boolean->new(1);
}

sub read_integer
{
	my $self = shift;
	
	my $n = 0;
	my $b = $self->io->read_u8 || 0;
	my $result = 0;
	
	while (($b & 0x80) != 0 && $n < 3)
	{
		$result = $result << 7;
		$result = $result | ($b & 0x7f);
		$b = $self->io->read_u8 || 0;
		$n++;
	}
	
	if ($n < 3)
	{
		$result = $result << 7;
		$result = $result | $b;
	}
	else
	{
		# Use all 8 bits from the 4th byte
		$result = $result << 8;
		$result = $result | $b;
		
		# Check if the integer should be negative
		if ($result > AMF3_INTEGER_MAX)
		{
			# and extend the sign bit
			$result -= (1 << 29);
		}
	}
		
	return $result;
}

sub read_number
{
	my $self = shift;
	return $self->io->read_double;
}

sub read_string
{
	my $self = shift;
	
	my $type = $self->read_integer();
	my $isReference = ($type & 0x01) == 0;

	if ($isReference)
	{
		my $reference = $type >> 1;
		if ($reference < @{ $self->{'stored_strings'} })
		{
			if (not defined $self->{'stored_strings'}->[$reference])
			{
				die "Reference to non existant object at index #{$reference}.";
			}
			
			return $self->{'stored_strings'}->[$reference];
		}
		else
		{
			die "Reference to non existant object at index #{$reference}.";
		}
	}
	else
	{
		my $length = $type >> 1;
		my $str = '';
		
		if ($length > 0)
		{
			$str = $self->io->read($length);
			push @{ $self->{'stored_strings'} }, $str;
		}
		
		return $str;
	}
}

sub read_xml_document
{
	my $self = shift;
	my $type = $self->read_integer();
	my $length = $type >> 1;
	my $obj = $self->io->read($length);
	push @{ $self->{'stored_objects'} }, $obj;
	return $obj;
}

sub read_date
{
	my $self = shift;
	
	my $type = $self->read_integer();
	my $isReference = ($type & 0x01) == 0;
	
	if ($isReference)
	{
		my $reference = $type >> 1;
		if ($reference < @{ $self->{'stored_objects'} })
		{
			if (not defined $self->{'stored_objects'}->[$reference])
			{
				die "Reference to non existant object at index #{$reference}.";
			}
			
			return $self->{'stored_objects'}->[$reference];
		}
		else
		{
			die "Reference to non existant object at index #{$reference}.";
		}
	}
	else
	{
		my $epoch = $self->io->read_double / 1000;
		
		DateTime->require;
		my $datetime = DateTime->from_epoch( epoch => $epoch );
		
		push @{ $self->{'stored_objects'} }, $datetime;
		return $datetime;
	}
}

sub read_array
{
	my $self = shift;
	
	my $type = $self->read_integer();
	my $isReference = ($type & 0x01) == 0;
	
	if ($isReference)
	{
		my $reference = $type >> 1;
		if ($reference < @{ $self->{'stored_objects'} })
		{
			if (not defined $self->{'stored_objects'}->[$reference])
			{
				die "Reference to non existant object at index #{$reference}.";
			}

			return $self->{'stored_objects'}->[$reference];
		}
		else
		{
			die "Reference to non existant object at index #{$reference}.";
		}
	}
	else
	{
		my $length = $type >> 1;
		my $key = $self->read_string();
		my $array;
		
		if ($key ne '')
		{
			$array = {};
			push @{ $self->{'stored_objects'} }, $array;
			
			while($key ne '')
			{
				my $value = $self->read_one();
				$array->{$key} = $value;
				$key = $self->read_string();
			}
			
			for (0 .. $length - 1)
			{
				$array->{$_} = $self->read_one();
			}
		}
		else
		{
			$array = [];
			push @{ $self->{'stored_objects'} }, $array;
			
			for (0 .. $length - 1)
			{
				push @{ $array }, $self->read_one();
			}
		}
		
		return $array;
	}
}

sub read_object
{
	my $self = shift;
	
	my $type = $self->read_integer();
	my $isReference = ($type & 0x01) == 0;
	
	if ($isReference)
	{
		my $reference = $type >> 1;
		
		if ($reference < @{ $self->{'stored_objects'} })
		{
			if (not defined $self->{'stored_objects'}->[$reference])
			{
				die "Reference to non existant object at index #{$reference}.";
			}
			
			return $self->{'stored_objects'}->[$reference];
		}
		else
		{
			warn "Reference to non existant object at index #{$reference}.";
		}
	}
	else
	{
		my $class_type = $type >> 1;
		my $class_is_reference = ($class_type & 0x01) == 0;
		my $class_definition;
		
		if ($class_is_reference)
		{
			my $class_reference = $class_type >> 1;
			
			if ($class_reference < @{ $self->{'stored_defs'} })
			{
				$class_definition = $self->{'stored_defs'}->[$class_reference];
			}
			else
			{
				die "Reference to non existant object at index #{$class_reference}.";
			}
		}
		else
		{
			my $as_class_name = $self->read_string();
			my $externalizable = ($class_type & 0x02) != 0;
			my $dynamic = ($class_type & 0x04) != 0;
			my $attr_count = $class_type >> 3;
			
			my $members = [];
			for (1 .. $attr_count)
			{
				push @{ $members }, $self->read_string();
			}
			
			$class_definition =
			{
				"as_class_name" => $as_class_name,
				"members" => $members,
				"externalizable" => $externalizable,
				"dynamic" => $dynamic
			};
			
			push @{ $self->{'stored_defs'} }, $class_definition;
		}
		
		my $action_class_name = $class_definition->{'as_class_name'};
		my ($skip_mapping, $obj);
		
		if ($action_class_name && $action_class_name =~ /flex\.messaging/)
		{
			$obj = {};
			$obj->{'_explicitType'} = $action_class_name;
			$skip_mapping = 1;
		}
		else
		{
			$obj = {};
			$skip_mapping = 0;
		}
		
		my $obj_position = @{ $self->{'stored_objects'} };
		push @{ $self->{'stored_objects'} }, $obj;
		
		if ($class_definition->{'externalizable'})
		{
			$obj = $self->read_one();
		}
		else
		{
			for my $key (@{ $class_definition->{'members'} })
			{
				$obj->{$key} = $self->read_one();
			}
		}
		
		if ($class_definition->{'dynamic'})
		{
			my $key;
			while (($key = $self->read_string()) && $key ne '') {
				$obj->{$key} = $self->read_one();
			}
		}
		
		return $obj;
	}
}

sub read_xml
{
	my $self = shift;
	my $type = $self->read_integer();
	my $length = $type >> 1;
	my $obj = $self->io->read($length);
	
	XML::LibXML->require;
	my $xml = XML::LibXML->new()->parse_string($obj);
	
	push @{ $self->{'stored_objects'} }, $xml;
	return $xml;
}

sub read_byte_array
{
	my $self = shift;
	
	my $type = $self->read_integer();
	my $isReference = ($type & 0x01) == 0;
	
	if ($isReference)
	{
		my $reference = $type >> 1;
		if ($reference < @{ $self->{'stored_objects'} })
		{
			if (not defined $self->{'stored_objects'}->[$reference])
			{
				die "Reference to non existant object at index #{$reference}.";
			}
			
			return $self->{'stored_objects'}->[$reference];
		}
		else
		{
			die "Reference to non existant object at index #{$reference}.";
		}
	}
	else
	{
		my $length = $type >> 1;
		my @obj = unpack('C' . $length, $self->io->read($length));
		
		Data::AMF::Type::ByteArray->require;
		my $obj = Data::AMF::Type::ByteArray->new(\@obj);
		
		push @{ $self->{'stored_objects'} }, $obj;
		return $obj;
	}
}

1;

__END__

=head1 NAME

Data::AMF::Parser::AMF3 - deserializer for AMF3

=head1 SYNOPSIS

    my $obj = Data::AMF::Parser::AMF3->parse($amf3_data);

=head1 METHODS

=head2 parse

=head1 AUTHOR

Takuho Yoshizu <seagirl@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut


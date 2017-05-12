package Data::AMF::Formatter::AMF3;
use strict;
use warnings;

require bytes;
use Data::AMF::IO;
use Scalar::Util qw/blessed looks_like_number/;

# ----------------------------------------------------------------------
# Class Constants
# ----------------------------------------------------------------------

use constant
{
	UNDEFINED_MARKER => 0x00,
	NULL_MARKER => 0x01,
	FALSE_MARKER => 0x02,
	TRUE_MARKER => 0x03,
	INTEGER_MARKER => 0x04,
	NUMBER_MARKER => 0x05,
	STRING_MARKER => 0x06,
	XML_DOC_MARKER => 0x07,
	DATE_MARKER => 0x08,
	ARRAY_MARKER => 0x09,
	OBJECT_MARKER => 0x0A,
	XML_MARKER => 0x0B,
	BYTE_ARRAY_MARKER => 0x0C,
	AMF3_INTEGER_MIN => "-268435456",
	AMF3_INTEGER_MAX => "268435455"
};

# ----------------------------------------------------------------------
# Class Methods
# ----------------------------------------------------------------------

sub format
{
	my ($class, $object) = @_;
	
	my $self = $class->new;
	
	$self->write($object);
	
	return $self->io->data;
}

# ----------------------------------------------------------------------
# Constructor
# ----------------------------------------------------------------------

sub new
{
	my $class = shift;
	my $self = bless {
		io => Data::AMF::IO->new( data => q[] ),
		stored_objects_count => 0,
		stored_objects => {},
		stored_strings_count => 0,
		stored_strings => {},
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

sub write
{
	my ($self, $value) = @_;
	
	if (my $pkg = blessed $value)
	{
		if ($pkg eq 'Data::AMF::Type::Boolean')
		{
			if ($value->data)
			{
				$self->io->write_u8(TRUE_MARKER);
			}
			else
			{
				$self->io->write_u8(FALSE_MARKER);
			}
		}
		elsif ($pkg eq 'Data::AMF::Type::ByteArray')
		{
			$self->io->write_u8(BYTE_ARRAY_MARKER);
			$self->write_byte_array($value);
		}
		elsif ($pkg eq 'Data::AMF::Type::Null')
		{
			$self->io->write_u8(NULL_MARKER);
		}
		elsif ($pkg eq 'DateTime')
		{
			$self->io->write_u8(DATE_MARKER);
			$self->write_date($value);
		}
		elsif ($pkg eq 'XML::LibXML::Document')
		{
			$self->io->write_u8(XML_MARKER);
			$self->write_xml($value);
		}
		else
		{
			$self->io->write_u8(OBJECT_MARKER);
			$self->write_object($value);
		}
	}
	elsif (my $ref = ref($value))
	{
		if ($ref eq 'ARRAY')
		{
			$self->io->write_u8(ARRAY_MARKER);
			$self->write_array($value);
		}
		elsif ($ref eq 'HASH')
		{
			$self->io->write_u8(OBJECT_MARKER);
			$self->write_object($value);
		}
		else
		{
			die qq[cannot format "$ref" object];
		}
	}
	else
	{
		if (looks_like_number($value))
		{
			if ($value >= AMF3_INTEGER_MIN && $value <= AMF3_INTEGER_MAX && $value == int($value))
			{
				$self->io->write_u8(INTEGER_MARKER);
				$self->write_integer($value);
			}
			else
			{
				$self->io->write_u8(NUMBER_MARKER);
				$self->write_number($value);
			}
		}
		elsif (defined $value)
		{
			$self->io->write_u8(STRING_MARKER);
			$self->write_string($value);
		}
		else
		{
			$self->io->write_u8(UNDEFINED_MARKER);
		}
	}
}

sub write_integer
{
	my ($self, $value) = @_;
	
	$value = $value & 0x1fffffff;
	
	if ($value < 0x80)
	{
		$self->io->write_u8($value);
	}
	elsif ($value < 0x4000)
	{
		$self->io->write(
			  pack('C', $value >> 7 & 0x7f | 0x80)
			. pack('C', $value & 0x7f)
		);
	}
	elsif ($value < 0x200000)
	{
		$self->io->write(
			  pack('C', $value >> 14 & 0x7f | 0x80)
			. pack('C', $value >> 7 & 0x7f | 0x80)
			. pack('C', $value & 0x7f)
		);
	}
	else
	{
		$self->io->write(
			  pack('C', $value >> 22 & 0x7f | 0x80)
			. pack('C', $value >> 15 & 0x7f | 0x80)
			. pack('C', $value >> 8 & 0x7f | 0x80)
			. pack('C', $value & 0xff)
		);
	}
}

sub write_number
{
	my ($self, $value) = @_;
	$self->io->write_double($value);
}

sub write_string
{
	my ($self, $value) = @_;
	
	my $i = $self->{'stored_strings'}->{$value};
	
	if (defined $i)
	{	
		if ($value eq '')
		{
			$self->io->write_u8(NULL_MARKER);
		}
		else
		{
			my $reference = $i << 1;
			$self->write_integer($reference);
		}
	}
	else
	{
		if ($value ne '') {
			$self->{'stored_strings'}->{$value} = $self->{'stored_strings_count'};
			$self->{'stored_strings_count'}++;
		}

		my $reference = length $value;
		$reference = $reference << 1 | 1;
		
		$self->write_integer($reference);
		$self->io->write($value);
	}
}

sub write_array
{
	my ($self, $value) = @_;
	
	my $i = $self->{'stored_objects'}->{$value};
	
	if (defined $i)
	{
		my $reference = $i << 1;
		$self->write_integer($reference);
	}
	else
	{
		$self->{'stored_objects'}->{$value} = $self->{'stored_objects_count'};
		$self->{'stored_objects_count'}++;
		
		my $reference = @{ $value };
		$reference = $reference << 1 | 0x01;
		
		$self->write_integer($reference);
		$self->io->write_u8(NULL_MARKER);
		
		for my $v (@{ $value })
		{
			$self->write($v);
		}
	}
}

sub write_object
{
	my ($self, $value) = @_;
	
	my $i = $self->{'stored_objects'}->{$value};
	
	if (defined $i)
	{
		
		my $reference = $i << 1;
		$self->write_integer($reference);
	}
	else
	{
		$self->{'stored_objects'}->{$value} = $self->{'stored_objects_count'};
		$self->{'stored_objects_count'}++;
		
		$self->io->write_u8(0x0B); # U29o-traits (ダイナミッククラス)
		
		if (defined $value->{'_explicitType'})
		{
			$self->write_string($value->{'_explicitType'});
		}
		else
		{
			$self->io->write_u8(NULL_MARKER);   # 匿名クラスの場合は空ストリング
		}
		
		for my $k (keys %{ $value })
		{
			next if $k eq '_explicitType';
			
			$self->write_string($k);
			
			my $v = $value->{$k};
			
			if (defined $v)
			{
				$self->write($value->{$k});
			}
			else
			{
				$self->io->write_u8(NULL_MARKER);
			}
			
		}
		
		$self->io->write_u8(NULL_MARKER);
	}
}

sub write_byte_array
{
	my ($self, $value) = @_;
	
	my $i = $self->{'stored_objects'}->{$value};
	
	if (defined $i)
	{
		my $reference = $i << 1;
		$self->write_integer($reference);
	}
	else
	{
		$self->{'stored_objects'}->{$value} = $self->{'stored_objects_count'};
		$self->{'stored_objects_count'}++;
		
		my $data = $value->data;
		my $length = scalar @$data;
		my $bin = pack('C' . $length, @$data);
		my $reference = $length << 1 | 1;
		
		$self->write_integer($reference);
		$self->io->write($bin);
	}
}

sub write_date
{
	my ($self, $value) = @_;
	
	my $i = $self->{'stored_objects'}->{$value};
	
	if (defined $i)
	{
		my $reference = $i << 1;
		$self->write_integer($reference);
	}
	else
	{
		$self->{'stored_objects'}->{$value} = $self->{'stored_objects_count'};
		$self->{'stored_objects_count'}++;
		
		$self->write_integer(1);
		my $msec = $value->epoch * 1000;
		$self->io->write_double($msec);
	}
}

sub write_xml
{
	my ($self, $value) = @_;
	
	my $i = $self->{'stored_objects'}->{$value};
	
	if (defined $i)
	{
		my $reference = $i << 1;
		$self->write_integer($reference);
	}
	else
	{
		$self->{'stored_objects'}->{$value} = $self->{'stored_objects_count'};
		$self->{'stored_objects_count'}++;

		my $obj = $value->toString();
		$self->write_string($obj);
	}
}

=head1 NAME

Data::AMF::Formatter::AMF3 - AMF3 serializer

=head1 SYNOPSIS

    my $amf3_data = Data::AMF::Formatter::AMF3->format($obj);

=head1 METHODS

=head2 format

=head1 AUTHOR

Takuho Yoshizu <seagirl@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;


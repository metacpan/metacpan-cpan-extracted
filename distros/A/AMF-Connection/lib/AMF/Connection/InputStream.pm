package AMF::Connection::InputStream;

use strict;
use Carp;

our $storable_with_options;

eval "use Storable::AMF0 0.84";
if ($@)
  {
    $storable_with_options = 0;
  }
else
  {
    $storable_with_options = 1;
  }

eval "use Storable::AMF3 0.84";
if ($@)
  {
    $storable_with_options = 0;
  }
else
  {
    $storable_with_options = 1;
  }

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my ($stream, $storable_amf_options) = @_;

	croak "Input stream must be a valid string"
		if(ref($stream));
	
	my $self = {
		'stream' => $stream,
		'cursor' => 0
		};

	if (defined $storable_amf_options)
	  {
	    if ($Storable::AMF::VERSION < 0.84)
	      {
	        croak "Storable::AMF 0.84 or newer needed to set stream options\n";
	      }
	    $self->{'options'} = Storable::AMF::parse_option ($storable_amf_options);
	  }

	return bless($self, $class);
	};

sub readBuffer {
	my ($class, $length) = @_;

	croak "Buffer underrun at position: ". $class->{'cursor'} . ". Trying to fetch ". $length . " bytes from buffer total length ".length($class->{'stream'})
		if($length + $class->{'cursor'} > length($class->{'stream'}));

        my $data = substr($class->{'stream'},$class->{'cursor'},$length);
	$class->{'cursor'}+=$length;
	
	return $data;
	};

sub readByte {
	my ($class) = @_;

	return ord($class->readBuffer(1));
	};

sub readInt {
	my ($class) = @_;

	my $block = $class->readBuffer(2);
	my @int = unpack("n",$block);

	return $int[0];
	};

sub readDouble {
	my ($class) = @_;

	my $double = $class->readBuffer(8);

	my @testEndian = unpack("C*",pack("S*",256));
        my $bigEndian = !$testEndian[1]==1;
        $double = reverse($double)
                if($bigEndian);
        my @double = unpack("d",$double);

        return $double[0];
	};

sub readLong {
	my ($class) = @_;

	my $block = $class->readBuffer(4);
	my @long = unpack("N",$block);

        return $long[0];
	};

# deparse out the next avail AMF entity
# TODO - make sure ref counts are reset/preserved between calls in the scope of the same InputStream - study Storable::AMF API
sub readAMFData {
	my ($class) = @_;

	my $type = $class->readByte();

	# Storable::AMF will take care of deparsing the right AMF format
	$class->{'cursor'}--;

	local $@ = undef;

        my ($obj, $len);
	my $encoding=0;
	if($type == 0x11) {
		$encoding=3;
		$class->{'cursor'}++;
		if ($storable_with_options  == 0
		    || not defined $class->{'options'})
		  {
        	    ($obj, $len) = Storable::AMF3::deparse_amf( substr($class->{'stream'},$class->{'cursor'}));
		  }
  		else
		  {
        	    ($obj, $len) = Storable::AMF3::deparse_amf( substr($class->{'stream'},$class->{'cursor'}), $class->{'options'});
		  }
	} else {
		# NOTE: Storable::AMF0 seems not needing extra readByte() before deparse

		if ($storable_with_options  == 0
		    || not defined $class->{'options'})
		  {
        	    ($obj, $len) = Storable::AMF0::deparse_amf( substr($class->{'stream'},$class->{'cursor'}));
		  }
		else
		  {
        	    ($obj, $len) = Storable::AMF0::deparse_amf( substr($class->{'stream'},$class->{'cursor'}), $class->{'options'});
		  }
		};

	croak "Can not read AMF".$encoding." data starting from position ".$class->{'cursor'}." of input - reason: ".$@ ."\n"
		if($@);

	if(defined $obj) {
		$class->{'cursor'}+=$len
			unless( $len + $class->{'cursor'} > length($class->{'stream'}) );	
		};

	return $obj;
	};

1;
__END__

=head1 NAME

AMF::Connection::InputStream - A simple pure perl implementation of an input binary stream

=head1 SYNOPSIS

  # ...

  my $stream = new AMF::Connection::InputStream($binary_buffer_or_string);
  my $stream_with_options = new AMF::Connection::InputStream($binary_buffer_or_string, 'prefer_number, json_boolean');
  my $int = $stream->readInt();
  my $long = $stream->readLong();

  # ..


=head1 DESCRIPTION

The AMF::Connection::InputStream class is a simple pure perl implementation of an input binary stream.

=head1 OPTIONS

See Storable::AMF0 documentation.

=head1 SEE ALSO

Storable::AMF0, Data::AMF::IO, AMF::Perl::IO::InputStream

=head1 AUTHOR

Alberto Attilio Reggiori, <areggiori at cpan dot org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 by Alberto Attilio Reggiori

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

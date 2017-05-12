package AMF::Perl::IO::Deserializer;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

=head1 NAME

AMF::Perl::IO::Deserializer

=head1 DESCRIPTION    

    Package used to turn the binary data into physical perl objects.

=head1 CHANGES

=head2 Sun Sep 19 13:01:35 EDT 2004

=item Patch from Kostas Chatzikokolakis about error checking of input data length.

=head2 Sat Mar 13 16:31:31 EST 2004

=item Patch from Kostas Chatzikokolakis handling encoding.

=head2 Sun Mar  9 18:17:31 EST 2003

=item The return value of readArray should be \@ret, not @ret.

=head2 Tue Mar 11 21:55:41 EST 2003

=item Fixed reading keys of objects.

=item Added floor(), as Perl lacks it.

=head2 Sun Apr  6 14:24:00 2003

=item Added code to read objects of type 8. Useful for decoding real AMF server packages, but hardly anywhere else.

=cut

use strict;

use Encode qw/from_to/;

# the number of headers in the packet
my $header_count;
# the content of the headers
my $headers;
# the number of body elements
my $body_count;
# the content of the body
my $body;

sub floor 
{
  my $n = shift;

  return int($n) - ($n < 0 ? 1: 0) * ($n != int($n) ? 1 : 0);
}


#******************** PUBLIC METHODS ****************************/

# constructor that also dserializes the raw data
sub new
{
    my ($proto, $is, $encoding)=@_;
    my $self = {};
    bless $self, $proto;
    # the object to store the deserialized data
    $self->{amfdata} = new AMF::Perl::Util::Object();
    # save the input stream in this object
    $self->{inputStream} = $is;
	# save the encoding in this object
	$self->{encoding} = $encoding;
    # read the binary header
    $self->readHeader();
    # read the binary body
    $self->readBody();
    return $self;
}

# returns the instance of the Object package
sub getObject
{
    my ($self)=@_;
    return $self->{amfdata};
}

#******************** PRIVATE METHODS ****************************/

sub readHeader
{
    my ($self)=@_;
    # ignore the first two bytes -- version or something
    $self->{inputStream}->readInt();
    # find the total number of header elements
    $self->{header_count} = $self->{inputStream}->readInt();
    # loop over all of the header elements
    while($self->{header_count}--)
    {
        my $name = $self->{inputStream}->readUTF();
        # find the must understand flag
        my $required = $self->readBoolean();
        # grab the length of the header element
        my $length = $self->{inputStream}->readLong();
        # grab the type of the element
        my $type = $self->{inputStream}->readByte();
        # turn the element into real data
        my $content = $self->readData($type);
        # save the name/value into the headers array
        $self->{amfdata}->addHeader($name, $required, $content);
    }
}

sub readBody
{
    my ($self)=@_;
    # find the total number of body elements
    $self->{body_count} = $self->{inputStream}->readInt();
    # loop over all of the body elements
    while($self->{body_count}--)
    {	
        my $method = $self->readString();
        # the target that the client understands
        my $target = $self->readString();
        # grab the length of the body element
        my $length = $self->{inputStream}->readLong();
        
        # grab the type of the element
        my $type = $self->{inputStream}->readByte();
        # turn the argument elements into real data
        my $data = $self->readData($type);
        # add the body element to the body object
        $self->{amfdata}->addBody($method, $target, $data);
    }
}


# reads an object and converts the binary data into a Perl object
sub readObject
{
    my ($self)=@_;
    # init the array
    my %ret;
    
    # grab the key
    my $key = $self->{inputStream}->readUTF();
        
    for  (my $type = $self->{inputStream}->readByte(); $type != 9; $type = $self->{inputStream}->readByte())
    {	
		die "Malformed AMF data, no object end byte" unless defined($type);
        # grab the value
        my $val = $self->readData($type);
        # save the name/value pair in the array
        $ret{$key} = $val;
        # get the next name
        $key = $self->{inputStream}->readUTF();
    }
    # return the array
    return \%ret;
}

# reads and array object and converts the binary data into a Perl array
sub readArray
{
    my ($self)=@_;
    # init the array object
    my @ret;
    # get the length of the array
    my $length = $self->{inputStream}->readLong();
	die "Malformed AMF data, array length too big" if $length > $self->{inputStream}{content_length};
    # loop over all of the elements in the data
    for (my $i=0; $i<$length; $i++)
    {
        # grab the type for each element
        my $type = $self->{inputStream}->readByte();
        # grab each element
        push @ret, $self->readData($type);
    }
    # return the data
    return \@ret;    
}

sub readCustomClass
{
    my ($self)=@_;
    # grab the explicit type -- I'm not really convinced on this one but it works,
    # the only example i've seen is the NetDebugConfig object
    my $typeIdentifier = $self->{inputStream}->readUTF();
    # the rest of the bytes are an object without the 0x03 header
    my $value = $self->readObject();
    # save that type because we may need it if we can find a way to add debugging features
    $value->{"_explicitType"} = $typeIdentifier;
    # return the object
    return $value;        
}

sub readNumber
{
    my ($self)=@_;
    # grab the binary representation of the number
    return $self->{inputStream}->readDouble();	
}

# read the next byte and return it's boolean value
sub readBoolean
{
    my ($self)=@_;
    # grab the int value of the next byte
    my $int = $self->{inputStream}->readByte();
    # if it's a 0x01 return true else return false
    return ($int == 1);
}

sub readString
{
    my ($self)=@_;
    my $s = $self->{inputStream}->readUTF();
	from_to($s, "utf8", $self->{encoding}) if $self->{encoding};
	return $s;
}

sub readDate
{
    my ($self)=@_;
    my $ms = $self->{inputStream}->readDouble(); # date in milliseconds from 01/01/1970

    # nasty way to get timezone 
    my $int = $self->{inputStream}->readInt();
    if($int > 720)
    {
        $int = -(65536 - $int);
    }
    my $hr = floor($int / 60);
    my $min = $int % 60;
    my $timezone = "GMT " . -$hr . ":" . abs($min);
    # end nastiness 

    # is there a nice way to return entire date(milliseconds and timezone) in PHP???
    return $ms; 
}

# XML comes in as a plain string except it has a long displaying the length instead of a short?
sub readXML
{
    my ($self)=@_;
        # reads XML
    my $rawXML = $self->{inputStream}->readLongUTF();
	from_to($rawXML, "utf8", $self->{encoding}) if $self->{encoding};
    
    # maybe parse the XML into a PHP XML structure??? or leave it to the developer
    
    # return the xml
    return $rawXML;
}
sub readFlushedSO
{
    my ($self)=@_;
    # receives [type(07) 00 00] if SO is flushed and contains 'public' properties
    # see debugger readout ???
    return $self->{inputStream}->readInt();
}

sub readASObject
{
    my ($self)=@_;

    #object Button, object Textformat, object Sound, object Number, object Boolean, object String, 
    #SharedObject unflushed, XMLNode, used XMLSocket??, NetConnection,
    #SharedObject.data, SharedObject containing 'private' properties

    #the final byte seems to be the dataType -> 0D
    return undef;
}

# main switch function to process all of the data types
sub readData
{
    my ($self, $type) = @_;
    my $data;
#print STDERR "Reading data of type $type\n";
    if ($type == 0) # number
    {	
        $data = $self->readNumber();
    }
    elsif ($type == 1) # boolean
    {
        $data = $self->readBoolean();
    }
    elsif ($type == 2) # string
    {
        $data = $self->readString();
    }
    elsif ($type == 3) # object Object
    {
        $data = $self->readObject();
    }
    elsif ($type == 5) # null
    {
        $data = undef;
    }
    elsif ($type == 6) # undefined
    {
        $data = undef;
    }
    elsif ($type == 7) # flushed SharedObject containing 'public' properties
    {
        $data = $self->readFlushedSO(); 
    }
    elsif ($type == 8) # array
    {
        # shared object format only (*.sol) 
        # only time I saw it was the serverinfo value in a ColdFusion RecordSet
        # It was just four zeroes - skip them.
        for (my $i=0; $i<4; $i++)
        {
            $self->{inputStream}->readByte();
        }
    }
    elsif ($type == 10) # array
    {
        $data = $self->readArray();
    }
    elsif ($type == 11) # date
    {
        $data = $self->readDate();
    }
    elsif ($type == 13) # mainly internal AS objects
    {
        $data = $self->readASObject();
    }
    elsif ($type == 15) # XML
    {
        $data = $self->readXML();
    }
    elsif ($type == 16) # Custom Class
    {
        $data = $self->readCustomClass();
    }
    else # unknown case
    {
        print STDERR "Unknown data type: $type\n";
    }

    return $data;
}
	
1;	

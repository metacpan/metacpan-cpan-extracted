package AMF::Perl::IO::Serializer;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)

=head1 NAME

    AMF::Perl::IO::Serializer

=head1 DESCRIPTION    

    Class used to convert physical perl objects into binary data.

=head1 CHANGES

=head2 Sun May 23 12:35:19 EDT 2004

=item Changed deduceType() to return the value too, as it may be changed inside, and to 
handle empty string ('') as a string.

=head2 Wed Apr 14 11:06:28 EDT 2004

=item Made basic data type determination work for both scalars and scalarrefs.

=item Now we check if we are sending a recordset and setting column types accordingly.

=head2 Sat Mar 13 16:25:00 EST 2004

=item Patch from Tilghman Lesher that detects numbers and dates in strings
and sets return type accordingly.

=item Patch from Kostas Chatzikokolakis handling encoding and sending null value.

=head2 Sun May 11 16:43:05 EDT 2003

=item Changed writeData to set type to "NULL" when the incoming data is undef. Previously
it became a String, just like other scalars.

=item Changed PHP's writeRecordset to a generic writeAMFObject. Verified Recordset support.

=head2 Sun Mar  9 18:20:16 EST 2003

=item Function writeObject should return the same as writeHash. This assumes that all meaningful data
are stored as hash keys.

=cut


use strict;

use Encode qw/from_to/;
use DBI;

# holder for the data
my $data;

sub new
{	
    my ($proto, $stream, $encoding) = @_;
    # save
    my $self={};
    bless $self, $proto;
    $self->{out} = $stream;
	$self->{encoding} = $encoding;
    return $self;
}

sub serialize
{
    my ($self, $d) = @_;
    $self->{amfout} = $d;
    # write the version ???
    $self->{out}->writeInt(0);
    
    # get the header count
    my $count = $self->{amfout}->numHeader();
    # write header count
    $self->{out}->writeInt($count);
    
    for (my $i=0; $i<$count; $i++)
    {
        $self->writeHeader($i);
    }
        
    $count = $self->{amfout}->numBody();
    # write the body count
    $self->{out}->writeInt($count);
    
    for (my $i=0; $i<$count; $i++)
    {
        # start writing the body
        $self->writeBody($i);
    }
}

sub writeHeader
{
    my ($self, $i)=@_;

    
    # for all header values
    # write the header to the output stream
    # ignoring header for now
}

sub writeBody
{
    my ($self, $i)=@_;
    my $body = $self->{amfout}->getBodyAt($i);
    # write the responseURI header
    $self->{out}->writeUTF($body->{"target"});
    # write null, haven't found another use for this
    $self->{out}->writeUTF($body->{"response"});
    # always, always there is four bytes of FF, which is -1 of course
    $self->{out}->writeLong(-1);
    # write the data to the output stream
    $self->writeData($body->{"value"}, $body->{"type"});
}

# writes a boolean
sub writeBoolean
{
    my ($self, $d)=@_;
    # write the boolean flag
    $self->{out}->writeByte(1);
    # write the boolean byte
    $self->{out}->writeByte($d);
}
# writes a string under 65536 chars, a longUTF is used and isn't complete yet
sub writeString
{
    my ($self, $d)=@_;
    # write the string code
    $self->{out}->writeByte(2);
    # write the string value
    #$self->{out}->writeUTF(utf8_encode($d));
	from_to($d, $self->{encoding}, "utf8") if $self->{encoding};
    $self->{out}->writeUTF($d);
}

sub writeXML
{
    my ($self, $d)=@_;
    $self->{out}->writeByte(15);
    #$self->{out}->writeLongUTF(utf8_encode($d));
	from_to($d, $self->{encoding}, "utf8") if $self->{encoding};
    $self->{out}->writeLongUTF($d);
}

# must be used PHPRemoting with the service to set the return type to date
# still needs a more in depth look at the timezone
sub writeDate
{
    my ($self, $d)=@_;
    # write date code
    $self->{out}->writeByte(11);
    # write date (milliseconds from 1970)
    $self->{out}->writeDouble($d);
    # write timezone
    # ?? this is wierd -- put what you like and it pumps it back into flash at the current GMT ?? 
    # have a look at the amf it creates...
    $self->{out}->writeInt(0); 
}

# write a number formatted as a double with the bytes reversed
# this may not work on a Win machine because i believe doubles are
# already reversed, to fix this comment out the reversing part
# of the writeDouble method
sub writeNumber
{
    my ($self, $d)=@_;
    # write the number code
    $self->{out}->writeByte(0);
    # write the number as a double
    $self->{out}->writeDouble($d);
}
# write null
sub writeNull
{
    my ($self)=@_;
    # null is only a 0x05 flag
    $self->{out}->writeByte(5);
}

# write array
# since everything in php is an array this includes arrays with numeric and string indexes
sub writeArray
{
    my ($self, $d)=@_;

    # grab the total number of elements
    my $len = scalar(@$d);

    # write the numeric array code
    $self->{out}->writeByte(10);
    # write the count of items in the array
    $self->{out}->writeLong($len);
    # write all of the array elements
    for(my $i=0 ; $i < $len ; $i++)
    {
		#If this is a basic data type in a recordset, consider the column type.
		if (!(ref $d->[$i]) && $self->{__writingRecordset__})
		{
			my $type = $self->{__columnTypes__}->[$i];
			$self->dispatchBySqlType($d->[$i], $type);
		}
		else
		{
        	$self->writeData($d->[$i]);
		}
    }
}

sub dispatchBySqlType
{
	my ($self, $data, $type) = @_;
	if ($type && ($type == DBI::SQL_NUMERIC) || ($type == DBI::SQL_DECIMAL) || ($type == DBI::SQL_INTEGER) || ($type == DBI::SQL_SMALLINT) || ($type == DBI::SQL_FLOAT) || ($type == DBI::SQL_DOUBLE) || ($type == DBI::SQL_REAL))
	{
		$self->writeNumber($data);
	}
	else
	{
		$self->writeString($data);
	}
}
    
sub writeHash
{
    my ($self, $d) = @_;
    # this is an object so write the object code
    $self->{out}->writeByte(3);
    # write the object name/value pairs	
    $self->writeObject($d);
}
# writes an object to the stream
sub writeObject
{
    my ($self, $d)=@_;
    # loop over each element
    while ( my ($key, $data) = each %$d)
    {	
        # write the name of the object
        $self->{out}->writeUTF($key);
		if ($self->{__columnTypes__} && $key eq "initialData")
		{
			$self->{__writingRecordset__} = 1;
		}
        # write the value of the object
        $self->writeData($data);
		$self->{__writingRecordset__} = 0;
    }
    # write the end object flag 0x00, 0x00, 0x09
    $self->{out}->writeInt(0);
    $self->{out}->writeByte(9);
}

# write an AMF object
# The difference with regular object is that the code is different 
# and the class name is explicitly sent. Good for RecordSets.
sub writeAMFObject
{	
    my ($self, $object)=@_;
    # write the custom package code
    $self->{out}->writeByte(16);
    # write the package name
    $self->{out}->writeUTF($object->{_explicitType});
	$self->{__columnTypes__} = $object->{__columnTypes__} if $object->{__columnTypes__};
    # write the package's data
    $self->writeObject($object);                        
	delete $self->{__columnTypes__};
}


# main switch for dynamically determining the data type
# this may prove to be inadequate because perl isn't a typed
# language and some confusion may be encountered as we discover more data types
# to be passed back to flash

#All scalars are assumed to be strings, not numbers.
#Regular arrays and hashes are prohibited, as they are indistinguishable outside of perl context
#Only arrayrefs and hashrefs will work

# were still lacking dates, xml, and strings longer than 65536 chars
sub writeData
{
    my ($self, $d, $type)=@_;
    $type = "unknown" unless $type;

#    **************** TO DO **********************
#    Since we are now allowing the user to determine
#    the datatype we have to validate the user's suggestion
#    vs. the actual data being passed and throw an error
#    if things don't check out.!!!!
#    **********************************************

    # get the type of the data by checking its reference name
    #if it was not explicitly passed
    if ($type eq "unknown")
    {
		if (!defined $d)		# convert undef to null, but not "" or 0
		{
			$type = "NULL";
		}
		else
		{
        my $myRef = ref $d;

        if (!$myRef || $myRef =~ "SCALAR")
        {
			if ($myRef) {
				study $$myRef;
				($type, $d) = $self->deduceType($$myRef);
			} else {
				($type, $d) = $self->deduceType($d);
			}
        }
        elsif ($myRef =~ "ARRAY")
        {
            $type = "array";
        }
        elsif ($myRef =~ "HASH")
        {
            $type = "hash"; 
        }
        else
        {
            $type = "object";
        }
		}
    }
    
    #BOOLEANS
    if ($type eq "boolean")
    {
        $self->writeBoolean($d);
    }
    #STRINGS
    elsif ($type eq "string")
    {
        $self->writeString($d);
    }
    # DOUBLES
    elsif ($type eq "double")
    {
        $self->writeNumber($d);
    }
    # INTEGERS
    elsif ($type eq "integer")
    {
        $self->writeNumber($d);
    }
    # OBJECTS
    elsif ($type eq "object")
    {
        $self->writeHash($d);
    }
    # ARRAYS
    elsif ($type eq "array")
    {
        $self->writeArray($d);
    }
    # HASHAS
    elsif ($type eq "hash")
    {
        $self->writeHash($d);
    }
    # NULL
    elsif ($type eq "NULL")
    {
        $self->writeNull();
    }
    # UDF's
    elsif ($type eq "user function")
    {
    
    }
    elsif ($type eq "resource")
    {
        my $resource = get_resource_type($d); # determine what the resource is
        $self->writeData($d, $resource); # resend with $d's specific resource type
    }
    # XML
    elsif (lc($type) eq "xml")
    {
        $self->writeXML($d);
    }
    # Dates
    elsif (lc($type) eq "date")
    {
        $self->writeDate($d);
    }
    # mysql recordset resource
    elsif (lc($type) eq "amfobject") # resource type
    {
        # write the record set to the output stream
        $self->writeAMFObject($d); # writes recordset formatted for Flash
    }		
    else
    {
        print STDERR "Unsupported Datatype $type in AMF::Perl::IO::Serializer";
        die;
    }
    
    }

sub deduceType
{
	my ($self, $scalar) = @_;

	my $type = "string";

	if ($scalar =~ m/^(\d{4})\-(\d{2})\-(\d{2})( (\d{2}):(\d{2}):(\d{2}))?$/) 
	{
		# Handle "YYYY-MM-DD" and "YYYY-MM-DD HH:MM:SS"
		require POSIX;
		if ($4) {
			$scalar = POSIX::mktime($7,$6,$5,$3,$2 - 1,$1 - 1900) * 1000;
		} else {
			$scalar = POSIX::mktime(0,0,0,$3,$2 - 1,$1 - 1900) * 1000;
		}
		$type = "date";
	} elsif ($scalar =~ m/[^0-9\.\-]/) {
		$type = "string";
	} elsif ($scalar =~ m/\..*\./) {
		# More than 1 period (e.g. IP address)
		$type = "string";
	} elsif (($scalar =~ m/.\-/) or ($scalar eq '-')) {
		# negative anywhere but at the beginning
		$type = "string";
	} elsif ($scalar =~ m/\./) {
		$type = "double";
	} elsif ($scalar eq '') {
		$type = "string";
	} else {
		$type = "integer";
	}
	return ($type, $scalar);
}
1;

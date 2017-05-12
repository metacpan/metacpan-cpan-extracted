package AMF::Perl::IO::InputStream;
# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)


=head1 NAME

    AMF::Perl::IO::InputStream

=head1 DESCRIPTION    

    InputStream package built to handle getting the binary data from the raw input stream.

=head1 CHANGES    

=head2 Sun Sep 19 13:01:35 EDT 2004
=item Patch from Kostas Chatzikokolakis about error checking of input data length.

=head2 Tue Jun 22 19:28:30 EDT 2004
=item Improved the check in readDouble to append "0" to the string instead of skipping
the value. Otherwise the number 16 did not go through.
=item Added defined($thisByte) in readInt, otherwise the character "0" (say, in string length of 30)
did not go through.

=head2 Sat Mar 13 16:39:29 EST 2004

=item Changed calls to ord() in readByte() and concatenation readDouble() 
to prevent the appearance of the "uninitialized" warning.

=head2 Sun May 11 16:41:52 EDT 2003

=item Rewrote readInt to get rid of the "uninitialized" warning when reading bytes of value 0.

=head2 Sun Jul 11 18:45:40 EDT 2004

=item Added the check for endianness.


=cut

use strict;

#InputStream constructor
sub new
{
    my ($proto,  $rd )=@_;
    my $self={};
    bless $self, $proto;
    $self->{current_byte}=0;
    # store the stream in this object
    my @array =  split //, $rd;
    $self->{raw_data} = \@array;
    # grab the total length of this stream
    $self->{content_length} = @{$self->{raw_data}};
    if (unpack("h*", pack("s", 1)) =~ /01/)
    {
        $self->{byteorder} = 'big-endian';
    }
    else
    {
        $self->{byteorder} = 'little-endian';
    }
    return $self;
}


# returns a single byte value.
sub readByte
{
    my ($self)=@_;
	# boundary check
	die "Malformed AMF data, cannot readByte\n"
		if $self->{current_byte} > $self->{content_length} - 1;
    # return the next byte
	my $nextByte = $self->{raw_data}->[$self->{current_byte}];
	my $result;
	$result = ord($nextByte) if $nextByte;
    $self->{current_byte} += 1;
    return $result;
}

# returns the value of 2 bytes
sub readInt
{
    my ($self)=@_;

	# boundary check
	die "Malformed AMF data, cannot readInt\n"
		if $self->{current_byte} > $self->{content_length} - 2;

    # read the next 2 bytes, shift and add
	my $thisByte = $self->{raw_data}->[$self->{current_byte}];
	my $nextByte = $self->{raw_data}->[$self->{current_byte}+1];

    my $thisNum = defined($thisByte) ? ord($thisByte) : 0;
    my $nextNum = defined($nextByte) ? ord($nextByte) : 0;

    my $result = (($thisNum) << 8) | $nextNum;

    $self->{current_byte} += 2;
    return $result;
}

# returns the value of 4 bytes
sub readLong
{
    my ($self)=@_;
 
	# boundary check
	die "Malformed AMF data, cannot readLong\n"
		if $self->{current_byte} > $self->{content_length} - 4;

    my $byte1 = $self->{current_byte};
    my $byte2 = $self->{current_byte}+1;
    my $byte3 = $self->{current_byte}+2;
    my $byte4 = $self->{current_byte}+3;
    # read the next 4 bytes, shift and add
    my $result = ((ord($self->{raw_data}->[$byte1]) << 24) | 
                    (ord($self->{raw_data}->[$byte2]) << 16) |
                    (ord($self->{raw_data}->[$byte3]) << 8) |
                        ord($self->{raw_data}->[$byte4]));
    $self->{current_byte} = $self->{current_byte} + 4;
    return $result;
}

sub readDouble
{
    my ($self)=@_;
	# boundary check
	die "Malformed AMF data, cannot readDouble\n"
		if $self->{current_byte} > $self->{content_length} - 8;
    # container to store the reversed bytes
    my $invertedBytes = "";
    if ($self->{byteorder} eq 'little-endian')
    {
        # create a loop with a backwards index
        for(my $i = 7 ; $i >= 0 ; $i--)
        {
            # grab the bytes in reverse order from the backwards index
	    my $nextByte = $self->{raw_data}->[$self->{current_byte}+$i];
	    $nextByte = "0" unless $nextByte;
            $invertedBytes .= $nextByte; 	    
        }
    }
    else
    {
        for(my $i = 0 ; $i < 8 ; $i++)
        {
            # grab the bytes in forwards order
	    my $nextByte = $self->{raw_data}->[$self->{current_byte}+$i];
	    $nextByte = "0" unless $nextByte;
            $invertedBytes .= $nextByte; 	    
        }
    }
    # move the seek head forward 8 bytes
    $self->{current_byte} += 8;
    # unpack the bytes
    my @zz = unpack("d", $invertedBytes);
    # return the number from the associative array
    return $zz[0];
}

# returns a UTF string
sub readUTF
{
    my ($self) = @_;
    # get the length of the string (1st 2 bytes)
    my $length = $self->readInt();
	# boundary check
	die "Malformed AMF data, cannot readUTF\n"
		if $self->{current_byte} > $self->{content_length} - $length;
    # grab the string
    my @slice = @{$self->{raw_data}}[$self->{current_byte}.. $self->{current_byte}+$length-1];
    my $val = join "", @slice;
    # move the seek head to the end of the string
    $self->{current_byte} += $length;
    # return the string
    return $val;
}

# returns a UTF string with a LONG representing the length
sub readLongUTF
{
    my ($self) = @_;
    # get the length of the string (1st 4 bytes)
    my $length = $self->readLong();
	# boundary check
	die "Malformed AMF data, cannot readLongUTF\n"
		if $self->{current_byte} > $self->{content_length} - $length;
    # grab the string
    my @slice = @{$self->{raw_data}}[$self->{current_byte} .. $self->{current_byte}+$length-1];
    my $val = join "", @slice;
    # move the seek head to the end of the string
    $self->{current_byte} += $length;
    # return the string
    return $val;
}

1;	

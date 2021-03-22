# Copyright (C) 2004 Domingo Alcázar Larrea
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the version 2 of the GNU General
# Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307


package DIME::Payload;
$DIME::Payload::VERSION = '0.05';
use 5.008;
use strict;
use warnings;

use Data::UUID;
use DIME::Record;
use IO::Scalar;
use IO::File;


sub new
{
	my $class = shift;
	my @records;
	my $this = {			
			_RECORDS => \@records,
			_CHUNK_SIZE => 0,
			_STREAM => undef,
			_BUFFER_SIZE => 1024,
			_MB => 0,
			_ME => 0,
			_TYPE => undef,
			_TNF => 3,
			_ID => undef,
			_FIRST_RECORD => 1,
		};
	my $self = bless $this, $class;
	$self->generate_uuid();
	return $self;
}


sub generate_uuid
{
        my $self = shift;
        # Generate a new UUID to identify the record
        my $duuid = Data::UUID->new();
        my $uuid = 'uuid:'.$duuid->create_str();
        $self->id($uuid);
}

sub type
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_TYPE} = $param;
        }
        else
        {
                return $self->{_TYPE};
        }
}

sub mb
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_MB} = $param;
        }
        else
        {
                return $self->{_MB};
        }
}


sub me
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_ME} = $param;
        }
        else
        {
                return $self->{_ME};
        }
}

sub tnf
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_TNF} = $param;
        }
        else
        {
                return $self->{_TNF};
        }
}


sub id
{
        my $self = shift;
        my $param = shift;
        if(defined($param))
        {
                $self->{_ID} = $param;
        }
        else
        {
                return $self->{_ID};
        }
}


# Add a Record to a Payload
sub add_record
{
        my $self = shift;
        my $record = shift;
        push(@{$self->{_RECORDS}},$record);
}


sub attach
{
        my $self = shift;
        my %params = @_;

	my $data;		
	
	$self->{_CHUNK_SIZE} = $params{Chunked} if(defined($params{Chunked}));

 	if(defined($params{Path}))
        {
	        my $file = IO::File->new($params{Path},"r");
                if($file)
                {

			# The user wants to load all the file in memory now...
			if(!defined($params{Dynamic}))
			{
		                # Load the attachment from a file

	                	my $buf;
	                        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = $file->stat();
	                        $file->read($buf,$size);
	                        $file->close();                        
	                        $data = \$buf; 
			}
			else
			{
				# Assign the opened stream to the member variable
				$self->{_STREAM} = $file;
			}
		}
        }

        if(defined($params{Data}))
        {
                # Get the attachment directly from memory
                $data = $params{Data};
        }

	$self->set_mime_type($params{MIMEType}) if (defined($params{MIMEType}));
	$self->set_uri_type($params{URIType}) if (defined($params{URIType}));
       
	# If the data is data already loaded in memory...
        if(defined($data))
	{
	        if(defined($params{Chunked}))
	        {
      			my $data_stream = IO::Scalar->new($data);
			my $record;
			for(my $i=0;$record = $self->create_chunk_record($data_stream);$i++)
			{
				$self->add_record($record);
			}
			$data_stream->close();
	        }
	        else
	        {
        			# The attachment goes in one record
        		
	        		my $record = DIME::Record->new($self);
        		
				my $data_io = IO::Scalar->new(\$data);
		                $record->data($data_io); 

			        $self->add_record($record);
	        }
        }
}

sub print
{
	my $self = shift;
	my $out = shift;
	if(defined($self->{_STREAM}))
	{
		if($self->{_CHUNK_SIZE})
		{
			my $i=0;
			while(my $record = $self->create_chunk_record($self->{_STREAM}))
			{
				$record->mb(1) if($self->mb() and $i==0);
				$record->me(1) if($self->me() and $self->{_STREAM}->eof());
				$record->print($out);
				$i++;
			}
		}
		else
		{
			my $record = DIME::Record->new($self);
			$record->data($self->{_STREAM});
			$record->mb(1) if($self->mb());
			$record->me(1) if($self->me());
			$record->print($out);
		}
	}
	else
	{
		my @records = @{$self->{_RECORDS}};
		my $howmany = @records;
		for(my $i=0;$i<$howmany;$i++)
		{
			$records[$i]->mb(1) if($self->mb() and $i==0);
			$records[$i]->me(1) if($self->me() and $i==$howmany-1);
			$records[$i]->print($out);
		}
	}
}

sub print_content
{
	my $self = shift;
	my $io = shift;
	my $buf;
	for my $r (@{$self->{_RECORDS}})
	{
		$r->print_content($io);
	}
}

sub print_content_data
{
	my $self = shift;
	my $data;
	my $io = IO::Scalar->new(\$data);
	$self->print_content($io);
	$io->close();
	return \$data;
}

sub print_data
{
	my $self = shift;
	my $data;
	my $io = IO::Scalar->new(\$data);
	$self->print($io);
	$io->close();
	return \$data;
}

sub print_chunk_data
{
	my $self = shift;
	my $data;
	my $io = IO::Scalar->new(\$data);
	$self->print_chunk($io);
	$io->close();
	return \$data;
}

sub print_chunk
{
	my $self = shift;
	my $out = shift;
	if(defined($self->{_STREAM}) and $self->{_CHUNK_SIZE})
	{
		my $record;
		if($record = $self->create_chunk_record($self->{_STREAM}))
		{
			$record->print($out);
		}
	}
}

# This method takes data from a IO::Handle
# and returns a DIME chunked record with a max size
# of _CHUNK_SIZE bytes

sub create_chunk_record
{
	my $self = shift;
	my $in_stream = shift;

	my $buf;
	my $bytes_read;
	my $record;
	$bytes_read = $in_stream->read($buf,$self->{_CHUNK_SIZE});
	if($bytes_read)
	{
		$record = DIME::Record->new($self);
		my $io_data = IO::Scalar->new(\$buf);
		$record->data($io_data);
		if($self->{_FIRST_RECORD})
		{
			$self->{_FIRST_RECORD} = 0;
			$record->id($self->id());
			$record->chunked(1);
		}
		elsif($in_stream->eof())
		{
			$record->id('');
			$record->set_unchanged_type();
			$record->chunked(0);
		}
		else
		{
			$record->id('');
			$record->set_unchanged_type();
			$record->chunked(1);
		}
	}
	return $record;
}


sub set_mime_type
{
        my $self = shift;
        my $type = shift;
        $self->type($type);
        $self->{_TNF} = 0x01;
}

sub set_uri_type
{
        my $self = shift;
        my $type = shift;
        $self->type($type);
        $self->{_TNF} = 0x02;
}					                	

1;

=encoding UTF-8

=head1 NAME

DIME::Payload - implementation of a payload of a DIME message

=head1 SYNOPSIS

  # Create a standard DIME message from an existing file
  # and a string

  use DIME::Payload;

  $payload1 = DIME::Payload->new();
  $payload1->attach(Path => 'existingfile.jpg',
		    MIMEType => 'image/jpeg',
		    Dynamic => 1);

  $payload2 = DIME::Payload->new();
  my $data = 'Hello World!!!';
  $payload2->attach(Data => \$data,	
		    MIMEType => 'text/plain');

  my $message = DIME::Message->new();
  $message->add_payload($payload1);
  $message->add_payload($payload2);

=head1 DESCRIPTION

DIME::Payload represents the content of DIME message. A message is composed of one or many Payload objects.

There are two types of DIME payloads: chunked and not chunked. A DIME message that isn't chunked has only one record with all the Payload content. A chunked message is splited in several records, allowing to sender and receiver process the content without know the total size of this.

=head1 CHUNKED AND DYNAMIC CONTENT

To create a chunked message you have to specify the Chunked key:

	# This create a dynamic payload with records of 16384 bytes

	my $payload = DIME::Payload->new();
	$payload->attach(Path => 'bigfile.avi',
			 Chunked => 16384,
			 Dynamic => 1);

	# You can encode all the payload at once:

	my $dime_encoded_message = ${$payload->print_data()};

	# Or, if you prefer, you can generate each chunk

	my $ret;
	do
	{
		$chunk = ${$payload->print_chunk_data()};
	} while ($chunk ne '');


The Dynamic key is used to avoid load all the file in memory. What DIME::Payload does is to open the file and, when it need more content, read from the file. If you don't set the Dynamic key, all the data is loaded in memory.

=head1 CONTENT TYPE

To specify the type of content of a Payload, you should use the MIMEType and URIType keys:

	# MIME media-type
	my $payload = DIME::Payload->new();
	$payload->attach(Path => 'image.jpg',
			 MIMEType => 'image/jpeg');

	# absolute URI 
	my $payload = DIME::Payload->new();
	$payload->attach(Path => 'message.xml',
			 URIType => 'http://schemas.xmlsoap.org/soap/envelope/');

=head1 PAYLOAD IDENTIFIER

When you create a new Payload, a unique identifier is generated automatically. You can get/set it with the id() method:

	my $payload = DIME::Payload->new();
	print $payload->id();

=head1 AUTHOR

Domingo Alcazar Larrea, E<lt>dalcazar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Domingo Alcázar Larrea

This program is free software; you can redistribute it and/or
modify it under the terms of the version 2 of the GNU General
Public License as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

=cut

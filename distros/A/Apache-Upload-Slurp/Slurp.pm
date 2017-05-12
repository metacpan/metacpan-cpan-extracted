=head1 NAME

Apache::Upload::Slurp - Component to slurp all uploaded file

=head1 SYNOPSIS

    use Apache::Upload::Slurp ();
    my $obj = new Apache::Upload::Slurp;
    my $uploads = $obj->uploads;

=head1 DESCRIPTION

I<Apache::Upload::Slurp> put all uploaded files via 
I<application/x-www-form-urlencoded> and their information in an array
to be simply process by clients.

=head1 METHODS

=head2 new

Create a new I<Apache::Upload::Slurp> object and process uploads

    my $obj = new Apache::Upload::Slurp;

=cut

package Apache::Upload::Slurp;

use strict;
use warnings;

use Apache::Request;

our $VERSION = '0.03';

sub new {
	my $package = shift;
  my $attribs = shift || {};
  my $self = bless $attribs, $package;
	return $self;
}

sub _slurp {
	my $self		= shift;
	$self->{uploads} = {};
	my $r = Apache::Request->instance( Apache->request );
	for (my $upload = $r->upload; $upload; $upload = $upload->next) {
		my $file_info = {};
		my $fh = $upload->fh;
		if (defined $fh) {
			my $binary;
			while (<$fh>) {
					$binary .= $_;
			}
			$file_info->{data} 			= $binary;
			$file_info->{filename} 	= $upload->filename;
			$file_info->{size} 			= $upload->size;
			$file_info->{name} 			= $upload->name;
			$file_info->{type} 			= $upload->type;
			my $info = $upload->info;
			while (my($key, $val) = each %$info) {
				$file_info->{$key} = $val;
			}
			$self->{uploads}->{$file_info->{name}} = $file_info;
		}
  }
}

sub _slurp_single {
	my $self				= shift;
	my $upload_name = shift;
	return $self->{uploads}->{$upload_name} 
		if (exists $self->{uploads}->{$upload_name});
	my $r = Apache::Request->instance( Apache->request );
	my $upload = $r->upload($upload_name);
	my $file_info = {};
	my $fh = $upload->fh;
	if (defined $fh) {
		my $binary;
		while (<$fh>) {
				$binary .= $_;
		}
		$file_info->{data} 			= $binary;
		$file_info->{filename} 	= $upload->filename;
		# IE add all path to filename, remove it
		$file_info->{filename} =~ s/\w\:\\(.+\\)*//;
		$file_info->{size} 			= $upload->size;
		$file_info->{name} 			= $upload->name;
		$file_info->{type} 			= $upload->type;
		my $info = $upload->info;
		while (my($key, $val) = each %$info) {
			$file_info->{$key} = $val;
		}
		$self->{uploads}->{$file_info->{name}} = $file_info;
		return $file_info;
  }
}

=pod

=head2 uploads

Return an array or an arrayref with an hashref for every file uploaded.
The hashref has this structure:

=over 4

=item * data

The binary stream of the file

=item * filename

The filename from the client point of view

=item * size

The size of the uploaded file

=item * name

The name of the form field that uploaded file.

=item * type

The content type of the uploaded file.

=item * other keys 

From the additional header information for the uploaded file

=back
    
=cut

sub uploads {
	my $self = shift;
	$self->_slurp;
	my @uploads = values %{$self->{uploads}};
	return wantarray ? @uploads : \@uploads;
}

=head2 upload(form_name)

Return an hash or hashref (based on contest) with infos for the single upload
The hashref has this structure:

=over 4

=item * data

The binary stream of the file

=item * filename

The filename from the client point of view

=item * size

The size of the uploaded file

=item * name

The name of the form field that uploaded file.

=item * type

The content type of the uploaded file.

=item * other keys 

From the additional header information for the uploaded file

=back
    
=cut

sub upload {
	my $self = shift;
	my $upload_name = shift;
	my $ret = $self->_slurp_single($upload_name);
	return wantarray ? %$ret : $ret;
}

1;

=pod

=head1 LICENSE

Apache::Upload::Slurp - Component to slurp all uploaded file

Copyright (C) 2006 Bruni Emiliano <info AT ebruni DOT it>

This module is free software; you can redistribute it and/or modify it under the terms of
either:

a) the GNU General Public License as published by the Free Software Foundation; 
either version 2, or (at your option) any later version, or

b) the "Artistic License" which comes with this module.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See
either the GNU General Public License or the Artistic License for more details.

You should have received a copy of the Artistic License with this module, 
in the file ARTISTIC.  If not, I'll be glad to provide one.

You should have received a copy of the GNU General Public License along with this program; if
not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA

=head1 AUTHOR

Bruni Emiliano, <info AT ebruni DOT it>

=head1 SEE ALSO

L<Apache::Upload>

=cut

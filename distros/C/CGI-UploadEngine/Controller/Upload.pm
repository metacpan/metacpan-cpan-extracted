package MBC::Controller::Upload;

use strict;
use warnings;
use Catalyst 'Session';
use base 'Catalyst::Controller';
use CGI::UploadEngine;
use Moose;
use namespace::autoclean;

# Sets the actions in this controller to be registered with no prefix
__PACKAGE__->config->{namespace} = '';

=head1 NAME

MBC::Controller::Upload - Upload Controller for MBC

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

sub upload : Local {
        my ($self, $c) = @_;

	my $token  = $c->request->param('token');
	my $upload = CGI::UploadEngine->new();
	my $file_obj;
	eval {
		# Validate upload attempt
		$file_obj  = $upload->upload_validate({ token => $token });
	
		# Upload file to server
		my ( $file_name, $target, $file_size, $success, @file_parts, $file_path_name ); 
		if ( my $file = $c->request->upload('auto_file') ) {
			# Clean client path from file name
			$file_path_name = $file->filename;
			if    ( $file_path_name =~ m%\\% ) { 
				@file_parts = split( /\\/, $file_path_name ); 
				$file_name = pop( @file_parts ); 
			} elsif ( $file_path_name =~ m%/% ) { 
				@file_parts = split( /\//, $file_path_name ); 
				$file_name = pop( @file_parts ); 
			}

			# Build server path name
			if ( $upload->verbose() ) { warn "TARGET: " . $file_obj->{file_path} . " + " . $file_name; }
			$target   = $file_obj->{file_path} . $file_name;

			# Save the file
			if ( not $file->link_to($target) and not $file->copy_to($target) ) {
				 die("ERROR: Failed to copy '$file_name' to '$target': $!");
			}

			# Check file size limits
			$file_size = $file->size; 
			my $min_size = $file_obj->{min_size};
			my $max_size = $file_obj->{max_size};
			if ( $upload->verbose() ) { warn "SIZE: ( $file_size , $max_size, $min_size )"; }
			if ( $file_size < $min_size ) {
				die("ERROR: file size $file_size is smaller than min size $min_size");
			}
			if ( $file_size > $max_size){
				die("ERROR: file size $file_size is larger than max size $max_size");
			}

			# Check file type limits
			$file_name           =~ /.*(\..*)$/;
			my $type             = $1;
			my $allowed_types    = $file_obj->{allowed_types};
			my $disallowed_types = $file_obj->{disallowed_types};
			if ( $upload->verbose() ) { warn "TYPES: ( $type , $allowed_types, $disallowed_types )"; }
			if ( length($allowed_types) > 1 ) {
				if(not $allowed_types =~ /$type/){
					die("ERROR: file type $type not allowed. Allowed types are: $allowed_types");
				}
			} elsif ( length($disallowed_types)>1 ) {
				if($disallowed_types =~ /$type/){
					die("ERROR: file type $type is forbidden. Forbidden types are: $disallowed_types");
				}
			}

			# Success
			$success  = $upload->upload_success({ token => $token, file_name => $file_name, file_size => $file_size}); 
			$c->stash->{'success'} = '"' . $success . '"';
			$c->stash->{template} = 'upload.tt2';
			$c->response->header('Content-Type' => 'text/html');
		}else{
			die("ERROR: request upload failed");
		}
	};
	if($@){
		# Check to see if exception is one of mine, and remove the exception origin 
		# from the end of the string as it will mess up the JSON
		if($@ =~ /(ERROR:.*)at \/.*/){
			# Exception is mine, handle it
			$c->stash->{'success'} = '"' . $1 . '"';
			$c->stash->{template} = 'upload.tt2';
			$c->response->header('Content-Type' => 'text/html');
			warn($@);		
		}else{
			# Rethrow exception that's not mine
			die($@);
		}
	}
}

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Roger Hall, Michael Bauer, et. al.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

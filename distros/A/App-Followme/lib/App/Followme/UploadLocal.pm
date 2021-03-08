package App::Followme::UploadLocal;

use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::ConfiguredObject);

use File::Copy;
use File::Path qw(remove_tree);
use File::Spec::Functions qw(abs2rel splitdir catfile);

our $VERSION = "2.00";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            remote_directory => '',
            permissions => 0644,
           );
}

#----------------------------------------------------------------------
# Add a directory to the remote site

sub add_directory {
    my ($self, $dir) = @_;

    my $new_dir = catfile($self->{remote_directory}, $dir);
    my $status = mkdir($new_dir);

    if ($status) {
        my $permissions = $self->{permissions} | 0111;
        chmod($permissions, $new_dir);
    }

    return $status;
}

#----------------------------------------------------------------------
# Add a file to the remote site

sub add_file {
    my ($self, $local_filename, $remote_filename) = @_;

    my $new_file = catfile($self->{remote_directory}, $remote_filename);
    my $status = copy($local_filename, $new_file);

    chmod($self->{permissions}, $new_file) if $status;
    return $status;
}

#----------------------------------------------------------------------
# Close the connection

sub close {
    my ($self) = @_;
    return;
}

#----------------------------------------------------------------------
# Delete a directory from the remote site

sub delete_directory {
    my ($self, $dir) = @_;

    my $err;
    my $new_dir = catfile($self->{remote_directory}, $dir);
    remove_tree($new_dir, {error => $err});

    my $status = ! ($err && @$err);
    return $status;
}

#----------------------------------------------------------------------
# Delete a file from the remote site

sub delete_file {
    my ($self, $filename) = @_;

    my $new_file = catfile($self->{remote_directory}, $filename);
    my $status = unlink($new_file);

    return $status;
}

#----------------------------------------------------------------------
# Open the connection to the remote site

sub open {
    my ($self, $user, $password) = @_;

    # Check existence of remote directory
    my $found = $self->{remote_directory} && -e $self->{remote_directory};

    die "Could not find remote_directory: $self->{remote_directory}"
        unless $found;

    return;
}

1;
__END__
=encoding utf-8

=head1 NAME

App::Followme::UploadLocal - Upload files through file copy

=head1 SYNOPSIS

    my $uploader = App::Followme::UploadLocal->new(\%configuration);
    $uploader->open();
    $uploader->add_directory($dir);
    $uploader->add_file($filename);
    $uploader->delete_directory($dir);
    $uploader->delete_file($filename);
    $uploader->close();

=head1 DESCRIPTION

L<App::Followme::UploadSite> splits off methods that do the actual uploading
into a separate package, so it can support more than one method. This package
uploads files to the server using a simple file copy.

=head1 METHODS

The following are the public methods of the interface. The return value
indicates if the operation was successful.

=over 4

=item $flag = $self->add_directory($dir);

Create a new directory

=item $flag = $self->add_file($filename);

Upload a new file. If it already exists, delete it.

=item $self->close();

Close the connection to the remote site.

=item $flag = $self->delete_directory($dir);

Delete a directory, including any files it might hold.

=item $flag = $self->delete_file($filename);

Delete a file on the remote site.

=item $self->open();

Open the connection to the remote site

=item $self->setup();

Set up computed fields in the new object

=back

=head1 CONFIGURATION

The following parameters are used from the configuration.

=over 4

=item remote_directory

The top directory of the website the files are being copied to

=item permissions

The permissions to put on the remote file.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

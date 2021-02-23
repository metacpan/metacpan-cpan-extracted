package App::Followme::UploadNone;

use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::ConfiguredObject);


our $VERSION = "1.98";

#----------------------------------------------------------------------
# Add a directory to the remote site

sub add_directory {
    my ($self, $dir) = @_;
    return 1;
}

#----------------------------------------------------------------------
# Add a file to the remote site

sub add_file {
    my ($self, $local_filename, $remote_filename) = @_;
    return 1;
}

#----------------------------------------------------------------------
# Close the ftp connection

sub close {
    my ($self) = @_;
    return;
}

#----------------------------------------------------------------------
# Delete a directory from the remote site

sub delete_directory {
    my ($self, $dir) = @_;
    return 1;
}

#----------------------------------------------------------------------
# Delete a file from the remote site

sub delete_file {
    my ($self, $filename) = @_;
    return 1;
}

#----------------------------------------------------------------------
# Open the connection to the remote site

sub open {
    my ($self, $user, $password) = @_;
    return;
}

1;
__END__
=encoding utf-8

=head1 NAME

App::Followme::UploadNone - Go through the motions of uploading files

=head1 SYNOPSIS

    my $uploader = App::Followme::UploadNone->new(\%configuration);
    $uploader->open($user, $password);
    $uploader->add_directory($dir);
    $uploader->add_file($local_filename, $remote_filename);
    $uploader->delete_directory($dir);
    $uploader->delete_file($filename);
    $uploader->close();

=head1 DESCRIPTION

L<App::Followme::UploadSite> splits off methods that do the actual uploading
into a separate package, so it can support more than one method. This is the
null method, that does no upload, which is invoked when the user only wants to
update the checksums without doing any uploads. In addition, this package
serves as a template for other packages, because it has all the necessary
methods with the correct interfaces.

=head1 METHODS

The following are the public methods of the interface. The return value
indicates if the operation was successful.

=over 4

=item $flag = $self->add_directory($dir);

Create a new directory

=item $flag = $self->add_file($locl_filename, $remote_filename);

Upload a new file. If it already exists, delete it.

=item $self->close();

Close the connection to the remote site.

=item $flag = $self->delete_directory($dir);

Delete a directory, including any files it might hold.

=item $flag = $self->delete_file($filename);

Delete a file on the remote site.

=item $self->open($user, $password);

Open the connection to the remote site

=item $self->setup();

Set up computed fields in the new object

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

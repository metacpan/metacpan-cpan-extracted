package App::Followme::UploadFtp;

use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::ConfiguredObject);
use Net::FTP;
use File::Spec::Functions qw(abs2rel splitdir catfile);

our $VERSION = "1.94";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            ftp_url => '',
            remote_directory => '',
            ftp_debug => 0,
            remote_pkg => 'File::Spec::Unix',
           );
}

#----------------------------------------------------------------------
# Add a directory to the remote site

sub add_directory {
    my ($self, $dir) = @_;

    my $status;
    $dir = $self->remote_name($dir);

    if ($self->{ftp}->ls($dir)) {
        $status = 1;
    } elsif ($self->{ftp}->mkdir($dir)) {
        $status = 1;
    }

    return $status;
}

#----------------------------------------------------------------------
# Add a file to the remote site

sub add_file {
    my ($self, $local_filename, $remote_filename) = @_;

    my $status;
    $remote_filename = $self->remote_name($remote_filename);

    # Delete file if already there
    if ($self->{ftp}->mdtm($remote_filename)) {
        $self->{ftp}->delete($remote_filename);
    }

    # Change upload mode if necessary
    if (-B $local_filename) {
        if ($self->{ascii}) {
            $self->{ftp}->binary();
            $self->{ascii} = 0;
        }

    } elsif (! $self->{ascii}) {
        $self->{ftp}->ascii();
        $self->{ascii} = 1;
    }

    # Upload the file
    if ($self->{ftp}->put($local_filename, $remote_filename)) {
        $status = 1;
    }

    return $status;
}

#----------------------------------------------------------------------
# Close the ftp connection

sub close {
    my ($self) = @_;

    $self->{ftp}->quit();
    undef $self->{ftp};

    return;
}

#----------------------------------------------------------------------
# Delete a directory on the remote site, including contents

sub delete_directory {
    my ($self, $dir) = @_;

    my $status;
    $dir = $self->remote_name($dir);

    if ($self->{ftp}->ls($dir)) {
        if ($self->{ftp}->rmdir($dir)) {
            $status = 1;
        }

    } else {
        $status = 1;
    }

    return $status;
}

#----------------------------------------------------------------------
# Delete a file on the remote site

sub delete_file {
    my ($self, $filename) = @_;

    my $status;
    $filename = $self->remote_name($filename);

    if ($self->{ftp}->mdtm($filename)) {
        if ($self->{ftp}->delete($filename)) {
            $status = 1;
        }

    } else {
        $status = 1;
    }

    return 1;
}

#----------------------------------------------------------------------
# Open the connection to the remote site

sub open {
    my ($self, $user, $password) = @_;

    # Open the ftp connection

    my $ftp = Net::FTP->new($self->{ftp_url}, Debug => $self->{ftp_debug})
        or die "Cannot connect to $self->{ftp_url}: $@";

    $ftp->login($user, $password) or die "Cannot login ", $ftp->message;

    $ftp->cwd($self->{remote_directory})
        or die "Cannot change remote directory ", $ftp->message;

    $ftp->binary();

    $self->{ftp} = $ftp;
    $self->{ascii} = 0;

    return;
}

#----------------------------------------------------------------------
# Get the name of the file on the remote system

sub remote_name {
    my ($self, $remote_filename) = @_;

    my @path = splitdir($remote_filename);
    $remote_filename = $self->{remote}->catfile(@path);
    return $remote_filename;
}

1;
__END__
=encoding utf-8

=head1 NAME

App::Followme::UploadFtp - Upload files using ftp

=head1 SYNOPSIS

    my $ftp = App::Followme::UploadNone->new(\%configuration);
    $ftp->open($user, $password);
    $ftp->add_directory($dir);
    $ftp->add_file($local_filename, $remote_filename);
    $ftp->delete_file($filename);
    $ftp->delete_dir($dir);
    $ftp->close();

=head1 DESCRIPTION

L<App::Followme::UploadSite> splits off methods that do the actual uploading
into a separate package, so it can support more than one method. This package
uploads files using good old ftp.

=head1 METHODS

The following are the public methods of the interface

=over 4

=item $flag = $self->add_directory($dir);

Create a new directory.

=item $flag = $self->add_file($local_filename, $remote_filename);

Upload a file.

=item $flag = $self->delete_directory($dir);

Delete a directory, including its contents

=item $flag = $self->delete_file($filename);

Delete a file on the remote site. .

=item $self->close();

Close the ftp connection to the remote site.

=back

=head1 CONFIGURATION

The follow parameters are used from the configuration. In addition, the package
will prompt for and save the user name and password.

=over 4

=item ftp_debug

Set to one to trace the ftp commands issued. Useful to diagnose problems
with ftp uploads. The default value is zero.

=item remote_directory

The top directory of the remote site

=item ftp_url

The url of the remote ftp site.

=item remote_pkg

The name of the package that manipulates filenames for the remote system. The
default value is 'File::Spec::Unix'. Other possible values are
'File::Spec::Win32' and 'File::Spec::VMS'. Consult the Perl documentation for
more information.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

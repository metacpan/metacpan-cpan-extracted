package App::Followme::UploadData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::FolderData);

use Digest::MD5 qw(md5_hex);
use App::Followme::FIO;
use App::Followme::Web;

our $VERSION = "1.99";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
           );
}

#----------------------------------------------------------------------
# Calculate the check sum for a file

sub calculate_checksum {
    my ($self, $filename) = @_;

    my $page = fio_read_page($filename, ':raw');
    return '' unless $page;

    my $md5 = Digest::MD5->new;
    $md5->add($page);

    return $md5->hexdigest;
}

#----------------------------------------------------------------------
# Return true if this is an included file

sub match_file {
    my ($self, $filename) = @_;

    $self->{exclude_file_patterns} ||= fio_glob_patterns($self->{exclude});

    my ($dir, $file) = fio_split_filename($filename);

    return if $self->match_patterns($file, $self->{exclude_file_patterns});
    return 1;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::UploadData

=head1 SYNOPSIS

    use App::Followme::UploadData;
    my $meta = App::Followme::UploadData->new(exclude => '*.cfg');
    my $index_file = $self->to_file($self->{base_directory});
    my $files = App::Followme::Template->build('files', $index_file);

=head1 DESCRIPTION

This module generates the list of files and folders to be uploaded to the
remote site and the checksums for each file.

=head1 METHODS

All data classes are first instantiated by calling new and data items are
retrieved by calling the build method with the item name as the first argument
and the file or folder as the second argument.

=head1 VARIABLES

The file metadata class can evaluate the following variables. When passing
a name to the build method, the sigil should not be used.

=over 4

=item @files

The list of files to be uploaded from a folder.

=item @folders

The list of folders contining files to be uploaded

=item $checksum

The MD5 hash of the file contents, used for determining if file has changed
and needs to be uploaded.

=back

=head1 CONFIGURATION

This class has the following configuration variables:

=over 4

=item excluded

A filename pattern or comma separated list of filename patterns that match files
that should not be uploaded. The default value is '*.cfg' which matches
configuration files.

=item exclude_dirs

A filename pattern or comma separated list of filename patterns that match
folders that should not be uploaded/ The default value is '.*,_*' which
matches folders starting with a dot (hiddern folders) and starting with an
underscore character.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

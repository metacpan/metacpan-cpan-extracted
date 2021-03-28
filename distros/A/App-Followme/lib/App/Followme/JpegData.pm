package App::Followme::JpegData;

use 5.008005;
use strict;
use warnings;
use integer;
use lib '../..';

use base qw(App::Followme::FileData);

use Image::Size;
use File::Spec::Functions qw(catfile);
use App::Followme::FIO;

our $VERSION = "2.02";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($self) = @_;

    return (
            extension => 'jpg',
            target_prefix => 'img',
            thumb_suffix => '-thumb',
           );
}

#----------------------------------------------------------------------
# Look in the file for the data

sub fetch_from_file {
    my ($self, $filename) = @_;

    return () unless -e $filename;
    return $self->SUPER::fetch_from_file($filename) if -T $filename;

    my %dimensions;
    ($dimensions{width}, $dimensions{height}) = imgsize($filename);

    return %dimensions;
}

#----------------------------------------------------------------------
# Get the name of the thumb photo file

sub get_thumb_file {
    my ($self, $filename) = @_;

    my ($dir, $file) = fio_split_filename($filename);
    my ($root, $ext) = split(/\./, $file);
    $file = join('', $root, $self->{thumb_suffix}, '.', $ext);
    my $photoname = catfile($dir, $file);

    return [$photoname];
}

#----------------------------------------------------------------------
# Get a url from a filename

sub get_url {
    my ($self, $filename) = @_;

    return $self->filename_to_url($self->{top_directory},
                                  $filename);
}

#----------------------------------------------------------------------
# Set up exclude

sub setup {
    my ($self) = @_;

    my $dir;
    my $thumb_files = $self->get_thumb_file("*.$self->{extension}");
    ($dir, $self->{exclude}) = fio_split_filename($thumb_files->[0]);

    return;
}

1;

=pod

=encoding utf-8

=head1 NAME

App::Followme::JpegData - Read datafrom a jpeg file

=head1 SYNOPSIS

    use App::Followme::JpegData;
    my $data = App::Followme::JpegData->new();
    my $html = App::Followme::Template->new('example.htm', $data);

=head1 DESCRIPTION

This module extratcs metadata from a jpeg image and uses that metadata to
build variables used in a template.

=head1 METHODS

All data classes are first instantiated by calling new and the object
created is passed to a template object. It calls the build method with an
argument name to retrieve that data item, though for the sake of
efficiency, all the data are read from the file at once.

=head1 VARIABLES

=over 4

=item @thumb_file

The name of the thumb file for a photo. Even though this is a single file, it
is returned as a hash and thus must be used in a for statement.

=item $height

The height of the photo

=item $width

The width of the photo

=back

=head1 CONFIGURATION

The following fields in the configuration file are used in this class and every
class based on it:

=over 4

=item extension

The extension used by jpeg files.

=item target_prefix

The prefix used to build the target names. The default value is 'img'.

=item thumb_suffix

The suffix added to the root of the photo filename to build the thumb photo
filename. The default value is '-thumb'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

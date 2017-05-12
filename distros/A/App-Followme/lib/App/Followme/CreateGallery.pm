package App::Followme::CreateGallery;
use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use GD;
use IO::File;
use File::Spec::Functions qw(abs2rel rel2abs splitdir catfile);
use App::Followme::FIO;

our $VERSION = "1.92";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            thumb_suffix => '-thumb',
            thumb_width => 0,
            thumb_height => 0,
            photo_width => 0,
            photo_height => 0,
            template_file => 'create_gallery.htm',
            data_pkg => 'App::Followme::JpegData',
            );
}

#----------------------------------------------------------------------
# Build a photo gallery

sub run {
    my ($self, $directory) = @_;

    eval {
        $self->resize_photos($directory);
        $self->update_folder($directory)
    };

    $self->check_error($@, $directory);

    return;
}

#---------------------------------------------------------------------------
# Calculate the new width and height of a photo

sub new_size {
    my($self, $field, $width, $height) = @_;

    my $width_field = "${field}_width";
    my $height_field = "${field}_height";

    my $factor;
    if ($self->{$width_field} && $self->{$height_field}) {
        my $width_factor = $self->{$width_field} / $width;
        my $height_factor = $self->{$height_field} / $height;
        $factor = ($height_factor < $width_factor ? $height_factor : $width_factor);

    } elsif ($self->{$width_field}) {
       $factor = $self->{$width_field} / $width;

    } elsif ($self->{$height_field}) {
        $factor = $self->{$height_field} / $height;

    } else {
        $factor = 0.0;
    }

    my $new_height = int($factor * $height);
    my $new_width  = int($factor * $width);

    return ($new_width, $new_height);
}

#---------------------------------------------------------------------------
# Resize a photo, return undef if it does not need to be resized

sub resize_a_photo {
    my ($self, $file, $new_width, $new_height, $width, $height) = @_;
    return if $width == $new_width && $height == $new_height;

    my $photo = GD::Image->new($file);
    my $new_photo = GD::Image->new($width, $height);

    $new_photo->copyResampled($photo,
                          0, 0, 0, 0,
                          $new_width, $new_height,
                          $width, $height);

    return $new_photo;
}

#---------------------------------------------------------------------------
# Resize any new photos that has been added to a directory

sub resize_photos {
    my ($self, $folder) = @_;

    my $index_file = $self->to_file($folder);
    my $files = $self->{data}->build('files', $index_file);

    foreach my $file (@$files) {
        last if fio_is_newer($index_file, $file);

        for my $field (qw(thumb photo)) {

            my $width = ${$self->{data}->build('width', $file)};
            my $height = ${$self->{data}->build('height', $file)};
            my ($new_width, $new_height) =
                $self->new_size($field, $width, $height);

            if ($new_width && $new_height) {
                my $new_photo = $self->resize_a_photo($file,
                                                      $new_width,
                                                      $new_height,
                                                      $width,
                                                      $height);
                if ($new_photo) {
                    my $photoname;
                    if ($field eq 'photo') {
                        $photoname = $file;
                    } else {
                        my $thumb_files = $self->{data}->build('thumb_file',
                                                               $file);
                        $photoname = $thumb_files->[0];
                    }

                    $self->write_photo($photoname, $new_photo);
                }
            }
        }
    }
}

#----------------------------------------------------------------------
# Update the index files in each directory

sub update_folder {
    my ($self, $folder) = @_;

    my $index_file = $self->to_file($folder);
    my $newest_file = $self->{data}->build('newest_file', $index_file);
    my $template_file = $self->get_template_name($self->{template_file});

    unless (fio_is_newer($index_file, $template_file, @$newest_file)) {
        my $page = $self->render_file($template_file, $index_file);
        my $prototype_file = $self->find_prototype();

        $page = $self->reformat_file($prototype_file, $index_file, $page);
        fio_write_page($index_file, $page);
    }

    return;
}

#----------------------------------------------------------------------
# Save a photo

sub write_photo {
    my ($self, $photoname, $photo) = @_;

    my $fd = IO::File->new($photoname, 'w');
    die "Couldn't write $photoname" unless $fd;

    my $data = $photo->jpeg();

    binmode($fd);
    print $fd $data;
    close($fd);

    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Followme::CreateGallery - Create a photo gallery page

=head1 SYNOPSIS

    use App::Followme::CreateGallery;
    my $gallery = App::Followme::CreateGallery->new($configuration);
    $gallery->run($directory);

=head1 DESCRIPTION

This package builds an index for a directory which serves as a photo gallery.
The variables described below are substituted into a template to produce the
gallery.

=head1 CONFIGURATION

The following fields in the configuration file are used:

=over 4

=item template_file

The name of the template used to produce the photo gallery. The default is
'create_gallery.htm'.

=item thumb_suffix

The suffix added to the photo name to produce the thumb photo name. The default
is '-thumb'.

=item thumb_width

The width of the thumb photos. Leave at 0 if the width is defined to be
proportional to the height.

=item thumb_height

The height of the thumb photos. Leave at 0 if the height is defined to be
proportional to the width. If both thumb_width and thumb_height are 0, no
thumb photo will be created.

=item photo_width

The width of the photo after resizing. Leave at 0 if the width is defined to be
proportional to the height.

=item photo_height

The height of the photo after resizing. Leave at 0 if the height is defined to
be proportional to the width. If both photo_width and photo_height are zero,
the image will not be resized.

=item data_pkg

The name of the package used to retrieve data from the photos. The default value
is 'App::Followme::JpegData'.

=back

=head1 LICENSE

Copyright (C) Bernie Simon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Bernie Simon E<lt>bernie.simon@gmail.comE<gt>

=cut

package App::Followme::CreateGallery;
use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::Module);

use IO::File;
use File::Spec::Functions qw(abs2rel rel2abs splitdir catfile);
use App::Followme::FIO;

our $VERSION = "1.95";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            thumb_suffix => '-thumb',
            template_file => 'create_gallery.htm',
            data_pkg => 'App::Followme::JpegData',
            );
}

#----------------------------------------------------------------------
# Build a photo gallery

sub run {
    my ($self, $directory) = @_;

    eval {$self->update_folder($directory)};
    $self->check_error($@, $directory);

    return;
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

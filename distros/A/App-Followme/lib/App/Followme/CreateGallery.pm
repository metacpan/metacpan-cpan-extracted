package App::Followme::CreateGallery;
use 5.008005;
use strict;
use warnings;

use lib '../..';

use base qw(App::Followme::CreateIndex);

use IO::File;
use File::Spec::Functions qw(abs2rel rel2abs splitdir catfile);
use App::Followme::FIO;

our $VERSION = "2.01";

#----------------------------------------------------------------------
# Read the default parameter values

sub parameters {
    my ($pkg) = @_;

    return (
            template_file => 'create_gallery.htm',
            data_pkg => 'App::Followme::JpegData',
            );
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

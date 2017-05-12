package CSS::SpriteBuilder::ImageDriver::Auto;

=head1 NAME

CSS::SpriteBuilder::ImageDriver::Auto - Class for auto select image manipulation module.

=cut

use warnings;
use strict;

our @MODULES = qw(Image::Magick GD);

TRY_LOAD: {
    for (@MODULES) {
        my $module = $_;
        $module =~ s/:://g;
        eval "use base 'CSS::SpriteBuilder::ImageDriver::$module'";
        last TRY_LOAD unless $@;
    }
    warn "You need one of these modules: ". join(', ', @MODULES) .", will use fake-mode.";
    eval "use base 'CSS::SpriteBuilder::ImageDriver::Fake'";
};

1;

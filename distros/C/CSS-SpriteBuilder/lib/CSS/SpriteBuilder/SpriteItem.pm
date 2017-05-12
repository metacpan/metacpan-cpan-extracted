package CSS::SpriteBuilder::SpriteItem;

use warnings;
use strict;
use base 'CSS::SpriteBuilder::ImageDriver::Auto';

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(
        source_file       => undef,
        is_background     => undef,
        is_repeat         => 0,
        css_selector      => undef,
        @args,
    );

    my $source_file = $self->{source_file}
        or die "The 'source_file' parameter is required";

    $self->read($source_file);

    return $self;
}

sub source_file   { return $_[0]->{source_file   } }
sub is_background { return $_[0]->{is_background } }
sub is_repeat     { return $_[0]->{is_repeat     } }
sub css_selector  { return $_[0]->{css_selector  } }

sub get_css_selector {
    my ($self, $css_selector_prefix) = @_;

    my $selector = $self->{css_selector};
    unless ($selector) {
        # Convert "img/icon/arrow.gif" to ".spr-img-icon-arrow"
        my (undef, $dirs, $file) = File::Spec->splitpath( $self->{source_file} );
        my @dirs = grep { $_ } File::Spec->splitdir($dirs);

        # remove extension
        $file =~ s/\.[^\.]+$//;
        $selector = lc( ($css_selector_prefix || '') . join('-', @dirs, $file) );

        $selector =~ s/[\s_]+/-/g;
    }

    return $selector;
}

1;

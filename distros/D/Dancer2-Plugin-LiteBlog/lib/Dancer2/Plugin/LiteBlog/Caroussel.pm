package Dancer2::Plugin::LiteBlog::Caroussel;

=head1 NAME

Dancer2::Plugin::LiteBlog::Caroussel - A slider widget for Liteblog

=head1 DESCRIPTION

This is basically the same as the Splash widget, but you can provide an 
array of slides and it will be possible for the user to slide in and out.

=head1 CONFIGURATION

The Widget looks for its configuration under the C<liteblog> entry of the
Dancer2 application.

It can be used either with a single entry, like so:

    liteblog:
      ...
      widgets:
        - name: caroussel
          params: 
            slides:
              - title: "This is slide 1"
                image: '/images/foo.jpg'
                baseline: "Some baseline" 
                cta:
                  label: "Subscribe to my Newsletter" # label of the button
                  link: "/subscribe" # the URL of the button
              - title: "This is slide 2"
                image: '/images/foo.jpg'
                baseline: "Some baseline" 
                cta:
                  label: "Subscribe to my Newsletter" # label of the button
                  link: "/subscribe" # the URL of the button


Supported params are listed below.

=head2 title

A big title on centered on the slide.

=head2 image

A background image supposed to fill all the screen.

=head2 baseline

A subtitle of the slide.

=head2 content

Any content in HTML you want to add.

=head2 youtube

If provided, the value is expected to be a Youtube video ID. A YouTube iframe player will 
be rendered (witout autoplay).

=head2 cta

A hash with C<link> and C<label> values, to generate a call-to-action button.

=cut

use Moo;
use Carp 'croak';

extends 'Dancer2::Plugin::LiteBlog::Widget';

sub has_routes { 0 }

has elements => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
# just return the config array
        return $self->slides;
    },
);

has slides => (
  is => 'ro',
);

1;

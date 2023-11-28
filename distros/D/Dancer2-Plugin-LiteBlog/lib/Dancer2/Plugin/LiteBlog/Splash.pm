package Dancer2::Plugin::LiteBlog::Splash;

=head1 NAME

Dancer2::Plugin::LiteBlog::Splash - A welcome and call-to-action widget for Liteblog

=head1 DESCRIPTION

This widget lets you display a big splash cover image on your home page. The
image takes the full widht and 80% of the visible height. The title and
description of the site is displayed in the center, with big and styled fonts. A
call-to-action button can also be defined.

This widget is a good way to guide your visitors to your main content on your
website. It can be used to collect subscribers to a newsletter for instance, or
guide visitors to a product page.

=head1 CONFIGURATION

The Widget looks for its configuration under the C<liteblog> entry of the
Dancer2 application.

    liteblog:
      ...
      widgets:
        - name: splash
          params: 
            title: "Some title" # if undefined, the liteblog's title is used
            image: '/images/foo.jpg'
            baseline: "Some baseline" # if not defined, liteblog's description
            cta:
              label: "Subscribe to my Newsletter" # label of the button
              link: "/subscribe" # the URL of the button
 
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
        return [
            { 
                title => $self->title, 
                image => $self->image,
                baseline => $self->baseline,
                cta_link => $self->cta->{'link'},
                cta_label => $self->cta->{'label'},
            }
        ];
    },
);

has image => (
    is => 'ro',
);

has title => (
    is => 'ro', 
    lazy => 1, 
    default => sub { 
        my ($self) = @_;
        my $liteblog = $self->dancer->config->{'liteblog'};
        return $liteblog->{title};
    }
);

has baseline => (
    is => 'ro', 
    lazy => 1, 
    default => sub { 
        my ($self) = @_;
        if (defined $self->dancer) {
            my $liteblog = $self->dancer->config->{'liteblog'};
            return $liteblog->{description};
        }
    }
);

# a  href with link/label keys.
has cta => (
    is => 'ro',
    lazy => 1,
    default => sub {
        {}
    }
);

1;

=head1 SEE ALSO

L<Dancer2::Plugin::LiteBlog::Widget>, L<Dancer2>

=head1 AUTHOR

Alexis Sukrieh, C<sukria@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Dancer2::Plugin::LiteBlog::Activities;

=head1 NAME

Dancer2::Plugin::LiteBlog::Activities - Activities widget for LiteBlog

=head1 DESCRIPTION

This module provides a specific implementation for an Activities widget in
LiteBlog, a Dancer2 plugin.

This widget provides a mechanism for managing and displaying "activity cards" in
LiteBlog, a Dancer2-based blogging platform. Each activity card showcases a
specific personal or professional activity, complete with an image, a title, a 
link (href) and a brief description.

For instance, these activity cards can be used to highlight: Profesional Profiles,
Open Source Contributions, Social Network Profiles, Hobby, or any other activity 
the user wants to showcase on their LiteBlog site.

=head1 CONFIGURATION

The Widget looks for its configuration under the C<liteblog> entry of the Dancer2
application.

    liteblog:
      ...
      widgets:
        - name: activities
          params: 
            source: "liteblog/activities.yml"
        ...

The C<source> setting must be a valid YAML file local to the C<appdir> where activities 
will be loaded from.

Example of a valid activities.yml file:

    ---
    - name: "LinkedIn"
      link: '#'
      image: '/images/some-linkedin-cover.jpg'
      desc: "Checkout my LinkedIn profile."
    - name: "GitHub"
      link: "https://github.com/PerlDancer"
      desc: "This is the Dancer GitHub Official account."

=cut

use Moo;
use Carp 'croak';
use YAML::XS;
use File::Spec;

extends 'Dancer2::Plugin::LiteBlog::Widget';

=head1 ATTRIBUTES

=head2 root

Inherited from L<Dancer2::Plugin::LiteBlog::Widget>, it specifies the root
directory for the widget, where the C<source> YAML file will be looked for.

=head2 source

The `source` attribute specifies the path to the YAML file relative to the
`root` directory. This YAML file contains the list of activities.

=cut

has source => (
    is => 'ro',
    required => 1,
);

=head2 elements

This attribute lazily loads and returns the activities from the specified
YAML source file.

=cut

# TODO: again, should be refactored with a common logic of loading a YML file
# (same as 'meta') in Blog.pm
has elements => (
    is => 'ro',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        my $activities = File::Spec->catfile($self->root, $self->source);
        if (! -e $activities) {
            croak "Missing file: $activities";
        }
        my $yaml = YAML::XS::LoadFile($activities);
        $self->info("Accessor 'elements' initialized from '$activities'");
        return $yaml;
    },
);

1;
__END__

=head1 SEE ALSO

L<Dancer2::Plugin::LiteBlog::Widget>, L<Dancer2>, L<Moo>, L<YAML::XS>

=head1 TODO

A refactoring is pending for the common logic of loading a YAML file which is
similar to the 'meta' logic in L<Dancer2::Plugin::LiteBlog::Blog>.

=head1 AUTHOR

Alexis Sukrieh, C<sukria@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 by Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package Catalyst::View::Graphics::Primitive;

use strict;
use warnings;

use Class::Load ':all';
use Scalar::Util 'blessed';

use Catalyst::Exception;

our $VERSION   = '0.06';
our $AUTHORITY = 'cpan:GPHAT';

use base 'Catalyst::View';

sub process {
    my $self = shift;
    my $c    = shift;
    my @args = @_;

    my $content_type = $c->stash->{'graphics_primitive_content_type'}
        || $self->{'content_type'};

    my $gp = $c->stash->{'graphics_primitive'};

    (defined $gp)
        || die "No Graphics::Primitive to render";

    (blessed($gp) && $gp->isa('Graphics::Primitive::Component'))
        || die "Bad graphics_primitive, must be an instance of Graphics::Primitive::Component";

    my $out = eval {

        my $dname = $c->stash->{'graphics_primitive_driver'}
            || $self->{'driver'};
        my $dclass = "Graphics::Primitive::Driver::$dname";
        # If we've got a unary plus, assume they want the driver to be the
        # name they gave, not a suffix.
        if($dname =~ /^\+(.*)/) {
            $dclass = $1;
        }
        my $meta = load_class($dclass);
        unless(defined($meta)) {
            die("Couldn't load driver: $dclass");
        }

        my $dargs = $c->stash->{'graphics_primitive_driver_args'}
            || $self->{'driver_args'} || {};
        my $driver = $dclass->new($dargs);

        $driver->prepare($gp);
        if($gp->can('layout_manager')) {
            $gp->layout_manager->do_layout($gp);
        }
        $driver->finalize($gp);
        $driver->draw($gp);

        $c->response->content_type($content_type);
        $c->response->body($driver->data);
    };
    if ($@) {
        die "Failed to render '$' as '$content_type' because: $@";
    }
}

1;
__END__
=head1 NAME

Catalyst::View::Graphics::Primitive - A Catalyst View for Graphics::Primitive

=head1 SYNOPSIS

  # lib/MyApp/View/GP.pm
  package MyApp::View::GP
  use base 'Catalyst::View::Graphics::Primitive';
  1;

  # configure in lib/MyApp.pm
  MyApp->config(
    ...
    'View::Graphics::Primitive' => {
        driver => 'Cairo',
        driver_args => { format => 'pdf' },
        content_type => 'application/pdf'
    }
  )

=head1 DESCRIPTION

This is the L<Catalyst> view class for L<Graphics::Primitive>.  Any components
created with Graphics::Primitive can be passed to this view and rendered via
whatever driver you desire.  This view has a helper so you can create your
view in the standard Catalyst way with I<myapp_create.pl> (where I<myapp> is
replaced with your application name).

=head1 CONFIGURATION

The following configuration options can be set:

=over 4

=item I<content_type>

Sets the default content type to put into the response.

=item I<driver>

Sets the default driver to use when rendering a component.

=item I<driver_args>

Sets the arguments to pass when insantiating the driver.  A common example
for the Cairo driver would be:

  MyApp->config(
      ...
      'View::Graphics::Primitive' => {
          driver => 'Cairo',
          driver_args => { format => 'pdf' },
          content_type => 'application/pdf'
      }
  );

=back

All of these options can be overridden at request time by prefixing the name
with C<graphics_primitive_> and setting the value in the stash.  For example,
to override the driver, args and content type:

  $c->stash->{graphics_primitive_driver} = 'SomethingElse';
  $c->stash->{graphics_primitive_driver_args} = { format => 'png' };
  $c->stash->{graphics_primitive_content_type} = 'image/png';

=head1 METHODS

=head2 new

The constructor for a new Graphics::Primitive view.

=head2 process

Renders the Graphics::Primitive::Component object stored in
C<< $c->stash->{graphics_primitive} >> using the driver specified in the
configuration or in C<< $c->stash->{graphics_primitive_driver} >> (for
runtime changes). The driver will instantiated using driver_args from the
configuration or C<< $c->stash->{graphics_primitive_driver_args} >>.  The
component will then be moved through the Graphics::Primitive rendering
lifecycle as follows:

  $driver->prepare($comp);
  $driver->finalize($comp);
  if($comp->can('layout_manager')) {
      $comp->layout_manager->do_layout($comp);
  }
  $driver->draw($comp);

The result of C<draw> is then set as the body response.  The content type is
set based on the C<content_type> configuration option or the value of
C<< $c->stash->{graphics_primitive_content_type} >>.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

Infinity Interactive, L<http://www.iinteractive.com>

=head1 ACKNOWLEDGEMENTS

This module was inspired by L<Catalyst::View::GD> and L<Catalyst::View::TT>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

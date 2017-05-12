package Catalyst::Component::ACCEPT_CONTEXT;

use warnings;
use strict;
use MRO::Compat;
use Scalar::Util qw(weaken);

=head1 NAME

Catalyst::Component::ACCEPT_CONTEXT - Make the current Catalyst
request context available in Models and Views.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.07';

=head1 SYNOPSIS

Models and Views don't usually have access to the request object,
since they probably don't really need it.  Sometimes, however, having
the request context available outside of Controllers makes your
application cleaner.  If that's the case, just use this module as a
base class:

    package MyApp::Model::Foobar;
    use base qw|Catalyst::Component::ACCEPT_CONTEXT Catalyst::Model|;

Then, you'll be able to get the current request object from within
your model:

    sub do_something {
        my $self = shift;
        print "The current URL is ". $self->context->req->uri->as_string;
    }

=head1 WARNING WARNING WARNING

Using this module is somewhat of a hack.  Changing the state of your
objects on every request is a pretty braindead way of doing OO.  If
you want your application to be brain-live, then you should use
L<Catalyst::Component::InstancePerContext>.

Instead of doing this on every request (which is basically
what this module does):

    $my_component->context($c);

It's better to do something like this:

    package FooApp::Controller::Root;
    use base 'Catalyst::Controller';
    use Moose;

    with 'Catalyst::Component::InstancePerContext';
    has 'context' => (is => 'ro');

    sub build_per_context_instance {
        my ($self, $c, @args) = @_;
        return $self->new({ context => $c, %$self, @args });
    }

    sub actions :Whatever {
        my $self = shift;
        my $c = $self->context; # this works now
    }

    1;

Now you get a brand new object that lasts for a single request instead
of changing the state of an existing one on each request.  This is
much cleaner OO design.

The best strategy, though, is not to use the context inside your
model.  It's best for your Controller to pull the necessary data from
the context, and pass it as arguments:

   sub action :Local {
       my ($self, $c) = @_;
       my $foo  = $c->model('Foo');
       my $quux = $foo->frobnicate(baz => $c->request->params->{baz});
       $c->stash->{quux} = $quux;
   }

This will make it Really Easy to test your components outside of
Catalyst, which is always good.

=head1 METHODS

=head2 context

Returns the current request context.

=cut

sub context {
    return shift->{context};
}

=head2 ACCEPT_CONTEXT

Catalyst calls this method to give the current context to your model.
You should never call it directly.

Note that a new instance of your component isn't created.  All we do
here is shove C<$c> into your component.  ACCEPT_CONTEXT allows for
other behavior that may be more useful; if you want something else to
happen just implement it yourself.

See L<Catalyst::Component> for details.

=cut

sub ACCEPT_CONTEXT {
    my $self    = shift;
    my $context = shift;

    $self->{context} = $context;
    weaken($self->{context});

    return $self->maybe::next::method($context, @_) || $self;
}

=head2 COMPONENT

Overridden to use initial application object as context before a request.

=cut

sub COMPONENT {
    my $class = shift;
    my $app   = shift;
    my $args  = shift;
    $args->{context} = $app;
    weaken($args->{context}) if ref $args->{context};
    return $class->maybe::next::method($app, $args, @_);
}

=head1 AUTHOR

Jonathan Rockway, C<< <jrockway at cpan.org> >>

Patches contributed and maintained by:

=over

=item Rafael Kitover (Caelum)

=item Tomas Doran (t0m) C<< <bobtfish@bobtfish.net> >>

=back

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-component-accept_context at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-Component-ACCEPT_CONTEXT>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Component::ACCEPT_CONTEXT

You can also look for information at:

=over 4

=item * Catalyst Website

L<http://www.catalystframework.org/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Component-ACCEPT_CONTEXT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Component-ACCEPT_CONTEXT>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Component-ACCEPT_CONTEXT>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Component-ACCEPT_CONTEXT>

=back

=head1 Source code

The source code for this project can be found at:

    git://git.shadowcat.co.uk/catagits/Catalyst-Component-ACCEPT_CONTEXT

=head1 COPYRIGHT & LICENSE

Copyright 2007 Jonathan Rockway.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Component::ACCEPT_CONTEXT

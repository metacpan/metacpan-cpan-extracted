#!/usr/bin/perl

package Catalyst::View::TT::FunctionGenerator;
use base qw/Catalyst::View::TT/;

use strict;
use warnings;

use Catalyst::Utils ();
use Class::Inspector ();
use Scalar::Util qw/weaken/;
use Carp ();

our $VERSION = "0.02";

__PACKAGE__->mk_accessors(qw/context/);

sub ACCEPT_CONTEXT {
	my ( $self, $c ) = @_;
	bless { %$self, context => $c }, ref $self;
}

sub generate_functions {
    my ( $self, @objects ) = @_;

    my $c = $self->context;

    # FIXME
    # need to add per instance view data whose lifetime is linked to $c's lifetime
    push @{ $c->{_evil_function_generator_data}{ref $self} }, map {
        my $meths = ref($_) ? $_ : $c->$_;

        if ( ref $meths eq "ARRAY" ) {
            if ( not ref $meths->[0] ) {
                my ( $name, @methods ) = @$meths;
                $meths = [ $c->$name => @methods ];
            }
        } else {
            $meths = [ $meths, @{ Class::Inspector->methods( ( ref $meths || $meths ), 'public' ) || Carp::croak("$meths has no methods") } ];
        }

        # if there is a closure with $c in it, and it's saved inside $c we have a circular referrence
        weaken($meths->[0]) if ( $meths->[0] == $c );

        $meths;
    } @objects;
}

# for each item passed to sub, check if its an arrayref, if it is, and the first
# item in it is not a ref, then assume its the name of a method on $c, and
# call it to get the object. Else assume an entire object (This will end up
# with an [name, (method names)] if you pass in a string?). Return an arrayref,
# which gets added to the evil list.

sub template_vars {
    my ( $self, $c ) = @_;

    return (
        $self->NEXT::template_vars( $c ),
        map {
            my ( $obj, @methods ) = @$_;
            weaken( $obj ) if ( $obj == $c );
            #see above
            map { my $method = $_; $method => sub { $obj->$method(@_) } } @methods;
        }
        @{ $c->{_evil_function_generator_data}{ref $self} || [] }
    );
}

# for each item (arrayref) in the evil list, create a template var using the
# method names, that calls that method, on the object in the first slot of the array.

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::View::TT::FunctionGenerator - Generate functions from ... to be used from a TT view

=head1 SYNOPSIS

    # running this:

    prompty_wompty> scripts/myapp_create.pl create view ViewName TT

    # generates a Template Toolkit view component.
    # change the base class like this:

    use base 'Catalyst::View::TT::FunctionGenerator';

    # In a nearby action method (in Controller code)
    sub action : Local {
        my ( $self, $c ) = @_;

        $c->view("ViewName")->generate_functions('prototype');
        # OR
        $c->view("ViewName")->generate_functions($c->prototype);
        # OR
        $c->view("ViewName")->generate_functions([$c, 'uri_for']);

    }

    # In your template, we can now have:
    [% link_to_remote("foo", { url => uri_for("blah")  } ) %]

    # instead of saying this:
    [% c.prototype.link_to_remote("foo", { url => c.uri_for("blah")  } ) %]

Note that the most appropriate place to put this code is probably in an C<end>
action at the top level of your application so that access to these functions
in uniform accross your templates.

=head1 DESCRIPTION

This module stuffs given methods as coderefs into your TT variables, enabling the
use of shorter names in your templates. To use this plugin, you will need to
be using the Singleton plugin as well (so that we only populate one correct
copy of the context object).

To use, first create a L<Catalyst::View::TT> module in the usual way (see
synopsis), then change its base class to this module. To add the method
shortcuts, call the generate_functions method in your controller code, in an
action, before forwarding to your template. 

=head1 METHODS

=over 4

=item generate_functions

This is the only available method. It's parameters are a list of one or more
of the following:

=over 4

=item [ $object or method name, (list of method names)]

An arrayref, where the first item in the array is either an object (e.g. what
C<< $c->prototype >> returns), or a method name that will return an object,
when called upon C<$c>, e.g. "prototype". The other array items are the method
names of the given object that will be created as template vars.

=item $object

An object (blessed reference). All methods found for the object will be
created as template vars.

=item A method name

The method name will be called upon <$c>, and all methods for the resulting
object will be added as template vars.

=back

=back

=head2 Overriden methods

=over 4

=item template_vars

=back

=head1 SEE ALSO

L<Catalyst::View::TT>
L<Catalyst::Plugin::Singleton>

=head1 AUTHORS

Yuval Kogman, C<nothingmuch@woobling.org>

Jess Robinson, Marcus Ramberg (POD)


=head1 COPYRIGHT & LICENSE

        Copyright (c) 2005 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.

=cut



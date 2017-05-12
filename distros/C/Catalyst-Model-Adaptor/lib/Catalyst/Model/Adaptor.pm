package Catalyst::Model::Adaptor;
use strict;
use warnings;
use MRO::Compat;

use base 'Catalyst::Model::Adaptor::Base';

our $VERSION = '0.10';

sub COMPONENT {
    my ($class, $app, @rest) = @_;
    my $arg = {};
    if ( scalar @rest ) {
        if ( ref($rest[0]) eq 'HASH' ) {
            $arg = $rest[0];
        }
        else {
            $arg = { @rest };
        }
    }
    my $self = $class->next::method($app, $arg);

    $self->_load_adapted_class;
    return $self->_create_instance(
        $app, $class->merge_config_hashes($class->config || {}, $arg)
    );
}

1;
__END__

=head1 NAME

Catalyst::Model::Adaptor - use a plain class as a Catalyst model

=head1 SYNOPSIS

Given a good old perl class like:

    package NotMyApp::SomeClass;
    use Moose; # to provide "new"
    sub method { 'yay' }

Wrap it with a Catalyst model:

    package MyApp::Model::SomeClass;
    use base 'Catalyst::Model::Adaptor';
    __PACKAGE__->config( class => 'NotMyApp::SomeClass' );

Then you can use C<NotMyApp::SomeClass> from your Catalyst app:

    sub action :Whatever {
        my ($self, $c) = @_;
        my $someclass = $c->model('SomeClass');
        $someclass->method; # yay
    }

Note that C<NotMyApp::SomeClass> is instantiated at application startup
time.  If you want the adapted class to be created for call to C<<
$c->model >>, see L<Catalyst::Model::Factory> instead.  If you want
the adapted class to be created once per request, see
L<Catalyst::Model::Factory::PerRequest>.

=head1 DESCRIPTION

The idea is that you don't want your Catalyst model to be anything
other than a line or two of glue.  Using this module ensures that your
Model classes are separate from your application and therefore are
well-abstracted, reusable, and easily testable.

Right now there are too many modules on CPAN that are
Catalyst-specific.  Most of the models would be better written as a class
that handles most of the functionality with just a bit of glue to make it
work nicely with Catalyst.  This module aims to make integrating your class
with Catalyst trivial, so you won't have to do any extra work to make
your model generic.

For a good example of a Model that takes the right design approach,
take a look at
L<Catalyst::Model::DBIC::Schema|Catalyst::Model::DBIC::Schema>.  All
it does is glues an existing
L<DBIx::Class::Schema|DBIx::Class::Schema> to Catalyst.  It provides a
bit of sugar, but no actual functionality.  Everything important
happens in the C<DBIx::Class::Schema> object.

The end result of that is that you can use your app's DBIC schema without
ever thinking about Catalyst.  This is a Good Thing.

Catalyst is glue, not a way of life!

=head1 CONFIGURATION

Subclasses of this model accept the following configuration keys, which
can be hard-coded like:

   package MyApp::Model::SomeClass;
   use base 'Catalyst::Model::Adaptor';
   __PACKAGE__->config( class => 'NotMyApp::SomeClass' );

Or be specified as application config:

   package MyApp;
   MyApp->config->{'Model::SomeClass'} = { class => 'NotMyApp::SomeClass' };

Or in your ConfigLoader-loaded config file:

   ---
   Model::SomeClass:
     class: NotMyApp::SomeClass
     args:
       foo: ...
       bar: ...

This is exactly like every other Catalyst component, so you should
already know this.

Anyway, here are the options:

=head2 class

This is the name of the class you're adapting to Catalyst.  It MUST be
specified.

Your application will die horribly if it can't require this package.

=head2 constructor

This is the name of the class method in C<class> that will create an
instance of the class.  It defaults to C<new>.

Your application will die horribly if it can't call this method.

=head2 args

This is a hashref of arguments to pass to the constructor of C<class>.
It is optional, of course.  If you omit it, nothing is passed to the
constructor (as opposed to C<{}>, an empty hashref).

=head1 METHODS

There are no methods that you call directly.  When you call C<<
$c->model >> on a model that subclasses this, you'll get back an
instance of the class being adapted, not this model.

These methods are called by Catalyst:

=head2 COMPONENT

Setup this component.

=head1 CUSTOMIZING THE PROCESS

By default, the instance of your adapted class is instantiated like
this:

    my $args = $self->prepare_arguments($app); # $app sometimes called $c
    $adapted_class->$constructor($self->mangle_arguments($args));

Since a static hashref of arguments may not be what C<$class> needs,
you can override the following methods to change what C<$args> is.

NOTE: If you need to pass some args at instance time, you can do something
like:

    my $model = $c->model('MyFoo', { foo => 'myfoo' });

or

    my $model = $c->model('MyFoo', foo => 'myfoo');

=head2 prepare_arguments

This method is passed the entire configuration for the class and the
Catalyst application, and returns the hashref of arguments to be
passed to the constructor.  If you need to get dynamic data out of
your application to pass to the consturctor, do it here.

By default, this method returns the C<args> configuration key.

Example:

    sub prepare_arguments {
        my ($self, $app) = @_; # $app sometimes written as $c
        return { foobar => $app->config->{foobar}, baz => $self->{baz} };
    }

=head2 mangle_arguments

This method is passed the hashref from C<prepare_arguments>, mangles
them into a form that your constructor will like, and returns the
mangled form.  If your constuctor wants a list instead of a hashref,
this is your opportunity to do the conversion.

Example:

    sub mangle_arguments {
        my ($self, $args) = @_;
        return %$args; # now the args are a plain list
    }

If you need to do more than this, you might as well just write
the whole class yourself.  This module is designed to make the common
case work with 1 line of code.  For special needs, it's easier to just
write the model yourself.

=head1 SEE ALSO

If you need a new instance returned each time C<< $c->model >> is called,
use L<Catalyst::Model::Factory|Catalyst::Model::Factory> instead.

If you need to have exactly one instance created per request, use
L<Catalyst::Model::Factory::PerRequest|Catalyst::Model::Factory::PerRequest>
instead.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 CONTRIBUTORS

Wallace Reis C<< <wreis@cpan.org> >>

=head1 LICENSE

This module is Copyright (c) 2007 Jonathan Rockway.  You may use,
modify, and redistribute it under the same terms as Perl itself.

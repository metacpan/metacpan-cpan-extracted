package Class::Meta::Express;

use strict;
use vars qw($VERSION);
use Class::Meta '0.60';

$VERSION = '0.13';

my %meta_for;

sub import {
    my $pkg = shift;
    my $caller = caller;
    no strict 'refs';
    return shift if defined &{"$caller\::meta"};
    *{"$caller\::$_"} = $pkg->can($_)
        for qw(class meta ctor has method build);
    return shift;
}

sub class (&) {
    my $code = shift;
    goto sub {
        $code->();
        goto &build;
    };
}

sub meta {
    _new_meta( scalar caller, @_ );
}

sub ctor {
    unshift @_, 'constructor';
    goto &_meth;
}

sub has {
    my $caller = caller;
    my $meta = _meta_for( $caller );
    unshift @_, $meta, 'name';
    splice @_, 3, 1, %{ $_[3] } if ref $_[3] eq 'HASH';
    goto &{ $meta->can('add_attribute') };
}

sub method {
    unshift @_, 'method';
    goto &_meth;
}

sub build {
    my $meta = delete $meta_for{ my $caller = caller };
    # Remove exported functions.
    _unimport($caller);

    # Build the class.
    unshift @_, $meta;
    goto &{ $meta->can('build') };
}

sub _new_meta {
    my ($caller, $key) = (shift, shift);
    my $args = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
    $args->{key} = $key;
    _export(delete $args->{reexport}, $caller, $args) if $args->{reexport};
    my $meta_class = delete $args->{meta_class} || 'Class::Meta';
    my $meta = $meta_class->new( package => $caller, %{ $args } );
    $meta_for{$caller} = $meta;
    return $meta;
}

sub _meta_for {
    my $caller = shift;
    unless ( $meta_for{ $caller } ) {
        # Create a key from the last part of the package name.
        (my $key = $caller) =~ s/.*:://;
        $key = lcfirst $key;
        $key =~ s/([[:upper:]]+)/_\L$1/g;
        _new_meta( $caller, $key );
    }
    return $meta_for{ $caller };
}

sub _meth {
    my $method = 'add_' . shift;
    my $meta = _meta_for( scalar caller );
    unshift @_, $meta, 'name';
    if (my $ref = ref $_[3]) {
        if ($ref eq 'CODE') {
            splice @_, 3, 0, 'code';
        } else {
            splice @_, 3, 1, %{ $_[3] } if $ref eq 'HASH';
        }
    }
    goto &{ $meta->can($method) };
}

sub _unimport {
    my $caller = shift;
    for my $fn (qw(class meta ctor has method build)) {
        no strict 'refs';
        my $name = "$caller\::$fn";
        # Copy the current glob contents, excluding CODE.
        my %things = map  { $_ => *{$name}{$_} }
                     grep { defined *{$name}{$_} }
                     qw(SCALAR ARRAY HASH IO FORMAT);
        # Undefine the glob and reinstall the contents.
        undef *{$name};
        *{$name} = $things{$_} for keys %things;
    }
}

sub _export {
    my ($export, $pkg, $args) = @_;
    my @args = map { $_ => $args->{$_} } grep { exists $args->{$_} }
        Class::Meta::INHERITABLE, 'meta_class';

    my $meta = !@args ? \&meta : sub {
        splice @_, 1, 0, @args;
        goto &Class::Meta::Express::meta;
    };

    $export = 0 unless ref $export eq 'CODE';

    no strict 'refs';
    *{"$pkg\::import"} = sub {
        my $caller = caller;
        no strict 'refs';
        unless (defined &{"$caller\::meta"}) {
            *{"$caller\::meta"} = $meta;
            *{"$caller\::$_"} = \&{__PACKAGE__ . "::$_"}
                for qw(class ctor has method build);
        }
        goto $export if $export;
        return shift;
    };
}

1;
__END__

##############################################################################

=head1 Name

Class::Meta::Express - Concise, expressive creation of Class::Meta classes

=head1 Synopsis

  package My::Contact;
  use Class::Meta::Express;

  class {
      meta contact => ( default_type => 'string' );
      has 'name';
      has contact => ( required => 1 );
  }

=head1 Description

This module provides an interface to concisely yet expressively create classes
with L<Class::Meta|Class::Meta>. It does so by temporarily exporting magical
functions into a package that uses it, thereby providing a declarative
alternative to L<Class::Meta|Class::Meta>'s verbose object-oriented syntax.a

=head1 Interface

Class::Meta::Express exports the following functions into any package that
C<use>s it. But beware: the functions are temporary! Once the class is
declared, the functions are all removed from the calling package, thereby
avoiding name space pollution I<and> allowing you to create your own functions
or methods with the same names, if you like, after declaring the class.

=head2 Functions

=head3 class

  class {
      # Declare class.
  }

Yes, the C<class> keyword is secretly a function. It takes a single argument,
a code reference, for which may omit the C<sub> keyword. Cute, eh?. It simply
executes the code reference passed as its sole argument, removes the C<class>,
C<meta>, C<ctor>, C<has>, C<method>, and C<build> functions from the calling
name space, and then calls C<build()> on the Class::Meta object, thus building
the class.

=head3 meta

  meta 'thingy';

This function creates and returns the C<Class::Meta|Class::Meta> object that
creates the class. Calling it is optional; if you don't use it to identify the
basic meta data of your class, Class::Meta::Express will create the
Class::Meta object for you, passing the last part of the class name -- with
uppercase characters converted to lowercase and preceded by an underscore --
as the C<key> parameter. So "My::FooXML" would get the key "foo_xml". Of
course, if you have more two classes that would end up with that key name,
you'll have to call C<meta> for all but one in order to avoid conflicts.

If you do choose to use this function, there are a number of benefits, as
you'll soon read.

The first argument must be the key to use for the class, which will be passed
as the C<key> parameter to C<< Class::Meta->new >>. Otherwise, it takes the
same parameters as L<Class::Meta|Class::Meta/"new">:

=over 4

=item name

A display name.

=item desc

A description of the class.

=item abstract

A boolean: Is the class an abstract class?

=item trust

An array reference of classes that this class trusts to call its trusted
methods.

=item default_type

The default data type to use for attributes that specify no data type.

=item class_class

A Class::Meta::Class subclass.

=item constructor_class

A Class::Meta::Constructor subclass.

=item attribute_class

A Class::Meta::Attribute subclass.

=item method_class

A Class::Meta::Method subclass.

=item error_handler

A code reference to handle exceptions.

=back

Consult the L<Class::Meta|Class::Meta/"new"> documentation for a detailed
description of these parameters, in addition to which, C<meta> adds support
for the following parameters:

=over

=item meta_class

If you've subclassed Class::Meta and want to use your subclass to define your
classes instead of Class::Meta itself, specify the subclass with this
parameter.

=item reexport

Installs an C<import()> method into the calling name space that re-exports the
express functions. The trick is that, if you've specified values for the
C<meta_class> or many of the parameters supported by Class::Meta, they will be
used in the C<meta> function exported by your class! For example:

  package My::Base;
  use Class::Meta::Express;
  class {
      meta base => (
           meta_class   => 'My::Meta',
           default_type => 'string',
           trust        => 'My::Util',
           reexport     => 1,
      );
  }

And now other classes can use My::Base instead of Class::Meta::Express and get
the same defaults. Of course, this is only important if you're not inheriting
from another Class::Meta class and not passing the C<meta_class> parameter,
because Class::Meta classes inherit the parameter values from their most
immediate super class. But if you're not using inheritance and want to set up
some universal settings to use throughout your project, this is a great way to
do it.a

For example, say that you want My::Contact to inherit from My::Base and use
its defaults. Just do this:

  package My::Contact;
  use My::Base;        # Forces import() to be called.
  use base 'My::Base';

  class {
      has  'name'      # Will be a string.
  }

Any parameters passed to C<meta> and labeled as "inheritable" by
L<Class::Meta|Class::Meta/"new"> will be duplicated, as will "meta_class".

If you need your own C<import()> method to export stuff, just pass it to the
reexport parameter:

  meta base => (
       meta_class   => 'My::Meta',
       default_type => 'string',
       trust        => 'My::Util',
       reexport     => sub { ... },
  );

Class::Meta::Express will do the right thing by shifting execution to your
import method after it finishes its dirty work.

=back

The parameters may be passed as either a list, as above, or as a hash
reference:

  meta base => {
       meta_class   => 'My::Meta',
       default_type => 'string',
       reexport     => 1,
  };

=head3 ctor

  ctor 'new';

Calls C<add_constructor()> on the Class::Meta object created by C<meta>,
passing the first argument as the C<name> parameter. All other arguments can
be any of the parameters supported by
L<add_constructor()|Class::Meta/"add_constructor">:

=over 4

=item create

A boolean indicating whether or not Class::Meta should create the constructor
method.

=item label

A display name for the constructor.

=item desc

A description.

=item code

A code reference implementing the constructor method.

=item view

Visibility of the constructor: PUBLIC, PRIVATE, TRUSTED, or PROTECTED.

=item caller

A code reference to call the constructor.

=back

Here's a simple example that adds a label to the constructor:

  ctor new => ( label => 'Foo' );

The second argument can optionally be a code reference that will be passed as
the C<code> parameter to C<add_constructor()>:

  ctor new => sub { bless {} => shift };

If you want to specify other parameters I<and> the code parameter, do so
explicitly:

  ctor new => (
      label => 'Foo',
      code  => sub { bless {} => shift },
      view  => 'PRIVATE',
  );

The parameters may be passed as either a list, as above, or as a hash
reference:

  ctor new => {
      label => 'Foo',
      code  => sub { bless {} => shift },
      view  => 'PRIVATE',
  };

=head3 has

  has name => ( is => 'string' );

Calls C<add_attribute()> on the Class::Meta object created by C<meta>, passing
the first argument as the C<name> parameter. All other arguments can be any of
the parameters supported by L<add_attribute()|Class::Meta/"add_attribute">:

=over 4

=item type

=item is

The attribute data type.

=item required

Boolean indicating whether or not the attribute is required to have a value.

=item once

Boolean indicating whether or not the attribute can be set only once.

=item label

A display name.

=item desc

A description.

=item view

Visibility of the attribute: PUBLIC, PRIVATE, TRUSTED, or PROTECTED.

=item authz

Authorization of the attribute: READ, WRITE, RDWR, or NONE.

=item create

Specifies how the accessor should be created: GET, SET, GETSET, or NONE.

=item context

The attribute context, either CLASS or OBJECT.

=item default

Default value for the attribute, or else a code reference that, when executed,
returns a default value.

=item override

Boolean indicating whether or not the attribute can override an attribute with
the same name in a parent class.

=back

If the C<default_type> parameter was specified in the call to C<meta>, then
the type (or C<is> if you have Class::Meta 0.53 or later and prefer it) can be
omitted unless you need a different type:

  meta thingy => ( default_type => 'string' );
  has 'name'; # Will be a string.
  has id => ( is => 'integer' );
  # ...

The parameters may be passed as either a list, as above, or as a hash
reference:

  has id => { is => 'integer' };

=head3 method

  method 'say';

Calls C<add_method()> on the Class::Meta object created by C<meta>, passing
the first argument as the C<name> parameter. An optional second argument can
be used to define the method itself (if you have Class::Meta 0.51 or later):

  method say => sub { shift; print @_, $/; }

Otherwise, you'll have to define the method in the class itself (as was
required in Class::Meta 0.50 and earlier). If you want to specify other
parameters to C<add_method()>, just pass them after the method name and
explicitly mix in the C<code> parameter if you need it:

  method say => (
      view => 'PROTECTED',
      code => sub { shift; print @_, $/; },
  );

All other arguments can be any of the parameters supported by
L<add_method()|Class::Meta/"add_method">:

=over 4

=item label

A display name.

=item desc

A description.

=item view

Visibility of the method: PUBLIC, PRIVATE, TRUSTED, or PROTECTED.

=item code

A code reference implementing the method.

=item context

The method context, either CLASS or OBJECT.

=item caller

A code reference to call the constructor.

=item args

A description of the supported arguments.

=item returns

A description of the return value.

=back

The parameters may be passed as either a list, as above, or as a hash
reference:

  method say => {
      view => 'PROTECTED',
      code => sub { shift; print @_, $/; },
  };

=head3 build

  build;

This function is a deprecated holdover from before version 0.05. It used to be
that there was no C<class> keyword and you had to just call the rest of the
above functions and then call C<build> when you're done. But who liked
I<that>? It was actually a bitter pill among all this sweet, sweet sugar. But
no more; C<build> will likely be removed in a future version.

=head1 Overriding Functions

It is possible to override the functions exported by this module by
subclassing it (after a fashion). Say that you wanted to change the C<meta()>
function so that it forces all attributes to default to a the type "string".
Just override the function like so:

  package My::Express;
  use base 'Class::Meta::Express';

  sub meta {
      splice @_, 1, 0, default_type => 'string';
      goto &Class::Meta::Express::meta;
  }

The trick here is to set C<@_> and then C<goto &Class::Meta::Express::meta>.
This is so that the package that calls this function will be seen as the
caller and therefore the Class::Meta object will be properly created for that
package.

Why would you want to do all this? Well, perhaps you're building a I<lot> of
classes and don't want to have to repeat yourself so much. So now all you have
to do is use your My::Express module instead of Class::Meta::Express:

  package My::Person;
  use My::Express;
  class {
      meta person => ();
      has  name   => ();
  }

And now you've created a new class with the string type attribute "name".

=head1 Justification

Although I am of course fond of L<Class::Meta|Class::Meta>, I've never been
overly thrilled with its interface for creating classes:

 package My::Thingy;
 use Class::Meta;

  BEGIN {
      # Create a Class::Meta object for this class.
      my $cm = Class::Meta->new( key => 'thingy' );

      # Add a constructor.
      $cm->add_constructor( name   => 'new' );

      # Add a couple of attributes with generated accessors.
      $cm->add_attribute(
          name     => 'id',
          is       => 'integer',
          required => 1,
      );

      $cm->add_attribute(
          name     => 'name',
          is       => 'string',
          required => 1,
      );

      $cm->add_attribute(
          name    => 'age',
          is      => 'integer',
      );

     # Add a custom method.
      $cm->add_method(
          name => 'chk_pass',
          code => sub { return 'code' },
      );
      $cm->build;
  }

This example is relatively simple; it can get a lot more verbose. But even
still, all of the method calls were annoying. I mean, whoever thought of using
an object oriented interface for I<declaring> a class? (Oh yeah: I did.) I
wasn't alone in wanting a more declarative interface; Curtis Poe, with my
blessing, created L<Class::Meta::Declare|Class::Meta::Declare>, which would
use this syntax to create the same class:

 package My::Thingy;
 use Class::Meta::Declare ':all';

 Class::Meta::Declare->new(
     # Create a Class::Meta object for this class.
     meta       => [
         key       => 'thingy',
     ],
     # Add a constructor.
     constructors => [
         new => { }
     ],
     # Add a couple of attributes with generated accessors.
     attributes => [
         id => {
             type    => $TYPE_INTEGER,
             required => 1,
         },
         name => {
             required => 1,
             type     => $TYPE_STRING,
         },
         age => { type => $TYPE_INTEGER, },
     ],
     # Add a custom method.
     methods => [
         chk_pass => {
             code => sub { return 'code' },
         }
     ]
 );

This approach has the advantage of being a bit more concise, and it I<is>
declarative, but I find all of the indentation levels annoying; it's hard for
me to figure out where I am, especially if I have to define a lot of
attributes. And finally, I<everything> is a string with this syntax, except
for those ugly read-only scalars such as C<$TYPE_INTEGER>. So I can't easily
tell where one attribute ends and the next one starts. Bleh.

What I wanted was an interface with the visual distinctiveness of the original
Class::Meta syntax but with the declarative approach and intelligent defaults
of Class::Meta::Declare, while adding B<expressiveness> to the mix. The
solution I've come up with is the use of temporary functions imported into a
class only until the end of the class declaration:

  package My::Thingy;
  use Class::Meta::Express;

  class {
      # Create a Class::Meta object for this class.
      meta 'thingy';

      # Add a constructor.
      ctor new => ( );

      # Add a couple of attributes with generated accessors.
      has id   => ( is => 'integer', required => 1 );
      has name => ( is => 'string',  required => 1 );
      has age  => ( is => 'integer' );

     # Add a custom method.
      method chk_pass => sub { return 'code' };
  }

That's much better, isn't it? In fact, we can simplify it even more by setting
a default data type and eliminating the empty lists:

  package My::Thingy;
  use Class::Meta::Express;

  class {
      # Create a Class::Meta object for this class.
      meta thingy => ( default_type => 'integer' );

      # Add a constructor.
      ctor 'new';

      # Add a couple of attributes with generated accessors.
      has id   => ( required => 1 );
      has name => ( is => 'string', required => 1 );
      has 'age';

      # Add a custom method.
      method chk_pass => sub { return 'code' };
  }

Not bad, eh? I have to be honest: I borrowed the syntax from L<Moose|Moose>.
Thanks for the idea, Stevan!

=head1 See Also

=over

=item L<Class::Meta|Class::Meta>

This is the module that's actually doing all the work. Class::Meta::Express
just offers a sweeter interface for creating new classes with Class::Meta.
You'll still want to know all about Class::Meta's introspection capabilities,
type constraints, and more. Check it out!

=item L<Class::Meta::Declare|Class::Meta::Declare>

Curtis Poe's declarative interface to Class::Meta. Deprecated in favor of this
module.

=back

=head1 To Do

=over

=item * Make it so that the C<reexport> parameter can work with an C<import>
method that's already installed in a module.

=back

=head1 Support

This module is stored in an open L<GitHub
repository|http://github.com/theory/class-meta-express/>. Feel free to fork and
contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/class-meta-express/issues/> or by sending mail to
L<bug-Class-Meta-Express.cpan.org|mailto:bug-Class-Meta-Express.cpan.org>.

=head1 Author

David E. Wheeler <david@justatheory.com>

=head1 Copyright and License

Copyright (c) 2006-2011 David E. Wheeler Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

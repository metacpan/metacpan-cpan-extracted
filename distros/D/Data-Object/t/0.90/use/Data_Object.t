use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object

=abstract

Modern Perl Development Framework and Standard Library

=synopsis

  package User;

  use Data::Object 'Class';

  extends 'Identity';

  has 'fname';
  has 'lname';

  1;

=description

Data-Object is a robust development framework for modern Perl development,
embracing Perl's multi-paradigm programming nature, flexibility and vast
ecosystem that many of engineers already know and love.

This framework aims to provide a standardized and cohesive set of classes,
types, objects, functions, patterns, and tools for jump-starting application
development with modern conventions and best practices.

The power of this framework comes from the extendable (yet fully optional) type
library which is integrated into the object system and type-constrainable
subroutine signatures (supporting functions, methods and method modifiers). We
also provide classes which wrap Perl 5 native data types and provides methods
for operating on the data.

Contrary to popular opinion, modern Perl programming can be extremely
well-structured and beautiful, leveraging many advanced concepts found on other
languages, and some which aren't. Abilities like method modification also
referred to as augmenting, reflection, advanced object-orientation,
type-constrainable object attributes, type-constrainable subroutine signatures
(with named and positional arguments), as well roles (similar to mixins or
interfaces in other languages).

  use Data::Object;

This is what's enabled whenever you import the L<Data::Object> application development framework.

  # basics
  use strict;
  use warnings;

  # loads say, state, switch, unicode_strings, array_base
  use feature ':5.14';

  # loads types and signatures
  use Data::Object::Library;
  use Data::Object::Signatures;

  # load super "do" function, etc
  use Data::Object::Export;

To explain by way of example: The following creates a class representing a user
which has the ability to greet user person.

  package User;

  use Data::Object 'Class', 'App';

  has name => (
    is  => 'ro',
    isa => 'Str',
    req => 1
  );

  method hello(User $user) {
    return 'Hello '. $user->name .'. How are you?';
  }

  1;

The following is a script that creates a function that returns how one user
greets another user.

  #!/usr/bin/perl

  use User;

  use Data::Object 'Core', 'App';

  fun greetings(User $u1, User $u2) {
    return $u1->hello($u2);
  }

  my $u1 = User->new(name => 'Jane');
  my $u2 = User->new(name => 'June');

  say(greetings($u1, $u2)); # Hey June

This demonstrates much of the power of this framework in one simple example. If
you're new to Perl, the code above creates a class with a single (read-only
string) attribute called C<name> and a single method called C<hello>, then
registers the class in a user-defined type-library called C<App> where all
user-defined type constraints will be stored and retrieved (and reified).

The C<main> program (namespace) initializes the framework and specifies the
user-defined type library to use in the creation of a single function
C<greetings> which takes two arguments which must both be instances of the
class we just created. It's important to note that in order for the code above
to execute, the C<App> type library must exist. This could be as simple as:

  package App;

  use Data::Object 'Library';

  1;

That having been explained, it's also important to note that while this example
showcases much of what's possible with this framework, all of the
sophistication is totally optional. For example, method and function signatures
are optionally typed, so the declarations would work just as well without the
types specified. In fact, you could then remove the C<App> type library
declarations from both packages and even resort rewriting the method and
function as plain-old Perl subroutines. This flexibility to be able to enable
more advanced capabilities is common in the Perl ecosystem and is one of the
things we love most. The wiring-up of things! If you're familiar with Perl,
this framework is in-part the wiring up of L<Moo> (with L<Moose> support),
L<Type::Tiny>, L<Function::Parameters>, L<Try::Tiny> and data objects in a
cooperative and cohesive way that feels like it's native to the language.

=installation

If you have cpanm, you only need one line:

  $ cpanm -qn Data::Object

If you don't have cpanm, get it! It takes less than a minute, otherwise:

  $ curl -L https://cpanmin.us | perl - -qn Data::Object

Add C<Data::Object> to the list of dependencies in C<cpanfile>:

  requires "Data::Object" => "0.97"; # 0.97 or newer

If cpanm doesn't have permission to install modules in the current Perl
installation, it will automatically set up and install to a local::lib in your
home directory.  See the L<local::lib|local::lib> documentation for details on
enabling it in your environment. We recommend using a
L<Perlbrew|https://github.com/gugod/app-perlbrew> or
L<Plenv|https://github.com/tokuhirom/plenv> environment. These tools will help
you manage multiple Perl installations in your C<$HOME> directory. They are
completely isolated Perl installations.

=cut

use_ok 'Data::Object';

ok 1 and done_testing;

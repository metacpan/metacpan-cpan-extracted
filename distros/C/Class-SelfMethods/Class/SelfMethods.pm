##############################################################################
#
# Class::SelfMethods - a Module for supporting instance-defined methods
#
# Author: Toby Ovod-Everett
# Last Change: Update POD to mention Class::Prototyped
##############################################################################
# Copyright 1999, 2003 Toby Ovod-Everett, 1999 Damian Conway.  All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Ovod-Everett at tovod-everett@alascom.att.com
#
# Damian Conway, damian@cs.monash.edu.au, was responsible for the _SET
# accessor code and the symbol table manipulation code.
##############################################################################

package Class::SelfMethods;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

$VERSION = '1.08';

use Carp;

sub AUTOLOAD {
  (my $func = $AUTOLOAD) =~ s/^.*::(_?)//;
  unless ($1) {
    my $method = can($_[0], $func);
    goto &$method if $method;
  }
  croak sprintf 'Can\'t locate object method "%s" via package "%s"', $func, ref($_[0]);
}

sub can {
  my($self, $func) = @_;

  if ($func =~ s/_SET$//) {
    my $method = UNIVERSAL::can($self, "${func}_SET");
    unless ($method) {
      no strict;
      *{"${func}_SET"} = $method = sub { $_[0]->{$func} = $_[1] };
    }
    return $method;
  }

  if ($func =~ s/_CLEAR$//) {
    my $method = UNIVERSAL::can($self, "${func}_CLEAR");
    unless ($method) {
      no strict;
      *{"${func}_CLEAR"} = $method = sub { delete $_[0]->{$func} };
    }
    return $method;
  }

  my $undercall = "_$func";
  if (exists $self->{$func} or UNIVERSAL::can($self, $undercall)) {
    my $method = UNIVERSAL::can($self, $func);
    unless ($method) {
      no strict;
      *{$func} = $method = sub {
          if (exists $_[0]->{$func}) {
            if (ref ($_[0]->{$func}) eq 'CODE') {
              goto &{$_[0]->{$func}};
            } else {
              return $_[0]->{$func};
            }
          } else {
            my $self = shift;
            return $self->$undercall(@_);
          }
        };
    }
    return $method;
  }
  return;
}

sub new {
  my $class = shift;
  my(%params) = @_;

  my %temp_params;
  foreach my $i (keys %params) {
    if ($i =~ /^_/) {
      $temp_params{$i} = $params{$i};
      delete $params{$i};
    }
  }

  my $self = \%params;
  bless $self, $class;

  foreach my $i (keys %temp_params) {
    $self->$i(@{$temp_params{$i}});
  }

  return $self;
}

1;

__END__

=head1 NAME

Class::SelfMethods - a Module for supporting instance-defined methods

=head1 SYNOPSIS

  use Class::SelfMethods;

  package MyClass;
  @ISA = qw(Class::SelfMethods);
  use strict;

  sub _friendly {
    my $self = shift;
    return $self->name;
  }

  package main;
  no strict;

  my $foo = MyClass->new( name => 'foo' );
  my $bar = MyClass->new( name => 'bar', friendly => 'Bar');
  my $bas = MyClass->new( name => 'bas',
                          friendly => sub {
                            my $self = shift;
                            return ucfirst($self->_friendly);
                          }
                        );

  print $foo->friendly, "\n";
  print $bar->friendly, "\n";
  print $bas->friendly, "\n";

  $bas->friendly_SET('a reset friendly');
  print $bas->friendly, "\n";

  $bas->friendly_SET( sub { my $self = shift; return uc($self->_friendly) });
  print $bas->friendly, "\n";

  $bas->friendly_CLEAR;
  print $bas->friendly, "\n";


=head1 DESCRIPTION

Development of this module has largely lapsed due to the superior performance 
and feature set of C<Class::Prototyped>.  If you haven't written code that 
depends upon C<Class::SelfMethods>, I strongly urge you to look at 
C<Class::Prototyped> first.

C<Class::SelfMethods> merges some features of other Object Oriented languages to build a
system for implementing more flexible objects than is provided by default in Perl.

The core features I was looking for when I wrote C<Class::SelfMethods> were:

=over 4

=item Class-based inheritance hierarchy

I wanted to retain Perl's normal class-based inheritance hierarchy rather than to write (or use) a
completely prototype based system.  If you are looking for a purely prototype based system, see
Sean M. Burke's C<Class::Classless>.  My reasoning on this is that it is easier in file based
languages (as opposed to world based languages like Self) to code class based inheritance
hierarchies (which are largely static) than to code object based inheritance hierarchies (since
objects in such languages have a dynamicism that is not granted to classes).

=item Instance-defined method overriding

I wanted instances to be able to override their class-defined methods.  In the example above,
the C<$bas> object has its own C<friendly> method.  Instance-defined methods are passed the exact
same parameter list as class-defined methods.

=item Subroutine/Attribute equivalence

Borrowing from Self, I wanted to be able to treat methods and attributes similarly.  For instance,
in the above example the C<$bar> object has an attribute C<friendly>, whereas the C<$bas> object
has a method C<friendly>, and the C<$foo> object uses the class-defined method.  The calling
syntax is independent of the implementation.  Parameters can even be passed in the method call and
they will simply be ignored if the method is implemented by a simple attribute

=back

In addition to those core features, I (and Damian) had a wish list of additional features:

=over 4

=item Simple syntax

I wanted the system to be reasonable easy to use for both implementers of classes and users of
objects.  Simple syntax for users is more important than simple syntax for implementers.

=item Full support for C<SUPER> type concepts

I wanted instance-defined methods to be able to call the class-defined methods they replace.

=item Support for calling methods at instantiation time

In some circumstances, rather than deal with multiple inheritance it is easier to have a
class-defined object method that sets up the various instance-defined methods for a given object.
To support this, the C<new> method allows deferred method calls to be passed in as parameters.

=item Modifying objects post-instantiation

I originally had no need for modifying objects post-instantiation, but Damian Conway thought it
would be a Good Thing (TM) to support.  Being so very good at these sorts of thing, he instantly
came up with a good general syntax to support such.  Method calls that end in a C<_SET> result in
the first parameter being assigned to the attribute/method.  I noticed one remaining hole and
added support for C<_CLEAR>.

=back

=head1 HOW TO

=head2 Write A Class

Your class should inherit from C<Class::SelfMethods>.  The class-defined instance methods
should be B<defined with> a leading underscore and should be B<called without> a leading
underscore.  Don't do anything silly like writing methods whose proper names have a leading
underscore and whose definitions have two leading underscores - that's just asking for trouble.

Do B<not>, of course, make use of attributes that have leading underscores - that's also just
asking for trouble.  Also, do not access attributes directly (i.e. C<$self-E<gt>{foo}>).  That
will prevent people who use your class from substituting a method for an attribute.  Instead,
always read attributes by making the corresponding method call (C<$self-E<gt>foo>).

If you need to call C<SUPER::methodname>, call C<SUPER::_methodname>.

=head2 Create An Instance

The default C<new> method uses named parameters.  Unless you are certifiable, you will too.  To
specify attributes, simply use the syntax C<name =E<gt> 'value'> and to specify a method use
C<name =E<gt> sub { my $self = shift; . . . }>.  Note that methods and attributes are
interchangeable.

=head2 Modify An Instance

Method calls that end in a C<_SET> will result in their first parameter being assigned to the
appropriate attribute/method.  For instance, in the C<SYNOPSIS> I use C<$foo-E<gt>friendly_SET> to
specify both a value and a method for C<friendly>.  Method calls that end in a C<_CLEAR> will
delete that attribute/method from the object.  The C<can> method will behave just like
C<UNIVERSAL::can> - it returns a code reference that will interoperate with the associated object
properly using the C<$obj-E<gt>$coderef()> syntax.  For examples of usage, see C<test.pl>.

=head2 Installation instructions

Standard module installation procedure.

=head1 INTERNALS

=head2 can

This implementation of C<can> is the heart of the system.  By making C<can> responsible for almost
everything relating to accessing the objects, the code for deciding how to respond to the various
situtations is kept in one place.

In order to get major speed improvements (a factor of 2 to 3 for attribute retrieval and method
calls), extensive symbol table manipulation was used to build methods on the fly that react
appropriately.

The three types of methods are C<_SET> methods, C<_CLEAR> methods, and "normal" methods.  The
first two are fairly straight forward as far as implementation goes.  First C<UNIVERSAL::can> is
called to determine whether an appropriate entry has been made in the package symbol table.  If
not, an anonymous subroutine (actually, a closure in this case because C<$func> is a lexically
scoped variable defined outside the anonymous subroutine and referenced from within) is created
and assigned into the package symbol table.  In either case, a reference to the appropriate
closure is returned (normal C<can> behavior is to return a reference to the code or C<undef> if
the method call is not legal).

The "normal" methods are somewhat trickier.  The outer C<if> statement exists to ensure that
C<can> returns C<undef> for illegal method calls (remember that there may be situations where
C<$self-E<gt>can($func)> should return false even though C<UNIVERSAL::can($self, $func)> returns
true). It then checks whether an appropriate entry has been made in the package symbol table.  If
not, it builds a closure that will do the trick.  Remember that the closure could get called on an
object that is in any of the four possible states - attribute, instance method, inherited method,
or illegal.  The closure includes the logic to test for instance methods and attributes, but if
neither are present it will make the call to C<_method> regardless of whether or not there is an
inherited method with the proper name.  It relies on C<AUTOLOAD> to properly deal with unhandled
C<_method> calls.

=head2 AUTOLOAD

C<AUTOLOAD> gets called the first time a given method call is made.  It first strips off the
package name from the function call to extract the actual function name.  It then checks to see
if the function name starts with an underscore.  If it does, it's a failed call from the "normal"
method closure, so C<AUTOLOAD> calls C<croak> to die with the appropriate error message.  Notice
that the underscore has been stripped off, so it will C<die> failing to find C<method>.

C<AUTOLOAD> then calls C<can>, which will return a reference to the appropriate C<CODE> entity if
the method call is supported.  At the same time, C<can> puts an entry into the symbol table for
C<Class::SelfMethods> to support future calls to that method.  C<AUTOLOAD> jumps to that C<CODE>
entity if a valid entity was return.  Otherwise, execution continues on to another C<croak> call.

=head2 new

The C<new> method supplied in C<Class::SelfMethods> provides one interesting twist on an
otherwise standard named parameters constructor.  It strips out any passed parameters that have
leading underscores and stores them away.  It then creates the hash ref from the remaining
parameters and blesses it appropriately.  Finally, it takes the stored parameters that have
leading underscores and makes the matching method calls - the key is used for the method name and
the value is dereferenced to an array and passed as parameters.

=head1 AUTHOR

Toby Ovod-Everett, tovod-everett@alascom.att.com

=head1 CREDITS

=over 4

=item Damian Conway, damian@cs.monash.edu.au

Responsible for accessor methods, module name, constructive criticism and moral support.  After I
responded to Sean's suggestion of implementing a C<can> method, Damian completely rewrote my first
attempt by routing everything through C<can>. He also was the first to point out direct symbol
table manipulation by implementing it for the C<_SET> and C<_CLEAR> methods.  I rebutted his
routing everything through C<can> by doing performance testing.  He agreed that the performance
issues were a problem, but suggested retaining the direct symbol table for the accessor methods.
It was then that the lightbulb went off and I realized that a properly written closure could be
used for the normal method calls. Damian's criticisms kept me on track and from making a fool of
myself, and the result is some very fast (and I hope safe:) code.

I first started writing to Damian as a result of an excellent book he wrote, Object Oriented Perl.
I highly recommend it - get it, read it.

=item Sean M. Burke, sburke@netadventure.net

Suggested implementing a C<can> method.  Sean was/is responsible for C<Class::Classless>.  If
you need a full-featured purely prototype based object system, check it out.

=back

=cut


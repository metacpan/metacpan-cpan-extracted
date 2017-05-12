package Class::Tie::InsideOut;

require Tie::InsideOut;

our $VERSION = '0.11';

our @ISA = qw( );

sub new {
  my $class = shift || __PACKAGE__;
  my $self = { };
  tie %$self, 'Tie::InsideOut';
  bless $self, $class;
}

1;

__END__

=for todo stop

=head1 NAME

Class::Tie::InsideOut - Inside-out objects on the cheap using tied hashes

=begin readme

=head1 REQUIREMENTS

Perl 5.6.1, and L<Scalar::Util>.

=head1 INSTALLATION

Installation can be done using the traditional Makefile.PL method:

Using Makefile.PL:

  perl Makefile.PL
  make test
  make install

=end readme

=head1 SYNOPSIS

  package MyClass;

  use Class::Tie::InsideOut;

  our @ISA = qw( Class::Tie::InsideOut );

  our %GoodKey;

  sub bad_method {
    my $self = shift;
    return $self->{BadKey}; # this won't work
  }

  sub good_method {
    my $self = shift;
    return $self->{GoodKey}; # %GoodKey is defined
  }

=head1 DESCRIPTION

This module is a proof-of-concept for implementing inside-out objects
using tied hashes.  It makes use of the L<Tie::InsideOut> package to
tie hash keys to hashes in the calling package's namespace.

Fields are accessed as hash keys, so in traditional Perl objects can be
easily converted into inside-out objects.

=begin readme

More information can be found in the module documentation.

=end readme

=for readme stop

To use, inherit our class from L<Class::Tie::InsideOut> and then specify
the legal keys for your object to use as hashes within the classes namespace:

  package MyClass;

  use Class::Tie::InsideOut;

  our @ISA = qw( Class::Tie::InsideOut );

  our (%Field1, %Field2, %Field3 ); # Fields used by MyClass

Note that your keys must be specified as C<our> variables so that they are accessible
from outside of the class, and not as C<my> variables!

Fields are accessed as hash keys from the object reference:

  sub method {
    my $self = shift;
    if (@_) {
      $self->{Field1} = shift;
    }
    else {
      return $self->{Field1};
    }
  }

Converting a Perl module which uses "traditional" objects into one which
uses inside-out objects can be a matter of adding L<Class::Tie::InsideOut>
to the C<@ISA> list and adding the field names as global hashes.

However, if child classes do not use parent class methods to access fields
in the parent class, then there will be problems.
See the L</KNOWN ISSUES> section below.

=head2 Serialization and Cloning

You can use L<Storable> to serialize clone objects, since there are hooks
in L<Tie::InsideOut> which allow for this.  To add a clone method to your
class:

  use Storable qw( dclone );

  ...

  sub clone {
    my $self = shift;
    my $clone = dclone($self);
    return $clone;
  }

But be aware that if the structure of parent classes are changed, then you may not be
able to deserialize objects. (The same can happen with tradititional classes,
but C<Tie::InsideOut> will catch this and return an error.)

=head1 KNOWN ISSUES

When a class is inherited from from a L<Class::Tie::InsideOut> class, then
it too must be an inside out class and have the fields defined as global
hashes.  This will affect inherited classes downstream.

Child classes cannot directly access the fields of parent classes. They
must use appropriate accessor methods from the parent classes.  If they
create duplicate field names, then those fields can only be accessed
from within the those classes.

As a consequence of this, objects may not be serializable or clonable out
of the box. Packages such as L<Clone> and L<Data::Dumper> will not work properly.

To use with packages which generate accessor methods such as
L<Class::Accessor> with this, you'll need to define the C<set> and C<get>
methods inside of your class.

Accessor-generating packages which do not make use of an intermediate
method are not compatible with this package. This is partly a Perl issue:
the caller information from closures reflects the namespace of the package
that created the closure, not the actual package that the closure resides.
However, the issue is fixable. The subroutine needs to set its namespace:

  $accessor = sub {
    local *__ANON__ = "${class}::${field}";
    my $self = shift;
    ...
  };

Another alternative is to use L<Sub::Name> to rename subroutines:

  use Sub::Name;

  $accessor = subname "${class}::${field}" => sub {
    my $self = shift;
    ...
  };

However, L<Sub::Name> uses XS and is not a pure-Perl solution.

This version does little checking of the key names, beyond that there is a
global hash variable with that name in the namespace of the method that
uses it.  It might be a hash intended as a field, or it might be one intended
for something else. (You could hide them by specifying them as C<my> variables, though.)

There are no checks against using the name of a tied L<Tie::InsideOut> or
L<Class::Tie::InsideOut> global hash variable as a key for itself, which
has unpredicable (and possibly dangerous) results.

=begin todo

=head1 TODO

To-do list for L<Class::Tie::InsideOut> and L<Tie::InsideOut>

=head2 Enhancements

=over

=item *

Add an equivalent mk_accessors function akin to what L<Class::Accessor>
does.

=item *

Change FIRSTKEY and NEXTKEY methods in L<Tie::InsideOut> so that they
only show methods that the caller has access to.

=item *

Add an option so that a default exception handler or callback can be
given rather than dieing when a key is accessed outside of its
namespace.  Then one can provide a map of field names to methods to
call.

=back

=head2 Tests

=over

=item *

Verify that deserialization into a different namespace causes an error.

=item *

Add better tests for FIRSTKEY and NEXTKEY methods in L<Tie::InsideOut>.

=item *

Add the usual "kwalitee" tests.

=back

=end todo

=for todo stop

=for readme continue

=begin readme

=head1 REVISION HISTORY

A brief list of changes since the previous release:

=for readme include file="Changes" start="0.11" stop="0.053" type="text"

For a detailed history see the F<Changes> file included in this distribution.

=end readme

=head1 SEE ALSO

=for readme stop

This module is a wrapper for L<Tie::InsideOut>.

=for readme continue

There are various other inside-out object packages on CPAN. Among them:

  Class::InsideOut
  Class::Std
  Object::InsideOut

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Acknowledgements

Thanks to Ovid (via Chromatic) and Steven Little for advice in PerlMonks
on the namespace issues with L<Class::Accessor>.

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 STATUS

This module has not been seriously updated since 2006, and inside-out
objects have largely fallen out of favor since then.

It has been marked as C<ADOPTME> on CPAN.

=head1 LICENSE

Copyright (c) 2006,2014 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


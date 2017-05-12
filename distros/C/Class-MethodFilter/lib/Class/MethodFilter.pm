package Class::MethodFilter;

use strict;
use warnings;
use vars qw/$VERSION/;
use Carp;

$VERSION = "0.02";

=head1 NAME

Class::MethodFilter - add filters to class methods

=head1 SYNOPSIS

  package SomeClass;

  sub foo {
    return "foo!\n";
  }

  __PACKAGE__->add_method_filter('foo', sub { $_[1] =~ tr/a-z/A-Z/; $_[1]; });

  # Meanwhile, in another piece of code ...

  my $obj = new SomeClass;
  print $obj->foo();             # Prints "foo!"
  print $obj->foo_filtered();    # Prints "FOO!"

=head1 DESCRIPTION

Class::MethodFilter is designed for situations where you want a filtered
version of the return values of a method that's separate from the method
itself; it provides a convenient API for installing filters written different
ways while leaving the eventual interface consistent.

=head1 DETAILS

A single additional class method is added to your package, add_method_filter.
It can be called with (so far) three different signatures -

  __PACKAGE__->add_method_filter('method', sub { ... } );
  __PACKAGE__->add_method_filter('method', 'filter_method');
  __PACKAGE__->add_method_filter('method');

The first form installs the supplied sub as __PACKAGE__::method_filter, the
second creates an __PACKAGE__::method_filter that proxies the call to the named
method, and the third assumes that __PACKAGE__::method_filter already exists.

If __PACKAGE__::method_filtered does not exist, one is created that calls

  $_[0]->method_filter($_[0]->method(@_));

and returns the result. If it *does* exist, it is assumed to have accessor-like
behaviour (as from e.g. use of Class::Accessor) and Class::MethodFilter
replaces __PACKAGE__::method with a sub that calls $_[0]->method_filtered(@_)
and then returns the result of invoking the original method. This is designed
to allow __PACKAGE__::method_filtered to act as a cache for the filtered
result which is automatically updated every time the method it's filtering is
called.

=head1 AUTHOR

Matt S Trout <mstrout@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub add_method_filter {
  my ($package, $method, $filter) = @_;
  croak "Can't filter nonexistant method $method on $package!"
    unless $package->can($method);
  my $m_filter = "${method}_filter";
  my $m_filtered = "${method}_filtered";
  no strict 'refs';
  if (defined $filter) {
    *{"${package}::${m_filter}"} =
      (ref $filter eq 'CODE'
        ? $filter
        : sub { $_[0]->$filter(@_[1..$#_]); } );
  }
  if ($package->can($m_filtered)) {
    my $cr = *{"${package}::${method}"}{CODE};
    no warnings qw/redefine/;
    *{"${package}::${method}"} =
      sub { my @args = @_;
        if ($#args > 0) {
          $args[0]->$m_filtered($args[0]->$m_filter(@args[1..$#args]));
        }
        return &$cr;
      };
  } else {
    *{"${package}::${m_filtered}"} =
      sub { $_[0]->$m_filter($_[0]->$method(@_)); };
  }
}

1;


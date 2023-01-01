use strict;
use warnings;
package Data::Hive::Store 1.015;
# ABSTRACT: a backend storage driver for Data::Hive

use Carp ();

#pod =head1 DESCRIPTION
#pod
#pod Data::Hive::Store is a generic interface to a backend store
#pod for Data::Hive.
#pod
#pod =head1 METHODS
#pod
#pod All methods are passed at least a 'path' (arrayref of namespace pieces).  Store
#pod classes exist to operate on the entities found at named paths.
#pod
#pod =head2 get
#pod
#pod   print $store->get(\@path, \%opt);
#pod
#pod Return the resource represented by the given path.
#pod
#pod =head2 set
#pod
#pod   $store->set(\@path, $value, \%opt);
#pod
#pod Analogous to C<< get >>.
#pod
#pod =head2 name
#pod
#pod   print $store->name(\@path, \%opt);
#pod
#pod Return a store-specific name for the given path.  This is primarily useful for
#pod stores that may be accessed independently of the hive.
#pod
#pod =head2 exists
#pod
#pod   if ($store->exists(\@path, \%opt)) { ... }
#pod
#pod Returns true if the given path exists in the store.
#pod
#pod =head2 delete
#pod
#pod   $store->delete(\@path, \%opt);
#pod
#pod Delete the given path from the store.  Return the previous value, if any.
#pod
#pod Stores can also implement C<delete_all> to delete this path and all paths below
#pod it.  If C<delete_all> is not provided, the generic one-by-one delete in this
#pod class will be used.
#pod
#pod =head2 keys
#pod
#pod   my @keys = $store->keys(\@path, \%opt);
#pod
#pod This returns a list of next-level path elements that lead toward existing
#pod values.  For more information on the expected behavior, see the L<KEYS
#pod method|Data:Hive/keys> in Data::Hive.
#pod
#pod =cut

BEGIN {
  for my $meth (qw(get set name exists delete keys)) {
    no strict 'refs';
    *$meth = sub { Carp::croak("$_[0] does not implement $meth") };
  }
}

sub save {}

sub save_all {
  my ($self, $path) = @_;

  $self->save;
  for my $key ($self->keys($path)) {
    $self->save_all([ @$path, $key ]);
  }

  return;
}

sub delete_all {
  my ($self, $path) = @_;

  $self->delete($path);
  for my $key ($self->keys($path)) {
    $self->delete_all([ @$path, $key ]);
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Hive::Store - a backend storage driver for Data::Hive

=head1 VERSION

version 1.015

=head1 DESCRIPTION

Data::Hive::Store is a generic interface to a backend store
for Data::Hive.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

All methods are passed at least a 'path' (arrayref of namespace pieces).  Store
classes exist to operate on the entities found at named paths.

=head2 get

  print $store->get(\@path, \%opt);

Return the resource represented by the given path.

=head2 set

  $store->set(\@path, $value, \%opt);

Analogous to C<< get >>.

=head2 name

  print $store->name(\@path, \%opt);

Return a store-specific name for the given path.  This is primarily useful for
stores that may be accessed independently of the hive.

=head2 exists

  if ($store->exists(\@path, \%opt)) { ... }

Returns true if the given path exists in the store.

=head2 delete

  $store->delete(\@path, \%opt);

Delete the given path from the store.  Return the previous value, if any.

Stores can also implement C<delete_all> to delete this path and all paths below
it.  If C<delete_all> is not provided, the generic one-by-one delete in this
class will be used.

=head2 keys

  my @keys = $store->keys(\@path, \%opt);

This returns a list of next-level path elements that lead toward existing
values.  For more information on the expected behavior, see the L<KEYS
method|Data:Hive/keys> in Data::Hive.

=head1 AUTHORS

=over 4

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Ricardo Signes <cpan@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Hans Dieter Pearcey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIx::Class::IntrospectableM2M;

use strict;
use warnings;
use base 'DBIx::Class';

our $VERSION = '0.001002';

#namespace pollution. sadface.
__PACKAGE__->mk_classdata( _m2m_metadata => {} );

sub many_to_many {
  my $class = shift;
  my ($meth_name, $link, $far_side) = @_;
  my $store = $class->_m2m_metadata;
  warn("You are overwritting another relationship's metadata")
    if exists $store->{$meth_name};

  my $attrs = {
    accessor => $meth_name,
    relation => $link, #"link" table or immediate relation
    foreign_relation => $far_side, #'far' table or foreign relation
    (@_ > 3 ? (attrs => $_[3]) : ()), #only store if exist
    rs_method => "${meth_name}_rs",      #for completeness..
    add_method => "add_to_${meth_name}",
    set_method => "set_${meth_name}",
    remove_method => "remove_from_${meth_name}",
  };

  #inheritable data workaround
  $class->_m2m_metadata({ $meth_name => $attrs, %$store});
  $class->next::method(@_);
}

1;

__END__;

=head1 NAME

DBIx::Class::IntrospectableM2M - Introspect many-to-many shortcuts

=head1 SYNOPSIS

In your L<DBIx::Class> Result class
(sometimes erroneously referred to as the 'table' class):

  __PACKAGE__->load_components(qw/IntrospectableM2M ... Core/);

  #Digest encoder with hex format and SHA-1 algorithm
  __PACKAGE__->many_to_many(roles => user_roles => 'role);

When you want to introspect this data

   my $metadata = $result_class->_m2m_metadata->{roles};
   #  $metadata->{accessor} method name e.g. 'roles'
   #  $metadata->{relation} maping relation e.g. 'user_roles'
   #  $metadata->{foreign_relation} far-side relation e.g. 'role
   #  $metadata->{attrs}  relationship attributes, if any
   # Convenience methods created by DBIx::Class
   #  $metadata->{rs_method}     'roles_rs'
   #  $metadata->{add_method}    'add_to_roles',
   #  $metadata->{set_method}    'set_roles',
   #  $metadata->{remove_method} 'remove_from_roles'

B<Note:> The component needs to be loaded I<before> Core.

=head1 COMPATIBILITY NOTICE

This module is fairly esoteric and, unless you are dynamically creating
something out of a DBIC Schema, is probably the wrong solution for
whatever it is you are trying to do. Please be advised that compatibility
is not guaranteed for DBIx::Class 0.09000+. We will try to manitain all
compatibility, but internal changes might make it impossible.

=head1 DESCRIPTION

Because the many-to-many relationships are not real relationships, they can not
be introspected with DBIx::Class. Many-to-many relationships are actually just
a collection of convenience methods installed to bridge two relationships.
This L<DBIx::Class> component can be used to store all relevant information
about these non-relationships so they can later be introspected and examined.

=head1 METHODS

=head2 many_to_many

Extended to store all relevant information in the C<_m2m_metadata> HASH ref.

=head2 _m2m_metadata

Accessor to a HASH ref where the keys are the names of m2m relationships and
the value is a HASH ref as described in the SYNOPSIS.

=head1 AUTHOR

Guillermo Roditi (groditi) E<lt>groditi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Guillermo Roditi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

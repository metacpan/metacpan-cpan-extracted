package DBIO::Base;
# ABSTRACT: Meta-infrastructure base for all DBIO internal classes

use strict;
use warnings;

use DBIO::Util;
use mro 'c3';

use DBIO::Optional::Dependencies;

use base qw/DBIO::Componentised Class::Accessor::Grouped/;
use Scalar::Util ();
use DBIO::StartupCheck;
use DBIO::Exception;

my $successfully_loaded_components;

sub get_component_class {
  my $class = $_[0]->get_inherited($_[1]);

  return $class if Scalar::Util::blessed($class);

  if (defined $class and ! $successfully_loaded_components->{$class} ) {
    $_[0]->ensure_class_loaded($class);

    no strict 'refs';
    $successfully_loaded_components->{$class}
      = ${"${class}::__LOADED__BY__DBIO__CAG__COMPONENT_CLASS__"}
        = do { \(my $anon = 'loaded') };
    Scalar::Util::weaken($successfully_loaded_components->{$class});
  }

  $class;
}

sub set_component_class {
  shift->set_inherited(@_);
}

__PACKAGE__->mk_group_accessors(inherited => '_skip_namespace_frames');
__PACKAGE__->_skip_namespace_frames('^DBIO|^SQL::Abstract|^Try::Tiny|^Class::Accessor::Grouped|^Context::Preserve');

sub mk_classdata {
  shift->mk_classaccessor(@_);
}

sub mk_classaccessor {
  my $self = shift;
  $self->mk_group_accessors('inherited', $_[0]);
  $self->set_inherited(@_) if @_ > 1;
}

sub component_base_class { 'DBIO' }

sub MODIFY_CODE_ATTRIBUTES {
  my ($class,$code,@attrs) = @_;
  $class->mk_classdata('__attr_cache' => {})
    unless $class->can('__attr_cache');
  $class->__attr_cache->{$code} = [@attrs];
  return ();
}

sub _attr_cache {
  my $self = shift;
  my $cache = $self->can('__attr_cache') ? $self->__attr_cache : {};

  return {
    %$cache,
    %{ $self->maybe::next::method || {} },
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Base - Meta-infrastructure base for all DBIO internal classes

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Base> is the shared meta-infrastructure base for all internal
DBIO classes. It bundles the common machinery that nearly every DBIO
class needs:

=over 4

=item * C<use mro 'c3'> for deterministic method resolution

=item * L<DBIO::Componentised> for C<load_components>

=item * L<Class::Accessor::Grouped> for C<mk_group_accessors>

=item * C<mk_classdata> / C<mk_classaccessor> shortcuts

=item * C<component_base_class> so Componentised knows where to search

=item * Perl subroutine attributes via C<MODIFY_CODE_ATTRIBUTES> / C<_attr_cache>

=item * C<_skip_namespace_frames> class data for L<DBIO::Carp>

=back

Internal DBIO classes (C<DBIO::Core>, C<DBIO::Row>, C<DBIO::ResultSet>,
C<DBIO::Schema>, C<DBIO::Storage>, and roughly twenty-five others)
inherit from this class. User-facing result classes transitively
inherit through their immediate bases.

=head1 NOT TO BE USED AS A USER-FACING BASE

User-facing result classes should inherit from L<DBIO::Core>, not from
C<DBIO::Base> directly. C<DBIO::Core> pulls in the standard result
components (Row, Relationship, PK, Timestamp, etc.) that user code
expects.

The split between L<DBIO::Base> (meta-infrastructure) and L<DBIO> (user
sugar pragma) mirrors the Moose pattern where C<Moose::Meta::*> sits
under the hierarchy and C<Moose.pm> provides C<use Moose;> sugar.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

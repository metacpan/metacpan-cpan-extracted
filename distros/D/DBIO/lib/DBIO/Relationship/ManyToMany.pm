package DBIO::Relationship::ManyToMany;
# ABSTRACT: Declare a many-to-many relationship via a bridge table

use strict;
use warnings;

use DBIO::Carp;
use Sub::Util 'set_subname';
use Scalar::Util 'blessed';
use DBIO::Util qw(fail_on_internal_wantarray assert_no_internal_wantarray);
use namespace::clean;

our %_pod_inherit_config =
  (
   class_map => { 'DBIO::Relationship::ManyToMany' => 'DBIO::Relationship' }
  );


sub many_to_many {
  my ($class, $meth, $rel, $f_rel, $rel_attrs) = @_;

  $class->throw_exception(
    "missing relation in many-to-many"
  ) unless $rel;

  $class->throw_exception(
    "missing foreign relation in many-to-many"
  ) unless $f_rel;

  $class->mk_classdata('_m2m_metadata' => {})
    unless $class->can('_m2m_metadata');

  my $store = $class->_m2m_metadata;
  carp("Overwriting existing many-to-many metadata for '$meth'")
    if exists $store->{$meth};

  $class->_m2m_metadata({
    %$store,
    $meth => {
      accessor         => $meth,
      relation         => $rel,
      foreign_relation => $f_rel,
      (@_ > 4 ? (attrs => $rel_attrs) : ()),
      rs_method        => "${meth}_rs",
      add_method       => "add_to_${meth}",
      set_method       => "set_${meth}",
      remove_method    => "remove_from_${meth}",
    },
  });

  {
    no strict 'refs';
    no warnings 'redefine';

    my $add_meth = "add_to_${meth}";
    my $remove_meth = "remove_from_${meth}";
    my $set_meth = "set_${meth}";
    my $rs_meth = "${meth}_rs";

    for ($add_meth, $remove_meth, $set_meth, $rs_meth) {
      if ( $class->can ($_) ) {
        carp (<<"EOW") unless $ENV{DBIO_OVERWRITE_HELPER_METHODS_OK};

***************************************************************************
The many-to-many relationship '$meth' is trying to create a utility method
called $_.
This will completely overwrite one such already existing method on class
$class.

You almost certainly want to rename your method or the many-to-many
relationship, as the functionality of the original method will not be
accessible anymore.

To disable this warning set to a true value the environment variable
DBIO_OVERWRITE_HELPER_METHODS_OK

***************************************************************************
EOW
      }
    }

    $rel_attrs->{alias} ||= $f_rel;

    my $rs_meth_name = join '::', $class, $rs_meth;
    *$rs_meth_name = set_subname $rs_meth_name, sub {
      my $self = shift;
      my $attrs = @_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {};
      my $rs = $self->search_related($rel)->search_related(
        $f_rel, @_ > 0 ? @_ : undef, { %{$rel_attrs||{}}, %$attrs }
      );
      return $rs;
    };

    my $meth_name = join '::', $class, $meth;
    *$meth_name = set_subname $meth_name, sub {
      assert_no_internal_wantarray and my $sog = fail_on_internal_wantarray;
      my $self = shift;
      my $rs = $self->$rs_meth( @_ );
      return (wantarray ? $rs->all : $rs);
    };

    my $add_meth_name = join '::', $class, $add_meth;
    *$add_meth_name = set_subname $add_meth_name, sub {
      my $self = shift;
      @_ > 0 or $self->throw_exception(
        "${add_meth} needs an object or hashref"
      );
      my $source = $self->result_source;
      my $schema = $source->schema;
      my $rel_source_name = $source->relationship_info($rel)->{source};
      my $rel_source = $schema->resultset($rel_source_name)->result_source;
      my $f_rel_source_name = $rel_source->relationship_info($f_rel)->{source};
      my $f_rel_rs = $schema->resultset($f_rel_source_name)->search({}, $rel_attrs||{});

      my $obj;
      if (ref $_[0]) {
        if (ref $_[0] eq 'HASH') {
          $obj = $f_rel_rs->find_or_create($_[0]);
        } else {
          $obj = $_[0];
        }
      } else {
        $obj = $f_rel_rs->find_or_create({@_});
      }

      my $link_vals = @_ > 1 && ref $_[$#_] eq 'HASH' ? pop(@_) : {};
      my $link = $self->search_related($rel)->new_result($link_vals);
      $link->set_from_related($f_rel, $obj);
      $link->insert();
      return $obj;
    };

    my $set_meth_name = join '::', $class, $set_meth;
    *$set_meth_name = set_subname $set_meth_name, sub {
      my $self = shift;
      @_ > 0 or $self->throw_exception(
        "{$set_meth} needs a list of objects or hashrefs"
      );
      my @to_set = (ref($_[0]) eq 'ARRAY' ? @{ $_[0] } : @_);
      # if there is a where clause in the attributes, ensure we only delete
      # rows that are within the where restriction
      if ($rel_attrs && $rel_attrs->{where}) {
        $self->search_related( $rel, $rel_attrs->{where},{join => $f_rel})->delete;
      } else {
        $self->search_related( $rel, {} )->delete;
      }
      # add in the set rel objects
      $self->$add_meth($_, ref($_[1]) ? $_[1] : {}) for (@to_set);
    };

    my $remove_meth_name = join '::', $class, $remove_meth;
    *$remove_meth_name = set_subname $remove_meth_name, sub {
      my ($self, $obj) = @_;
      $self->throw_exception("${remove_meth} needs an object")
        unless blessed ($obj);
      my $rel_source = $self->search_related($rel)->result_source;
      my $cond = $rel_source->relationship_info($f_rel)->{cond};
      my ($link_cond, $crosstable) = $rel_source->_resolve_condition(
        $cond, $obj, $f_rel, $f_rel
      );

      $self->throw_exception(
        "Relationship '$rel' does not resolve to a join-free condition, "
       ."unable to use with the ManyToMany helper '$f_rel'"
      ) if $crosstable;

      $self->search_related($rel, $link_cond)->delete;
    };

  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship::ManyToMany - Declare a many-to-many relationship via a bridge table

=head1 VERSION

version 0.900002

=head1 METHODS

=head2 many_to_many

=head2 _m2m_metadata

Accessor for a HASH ref where each key is the name of a many-to-many
relationship declared on the Result class, and the value is a HASH ref
describing that relationship:

  $class->_m2m_metadata->{roles} = {
    accessor         => 'roles',
    relation         => 'user_roles',
    foreign_relation => 'role',
    attrs            => $rel_attrs,   # only present if a 4th arg was given
    rs_method        => 'roles_rs',
    add_method       => 'add_to_roles',
    set_method       => 'set_roles',
    remove_method    => 'remove_from_roles',
  };

Installed lazily on the Result class the first time C<many_to_many> is
called. Provides the same API as L<DBIx::Class::IntrospectableM2M>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

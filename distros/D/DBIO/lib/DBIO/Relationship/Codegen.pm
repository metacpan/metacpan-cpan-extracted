package DBIO::Relationship::Codegen;
# ABSTRACT: Schema-time relationship method synthesis (accessors and proxies)

use strict;
use warnings;
use DBIO::Carp;
use DBIO::Util qw(quote_sub perlstring fail_on_internal_wantarray assert_no_internal_wantarray);
use namespace::clean;

our %_pod_inherit_config =
  (
   class_map => { 'DBIO::Relationship::Codegen' => 'DBIO::Relationship' }
  );


sub register_relationship {
  my ($class, $rel, $info) = @_;

  if (my $acc_type = $info->{attrs}{accessor}) {
    $class->add_relationship_accessor($rel => $acc_type);
  }

  if (my $proxy_args = $info->{attrs}{proxy}) {
    $class->proxy_to_related($rel, $proxy_args);
  }

  $class->next::method($rel => $info);
}


sub add_relationship_accessor {
  my ($class, $rel, $acc_type) = @_;

  if ($acc_type eq 'single') {
    quote_sub "${class}::${rel}" => sprintf(<<'EOC', perlstring $rel);
      my $self = shift;

      if (@_) {
        $self->set_from_related( %1$s => @_ );
        return $self->{_relationship_data}{%1$s} = $_[0];
      }
      elsif (exists $self->{_relationship_data}{%1$s}) {
        return $self->{_relationship_data}{%1$s};
      }
      else {
        my $relcond = $self->result_source->_resolve_relationship_condition(
          rel_name => %1$s,
          foreign_alias => %1$s,
          self_alias => 'me',
          self_result_object => $self,
        );

        return undef if (
          $relcond->{join_free_condition}
            and
          $relcond->{join_free_condition} ne DBIO::Util::UNRESOLVABLE_CONDITION()
            and
          scalar grep { not defined $_ } values %%{ $relcond->{join_free_condition} || {} }
            and
          $self->result_source->relationship_info(%1$s)->{attrs}{undef_on_null_fk}
        );

        my $val = $self->search_related( %1$s )->single;
        return $val unless $val;  # $val instead of undef so that null-objects can go through

        return $self->{_relationship_data}{%1$s} = $val;
      }
EOC
  }
  elsif ($acc_type eq 'filter') {
    $class->throw_exception("No such column '$rel' to filter")
       unless $class->has_column($rel);

    my $f_class = $class->relationship_info($rel)->{class};

    $class->inflate_column($rel, {
      inflate => sub {
        my ($val, $self) = @_;
        return $self->find_or_new_related($rel, {}, {});
      },
      deflate => sub {
        my ($val, $self) = @_;
        $self->throw_exception("'$val' isn't a $f_class") unless $val->isa($f_class);

        # MASSIVE FIXME - this code assumes we pointed at the PK, but the belongs_to
        # helper does not check any of this
        # fixup the code a bit to make things saner, but ideally 'filter' needs to
        # be deprecated ASAP and removed shortly after
        # Not doing so before 0.08250 however, too many things in motion already
        my ($pk_col, @rest) = $val->result_source->_pri_cols_or_die;
        $self->throw_exception(
          "Relationship '$rel' of type 'filter' can not work with a multicolumn primary key on source '$f_class'"
        ) if @rest;

        my $pk_val = $val->get_column($pk_col);
        carp_unique (
          "Unable to deflate 'filter'-type relationship '$rel' (related object "
        . "primary key not retrieved), assuming undef instead"
        ) if ( ! defined $pk_val and $val->in_storage );

        return $pk_val;
      },
    });
  }
  elsif ($acc_type eq 'multi') {

    quote_sub "${class}::${rel}_rs", "shift->search_related_rs( $rel => \@_ )";
    quote_sub "${class}::add_to_${rel}", "shift->create_related( $rel => \@_ )";
    quote_sub "${class}::${rel}", sprintf( <<'EOC', perlstring $rel );
      DBIO::Util::assert_no_internal_wantarray() and my $sog = DBIO::Util::fail_on_internal_wantarray;
      shift->search_related( %s => @_ )
EOC
  }
  else {
    $class->throw_exception("No such relationship accessor type '$acc_type'");
  }

}


sub proxy_to_related {
  my ($class, $rel, $proxy_args) = @_;
  my %proxy_map = $class->_build_proxy_map_from($proxy_args);

  quote_sub "${class}::$_", sprintf( <<'EOC', $rel, $proxy_map{$_} )
    my $self = shift;
    my $relobj = $self->%1$s;
    if (@_ && !defined $relobj) {
      $relobj = $self->create_related( %1$s => { %2$s => $_[0] } );
      @_ = ();
    }
    $relobj ? $relobj->%2$s(@_) : undef;
EOC
    for keys %proxy_map
}


sub _build_proxy_map_from {
  my ( $class, $proxy_arg ) = @_;
  my $ref = ref $proxy_arg;

  if ($ref eq 'HASH') {
    return %$proxy_arg;
  }
  elsif ($ref eq 'ARRAY') {
    return map {
      (ref $_ eq 'HASH')
        ? (%$_)
        : ($_ => $_)
    } @$proxy_arg;
  }
  elsif ($ref) {
    $class->throw_exception("Unable to process the 'proxy' argument $proxy_arg");
  }
  else {
    return ( $proxy_arg => $proxy_arg );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Relationship::Codegen - Schema-time relationship method synthesis (accessors and proxies)

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Schema-time relationship codegen for L<DBIO::Relationship>. Hooks
C<register_relationship> to install:

=over 4

=item *

The relationship accessor methods (C<single>, C<filter>, C<multi> styles)
on the result class. See L</add_relationship_accessor>.

=item *

Proxy attribute accessors that forward through a relationship when the
declaration includes C<< proxy => ... >>. See L</proxy_to_related>.

=back

=head1 METHODS

=head2 register_relationship

=head2 add_relationship_accessor

=head2 proxy_to_related

=head2 _build_proxy_map_from

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package DBIO::Relationship::Codegen;
# ABSTRACT: Schema-time relationship method synthesis (accessors and proxies)

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Carp;
use Scalar::Util 'blessed';
use DBIO::Util qw(quote_sub perlstring assert_no_list_context);
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

        # a plain hashref is column values, reduced to our own columns just
        # above (ADR 0034) -- not a related object to keep
        return $_[0] if ref $_[0] eq 'HASH';

        return $self->{_relationship_data}{%1$s} = $_[0];
      }
      elsif (exists $self->{_relationship_data}{%1$s}) {
        return $self->{_relationship_data}{%1$s};
      }
      else {
        return undef if $self->_relationship_null_fk_miss(%1$s);

        my $val = $self->search_related( %1$s )->single;
        return $val unless $val;  # $val instead of undef so that null-objects can go through

        return $self->{_relationship_data}{%1$s} = $val;
      }
EOC

    quote_sub "${class}::${rel}_async" => sprintf(<<'EOC', perlstring $rel, $rel);
      my $self = shift;
      $self->throw_exception("%2$s_async doesn't take arguments -- use ->%2$s(...) to set the relationship")
        if @_;

      return $self->_row_run_async(%1$s,
        sub {
          my ($backend, $fc) = @_;

          return $fc->done($self->{_relationship_data}{%1$s})
            if exists $self->{_relationship_data}{%1$s};

          return $fc->done(undef)
            if $self->_relationship_null_fk_miss(%1$s);

          return $self->search_related(%1$s)->single_async->then(sub {
            my ($val) = @_;
            return $val unless $val;  # $val instead of undef so that null-objects can go through
            return $self->{_relationship_data}{%1$s} = $val;
          });
        },
        sub { $self->%2$s },
      );
EOC
  }
  elsif ($acc_type eq 'filter') {
    $class->throw_exception("No such column '$rel' to filter")
       unless $class->has_column($rel);

    my $f_class = $class->relationship_info($rel)->{class};

    $class->inflate_column($rel, {
      inflate => sub {
        my ($val, $self) = @_;
        # the row the foreign key names: found by the key the related
        # resultset holds, a new row when there is none
        my $found = $self->find_related($rel, {}, {});
        return defined $found ? $found : $self->new_related($rel, {}, {});
      },
      deflate => sub {
        my ($val, $self) = @_;
        $self->throw_exception("The value given for '$rel' isn't a $f_class")
          unless blessed $val and $val->isa($f_class);

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

    quote_sub "${class}::${rel}_rs", sprintf('shift->search_related_rs( %s => @_ )', perlstring $rel);
    quote_sub "${class}::add_to_${rel}", sprintf('shift->create_related( %s => @_ )', perlstring $rel);
    quote_sub "${class}::${rel}", sprintf( <<'EOC', perlstring $rel, perlstring $rel );
      my $self = shift;
      DBIO::Util::assert_no_list_context('relationship accessor %s') if wantarray;
      $self->search_related_rs( %s => @_ )
EOC
  }
  else {
    $class->throw_exception("No such relationship accessor type '$acc_type'");
  }

}

# Shared by the single-type accessor and its _async twin: true when the
# relationship's join-free condition is fully resolved but every value in it
# is undef (the FK is definitely NULL) and the relationship is configured to
# skip the query in that case (undef_on_null_fk -- the belongs_to default).
# See DBIO::Relationship/belongs_to.
sub _relationship_null_fk_miss {
  my ($self, $rel) = @_;

  my $relcond = $self->result_source->_resolve_relationship_condition(
    rel_name => $rel,
    foreign_alias => $rel,
    self_alias => 'me',
    self_result_object => $self,
  );

  return !!(
    $relcond->{join_free_condition}
      and
    $relcond->{join_free_condition} ne DBIO::Util::UNRESOLVABLE_CONDITION()
      and
    scalar grep { not defined $_ } values %{ $relcond->{join_free_condition} || {} }
      and
    $self->result_source->relationship_info($rel)->{attrs}{undef_on_null_fk}
  );
}


sub proxy_to_related {
  my ($class, $rel, $proxy_args) = @_;
  my %proxy_map = $class->_build_proxy_map_from($proxy_args);

  for my $col (values %proxy_map) {
    $class->throw_exception(
      "proxy column of relationship '$rel' must be a plain column name"
    ) unless defined $col and !ref $col and $col =~ /\A\w+\z/;
  }

  quote_sub "${class}::$_", sprintf( <<'EOC', perlstring($rel), perlstring($proxy_map{$_}) )
    my $self = shift;
    my $relobj = $self->${\ %1$s};
    if (@_ && !defined $relobj) {
      $relobj = $self->create_related( %1$s => { %2$s => $_[0] } );
      @_ = ();
    }
    $relobj ? $relobj->${\ %2$s}(@_) : undef;
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

version 0.900004

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

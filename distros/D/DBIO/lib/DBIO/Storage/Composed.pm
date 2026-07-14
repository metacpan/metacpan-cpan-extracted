package DBIO::Storage::Composed;
# ABSTRACT: Runtime C3 composition of storage extension layers over a base storage class

use strict;
use warnings;

use mro;
use B ();
use Class::C3::Componentised ();
use DBIO::Exception;
use namespace::clean;


# name => registry entry { base => $base, layers => [ @layers ] }.
# Keyed by the synthesised package name so it is idempotent for a given
# (base, layers) tuple and recoverable from ref($instance) at rebless time.
our %COMPOSED;


sub compose {
  my ($class, $base, $layers) = @_;
  $layers ||= [];
  my @layers = @$layers;

  return $base unless @layers;

  my $pkg = 'DBIO::Storage::Composed::'
    . join('__', map { (my $s = $_) =~ s/::/_/g; $s } @layers, $base);

  return $pkg if $COMPOSED{$pkg};

  Class::C3::Componentised->ensure_class_loaded($base);
  Class::C3::Componentised->ensure_class_loaded($_) for @layers;

  $class->_assert_no_layer_collisions(\@layers);

  {
    no strict 'refs';
    @{"${pkg}::ISA"} = (@layers, $base);
  }
  mro::set_mro($pkg, 'c3');

  $COMPOSED{$pkg} = { base => $base, layers => [@layers] };

  return $pkg;
}


sub composition_of {
  my ($class, $pkg) = @_;
  return undef unless defined $pkg;
  return $COMPOSED{$pkg};
}


sub layers_of {
  my ($class, $pkg) = @_;
  my $entry = $class->composition_of($pkg) or return;
  return @{ $entry->{layers} };
}


sub recompose {
  my ($class, $pkg, $new_base) = @_;
  my $entry = $class->composition_of($pkg)
    or DBIO::Exception->throw(
      "recompose: '$pkg' is not a composed storage class"
    );
  return $class->compose($new_base, $entry->{layers});
}

# The method names a package defines IN ITSELF -- CODE slots whose compiled body
# actually originates in $pkg, not aliased/imported subs and not inherited ones.
# Standard phasers and OO plumbing are never "layer methods" for collision
# purposes, so they are excluded (two layers each having a BEGIN block, or an
# imported croak, is not a method collision).
my %NOT_A_METHOD = map { $_ => 1 }
  qw(BEGIN END INIT CHECK UNITCHECK DESTROY AUTOLOAD import unimport);

sub _own_methods {
  my ($class, $pkg) = @_;

  my @names;
  no strict 'refs';
  my $stash = \%{"${pkg}::"};
  for my $name (keys %$stash) {
    next if $name =~ /::\z/;          # nested stash, not a sub
    next if $NOT_A_METHOD{$name};
    my $code = *{"${pkg}::${name}"}{CODE};
    next unless defined $code;
    # Only count a sub whose compiled body originates in $pkg -- skips imports
    # and re-exports that merely alias into the stash.
    my $origin = B::svref_2object($code)->GV->STASH->NAME;
    next unless $origin eq $pkg;
    push @names, $name;
  }
  return @names;
}

sub _assert_no_layer_collisions {
  my ($class, $layers) = @_;

  my %defined_in;   # method name => [ packages that define it ]
  for my $layer (@$layers) {
    push @{ $defined_in{$_} }, $layer for $class->_own_methods($layer);
  }

  my @collisions = grep { @{ $defined_in{$_} } > 1 } sort keys %defined_in;
  return unless @collisions;

  my $detail = join '; ', map {
    "$_ (defined in " . join(', ', @{ $defined_in{$_} }) . ')'
  } @collisions;

  DBIO::Exception->throw(
    "storage layer method collision: $detail -- two or more storage layers "
  . 'define the same method; rename or merge them so only one layer owns it, '
  . 'or override the base method in a single layer and let the others chain '
  . 'via next::method'
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Composed - Runtime C3 composition of storage extension layers over a base storage class

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

One behaviour, one transport. DBIO storage extensions ship as B<layers> --
plain method packages that override or wrap the documented public storage
surface -- and any number of them compose at runtime, over any base storage
(the generic L<DBIO::Storage::DBI>, a concrete driver storage, or a
L<DBIO::Storage::Async> transport), into a single synthesised class. There is
no hand-written NxM matrix of extension-times-transport classes; the cell is
built on demand here.

Composition is C3-MRO class synthesis -- the same mechanism family as
C<load_components> -- plus an explicit method-collision check. The synthesised
class has no methods of its own: it is an empty package whose C<@ISA> is
C<(@layers, $base)> under the C<c3> MRO, so method resolution walks the layers
in registration order and falls through to the base. Layer hooks chain into the
base (and into each other) with C<< $self->next::method(@_) >>.

=head2 Precedence

Registration order is C3 precedence: the B<first>-registered layer is the
most-specific rung of the synthesised C<@ISA>, so its methods win the MRO and
its C<next::method> reaches the next layer, then the base. This is consistent
with C<load_components>: the component loaded first runs first.

=head2 Collision check

Silent shadowing between sibling layers is forbidden. If two or more layers
each define their B<own> copy of the same method name, L</compose> croaks at
compose time naming the method and every defining package. A single layer
overriding a base method is fine (that is ordinary C<next::method> layering);
two layers overriding the same base method still croak -- the resolution
between them would be an accident of registration order, never a decision.

=head2 Layer rules

A layer package:

=over 4

=item * MUST NOT C<use base> a driver storage (it is mixed in above the base,
not beside it);

=item * is a plain method package -- no constructor, no C<@ISA> pointing at a
storage;

=item * chains its hooks with C<< $self->next::method(@_) >>;

=item * may only call the documented public storage surface.

=back

=head1 METHODS

=head2 compose

  my $class = DBIO::Storage::Composed->compose($base, \@layers);

Synthesise (or return the cached) storage class with C<@ISA = (@layers, $base)>
under the C<c3> MRO. The package name is deterministic --
C<< DBIO::Storage::Composed::<layers>__<base> >> with C<::> flattened to C<_> --
so the same C<(base, layers)> tuple always maps to the same class and is built
at most once. With no layers the C<$base> is returned unchanged (nothing to
compose). Croaks (naming the method and the defining packages) if two or more
layers define the same own method. Loads the base and every layer via
L<Class::C3::Componentised/ensure_class_loaded>; an unloadable one fails loud.

=head2 composition_of

  my $entry = DBIO::Storage::Composed->composition_of($pkg);

Return the C<< { base => $base, layers => \@layers } >> registry entry for a
synthesised class, or C<undef> when C<$pkg> was not produced by L</compose>.
This is how the rebless path (L<DBIO::Storage::DBI/_determine_driver>)
recognises a composed instance and recovers what it was composed from.

=head2 layers_of

  my @layers = DBIO::Storage::Composed->layers_of($pkg);

The layer list a synthesised class was composed with, in registration order, or
an empty list when C<$pkg> is not a composed class.

=head2 recompose

  my $new_class = DBIO::Storage::Composed->recompose($pkg, $new_base);

Re-run L</compose> keeping C<$pkg>'s layer list but swapping in a different
base. Used when a composed generic storage is reblessed onto its concrete
driver class (L<DBIO::Storage::DBI/_determine_driver>): the same layers must be
re-composed over the driver, not dropped. Croaks if C<$pkg> is not a composed
class.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

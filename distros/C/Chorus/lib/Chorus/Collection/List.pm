package Chorus::Collection::List;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

  @ISA         = qw(Exporter);
  @EXPORT      = qw();
  @EXPORT_OK   = qw($LIST);

  # %EXPORT_TAGS = ( );		# eg: TAG => [ qw!name1 name2! ];
}

use Chorus::Frame;
use strict;

use constant DEFAULT_CONTAINER_NAME => '_CONTAINER';

our $LIST = Chorus::Frame->new(

    container_name => sub {
      $SELF->_CONTAINER_NAME || DEFAULT_CONTAINER_NAME
    },

    set_container_name => sub {
      $SELF->set('_CONTAINER_NAME', shift);
    },

    #    build :
    #      - Fills List _ITEMS with array @_
    #      - set container to $SELF for each elements of array @_,
    #
    build => sub {
      my $ref = $SELF;
      my $contname = $SELF->container_name;
      $_->set($contname, $ref) for (@_);
      $SELF->set('_ITEMS', [@_]);
      return $SELF;
    },


    #  merge_left :
    #    injecte a gauche des elements de $SELF les elements
    #    des listes (references a des Chorus::Collection::List) passees en argument
    #    les listes initiales sont videes (elements deplaces)
    #
    merge_left => sub {

      my $ref = $SELF;
      my $lst = $SELF->_ITEMS;
      my $contname = $SELF->container_name;

      foreach my $l (@_ ) { # @_ = array of List references !!
        $_->set($contname, $ref) for (@{$l->_ITEMS}); # change container before merging
      }

      unshift @{$lst}, map { @{$_->_ITEMS}; } @_;
      $_->set('_ITEMS', []) for (@_); # reset/clear items from initial Lists
      return $SELF;
    },

    #  merge_right :
    #    injecte a droite des elements de $SELF les elements
    #    des listes (references a des Chorus::Collection::List) passées en argument
    #    les listes initiales sont videes (elements deplaces)
    #
    merge_right => sub {

      my $ref = $SELF;
      my $lst = $SELF->_ITEMS;
        my $contname = $SELF->container_name;

      foreach my $l (@_ ) { # @_ can be multiple
        $_->set($contname, $ref) for (@{$l->_ITEMS});
      }

      push @{$lst}, map { @{$_->_ITEMS}; } @_;
      $_->set('_ITEMS', []) for (@_);
      return $SELF;
    },

    #  connect_left : Double chainage (prev & succ) a gauche de $SELF
    #
    connect_left  => sub {
      my $to   = shift;
      return unless $to;
      my $self = $SELF;        # capture before $to->set() overwrites $SELF
      $self->set('prev', $to);
      $to->set('succ', $self);
    },

    #  connect_right : Double chainage (prev & succ) a droite de $SELF
    #
    connect_right  => sub {
      my $to   = shift;
      my $self = $SELF;        # capture before $to->set() overwrites $SELF
      $self->set('succ', $to);
      $to->set('prev', $self);
    },

    #  unshift_items : ajout d'éléments à gauche de $SELF
    #
    unshift_items => sub {# set_lemma :
  #
  # * Controle qu'il n'existe plus d'ambiguité sur le lemme (même si la catégorie est résolue )
  # * si OK, pose le flag '_CHECK_LEMMA' (cf agent Lemma.pm)
  # * attribue le slot _LEMMA qui renseigne :
  #     - _VALUE : la valeur de 'lemma' dans la forme retenue
  #     - _ITEM  : la structure complète de la forme retenue
  #
      my $ref = $SELF;
      my $contname = $SELF->container_name;
      $_->set($contname, $ref) for @_;
      my $l = $SELF->_ITEMS;
      unshift @{$l}, @_;
      $SELF->set('_ITEMS', $l);
      return $SELF;
    },

    #  push_items : ajout d'éléments à droite de $SELF
    #
    push_items => sub {
      my $ref = $SELF;
      my $contname = $SELF->container_name;
      $_->set($contname, $ref) for @_;
      my $l = $SELF->_ITEMS;
      push @{$l}, @_;
      $SELF->set('_ITEMS', $l);
      return $SELF;
    },

    # -- Searching items

    first_item => sub {
      return $SELF->_ITEMS->[0];
    },

    last_item  => sub {
      return unless $SELF->_ITEMS->[0];
      $SELF->_ITEMS->[scalar(@{$SELF->_ITEMS}) - 1];
    },

    length => sub { scalar @{$SELF->_ITEMS} },

    # TODO : useful methods
    #
    # find => sub { my ($call) = @_; grep &{$call}, @{$SELF->_ITEMS}; },
    # grep => sub { my ($call) = @_; grep &{$call}, @{$SELF->_ITEMS}; },
    # map  => sub { my ($call) = @_; map  $call @{$SELF->_ITEMS}; },

    # HAS         => sub { my ($slot) = @_; return   grep { $_->is($slot) } @{$SELF->_ITEMS}; },                   # ALLOW _LEMMA UNSOLVED
    # HAS_NO      => sub { my ($slot) = @_; return ! grep { $_->is($slot) } @{$SELF->_ITEMS}; },                   # ALLOW _LEMMA UNSOLVED
    #
    HAS  => sub {
      my ($slot) = @_;
      for (@{$SELF->_ITEMS}) {
         return $_ if $_->$slot;
      }
      return;
    },
    HAS_NO => sub { ! $SELF->HAS(@_) },

    # STARTS_WITH => sub { my ($slot) = @_; my $w = $SELF->_ITEMS; return $w->[0]->is($slot); },                   # ALLOW _LEMMA UNSOLVED
    # ENDS_WITH   => sub { my ($slot) = @_; my $w = $SELF->_ITEMS; return $w->[scalar(@{$w}) - 1]->is($slot); },   # ALLOW _LEMMA UNSOLVED
    #
    STARTS_WITH => sub { my ($slot) = @_; my $w = $SELF->_ITEMS; return $w->[0]->$slot; },
    ENDS_WITH   => sub { my ($slot) = @_; my $w = $SELF->_ITEMS; return $w->[scalar(@{$w}) - 1]->$slot; },

    _ITEMS => {
      _NEEDED => sub { $SELF->set('_ITEMS',[])}
    },

);

END {}

1;

__END__

=encoding UTF-8

=head1 NAME

Chorus::Collection::List - Ordered, doubly-linked list of Chorus::Frame objects

=head1 VERSION

This module is part of Chorus::Engine 1.05.

=head1 SYNOPSIS

  use Chorus::Frame;
  use Chorus::Collection::List qw($LIST);

  # Create a list from existing Frames
  my $seq = Chorus::Frame->new(_ISA => $LIST);
  $seq->build($f1, $f2, $f3);

  # Traverse
  printf "length : %d\n", $seq->length;       # 3
  my $first = $seq->first_item;               # $f1
  my $last  = $seq->last_item;                # $f3

  # Append / prepend
  $seq->push_items($f4);                      # → f1 f2 f3 f4
  $seq->unshift_items($f0);                   # → f0 f1 f2 f3 f4

  # Doubly-linked navigation (prev / succ slots)
  $f2->connect_left($f1);                     # $f2->prev = $f1, $f1->succ = $f2
  $f2->connect_right($f3);                    # $f2->succ = $f3, $f3->prev = $f2

  # Predicates
  if ($seq->HAS('categorie')) { ... }         # first item with truthy slot
  $seq->STARTS_WITH('head') or die;
  $seq->ENDS_WITH('tail')   or die;

  # Merge two lists into one (source lists are emptied)
  $seq->merge_right($other);

  # Custom container name (default: _CONTAINER)
  $seq->set_container_name('_PHRASE');

=head1 DESCRIPTION

C<Chorus::Collection::List> provides C<$LIST>, a L<Chorus::Frame> prototype for
building ordered, doubly-linked sequences of Frames.

Any Frame that inherits from C<$LIST> (via C<_ISA =E<gt> $LIST>) becomes a list
object.  Each item added to the list automatically receives a back-reference slot
(C<_CONTAINER> by default, or the name set with L<"set_container_name">) pointing
to the list it belongs to.

Items can also be doubly linked to their neighbours with explicit C<prev> and
C<succ> slots using L<"connect_left"> and L<"connect_right">.

=head1 EXPORTS

Nothing is exported by default.  The following symbol is available on request:

  use Chorus::Collection::List qw($LIST);

=over 4

=item C<$LIST>

The Frame prototype.  Use C<_ISA =E<gt> $LIST> to create list instances.

=back

=head1 METHODS

All methods are slots defined on the C<$LIST> prototype and are therefore
called as methods on any Frame that inherits from C<$LIST>.

=head2 build

  $seq->build( @frames )

Initialises the list with the given Frames.  Sets C<_ITEMS> to C<\@frames> and
writes the container back-reference slot (see L<"set_container_name">) on every
item.  Returns C<$self>.

  $seq->build($f1, $f2, $f3);

=head2 push_items

  $seq->push_items( @frames )

Appends one or more Frames to the right end of the list.  Sets the container
back-reference on each new item.  Returns C<$self>.

  $seq->push_items($f4, $f5);

=head2 unshift_items

  $seq->unshift_items( @frames )

Prepends one or more Frames to the left end of the list.  Sets the container
back-reference on each new item.  Returns C<$self>.

  $seq->unshift_items($f0);

=head2 first_item

Returns the first item (leftmost) in the list, or C<undef> if the list is empty.

=head2 last_item

Returns the last item (rightmost) in the list, or C<undef> if the list is empty.

=head2 length

Returns the number of items currently in the list.

=head2 connect_left

  $self->connect_left( $other_frame )

Establishes a doubly-linked bond to the B<left> of C<$self>:

  $self->prev  = $other_frame
  $other_frame->succ = $self

Does nothing if C<$other_frame> is undefined.

  $f2->connect_left($f1);    # f1 <-> f2

=head2 connect_right

  $self->connect_right( $other_frame )

Establishes a doubly-linked bond to the B<right> of C<$self>:

  $self->succ  = $other_frame
  $other_frame->prev = $self

  $f2->connect_right($f3);   # f2 <-> f3

=head2 merge_left

  $self->merge_left( @lists )

Moves all items from the given lists to the B<left> end of the current list.
The source lists are emptied (their C<_ITEMS> are reset to C<[]>).  The
container back-reference on each moved item is updated to point to C<$self>.
Returns C<$self>.

  $target->merge_left($list_a, $list_b);

=head2 merge_right

  $self->merge_right( @lists )

Moves all items from the given lists to the B<right> end of the current list.
The source lists are emptied.  Returns C<$self>.

  $target->merge_right($list_c);

=head2 HAS

  $self->HAS( $slot_name )

Returns the first item for which the named slot has a truthy value, or C<undef>
if no such item exists.

  my $match = $seq->HAS('is_noun');

=head2 HAS_NO

  $self->HAS_NO( $slot_name )

Returns true if B<no> item in the list has a truthy value for the named slot.

  $seq->HAS_NO('error') or die "sequence contains errors";

=head2 STARTS_WITH

  $self->STARTS_WITH( $slot_name )

Returns the value of the named slot on the B<first> item of the list (truthy
means the sequence starts with that property).

  $seq->STARTS_WITH('determiner') or ...;

=head2 ENDS_WITH

  $self->ENDS_WITH( $slot_name )

Returns the value of the named slot on the B<last> item of the list.

  $seq->ENDS_WITH('punctuation') or ...;

=head2 container_name

Returns the name of the back-reference slot written on each item when it is
added to the list.  Defaults to C<_CONTAINER>.

=head2 set_container_name

  $self->set_container_name( $name )

Changes the container back-reference slot name for this list.  Must be called
before L<"build"> (or any C<push_items> / C<unshift_items> calls) to take effect
on subsequent additions.

  $seq->set_container_name('_PHRASE');
  # each item added afterwards will have: $item->_PHRASE == $seq

=head1 INTERNAL SLOTS

=over 4

=item C<_ITEMS>

Arrayref holding the list items.  Auto-initialised to C<[]> via C<_NEEDED> if
accessed before L<"build"> is called.  B<Do not write to this slot directly> —
use the provided methods.

=item C<_CONTAINER_NAME>

Stores the custom container name set by L<"set_container_name">.

=back

=head1 SEE ALSO

L<Chorus::Frame>, L<Chorus::Collection::Filter>, L<Chorus::Engine>

=head1 AUTHOR

Christophe Ivorra

=head1 BUGS

Please report bugs via L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Chorus>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013-2026 Christophe Ivorra.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published by
the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


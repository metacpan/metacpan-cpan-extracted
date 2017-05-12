package Algorithm::SkipList;

use 5.006;
use strict;
use warnings::register __PACKAGE__;

our $VERSION = '1.02';
# $VERSION = eval $VERSION;

use AutoLoader qw( AUTOLOAD );
use Carp qw( carp croak );

require Algorithm::SkipList::Node;
require Algorithm::SkipList::Header;

# Future versions should check Config module to determine if it is
# being run on a 64-bit processor, and set MAX_LEVEL to 64.

use constant MIN_LEVEL       =>  2;
use constant MAX_LEVEL       => 32;
use constant DEF_P           => 0.25;
use constant DEF_K           => 0;

use constant BASE_NODE_CLASS => 'Algorithm::SkipList::Node';

# We use Exporter instead of something like Exporter::Lite because
# Carp uses it.

require Exporter;

our @EXPORT    = ( );
our @EXPORT_OK = ( );

sub new {
  no integer;

  my $class = shift;

  my $self = {
    NODECLASS => BASE_NODE_CLASS,       # node class used by list
    LIST      => undef,                 # pointer to the header node
    SIZE      => undef,                 # size of list
    SIZE_THRESHOLD => undef,            # size at which SIZE_LEVEL increased
    LAST_SIZE_TH   => undef,            # previous SIZE_THRESHOLD
    SIZE_LEVEL     => undef,            # maximum level random_level
    MAXLEVEL  => MAX_LEVEL,             # absolute maximum level
    P         => 0,                     # probability for each level
    K         => 0,                     # minimum power of P
    P_LEVELS  => [ ],                   # array used by random_level
    LIST_END  => undef,                 # node with greatest key
    LASTKEY   => undef,                 # last key used by next_key
    LASTINSRT => undef,                 # cached insertion fingers
    DUPLICATES => 0,                    # allow duplicates?
  };

  bless $self, $class;

  $self->_set_p( DEF_P ); # initializes P_LEVELS
  $self->_set_k( DEF_K );

  if (@_) {
    my %args = @_;
    foreach my $arg_name (CORE::keys %args) {
      my $method = "_set_" . $arg_name;
      if ($self->can($method)) {
	$self->$method( $args{ $arg_name } );
      } else {
	croak "Invalid parameter name: ``$arg_name\'\'";
      }
    }
  }

  $self->clear;

  return $self;
}

sub _set_duplicates {
  my ($self, $dup) = @_;
  $self->{DUPLICATES} = $dup || 0;
}

sub _set_node_class {
  my ($self, $node_class) = @_;
  $self->{NODECLASS} = $node_class;
}

sub _node_class {
    my ($self) = @_;
    $self->{NODECLASS};
  }

sub reset {
  my ($self) = @_;
  $self->{LASTKEY}  = undef;
}

sub clear {
  my ($self) = @_;

  $self->{SIZE}     = 0;
  $self->{SIZE_THRESHOLD} = 2;
  $self->{LAST_SIZE_TH}   = 0;
  $self->{SIZE_LEVEL}     = MIN_LEVEL;

  my $hdr = [ (undef) x $self->{SIZE_LEVEL} ];

  CORE::delete $self->{LIST};
  $self->{LIST} = new Algorithm::SkipList::Header( undef, undef, $hdr );

  $self->{LIST_END}  = undef;
  $self->{LASTINSRT} = undef;

  $self->reset;
}

sub _set_max_level {
  my ($self, $level) = @_;
  if ($level > MAX_LEVEL) {
    croak "Cannot set max_level greater than ", MAX_LEVEL;
  } elsif ($level < MIN_LEVEL) {
    croak "Cannot set max_level less than ", MIN_LEVEL;
  } elsif ((defined $self->list) && ($level < $self->list->level)) {
    croak "Current level exceeds specified level";
  }
  $self->{MAXLEVEL} = $level;
}

sub max_level {
  my ($self, $level) = @_;

  if (defined $level) {
    $self->_set_max_level($level);
  } else {
    $self->{MAXLEVEL};
  }
}

# We use the formula from Pugh's "Skip List Cookbook" paper.  We
# generate a reverse-sorted array of values based on p and k.  In
# _new_node_level() we look for the highest value in the array that is
# less than a random number n (0<n<1).

sub _build_distribution {
  no integer;

  my ($self) = @_;

  my $p = $self->p;
  my $k = $self->k;

  $self->{P_LEVELS} = [ (0) x MAX_LEVEL ]; 
  for my $i (0..MAX_LEVEL) {
    $self->{P_LEVELS}->[$i] = $p**($i+$k);
  }
}

sub _set_p {
  no integer;

  my ($self, $p) = @_;

  unless ( ($p>0) && ($p<1) ) {
    croak "Unvalid value for P (must be between 0 and 1)";
  }

  $self->{P} = $p;
  $self->_build_distribution;

}

sub p {
  no integer;

  my ($self, $p) = @_;

  if (defined $p) {
    $self->_set_p($p);
  } else {
    $self->{P};
  }
}

sub _set_k {
  my ($self, $k) = @_;

  unless ( $k>=0 ) {
    croak "Unvalid value for K (must be at least 0)";
  }

  $self->{K} = $k;
  $self->_build_distribution;
}

sub k {
  my ($self, $k) = @_;

  if (defined $k) {
    $self->_set_k($k);
  } else {
    $self->{K};
  }
}

sub size {
  my ($self) = @_;
  $self->{SIZE};
}

sub list {
  my ($self) = @_;
  $self->{LIST};
}


sub _adjust_level_threshold {
  use integer;

  my ($self) = @_;

  if ($self->{SIZE} >= $self->{SIZE_THRESHOLD}) {
    $self->{LAST_SIZE_TH}    = $self->{SIZE_THRESHOLD};
    $self->{SIZE_THRESHOLD} += $self->{SIZE_THRESHOLD};
    $self->{SIZE_LEVEL}++, if ($self->{SIZE_LEVEL} < $self->{MAXLEVEL});
  } elsif ($self->{SIZE} < $self->{LAST_SIZE_TH}) {
    $self->{SIZE_THRESHOLD}  = $self->{LAST_SIZE_TH};
    $self->{LAST_SIZE_TH}    = $self->{LAST_SIZE_TH} / 2;
    $self->{SIZE_LEVEL}--, if ($self->{SIZE_LEVEL} > MIN_LEVEL);
  }
}

sub _new_node_level { # previously _random_level
  no integer;

  my ($self) = @_;

  my $n     = CORE::rand();
  my $level = 1;

  while (($n < $self->{P_LEVELS}->[$level]) &&
	 ($level < $self->{SIZE_LEVEL})) {
    $level++;
  }

  $level;
}

sub _search_with_finger {
  my ($self, $key, $finger) = @_;

  use integer;

  my $list   = $self->list;
  my $level  = $list->level-1;

  my $node   = $finger->[ $level ] || $list;

  # Iteresting Perl syntax quirk:
  #   do { my $x = ... } while ($x)
  # doesn't work because it considers $x out of scope.
  #
  # However, benchmarking shows that it's faster to use
  #   my $x; do { $x = ... } while ($x)
  #

  my $fwd;
  my $cmp = -1;

  # This version of the search algorithm is based on Schneier, 1994.

  do {
    while ( ($fwd = $node->header()->[$level]) &&
	    ($cmp = $fwd->key_cmp($key)) < 0) {
      $node = $fwd;
    }
    $finger->[$level] = $node;
  } while ((--$level>=0)); # && ($cmp));

  $node = $fwd, unless ($cmp);

  # Ideally we could stop when $cmp == 0, but the update vector would
  # not be complete for levels below $level.  insert still works, but
  # delete and truncate have problems and need kluges to make up for
  # that.

  ($node, $finger, $cmp);
}

sub _search {
  my ($self, $key, $finger) = @_;

  use integer;

  my $list   = $self->list;
  my $level  = $list->level-1;

#  $finger ||= [ ];

  my $node   = $finger->[ $level ]  || $list;

  # This version of the search algorithm is based on Schneier, 1994.

  my $fwd;
  my $cmp = -1;

  do {
    while ( ($fwd = $node->header()->[$level]) &&
	    ($cmp = $fwd->key_cmp($key)) < 0) {
      $node = $fwd;
    }
  } while ((--$level>=0) && ($cmp));

  $node = $fwd; # , unless ($cmp); # Devel::Cover says it's never false

  ($node, $finger, $cmp);
}

sub insert {
  my ($self, $key, $value, $finger) = @_;

  use integer;

  my $list   = $self->list;

  # We save the node and finger of the last insertion. If the next key
  # is larger, then we can use the "finger" to speed up insertions.

  my ($node, $cmp);

  unless ($finger) {
    $node   = $self->{LASTINSRT}->[0] and do {
      $finger = $self->{LASTINSRT}->[1],
	if ($node->key_cmp($key) <= 0);
      };
  }

  ($node, $finger, $cmp) = $self->_search_with_finger($key, $finger);

  if ($cmp || $self->{DUPLICATES}) {

    my $new_level = $self->_new_node_level;

    my $node_hdr = [ ];
    my $fing_hdr;

    $node = $self->_node_class->new( $key, $value, $node_hdr );

    for (my $i=0;$i<$new_level;$i++) {
      $fing_hdr = ($finger->[$i]||$list)->header();
      $node_hdr->[$i] = $fing_hdr->[$i];
      $fing_hdr->[$i] = $node;
    }


    # We no longer set the LIST_END value, since it is the job of the
    # _greatest_node method to find it, as needed.

    $self->{SIZE}++;
    $self->_adjust_level_threshold;
  } else {
    $node->value($value);
  }
  $self->{LASTINSRT}->[0] = $node;
  $self->{LASTINSRT}->[1] = $finger;
}

sub delete {

  my ($self, $key, $finger) = @_;

  use integer;

  my $list = $self->list;

  my ($node, $update_ref, $cmp) = $self->_search_with_finger($key, $finger);

  if ($cmp == 0) {
    my $value = $node->value;

    # Note: it might make better sense to set $self->{LIST_END} = undef, and
    # let the _greatest_node method search for it if it's needed again.

    if (($self->{LIST_END}) && ($node == $self->{LIST_END})) {
      $self->{LIST_END}  = $update_ref->[0];
    }

    my $level = $node->level; 

    for (my $i=0; $i<$level; $i++) {
      $update_ref->[$i]->header()->[$i] = $node->header()->[$i];
    }

    # There's probably a smarter way to handle the last insert and
    # last key values, but this is the fastest, easiest, safest and
    # most consistent way.

    $self->{LASTINSRT} = undef;
    $self->reset;

    $self->{SIZE} --;
    $self->_adjust_level_threshold;

    # We shouldn't need to "undef $node" here. The Garbage Collector
    # should hanldle that (especially if there's a finger that points
    # to it somewhere).

    # Note: It doesn't seem to be a wise idea to return a search
    # finger for deletions without further analysis

    $value;

  } else {
    carp "key not found", if (warnings::enabled);
    return;
  }
}

sub exists {

  my ($self, $key, $finger) = @_;

  (($self->_search($key, $finger))[2] == 0);
}

sub find_with_finger {
  my ($self, $key, $finger) = @_;

  my ($x, $update_ref, $cmp) = $self->_search_with_finger($key, $finger);

  ($cmp == 0) ? (
    (wantarray) ? ($x->value, $update_ref) : $x->value
  ) : undef;

}

sub find {
  my ($self, $key, $finger) = @_;

  my ($node, $update_ref, $cmp) = $self->_search($key, $finger);

  ($cmp == 0) ? $node->value : undef;
}


sub _first_node { # actually this is the second node
  my $self = shift;

  my $list = $self->list;
  my $node = $list->header()->[0];
}


sub last_key {
  my ($self, $node, $index) = @_;

  if (@_ > 1) {
    $self->{LASTKEY} = [ $node, $index ];
    my $check = $index || 0;
    if (($check < 0) || ($check >= $self->size)) {
      carp "index out of bounds", if (warnings::enabled);
    }
  }
  else {
    unless ($self->{LASTKEY}) {
      $self->{LASTKEY} = [ $self->_first_node, 0 ];
    }
    ($node, $index) = @{ $self->{LASTKEY} };
  }

  if ($node) {
    return (wantarray) ?
      ( $node->key, [ $node ], $node->value, $index ) : $node->key;
  } else {
    return;
  }
}

sub first_key {
  my $self = shift;

  my $node = $self->_first_node;

  if ($node) {
    return $self->last_key( $node, 0);
  }
  else {
    carp "no _first_node", if (warnings::enabled);
    return;
  }
}

sub next_key {
  my ($self, $last_key, $finger) = @_;

  my ($node, $cmp, $value, $index);

  if (defined $last_key) {
    ($node, $finger, $cmp) = $self->_search_with_finger($last_key, $finger);

    if ($cmp) {
      carp "cannot find last_key", if (warnings::enabled);
      return;
    }
  }
  else {
    ($node, $index) = @{ $self->{LASTKEY} || [ ] };
    unless ($node) {
      return $self->first_key;
    }
  }

  if ($node) {
    $node = $node->header()->[0];
    return $self->last_key(
      $node,
      (($node && (defined $index)) ? ($index+1) : undef )
    );
  }
  else {
    return $self->reset;
  }
}


BEGIN
  {
    # make aliases to methods...
    no strict;
    *TIEHASH = \&new;
    *STORE   = \&insert;
    *FETCH   = \&find;
    *EXISTS  = \&exists;
    *CLEAR   = \&clear;
    *DELETE  = \&delete;
    *FIRSTKEY = \&first_key;
    *NEXTKEY = \&next_key;

    *search  = \&find;
  }

1;

__END__

sub find_duplicates {
  my ($self, $key, $finger) = @_;

  my ($node, $update_ref, $cmp) = $self->_search_with_finger($key, $finger);

  if ($cmp == 0) {
    my @values = ( $node->value );

    while ( ($node->header()->[0]) &&
	    ($node->header()->[0]->key_cmp($key) == 0) ) {
      $node = $node->header()->[0];
      push @values, $node->value;
    }

    return @values;
  }
  else {
    return;
  }
}

sub level {
  my $self = shift;
  return $self->list->level;
}

sub _greatest_node {
  my ($self) = @_;

  my $list = $self->{LIST_END} || $self->list;

  my $level = $list->level-1;
  do {
    while ($list->header()->[$level]) {
      $list = $list->header()->[$level];
    }
  } while (--$level >=0);

  $self->{LIST_END} = $list;
}

sub least {
  my $self = shift;

  my ($node) = $self->_first_node;

  if ($node) {
    return ($node->key, $node->value);
  } else {
    carp "no _first_node", if (warnings::enabled);
    return;
  }
}

sub greatest {
  my $self = shift;

  my $node = $self->_greatest_node;
  if ($node) {
    return ($node->key, $node->value);
  } else {
    carp "no _greatest_node", if (warnings::enabled);
    return;
  }
}

sub next {
  my $self = shift;

  my ($key, $finger, $value) = $self->next_key;

  if (defined $key) {
    return ($key, $value)
  } else {
    return;
  }
}

sub prev_key {
  my $self = shift;
  croak "unimplemented method";
}

sub prev {
  my ($self) = @_;
  croak "unimplemented method";
}

sub _search_nodes {
  my ($self, $low, $finger_low, $high ) = @_;
  my @nodes = ();

  $low  = $self->_first_node()->key(),  unless (defined $low);
  $high = $self->_greatest_node->key(), unless (defined $high);

  if ($self->_node_class->new($low)->key_cmp($high) > 0) {
    carp "low > high";
    return;
  }

  my ($node, $finger, $cmp) = $self->_search($low, $finger_low);
  if ($cmp) {
    return;
  } else {
    while ((defined $node) && ($node->key_cmp($high) <= 0)) {
      push @nodes, $node;
      $node = $node->header()->[0];
    }
  }
  return @nodes;
}

sub keys {
  my ($self, $low, $finger_low, $high) = @_;

  my @keys = map { $_->key }
    $self->_search_nodes($low, $finger_low, $high);
  return @keys;
}

sub values {
  my ($self, $low, $finger_low, $high) = @_;

  my @values = map { $_->value }
    $self->_search_nodes($low, $finger_low, $high);
  return @values;
}

sub truncate {
  my $self = shift;

  my ($key, $finger) = @_;

  if (defined $key) {
    my ($node, $finger, $cmp) = $self->_search_with_finger( $key, $finger );
    if ($cmp == 0) {

      # This is the most braindead way to find the index of a node. We
      # could come up with more sophisticated way by saving the number
      # of "skips" in the forward pointers when we add nodes, but that
      # will significantly affect the speed.

      my $size = 1 + $self->index_by_key( $key );
#       {
# 	my $aux  = $self->list;
# 	while ($aux != $node) {
# 	  $size++;
# 	  $aux = $aux->header()->[0];
# 	}
#       }

      my $list = __PACKAGE__->new(
        max_level  => $self->max_level,
        p          => $self->p,
        node_class => $self->_node_class,
      );

      my $level   = $self->list->level;
      my $old_hdr = $self->list->header;
      my $new_hdr = $list->list->header;

      for (my $i=0; $i<$level; $i++) {

	if ($finger->[$i]) {
	  if ($finger->[$i] == $node) {
	    $new_hdr->[$i] = $finger->[$i];
	    $finger->[$i]  = undef;
	  }
	  else {
	    $new_hdr->[$i] = $finger->[$i]->header()->[$i];
	    $finger->[$i]->header()->[$i]  = undef;
	  }
	}
	elsif ($old_hdr->[$i]) {

	  if ($old_hdr->[$i] == $node) {
	    $new_hdr->[$i] = $old_hdr->[$i];
	    $old_hdr->[$i]  = undef;
	  }
	  else {
	    carp "unexpected situation",
	      if (warnings::enabled);
	    # If _search_with_finger does not stop on !$cmp but
	    # continues to remaining levels, then we should not
	    # need to worry about this.
	  }
	}


      }

      $list->{SIZE} = $self->size - $size;
      $self->{SIZE} = $size;

      $list->{LIST_END} = undef;
      $self->{LIST_END} = undef;

      $self->_adjust_level_threshold;
      $list->_adjust_level_threshold;

      return $list;
    }
    else {
    carp "key not found", if (warnings::enabled);
      return;
    }
  }
  else {
    croak "no key specified";
    return;
  }

}


sub copy {
  my $self = shift;

  my ($key, $finger_or, $key_to) = @_;

  my $list = __PACKAGE__->new(
    max_level  => $self->max_level,
    p          => $self->p,
    node_class => $self->_node_class,
  );
  $list->{DUPLICATES} = $self->{DUPLICATES};

  my @nodes = $self->_search_nodes($key, $finger_or, $key_to);
  return, unless (@nodes);

  my $finger_cp;
  foreach my $node (@nodes) {
    $finger_cp = $list->insert($node->key, $node->value, $finger_cp);
  }

  return $list;
}

sub merge {

  my $list1 = shift;

  my $list2 = shift;

  my ($finger1, $finger2);
  my ($node1) = $list1->_first_node;
  my ($node2) = $list2->_first_node;

  while ($node1 || $node2) {

    my $cmp = ($node1) ? (
      ($node2) ? $node1->key_cmp( $node2->key ) : 1 ) : -1;
    
    if ($cmp < 0) {                     # key1 < key2
      if ($node1) {
	$finger1 = $list1->insert( $node1->key, $node1->value, );
	$node1 = $node1->header()->[0];
      } else {
	$finger1 = $list1->insert( $node2->key, $node2->value, );
	$node2 = $node2->header()->[0];
      }
    } elsif ($cmp > 0) {                # key1 > key2
      if ($node2) {
	$finger1 = $list1->insert( $node2->key, $node2->value, );
	$node2 = $node2->header()->[0];
      } else {
	$finger1 = $list1->insert( $node1->key, $node1->value, );
	$node1 = $node1->header()->[0];
      }
    } else {                            # key1 = key2
      $node1 = $node1->header()->[0],
	if $node1;
      $node2 = $node2->header()->[0],
	if $node2;
    }
  }
}

sub append {
  my $list1 = shift;

  my $list2 = shift;

  unless (defined $list2) { return; }

  my $node = $list1->_greatest_node;
  if ($node) {

    my ($next) = $list2->_first_node;

    if ($list1->list->level > $list2->list->level) {

      if ($list1->list->level < $list1->max_level) {

	my $i = $list1->list->level;
	while (!defined $list1->list->header()->[$i]) { $i--; }
	$list1->list->header()->[$i+1] = $next;
      } else {
	my $i = $list1->list->level-1;
	my $x = $list1->list->header()->[$i];
	while (defined $x->header()->[$i]) {
	  $x = $x->header()->[$i];
	}
	$x->header()->[$i] = $next;
      }
      $node->header()->[0] = $next;

    } else {
      for (my $i=0; $i<$node->level; $i++) {
	$node->header()->[$i] = $next;
      }
      for (my $i=$list1->list->level; $i<$list2->list->level; $i++) {
	$list1->list->header()->[$i] = $next;
      }
    }

    $list1->{SIZE}    += $list2->size;
    $list1->{LIST_END} = $list2->{LIST_END};
  } else {
    $list1->{LIST}     = $list2->list;
    $list1->{SIZE}     = $list2->size;
    $list1->{LIST_END} = $list2->{LIST_END};
  }
  $list1->_adjust_level_threshold;
}

sub _node_by_index {
  my ($self, $index) = @_;

  # Bug: for some reason, change $[ does not affect this module.

#   if ($index >= $[) {
#     $index -= $[;
#   }

  if ($index < 0) {
    $index += $self->size;
  }

  if (($index < 0) || ($index >= $self->size)) {
    carp "index out of range", if (warnings::enabled);
    return;
  }


  my ($node, $last_index) = @{ $self->{LASTKEY} || [ ] };

  if ((defined $last_index)  && ($last_index <= $index)) {
    ($last_index, $index) = ($index, $index - $last_index);
  }
  else {
    $last_index = $index;
    $node = undef;
  }

  $node ||= $self->_first_node;

  unless ($node) {
    return;
  }

  while ($node && $index--) {
    $node = $node->header()->[0];
  }

  $self->last_key( $node, $last_index );
  return $node;
}

sub key_by_index {
  my ($self, $index) = @_;

  my $node = $self->_node_by_index($index);
  if ($node) {
    return $node->key;
  } else {
    return;
  }
}

sub value_by_index {
  my ($self, $index) = @_;

  my $node = $self->_node_by_index($index);
  if ($node) {
    return $node->value;
  } else {
    return;
  }
}

sub index_by_key {
  my ($self, $key) = @_;

  my $node  = $self->_first_node;
  my $index = 0;
  while ($node && ($node->key_cmp($key) < 0)) {
    $node = $node->header()->[0];
    $index++;
  }

  if ($node->key_cmp($key) == 0) {
    $self->last_key( $node, $index );
    return $index;
  } else {
    return;
  }
}


sub _debug {

  my $self = shift;

  my $list   = $self->list;

  while ($list) {
    print STDERR
      $list->key||'undef', "=", $list->value||'undef'," ", $list,"\n";

    for(my $i=0; $i<$list->level; $i++) {
      print STDERR " ", $i," ", $list->header()->[$i]
	|| 'undef', "\n";
    }
#     print STDERR " P ", $list->prev() || 'undef', "\n";
    print STDERR "\n";

    $list = $list->header()->[0];
  }

}

=head1 NAME

Algorithm::SkipList - Perl implementation of skip lists

=head1 REQUIREMENTS

The following non-standard modules are used:

  enum

=head1 SYNOPSIS

  my $list = new Algorithm::SkipList();

  $list->insert( 'key1', 'value' );
  $list->insert( 'key2', 'another value' );

  $value = $list->find('key2');

  $list->delete('key1');

=head1 DESCRIPTION

This is an implementation of I<skip lists> in Perl.

Skip lists are similar to linked lists, except that they have random
links at various I<levels> that allow searches to skip over sections
of the list, like so:

  4 +---------------------------> +----------------------> +
    |                             |                        |
  3 +------------> +------------> +-------> +-------> +--> +
    |              |              |         |         |    |
  2 +-------> +--> +-------> +--> +--> +--> +-------> +--> +
    |         |    |         |    |    |    |         |    |
  1 +--> +--> +--> +--> +--> +--> +--> +--> +--> +--> +--> +
         A    B    C    D    E    F    G    H    I    J   NIL

A search would start at the top level: if the link to the right
exceeds the target key, then it descends a level.

Skip lists generally perform as well as balanced trees for searching
but do not have the overhead with respect to inserting new items.  See
the included file C<Benchmark.txt> for a comparison of performance
with other Perl modules.

For more information on skip lists, see the L</"SEE ALSO"> section below.

Only alphanumeric keys are supported "out of the box".  To use numeric
or other types of keys, see L</"Customizing the Node Class"> below.

=head2 Methods

A detailed description of the methods used is below.

=over

=item new

  $list = new Algorithm::SkipList();

Creates a new skip list.

If you need to use a different L<node class|/"Node Methods"> for using
customized L<comparison|/"key_cmp"> routines, you will need to specify a
different class:

  $list = new Algorithm::SkipList( node_class => 'MyNodeClass' );

See the L</"Customizing the Node Class"> section below.

Specialized internal parameters may be configured:

  $list = new Algorithm::SkipList( max_level => 32 );

Defines a different maximum list level.

The initial list (see the L</"list"> method) will be a
L<random|/"_new_node_level"> number of levels, and will increase over
time if inserted nodes have higher levels, up until L</max_level>
levels.  See L</max_level> for more information on this parameter.

You can also control the probability used to determine level sizes for
each node by setting the L<P|/"p"> and k values:

  $list = new Algorithm::SkipList( p => 0.25, k => 1 );

See  L<P|/p> for more information on this parameter.

You can enable duplicate keys by using the following:

  $list = new Algorithm::SkipList( duplicates => 1 );

This is an experimental feature. See the L</KNOWN ISSUES> section
below.

=item insert

  $list->insert( $key, $value );

Inserts a new node into the list.

You may also use a L<search finger|/"About Search Fingers"> with insert,
provided that the finger is for a key that occurs earlier in the list:

  $list->insert( $key, $value, $finger );

Using fingers for inserts is I<not> recommended since there is a risk
of producing corrupted lists.

=item exists

  if ($list->exists( $key )) { ... }

Returns true if there exists a node associated with the key, false
otherwise.

This may also be used with  L<search fingers|/"About Search Fingers">:

  if ($list->exists( $key, $finger )) { ... }

=item find_with_finger

  $value = $list->find_with_finger( $key );

Searches for the node associated with the key, and returns the value. If
the key cannot be found, returns C<undef>.

L<Search fingers|/"About Search Fingers"> may also be used:

  $value = $list->find_with_finger( $key, $finger );

To obtain the search finger for a key, call L</find_with_finger> in a
list context:

  ($value, $finger) = $list->find_with_finger( $key );

=item find

  $value = $list->find( $key );

  $value = $list->find( $key, $finger );

Searches for the node associated with the key, and returns the value. If
the key cannot be found, returns C<undef>.

This method is slightly faster than L</find_with_finger> since it does
not return a search finger when called in list context.

If you are searching for duplicate keys, you must use
L</find_with_finger> or L</find_duplicates>.

=item find_duplicates

  @values = $list->find_duplicates( $key );

  @values = $list->find_duplicates( $key, $finger );

Returns an array of values from the list.

This is an autoloading method.

=item search

Search is an alias to L</find>.

=item first_key

  $key = $list->first_key;

Returns the first key in the list.

If called in a list context, will return a
L<search finger|/"About Search Fingers">:

  ($key, $finger) = $list->first_key;

A call to L</first_key> implicitly calls L</reset>.

=item next_key

  $key = $list->next_key( $last_key );

Returns the key following the previous key.  List nodes are always
maintained in sorted order.

Search fingers may also be used to improve performance:

  $key = $list->next_key( $last_key, $finger );

If called in a list context, will return a
L<search finger|/"About Search Fingers">:

  ($key, $finger) = $list->next_key( $last_key, $finger );

If no arguments are called,

  $key = $list->next_key;

then the value of L</last_key> is assumed:

  $key = $list->next_key( $list->last_key );

Note: calls to L</delete> will L</reset> the last key.

=item next

  ($key, $value) = $list->next( $last_key, $finger );

Returns the next key-value pair.

C<$last_key> and C<$finger> are optional.

This is an autoloading method.

=item last_key

  $key = $list->last_key;

  ($key, $finger, $value) = $list->last_key;

Returns the last key or the last key and finger returned by a call to
L</first_key>, L</next_key>, L</index_by_key>, L</key_by_index> or
L</value_by_index>.  This is not the greatest key.

Deletions and inserts may invalidate the L</last_key> value.
(Deletions will actually L</reset> the value.)

Values for L</last_key> can also be set by including parameters,
however this feature is meant for I<internal use only>:

  $list->last_key( $node );

Note that this is a change form versions prior to 0.71.

=item reset

  $list->reset;

Resets the L</last_key> to C<undef>. 

=item index_by_key

  $index = $list->index_by_key( $key );

Returns the 0-based index of the key (as if the list were an array).
I<This is not an efficient method of access.>

This is an autoloading method.

=item key_by_index

  $key = $list->key_by_index( $index );

Returns the key associated with an index (as if the list were an
array).  Negative indices return the key from the end.  I<This is not
an efficient method of access.>

This is an autoloading method.

=item value_by_index

  $value = $list->value_by_index( $index );

Returns the value associated with an index (as if the list were an
array).  Negative indices return the value from the end.  I<This is not
an efficient method of access.>

This is an autoloading method.

=item delete

  $value = $list->delete( $key );

Deletes the node associated with the key, and returns the value.  If
the key cannot be found, returns C<undef>.

L<Search fingers|/"About Search Fingers"> may also be used:

  $value = $list->delete( $key, $finger );

Calling L</delete> in a list context I<will not> return a search
finger.

=item clear

  $list->clear;

Erases existing nodes and resets the list.

=item size

  $size = $list->size;

Returns the number of nodes in the list.

=item copy

  $list2 = $list1->copy;

Makes a copy of a list.  The L</"p">, L</"max_level"> and
L<node class|/"_node_class"> are copied, although the exact structure of node
levels is not copied.

  $list2 = $list1->copy( $key_from, $finger, $key_to );

Copy the list between C<$key_from> and C<$key_to> (inclusive).  If
C<$finger> is defined, it will be used as a search finger to find
C<$key_from>.  If C<$key_to> is not specified, then it will be assumed
to be the end of the list.

If C<$key_from> does not exist, C<undef> will be returned.

This is an autoloading method.

=item merge

  $list1->merge( $list2 );

Merges two lists.  If both lists share the same key, then the valie
from C<$list1> will be used.

Both lists should have the same L<node class|/"_node_class">.

This is an autoloading method.

=item append

  $list1->append( $list2 );

Appends (concatenates) C<$list2> after C<$list1>.  The last key of
C<$list1> must be less than the first key of C<$list2>.

Both lists should have the same L<node class|/"_node_class">.

This method affects both lists.  The L</"header"> of the last node of
C<$list1> points to the first node of C<$list2>, so changes to one
list may affect the other list.

If you do not want this entanglement, use the L</merge> or L</copy>
methods instead:

  $list1->merge( $list2 );
  
or

  $list1->append( $list2->copy );

This is an autoloading method.

=item truncate

  $list2 = $list1->truncate( $key );

Truncates C<$list1> and returns C<$list2> starting at C<$key>.
Returns C<undef> is the key does not exist.

It is asusmed that the key is not the first key in C<$list1>.

This is an autoloading method.

=item least

  ($key, $value) = $list->least;

Returns the least key and value in the list, or C<undef> if the list
is empty.

This is an autoloading method.

=item greatest

  ($key, $value) = $list->greatest;

Returns the greatest key and value in the list, or C<undef> if the list
is empty.

This is an autoloading method.

=item keys

  @keys = $list->keys;

Returns a list of keys (in sorted order).

  @keys = $list->keys( $low, $high);

Returns a list of keys between C<$low> and C<$high>, inclusive. (This
is only available in versions 1.02 and later.)

This is an autoloading method.

=item values

  @values = $list->values;

Returns a list of values (corresponding to the keys returned by the
L</keys> method).

This is an autoloading method.

=back

=head2 Internal Methods

Internal methods are documented below. These are intended for
developer use only.  These may change in future versions.

=over

=item _search_with_finger

  ($node, $finger, $cmp) = $list->_search_with_finger( $key );

Searches for the node with a key.  If the key is found, that node is
returned along with a L</"header">.  If the key is not found, the previous
node from where the node would be if it existed is returned.

Note that the value of C<$cmp>

  $cmp = $node->key_cmp( $key )

is returned because it is already determined by L</_search>.

Search fingers may also be specified:

  ($node, $finger, $cmp) = $list->_search_with_finger( $key, $finger );

Note that the L</"header"> is actually a
L<search finger|/"About Search Fingers">.

=item _search

  ($node, $finger, $cmp) = $list->_search( $key, [$finger] );

Same as L</_search_with_finger>, only that a search finger is not returned.
(Actually, an initial "dummy" finger is returned.)

This is useful for searches where a finger is not needed.  The speed
of searching is improved.

=item k

  $k = $list->k;

Returns the I<k> value.

  $list->k( $k );

Sets the I<k> value.

Higher values will on the average have less pointers per node, but
take longer for searches.  See the section on the L<P|/p> value.

=item p

  $plevel = $list->p;

Returns the I<P> value.

  $list->p( $plevel );

Changes the value of I<P>.  Lower values will on the average have less
pointers per node, but will take longer for searches.

The probability that a particular node will have a forward pointer at
level I<i> is: I<p**(i+k-1)>.

For more information, consult the references below in the
L</"SEE ALSO"> section.

=item max_level

  $max = $list->max_level;

Returns the maximum level that L</_new_node_level> can generate.

  eval {
    $list->max_level( $level );
  };

Changes the maximum level.  If level is less than L</MIN_LEVEL>, or
greater than L</MAX_LEVEL> or the current list L</level>, this will fail
(hence the need for setting it in an C<eval> block).

The value defaults to L</MAX_LEVEL>, which is 32.  There is usually no
need to change this value, since the maximum level that a new node
will have will not be greater than it actually needs, up until 2^32
nodes.  (The current version of this module is not designed to handle
lists larger than 2^32 nodes.)

Decreasing the maximum level to less than is needed will likely
degrade performance.

=item _new_node_level

  $level = $list->_new_node_level;

This is an internal function for generating a random level for new nodes.

Levels are determined by the L<P|/"p"> value.  The probability that a
node will have 1 level is I<P>; the probability that a node will have
2 levels is I<P^2>; the probability that a node will have 3 levels is
I<P^3>, et cetera.

The value will never be greater than L</max_level>.

Note: in earlier versions it was called C<_random_level>.

=item list

  $node = $list->list;

Returns the initial node in the list, which is a
C<Algorithm::SkipList::Node> (See L<below|/"Node Methods">.)

The key and value for this node are undefined.

=item _first_node

  $node = $list->_first_node;

Returns the first node with a key (the second node) in a list.  This
is used by the L</first_key>, L</least>, L</append> and L</merge>
methods.

=item _greatest_node

  $node = $list->_greatest_node;

Returns the last node in the list.  This is used by the L</append> and
L</greatest> methods.

=item _node_class

  $node_class_name = $list->_node_class;

Returns the name of the node class used.  By default this is the
C<Algorithm::SkipList::Node>, which is discussed below.

=item _build_distribution

  $list->_build_distribution;

Rebuilds the probability distribution array C<{P_LEVELS}> upon calls
to L</_set_p> and L</_set_k>.

=item _set_node_class

=item _set_max_level

=item _set_p

=item _set_k

These methods are used during initialization of the object.

=item _debug

  $list->_debug;

Used for debugging skip lists by developer.  The output of this
function is subject to change.

=back

=head2 Node Methods

Methods for the L<Algorithm::SkipList::Node> object are documented in
that module.  They are for internal use by the main
C<Algorithm::SkipList> module.

=head1 SPECIAL FEATURES

=head2 Tied Hashes

Hashes can be tied to C<Algorithm::SkipList> objects:

  tie %hash, 'Algorithm::SkipList';
  $hash{'foo'} = 'bar';

  $list = tied %hash;
  print $list->find('foo'); # returns bar

See the L<perltie> manpage for more information.

=head2 Customizing the Node Class

The default node may not handle specialized data types.  To define
your own custom class, you need to derive a child class from
C<Algorithm::SkipList::Node>.

Below is an example of a node which redefines the default type to use
numeric instead of string comparisons:

  package NumericNode;

  our @ISA = qw( Algorithm::SkipList::Node );

  sub key_cmp {
    my $self = shift;

    my $left  = $self->key;  # node key
    my $right = shift;       # value to compare the node key with

    unless ($self->validate_key($right)) {
      die "Invalid key: \'$right\'"; }

    return ($left <=> $right);
  }

  sub validate_key {
    my $self = shift;
    my $key  = shift;
    return ($key =~ s/\-?\d+(\.\d+)?$/); # test if key is numeric
  }

To use this, we say simply

  $number_list = new Algorithm::SkipList( node_class => 'NumericNode' );

This skip list should work normally, except that the keys must be
numbers.

For another example of customized nodes, see L<Tie::RangeHash> version
1.00_b1 or later.

=head2 About Search Fingers

A side effect of the search function is that it returns a I<finger> to
where the key is or should be in the list.

We can use this finger for future searches if the key that we are
searching for occurs I<after> the key that produced the finger. For
example,

  ($value, $finger) = $list->find('Turing');

If we are searching for a key that occurs after 'Turing' in the above
example, then we can use this finger:

  $value = $list->find('VonNeuman', $finger);

If we use this finger to search for a key that occurs before 'Turing'
however, it may fail:

  $value = $list->find('Goedel', $finger); # this may not work

Therefore, use search fingers with caution.

Search fingers are specific to particular instances of a skip list.
The following should not work:

  ($value1, $finger) = $list1->find('bar');
  $value2            = $list2->find('foo', $finger);

One useful feature of fingers is with enumerating all keys using the
L</first_key> and L</next_key> methods:

  ($key, $finger) = $list->first_key;

  while (defined $key) {
    ...
    ($key, $finger) = $list->next_key($key, $finger);
  }

See also the L</keys> method for generating a list of keys.

=head2 Similarities to Tree Classes

This module intentionally has a subset of the interface in the
L<Tree::Base> and other tree-type data structure modules, since skip
lists can be used in place of trees.

Because pointers only point forward, there is no C<prev> method to
point to the previous key.

Some of these methods (least, greatest) are autoloading because they
are not commonly used.

One thing that differentiates this module from other modules is the
flexibility in defining a custom node class.

See the included F<Benchmark.txt> file for performance comparisons.

=head1 KNOWN ISSUES

=over

=item Upgrading from List::SkipList

If you are upgrading a prior version of L<List::SkipList>, then you
may want to uninstall the module before installing
L<Algorithm::SkipList>, so as to remove unused autoloading files.

=item Undefined Values

Certain methods such as L</find> and L</delete> will return the the
value associated with a key, or C<undef> if the key does not exist.
However, if the value is C<undef>, then these functions will appear to
claim that the key cannot be found.

In such circumstances, use the L</exists> method to test for the
existence of a key.

=item Duplicate Keys

Duplicate keys are an experimental feature in this module, since most
methods have been designed for unique keys only.

Access to duplicate keys is akin to a stack.  When a duplicate key is
added, it is always inserted I<before> matching keys.  In searches, to
find duplicate keys one must use L</find_with_finger> or the
L</find_duplicates> method.

The L</copy> method will reverse the order of duplicates.

The behavior of the L</merge> and L</append> methods is not defined
for duplicates.

=item Non-Determinism

Skip lists are non-deterministic.  Because of this, bugs in programs
that use this module may be subtle and difficult to reproduce without
many repeated attempts.  This is especially true if there are bugs in
a L<custom node|/"Customizing the Node Class">.

=back

Additional issues may be listed on the CPAN Request Tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-SkipList> or
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-SkipList>.

=head1 AUTHOR

Robert Rothenberg <rrwo at cpan.org>

=head2 Acknowledgements

Carl Shapiro <cshapiro at panix.com> for introduction to skip lists.

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2003-2005 Robert Rothenberg. All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

See the article by William Pugh, "A Skip List Cookbook" (1989), or
similar ones by the author at L<http://www.cs.umd.edu/~pugh/> which
discuss skip lists.

Another article worth reading is by Bruce Schneier, "Skip Lists:
They're easy to implement and they work",
L<Doctor Dobbs Journal|http://www.ddj.com>, January 1994.

L<Tie::Hash::Sorted> maintains a hash where keys are sorted.  In many
cases this is faster, uses less memory (because of the way Perl5
manages memory), and may be more appropriate for some uses.

If you need a keyed list that preserves the order of insertion rather
than sorting keys, see L<List::Indexed> or L<Tie::IxHash>.

=cut

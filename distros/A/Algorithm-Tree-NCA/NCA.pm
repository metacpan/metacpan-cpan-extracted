# Copyright 2002 by Mats Kindahl. All rights reserved. 
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 

package Algorithm::Tree::NCA::Data;

use 5.006;
use strict;
use warnings;

use fields qw(_run _magic _number _parent _leader _max _node);

sub new ($%) {
    my $class = shift;
    # Default values first, then the provided parameters
    my %args = (_run => 0,        # Corresponds to I(v)
                _magic => 0,      # Corresponds to A_v
                _max => 0,        # Maximum number assigned to subtree
                _number => 0,     # The DFS number assigned to this node
                _parent => undef, # The parent node data for this node
                _leader => undef, # The leader node data for this node
                _node => undef,   # The node that the data is for
                @_);

    my $self = fields::new($class);
    @$self{keys %args} = values %args;
    return $self;
}

package Algorithm::Tree::NCA;

use strict;
use warnings;

use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = ();
our @EXPORT = ();
our $VERSION = '0.02';

# Preloaded methods go here.

use fields qw(_get _set _data);

sub _set_method {
    my($node,$value) = @_;

    $node->{'_nca_number'} = $value;
}

sub _get_method {
    my($node) = @_;

    return $node->{'_nca_number'};
} 


sub new ($%) {
    my($class,%o) = @_;

    $o{-get} = \&_get_method unless defined $o{-get};
    $o{-set} = \&_set_method unless defined $o{-set};

    my $self = fields::new($class);

    $self->{_get} = $o{'-get'}; # Get method to use
    $self->{_set} = $o{'-set'}; # Set method to use
    $self->{_data} = [];	# Array of node data


    # Preprocess the tree if there is one supplied
    $self->preprocess($o{-tree}) if exists $o{-tree};

    return $self;
}

sub _get ($$) {
    my($self,$node) = @_;
    $self->{_get}->($node);
}

sub _set ($$$) {
    my($self,$node,$val) = @_;
    $self->{_set}->($node,$val);
}

sub _lssb ($) {
    my($v) = @_;
    return $v & -$v;
}

sub _mssb ($) {
    my($v) = @_;

    $v |= $v >> 1;
    $v |= $v >> 2;
    $v |= $v >> 4;
    $v |= $v >> 8;
    $v |= $v >> 16;

    return $v - ($v >> 1);
}

sub _data ($$) {
    my($self,$node) = @_;
    return $self->{_data}->[$self->_get($node)];
}

sub preprocess ($$) {
    my($self,$root) = @_;

    # Enumeration phase
    $self->_enumerate($root, 1);

    # Computing magic number and leaders
    $self->_compute_magic($root, $self->_data($root), 0);
}

# Enumerate each node of the tree with a number v and compute the run
# I(v) for each node. Also set the parent for each node.
sub _enumerate ($$$;$) {
    my($self,$node,$number,$parent) = @_;

    my $data = Algorithm::Tree::NCA::Data
	->new(_node => $node,
	      _run => $number, 
	      _parent => $parent,
	      _number => $number);

    $self->{_data}->[$number] = $data;

    $self->_set($node,$number);

    my $run = $number++;
    
    for my $c ($node->children()) {
	($number, $run) = $self->_enumerate($c, $number, $data);
	if (_lssb($run) > _lssb($data->{_run})) {
	    $data->{_run} = $run;
	}
    }
    $data->{_max} = $number;
    return ($number,$data->{_run});
}

# Compute the magic number A_v and the leader L(v) for each node v.
sub _compute_magic ($$$$) {
    my($self,$node,$ldata,$magic) = @_;

    my $ndata = $self->_data($node);

    $ndata->{_magic} = $magic | _lssb($ndata->{_run});

    if ($ndata->{_run} != $ldata->{_run}) {
	$ndata->{_leader} = $ndata;
    } else {
	$ndata->{_leader} = $ldata;
    }

    foreach my $c ($node->children()) {
	$self->_compute_magic($c, 
			      $ndata->{_leader}, 
			      $ndata->{_magic});
    }
}

sub _display_data ($) {
    my($self) = @_;

    my(@L,@I,@A);
    foreach my $d (@{$self->{_data}}) {
	push(@L, defined $d ? $d->{_leader}->{_number} : "*");
	push(@I, defined $d ? $d->{_run} : "*");
	push(@A, defined $d ? $d->{_magic} : "*");
    }

    print STDERR "L = (@L)\n";
    print STDERR "I = (@I)\n";
    print STDERR "A = (@A)\n";
}

# Compute the nearest common ancestor of nodes I(x) and I(y)
sub _bin_nca ($$$) {
    my($self,$xd,$yd)= @_;

    if ($xd->{_number} <= $yd->{_number} && $yd->{_number} < $xd->{_max}) {
	return $xd->{_run};
    }

    if ($yd->{_number} <= $xd->{_number} && $xd->{_number} < $yd->{_max}) {
	return $yd->{_run};
    }

    my $k = _mssb($xd->{_run} ^ $yd->{_run});
    my $m = $k ^ ($k - 1);	# Mask off the k-1 most significant bits
    my $r = ~$m & $xd->{_run};	# Take the k-1 most significant bits

    # Return k-1 least significant bits of I(x) with a 1 in position k
    return ($r | $k);

}

# Find the node closest to 'x' but on the same run as the NCA.
sub _closest ($$$) {
    my($self,$xd,$j) = @_;

    # a. Find the position l of the right-most 1-bit in A_x
    my $l = _lssb($xd->{_magic});

    # b. If l == j then nx is x (since x and z are on the same run)
    if ($l == $j) {
        return $xd;
    }

    # c. Find the position k of the left-most 1-bit in A_x that is to
    #    the right of position j.
    my $k = _mssb(($j - 1) & $xd->{_magic});

    #    Form the number u consisting of the bits of I(x) to the left
    #    of position k, followed by a 1-bit in position k, followed by
    #    all zeroes. (u will be I(w))
    my $u = ~(($k - 1) | $k) & $xd->{_run} | $k;

    #    Look up node L(I(w)), which must be node w. nx is then the parent
    #    of node w.
    my $wd = $self->{_data}->[$u]->{_leader};

    return $wd->{_parent};
    
}

sub nca ($$$) {
    my($self,$x,$y) = @_;
    my $xd = $self->_data($x);
    my $yd = $self->_data($y);

    if ($xd->{_number} == $yd->{_number}) {
	return $x;
    }

    # 1. Find the [nearest] common ancestor b in B of nodes I(x) and I(y).
    my $b = $self->_bin_nca($xd,$yd);

    # 2. Find the smallest position j greater than or equal to h(b) such
    #    that both numbers A_x and A_y have 1-bits in position j. j is
    #    then h(I(z)).
    my $m = ~$b & ($b - 1);	# Mask for the h(b)-1 least significant bits
    my $c = $xd->{_magic} & $yd->{_magic};
				# The common set bits in A_x and A_y
    my $u = $c & ~$m;		# The upper bits of the common set bits
    my $j = _lssb($u);		# Isolate the rightmost 1-bit of u

    # 3a. Find node nx, the closest node to x on the same run as z.
    my $nxd = $self->_closest($xd,$j);
    # 3b. Find node ny, the closest node to y on the same run as z.
    my $nyd = $self->_closest($yd,$j);

    # 4. If nx < ny then z is nx, else z is ny
    if ($nxd->{_number} < $nyd->{_number}) {
	return $nxd->{_node};
    } else {
	return $nyd->{_node};
    }
}

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Algorithm::Tree::NCA - Constant time retrieval of I<Nearest Common Ancestor>

=head1 SYNOPSIS

  use Algorithm::Tree::NCA;

  my $tree = ...;
  my $nca = new Algorithm::Tree::NCA(-tree => $tree);

  my $x = $tree->get_node(...);
  my $y = $tree->get_node(...);
  my $z = $nca->nca($x,$y);

=head1 DESCRIPTION

This package provides constant-time retrieval of the Nearest Common
Ancestor (NCA) of nodes in a tree. The implementation is based on the
algorithm by Harel and which can, after linear-time preprocessing,
retrieve the nearest common ancestor of two nodes in constant time.

To implement the algorithm it is necessary to store some data for each
node in the tree.

=over 4

=item -
A I<node number> assigned to the node in a pre-order fashion

=item -
A number to identify the I<run> of the node (L<"ALGORITHM">)

=item -
The I<leader> for each run, which should be retrievable through its
node number

=item -
A I<magic> number (L<"ALGORITHM">)

=item -
The I<parent> node for each node

=item -
The I<maximum> number assigned to a any node in the subtree

=back

All data above, with the exception of the node number, is stored in an
array inside the C<Algorithm::Tree::NCA> object.

The node number has to be stored in the actual tree node in some
manner (alternative solutions would be to slow to give constant-time
retrieval), which requires a I<set method> and a I<get method> for the
nodes. Since the most common case is using hashes to represent nodes,
there are default implementations of the set and get methods.

The default set method is:

  sub _set_method {
      my($node,$value) = @_;

      $node->{'_nca_number'} = $value;
  }

and the default get method is:

  sub _get_method {
      my($node) = @_;

      return $node->{'_nca_number'};
  } 

If have chosen another representation of your nodes, you can provide
alternative set and get methods by using the B<-set> and B<-get>
options when creating the C<Algorithm::Tree::NCA> object.

=head1 CLASS AND OBJECT METHODS

=head1 EXAMPLES

=head2 ALGORITHM

This section describes the algorithm used for preprocessing and for
nearest common ancestor retrieval. It does not provide any intuition
to I<why> the algorithm works, just a description how it works. For
the algorithm description, it is assumed that the nodes themself
contain all necessary information. The algorithm is described in a
Pascal-like fashion. For detailed information about the algorithm,
please have a look in [1] or [2].

The I<height> of a non-zero integer is the number of zeros at the
right end of the integer. The I<least significant set bit> (LSSB) of a
non-zero number is the the number with only the least significant bit
set (surprise). For instance, here is the LSSB and the height of some
numbers:

  Number    LSSB       Height
  --------  --------   ------
  01001101  00000001   0
  01001100  00000100   2

Important to note here is that for numbers I<i> and I<j>, I<height(i)
E<lt> height(j)> if and only if I<LSSB(i) E<lt> LSSB(j)>, which means
that we can replace a test of I<height(i) E<lt> height(j)> with
I<LSSB(i) E<lt> LSSB(j)>. Since I<LSSB(i)> is easier to compute, this
will speed up the computation.

=head2 Preprocessing the tree

Preprocessing the tree requires the computation of three numbers: the
I<node number>, the I<run>, and a I<magic> number. It also requires
computation of the I<leader> of each run. These computations are done
in two recursive descents and ascents of the tree.

  Procedure Preprocess(root:Node)
  Var x,y : Integer;   (* Dummy variables *)
  Begin
      (x,y) := Enumerate(root,nil,1);
      ComputeMagic(root,root,0);
  End;

In the first phase, we enumerate the tree, compute the I<run> for each
node, the I<max> number assigned to a node in the subtree, and also
the I<parent> of each node. If the parent is already available through
other means, that part is redundant. The run of a node is the number
of the node in the subtree with the largest height.

  Function Enumerate(node,parent:Node; num:Integer) : (Integer,Integer)
  Var run : Integer;
  Begin
      node.parent := parent;
      node.number := num;
      node.run := num;

      run := num;
      num := num + 1;

      Foreach child in node.children Do
	  (num,run) := Enumerate(child,node,num);
	  If height(run) > height(node.run) Then
	      node.run := run;
      Done
      node.max := num;
      Return (num,node.run)
  End;

In the second phase, we compute the I<leader> for each run (which we
can since we know the run for each node) and the I<magic> number. The
leader I<has> to be stored so that we can access is through a node
number, so we store it in an array.
  
  VAR Leader : Array [1..NODE_COUNT] of NodePtr;

The leader for each run can either be stored for each node (which we
assume here), or only stored in the node where the C<node.run ==
node.number>. We can then compute the leader of any C<node> through
C<Leader(node.run)>, which requires less storage if C<Leader> is
implemented as a spare array.

The magic number of a node is the bitwise or of all run:s of nodes in
the path leading from the root node to the node.

  Procedure ComputeMagic(node, current_leader:Node; magic:Integer)
  Begin
    node.magic = magic | LSSB(node.run);
    If node.run != leader.run Then
      Leader(node.number) = node
    Else
      Leader(node.number) = current_leader

    Foreach child in node.children Do
      ComputeMagic(child, Leader(node.number), node.magic)
    Done
  End;

=head2 Constant-time retrieval of the nearest common ancestor

To find the NCA of two nodes, we map the nodes to a binary tree and
find the NCA I<b> there (which is easy). We then do some bitwise
arithmetics to find the bit I<j> where the magic numbers of the two
nodes have a C<1> in common and that has a greater height than I<b>.

  Function NCA(x,y:Node) : Node;
  Begin
    b  := BinNCA(x,y);          (* b = 10111000 *)
    m  := (NOT b) AND (b - 1);  (* m = 00000111 *)
    c  := x.magic AND y.magic;
    u  := c AND (NOT m);
    j  := LSSB(u);
    x1 := Closest(x,j);
    y1 := Closest(y,j);
    If x1.number < y1.number Then
      Return x1
    Else
      Return y1
  End;

Retrieving the nearest common ancestor in a complete binary tree is
easy assuming you have a special numbering of the nodes. We number
each node with a I<path number> such that the root node is numbered
C<10000000> and for each choice down the tree, we use (for example)
C<0> for left and C<1> for right. Assuming that the nodes are not on
the same path from the root, we can then:

=over 4

=item a.
compute the XOR of the path numbers, 

=item b.
find the most significant C<1> in the XOR, which is where the paths differ;

=item c.
take the part I<before> (i.e., high end) the most significant C<1> in
one of the path number (either one, since these parts are equal),

=item d.
add a C<1> after, and

=item e.
set the lowest part after the C<1> to all zeroes.

=back

The value returned is the path number of the node that is the nearest
common ancestor. (In this implementation, the mapping from node number
to run is a mapping to a binary tree where the run is the path number.)

  Function BinNCA(x,y:Node) : Integer
  Var k,m,r : Integer;
  Begin
    (* Check that neither is the ancestor of the other *)
    If x.number <= y.number and y.number < x.max Then
      Return x.run
    If y.number <= x.number and x.number < y.max Then
      Return y.run

    (* Suppose x.run = 10110--- and y.run = 10111--- *)
    (* Then x.run XOR y.run = 00001---, and further: *)
    k := MSSB(x.run XOR y.run); (* k = 00001000 *)
    m := k XOR (k - 1);         (* m = 00001111 *)
    r := (NOT m) AND x.run;     (* r = 10110000 *)
    Return r OR k;          (* result: 10111000 *)
  End;


To find the node closest to a node I<n> but on the same run as the NCA
I<z> we need the I<j> supplied by the C<NCA> function above.

  Function Closest(n:Node; j:Integer) : Node;
  Begin
    l := LSSB(n.magic);
    If l = j Then Return x
    k := MSSB((j - 1) AND x.magic);
    u := ((NOT ((k - 1) OR k)) AND x.run) OR k
    w := Leader(u);
    Return w.parent;  (* z = w.parent *)
  End;

=head1 REFERENCES

=over 4

=item [1] I<Fast algorithms for finding nearest common ancestor> by
          D. Harel and R. E. Tarjan.

=item [2] I<On finding lowest common ancestor: simplifications and
          parallelizations> by B. Schieber and U. Vishkin.

=item [3] I<Algorithms on strings, trees, and sequences> by Dan
          Gusfield.

=back

=head1 AUTHOR

Mats Kindahl <matkin@acm.org>

=head1 SEE ALSO

L<perl>.

=cut

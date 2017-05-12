package AI::PBDD;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

require Exporter;
require DynaLoader;

use constant BDD_REORDER_NONE => 0;
use constant BDD_REORDER_WIN2 => 1;
use constant BDD_REORDER_WIN3 => 2;
use constant BDD_REORDER_SIFT => 3;
use constant BDD_REORDER_RANDOM => 4;


@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
	      BDD_REORDER_NONE
	      BDD_REORDER_WIN2
	      BDD_REORDER_WIN3
	      BDD_REORDER_SIFT
	      BDD_REORDER_RANDOM
);

@EXPORT_OK = qw(
// setup and cleanup
		 init
		 gc
		 verbose
		 kill
// simple BDD operations
		 getOne
		 getZero
		 createBDD
		 getVarCount
		 getBDD
// ref counting
		 ref
		 deref
		 localDeref
// BDD operations
		 and
		 or
		 andTo
		 orTo
		 nand
		 nor
		 xor
		 ite
		 imp
		 biimp
		 not
                 makeSet
		 exists
		 forall
		 relProd
		 restrict
		 constrain
// variables replacement
		 createPair
		 deletePair
		 replace
		 showPair
// BDD analysis
		 support
		 nodeCount
		 satOne
		 satCount
// printing
		 printDot
		 printSet
		 print
// debugging
		 printStats                 
		 checkPackage
		 debugPackage
		 debugBDD
// low-level access
		 internal_index
		 internal_refcount
		 internal_isconst
		 internal_constvalue
		 internal_iscomplemented
		 internal_then
		 internal_else
// dynamic variable ordering
		 reorder_setMethod
		 reorder_now
		 reorder_enableDynamic
		 reorder_createVariableGroup
);

$VERSION = '0.01';

bootstrap AI::PBDD $VERSION;

sub satCount {
  my ($bdd, $vars_ignored) = @_;

  if (!defined($vars_ignored)) {
    return satCount__I($bdd);
  } else {
    return satCount__II($bdd, $vars_ignored);
  }
}

sub printDot {
  my ($bdd, $filename) = @_;

  if (!defined($filename)) {
      printDot__I($bdd);
  } else {
      printDot__II($bdd, $filename);
  }
}

sub makeSet {
  my ($vars, $size, $offset) = @_;

  if (!defined($offset)) {
      return makeSetI($vars, $size);
  } else {
      return makeSetII($vars, $size, $offset);
  }
}

sub createPair {
  my ($old, $new) = @_;
  my $size = @$old;

  return createPairI($old, $new, $size);
}

1;

__END__

=head1 AI::PBDD

Perl wrapper for the BuDDy C library

=head1 SYNOPSIS

  use AI::PBDD qw(init createBDD and printDot kill);

  init(100, 100000);

  my $var1 = createBDD();
  my $var2 = createBDD();

  my $bdd = and($var1, $var2);

  printDot($bdd);

  kill();

=head1 DESCRIPTION

Binary Decision Diagrams (BDDs) are used for efficient computation of many common problems. This is done by giving a compact representation and a set of efficient operations on boolean functions f: {0,1}^n --> {0,1}.

It turns out that this representation is good enough to solve a huge amount of problems in Artificial Intelligence and other areas of computing such as hardware verification.

This is a Perl interface to the popular BDD package BuDDy. The interface is largely inspired by JBDD, a Java common interface for the two BDD packages BuDDy and CUDD written by Arash Vahidi, which can be found at L<http://javaddlib.sourceforge.net/jbdd/>.

PBDD allows you to combine the power of Perl with an efficient BDD package written in highly optimized C.

=head1 FUNCTIONS

=head2 SETUP AND CLEANUP

=over 4 

=item B<init($nvars, $nnodes))>

Initialize the BDD package using the given number of variables and nodes.

=item B<gc>

Invoke garbage collection.

=item B<verbose($be_verbose)>

Make the BDD package verbose or non-verbose.

=item B<kill>

Close the BDD package and cleanup.

=back

=head2 SIMPLE BDD OPERATIONS

=over 4

=item B<$bddone = getOne>

Returns the BDD constant 1.

=item B<$bddzero = getZero>

Returns the BDD constant 0.

=item B<$bdd = createBDD>

Returns a new BDD variable.

=item B<$nvars = getVarCount>

Returns the number of BDD variables currently in the system.

=item B<$bdd = getBDD($idx)>

Returns the BDD at the given index C<$idx> (ranked after calling C<createBDD>).

=back

=head2 REF COUNTING

=over 4

=item B<$bdd = ref($bdd)>

Increase the reference count of a BDD, and return the BDD.

=item B<deref($bdd)>

Decrease the reference count of a BDD.

=item B<localDeref($int)>

Same as C<deref>, since BuDDy does not distinguish between local and recursive derefs.

=back

=head2 BDD OPERATIONS

=over 4

=item B<$bdd = and($bdd1,$bdd2)>

BDD AND operation. The returned result is already referenced.

=item B<$bdd = or($bdd1,$bdd2)>

BDD OR operation. The returned result is already referenced.

=item B<$bdd1new = andTo($bdd1,$bdd2)>

BDD cumulative AND operation. The returned result is already referenced, while $bdd1 is de-referenced.

=item B<$bdd1new = orTo($bdd1,$bdd2)>

BDD cumulative OR operation. The returned result is already referenced, while $bdd1 is de-referenced.

=item B<$bdd = nand($bdd1,$bdd2)>

BDD NAND operation. The returned result is already referenced.

=item B<$bdd = nor($bdd1,$bdd2)>

BDD NOR operation. The returned result is already referenced.

=item B<$bdd = xor($bdd1,$bdd2)>

BDD XOR operation. The returned result is already referenced.

=item B<$bdd = ite($bdd_if,$bdd_then,$bdd_else)>

BDD ITE (If-Then-Else) operation, i.e. C<($bdd_if AND $bdd_then) OR (NOT $bdd_if AND $bdd_else)>. The returned result is already referenced.

=item B<$bdd = imp($bdd1,$bdd2)>

BDD IMPlication operation. The returned result is already referenced.

=item B<$bdd = biimp($bdd1,$bdd2)>

BDD BIIMPlication operation. The returned result is already referenced.

=item B<$bdd = not($bdd1)>

BDD NOT operation. The returned result is already referenced.

=item B<$cube = makeSet($vars,$size)>

=item B<$cube = makeSet($vars,$size,$offset)>

Create a cube (all-true minterm, e.g. C<$v1 AND $v2 AND $v3> where each C<$vi> is a BDD variable) of C<$size> variables from the array referenced by C<$vars>, starting at position 0 (or C<$offset>).

=item B<$bdd = exists($bdd1,$cube)>

BDD existential quantification. Parameter C<$cube> is an all-true minterm. The returned result is already referenced.

=item B<$bdd = forall($bdd1,$cube)>

BDD universal quantification. Parameter C<$cube> is an all-true minterm. The returned result is already referenced.

=item B<$bdd = relProd($bdd_left,$bdd_right,$cube)>

BDD relation-product (quantification and product computation in one pass): C<EXISTS $cube: $bdd_left AND $bdd_right>. The returned result is already referenced.

=item B<$bdd = restrict($bdd1,$minterm)>

Restrict a set of variables to constant values. The returned result is already referenced.

=item B<$bdd = constrain($bdd1,$bdd2)>

Compute the generalized co-factor of C<$bdd1> w.r.t. C<$bdd2>. The returned result is already referenced.

=back

=head2 VARIABLES REPLACEMENT

=over 4

=item B<$pair = createPair($vars_old,$vars_new)>

Create a function C<$pair: BDD variable -E<gt> BDD variable> that maps C<$vars_old-E<gt>[i]> to C<$vars_new-E<gt>[i]>.

=item B<deletePair($pair)>

Free the memory occupied by C<$pair>.

=item B<$bdd = replace($bdd1,$pair)>

Replace the variables in a BDD according to the given pair. The returned result is already referenced.

=item B<showPair($pair)>

Print a pair.

=back

=head2 BDD ANALYSIS

=over 4

=item B<$cube = support($bdd)>

BDD support set as a cube.

=item B<$cnt = nodeCount($bdd)>

Number of nodes a BDD.

=item B<$minterm = satOne($bdd)>

One arbitrary minterm (satisfying variable assignment), unless C<$bdd> equals 0.

=item B<$cnt = satCount($bdd)>

=item B<$cnt = satCount($bdd,$nvars)>

Number of minterms that satisfy C<$bdd>. The number of minterms is computed by considering all of the variables in the package (defined with the call to the C<init> function), but it is possible to specify the number of variables C<$nvars> to be ignored in the computation.

=back

=head2 PRINTING

=over 4

=item B<printDot($bdd)>

=item B<printDot($bdd,$filename)>

Print the BDD as a Graphviz DOT model to STDOUT (or the given C<$filename>).

=item B<printSet($bdd)>

Print the BDD minterms to STDOUT.

=item B<print($bdd)>

Print the BDD in the native BuDDy representation to STDOUT.

=back

=head2 DEBUGGING

=over 4

=item B<printStats>

Print package statistics to STDOUT.

=item B<$ok = checkPackage>

Return 0 if something is wrong.

=item B<debugPackage>

Debug the BDD package.

=item B<$ok = debugBDD($bdd)>

Debug C<$bdd> in the BDD package. Return 0 if something is wrong.

=back

=head2 LOW LEVEL ACCESS

=over 4

=item B<$idx = internal_index($bdd)>

Get the index of a BDD variable.

=item B<$cnt = internal_refcount($bdd)>

Get the number of references to a BDD variable.

=item B<$bool = internal_isconst($bdd)>

Returns 1 if the BDD is either 0 or 1.

=item B<$bool = internal_constvalue($bdd)>

If C<$bdd> is either 0 or 1, it returns that value.

=item B<$bool = internal_iscomplemented($bdd)>

Returns 1 if the BDD is complemented.

=item B<$bdd_then = internal_then($bdd)>

Get the THEN-node of a BDD.

=item B<$bdd_else = internal_else($bdd)>

Get the ELSE-node of a BDD.

=back

=head2 DYNAMIC VARIABLE ORDERING

=over 4

=item B<reorder_setMethod($method)>

Set dynamic reordering heuristic. The possible values are:

=over 4

=item BDD_REORDER_NONE

No reordering.

=item BDD_REORDER_WIN2

Reordering using a sliding window of size 2. This algorithm swaps two adjacent variable blocks and if this results in more nodes then the two blocks are swapped back again. Otherwise the result is kept in the variable order. This is then repeated for all variable blocks.

=item BDD_REORDER_WIN3

Same as above but with a window size of 3.

=item BDD_REORDER_SIFT

Each block is moved through all possible positions. The best of these is then used as the new position. Potentially a very slow but good method.

=item BDD_REORDER_RANDOM

Select a random position for each variable.

=back

These constants are automatically exported by the package.

=item B<reorder_now>

Start dynamic reordering.

=item B<reorder_enableDynamic($enable)>

Enable/disable automatic dynamic reordering.

=item B<reorder_createVariableGroup($first,$last,$fix_group)>

Create a variable block, between the C<$first> and C<$last> variable indexes. Parameter C<$fix_group> decides whether to allow reordering inside the group or fix to current ordering.

=back

=head1 SEE ALSO

BDDs and their operations are described in many academic papers that can be found on the Internet. A good place to get started with BDDs is the wikipedia article L<http://en.wikipedia.org/wiki/Binary_decision_diagram>.

It can also be useful to look at the test code for this package in the C<t> directory, as well as at the JBDD documentation and exaples at L<http://javaddlib.sourceforge.net/jbdd/>.

=head1 VERSION
    
This man page documents "PBDD" version 0.01.

=head1 AUTHOR

  Gianluca Torta
  mailto:torta@di.unito.it

=head1 COPYRIGHT

Copyright (c) 2011 by Gianluca Torta. All rights reserved.

=head1 LICENSE

This package is free software; you can use, modify and redistribute
it under the same terms as Perl itself, i.e., at your option, under
the terms either of the "Artistic License" or the "GNU General Public
License".

The interface design and part of the C code and documentation are modifications of the JBDD package by Arash Vahidi. A copy of the JBDD licence can be found in the C<licences> directory of this package.

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

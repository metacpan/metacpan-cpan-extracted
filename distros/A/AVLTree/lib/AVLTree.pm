package AVLTree;

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';
our $ENABLE_DEBUG = 0;

require XSLoader;
XSLoader::load('AVLTree', $VERSION);

1; # End of AVLTree
__END__

=head1 NAME

AVLTree - Perl extension for efficient creation and manipulation of AVL balanced binary trees.

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This module provides a simple and fast implementation of AVL balanced trees.
It uses the Perl XS extension mechanism by providing a tiny wrapper around 
an efficient C library which does the core of the work. Preliminary benchmarking 
shows this module one order of magnitude faster than a pure perl implementation.

The nodes of an AVL tree object can hold any kind of item, as long as each 
one of these has an element which can be used to define a partial order on 
the set of possible items. This is specified by providing, upon tree construction,
a reference to a function for comparing any two of the possible items.

The underlying C library is a reinterpretation of the C library originally 
developed by Julienne Walker. This library has been adapted for dealing 
directly with Perl (SV) variables.

The module at the moment is in beta stage but it is usable. It provides methods 
for creating and querying an AVL tree, get its size and insert and remove elements 
from it. No methods exist to traverse the tree at this stage, but I promise this
functionality is going to be implemented very soon.

=head1 SYNOPSIS

  use AVLTree;

  # Define a function to compare two numbers i1 and i2,
  # return -1 if i1 < i2, 1 if i2 > i1 and 0 otherwise 

  sub cmp_f = sub {
    my ($i1, $i2) = @_;

    return $i1<$i2?-1:($i1>$i2)?1:0;
  }

  # Instantiate a tree which holds numbers
  my $tree = AVLTree->new(\&cmp_f);
  
  # Add some numbers to the tree
  map { $tree->insert($_) } qw/10 20 30 40 50 25/;

  # Now invoke some useful methods
  # Size of the tree
  printf "Size of the tree: %d\n", $tree->size();
  
  # Query the tree
  my $query = 30;
  print "Query: %d, Found: %d\n", $query, $tree->find($query)?1:0;

  # Remove an item
  my $item = 1
  if($tree->remove($item)) {
    print "Item $item has been removed\n";
  } else {
    print "Item $item was not in the tree so it's not been removed\n";
  }
  
  printf "Size of tree is now: %d\n", $tree->size();

  ...

  # Suppose you want the tree to hold generic data items, e.g. hashrefs
  # which hold some data. We can deal with these by definying a custom
  # comparison function based on one of the attributes of these data items, 
  # e.g. 'id':
 
  sub compare {
    my ($i1, $i2) = @_;
    my ($id1, $id2) = ($i1->{id}, $i2->{id});

    croak "Cannot compare items based on id"
      unless defined $id1 and defined $id2;
  
    return $id1<$id2?-1:($id1>$id2)?1:0;
  }

  # Now can do the same as with numbers
  my $tree = AVLTree->new(\&compare);

  my $insert_ok = $tree->insert({ id => 10, data => 'ten' });
  croak "Could not insert item" unless $insert_ok;

  $insert_ok = $tree->insert({ id => 20, data => 'twenty' });
  
  ...

  my $id = 10;
  my $result = $tree->find({ id => $id });
  if($result) {
    printf "Item with id %d found\nData: %s\n", $id, $result->{data};
  } else {
    print "Item with id $id not found\n";
  }

  ...

=head1 METHODS

=head2 new

  Arg [1]     : (required) A reference to a subroutine
  
  Example     : my $tree->new(\&compare);
                carp "Unable to instantiate tree" unless defined $tree;

  Description : Creates a new AVL tree object.
                The objects hold by the tree are implicitly defined
                by the provided callback.

  Returntype  : AVLTreePtr or undef if unable to instantiate
  Exceptions  : None
  Caller      : General
  Status      : Unstable, interface might change to accomodate suitable defaults, 
                e.g. numbers

=head2 find

  Arg [1]     : Item to search, can be defined just in terms of the attribute
                with which the items in the tree are compared. 
  
  Example     : $tree->find({ id => 10 }); # objects in the tree can hold data as well
                if($result) {
                  printf "Item with id %d found\nData: %s\n", $id, $result->{data};
                } else { print "Item with id $id not found\n"; }

  Description : Query if an item exists in the tree.

  Returntype  : The item, if found, as stored in the tree or undef
                if the item was not found or the query was not provided
                or it was undefined.
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head2 insert

  Arg [1]     : An item to insert in the tree.
  
  Example     : my $ok = $tree->insert({ id => 10, data => 'ten' });
                croak "Unable to insert 10" unless $ok;

  Description : Insert an item in the tree, use the provided, upon tree construction,
                comparison function to determine the position of the item in the tree

  Returntype  : Bool, true if the item was successfully installed, false otherwise 
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head2 remove

  Arg[1]      : An item to remove from the tree
  
  Example     : my $ok = $tree->remove({ id => 10 });
                croak "Unable to remove 10" unless $ok;

  Description : Remove an item from the tree.

  Returntype  : Bool, true if the item was successfully installed, false otherwise 
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head2 size

  Arg[...]    : None
  
  Example     : print "Size of the tree is: %d\n", $tree->size();

  Description : Returns the size of the tree (number of nodes)

  Returntype  : Int, the size of the tree
 
  Exceptions  : None
  Caller      : General
  Status      : Unstable

=head1 DEPENDENCIES

AVLTree requires Carp and Test::More and Test::LeakTrace to run the tests during installation.
If you want to run the benchmarks in the scripts directory, you need to install the Benchmark 
and List::Util modules.

=head1 CHANGES

0.01 2017-12-18
   * First release to CPAN, partial port of jsw_avltree AVL tree C library, traversal methods not implemented.

=head1 EXPORT

None

=head1 SEE ALSO

There are of course other modules which provide this functionality, see e.g. Tree::AVL, Btrees.

You can appreciate the power of this module by running some benchmarking against the above.
If you've installed from source, go to the installation directory and:  

  cd scripts
  perl benchmarking.pl

Preliminary experiments suggest speed gains of one order of magnitude.

To the best of my knowledge, there are no modules using Perl XS attempting to implement AVL
trees in the most efficient possible way. The closest thing is Tree::Fat, a Perl extension
to implement Fat-Node trees.

=head1 AUTHOR

Alessandro Vullo, C<< <avullo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-avltree at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AVLTree>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 CONTRIBUTING

You can obtain the most recent development version of this module via the GitHub
repository at https://github.com/avullo/AVLTree. Please feel free to submit bug
reports, patches etc.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AVLTree

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AVLTree>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AVLTree>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AVLTree>

=item * Search CPAN

L<http://search.cpan.org/dist/AVLTree/>

=back

=head1 ACKNOWLEDGEMENTS

I am very grateful to Julienne Walker for generously providing the source 
code of his production quality C library for handling AVL balanced trees.

Julienne's library can be found at:

http://www.eternallyconfuzzled.com/Libraries.aspx

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Alessandro Vullo.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

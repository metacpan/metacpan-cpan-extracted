package Data::Hierarchy::Traverser;

use 5.008;
use Carp;
use strict;
use warnings;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter AutoLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Hierarchy::Traverser ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	hierarchy_traverse
);

our $VERSION = '0.01';

sub hierarchy_traverse {
  my ($roots, $get_children_function, $options) = @_;
  my  $deepth =           $options->{deepth};
  my  $is_leaf =          $options->{is_leaf};
  my  $leaf =             $options->{leaf};
  my  $bare_branch     =   $options->{bare_branch};
  my  $pre_branch=        $options->{pre_branch};
  my  $post_branch =      $options->{post_branch};

  $options->{deepth} -- if defined $options->{deepth};

  defined $roots or croak "parameter roots is mandatory";
  defined $get_children_function  or croak "parameter get_children_function is mandatory\n";
  UNIVERSAL::isa($get_children_function, 'CODE')  or croak "get_children_function must be a sub\n";

  # should check if $get_children_function is ref to CODE.
  $is_leaf ||= sub {};
  $leaf ||=  sub {};
  $pre_branch ||=  sub {};
  $post_branch ||= sub {};
  $bare_branch ||=  sub {};

  my @roots;
  @roots = ref($roots)? @$roots : ($roots);
  foreach my $node (@roots) {
    if ($is_leaf->($node)) {
       $leaf->($node);
    } else {
      my $children = $get_children_function->($node); 
      if (not defined $children or 0 ==@$children) {
	$bare_branch->($node);
        next;
      } else {
        if (defined $deepth and $deepth < 0 ) {
          $bare_branch->($node);
          next;
      }
        $pre_branch->($node);
        hierarchy_traverse($children, $get_children_function, $options);
        $post_branch->($node);
      }
    }
  }
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Data::Hierarchy::Traverser - Perl extension for generic hierarchy structure traversal.

=head1 SYNOPSIS

  use Data::Hierarchy::Traverser;
  
  hierarchy_traverse (
     $roots,   # a scalar for one root,
               # or a ref to a list of roots,
               # or a ref to a list of the wrappers of root.
  
    \&get_children,   # a function for getting child nodes
    {                                        # Options:
      depth          => 1,                   # how depth limitaion. (default undef, no limitation)
      pre_branch     => $per_banch_function, # the function called before visit childeren nodes
      post_branch    => $per_banch_function, # the fucntion called after visite all it children nodes
      bare_branch    => $per_banch_function, # the function for empty branches
      leaf           => $leaf_function,      # the function for leaf nodes
      is_leaf        => $is_leaf_function,   # the function for check if a node is leaf
                                             # all default functions are default to be {}
                                             # (do nothing and return false.
                                             # (?Should it just skip the call to an empty funcion?)
     } ,
  );

=head1 DESCRIPTION

This module export one recursive function hierarchy_traverse, which traverses a hierarchy structure in the depth-first fashion.

Caution: As it is a recursive function, pay attention of the usage of gobal variables such as $_, <FH>.

More detail will be added here.

=head2 EXPORT

sub hierarchy_traverse

=head2 Examples

=head3 1. Partition (Higher-Order Perl::Chapter 5::Figure 5.2?)
  
  use Data::Hierarchy::Traverser;
  
  my $roots=[
             [6,[2,3,4,6],[]],
            ];
  hierarchy_traverse(
    $roots,
    \&get_children,
    { is_leaf => sub { $_[0]->[0] == 0 } ,
      leaf    => sub {
                       print join ', ', @{$_[0]->[2]};
                       print "\n"
                       # exit; #if want only one solution
                     },
    }
  );
  
  sub get_children {
    my ($target, $remain, $result) = @{shift()};
    return if $target < 0;
    return if 0 == @$remain;
    my $item = shift @$remain;
    my $new_result;
    $new_result = [@$result, $item];
    return [
      [$target - $item, [@$remain],  [@$new_result]],
      [$target        , [@$remain],  [@$result]]
    ];
  }
  

=head3 2. Eight Queens


  use Data::Hierarchy::Traverser;
  
  my $n = $ARGV[0];
  $n ||= 8;
  my $checkboard;
  
  for my $x (0..$n -1) {
    for my $y (0..$n -1) {
     push @$checkboard, [$x, $y];
    }
  };
  
  hierarchy_traverse(
    [ [0, $checkboard,[]], ],
    \&get_children,
    { is_leaf => sub { $_[0]->[0] ==  $n; } ,
      leaf    => sub { printCheckBoard($_[0]->[2]);
                       #exit; # if you just only want one solution
                     },
    }
  );
  
  sub get_children {
    my ($row, $points, $qs) = @{shift()};
    my $results = [];
    foreach my $point (grep {$_->[0] == $row} @$points) {
      my @remain_points =
          grep {
            not (
                 $_->[0] == $point->[0]                        # exclude the column
              or $_->[1] == $point->[1]                        # the row
              or $_->[0]-$_->[1] == $point->[0] - $point->[1]  # the "\" diagonal
              or $_->[0]+$_->[1] == $point->[0] + $point->[1]  # the "/" diagonal
            )
          } @$points; 
      my @new_qs = (@$qs, $point);
      push @$results, [$row+1, [@remain_points], [@new_qs]];
    }
    return $results;
  }
  
  sub printCheckBoard {
    my $cross = shift;
    print "~~~" x ($n), "\n";
    print "+--" x $n, "+\n";
    for my $x (0..$n -1) {
      for my $y (0..$n -1) {
        if (grep {$x == $_->[0] and $y == $_->[1]} @$cross ){
           print '|Q ';
         } else {
           print '|  ';
         } 
       }
       print "|\n" . '+--' x $n, "+\n";
    }
  }
  

=head1 SEE ALSO


=head1 AUTHOR

Ge Peng, E<lt>tigerpeng2001@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007 by Ge Peng

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

package AI::DecisionTree::Instance;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.11';

use DynaLoader ();
@ISA = qw(DynaLoader);

bootstrap AI::DecisionTree::Instance $VERSION;

1;
__END__

=head1 NAME

AI::DecisionTree::Instance - C-struct wrapper for training instances

=head1 SYNOPSIS

  use AI::DecisionTree::Instance;
  
  my $i = new AI::DecisionTree::Instance([3,5], 7, 'this_instance');
  $i->value_int(0) == 3;
  $i->value_int(1) == 5;
  $i->result_int == 7;

=head1 DESCRIPTION

This class is just a simple Perl wrapper around a C struct embodying a
single training instance.  Its purpose is to reduce memory usage.  In
a "typical" training set with about 1000 instances, memory usage can
be reduced by about a factor of 5 (from 43.7M to 8.2M in my test
program).

A fairly tight loop is also implemented that helps speed up the
C<train()> AI::DecisionTree method by about a constant factor of 4.

Please do not consider this interface stable - I change it whenever I
have a new need in AI::DecisionTree.

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 SEE ALSO

AI::DecisionTree

=cut

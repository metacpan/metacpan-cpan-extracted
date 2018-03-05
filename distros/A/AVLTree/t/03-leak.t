#!perl -T
use 5.008;

use strict;
use warnings FATAL => 'all';

use constant HAS_LEAKTRACE => eval{ require Test::LeakTrace };
use Test::More HAS_LEAKTRACE ? (tests => 10) : (skip_all => 'require Test::LeakTrace');
use Test::LeakTrace;
use Carp;

BEGIN { use_ok('AVLTree'); }

sub cmp_numbers {
  my ($i1, $i2) = @_;

  return $i1<$i2?-1:($i1>$i2)?1:0;
}

sub cmp_custom {
  my ($i1, $i2) = @_;
  my ($id1, $id2) = ($i1->{id}, $i2->{id});
  croak "Cannot compare items based on id"
    unless defined $id1 and defined $id2;
  
  return $id1<$id2?-1:($id1>$id2)?1:0;
}

# tests with numbers
no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_numbers);
} 'Empty tree';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_numbers);
  map { $tree->insert($_) } qw/10 20 30 40 50 25/;
} 'Non-empty tree';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_numbers);
  map { $tree->insert($_) } qw/10 20 30 40 50 25/;

  my $query = 30;
  my $result = $tree->find($query);
} 'After inserting&querying';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_numbers);
  map { $tree->insert($_) } qw/10 20 30 40 50 25/;

  $tree->remove(1); # unsuccessful removal
  $tree->remove(10); # successful removal
} 'After inserting&removing';

# repeat with custom data
no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_custom);
} 'Empty tree';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_custom);
  map { $tree->insert($_) }
    ({ id => 10, data => 'ten' },
     { id => 20, data => 'twenty' },
     { id => 30, data => 'thirty' },
     { id => 40, data => 'forty' },
     { id => 50, data => 'fifty' },
     { id => 25, data => 'twneryfive' });
} 'Non-empty tree';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_custom);
  map { $tree->insert($_) }
    ({ id => 10, data => 'ten' },
     { id => 20, data => 'twenty' },
     { id => 30, data => 'thirty' },
     { id => 40, data => 'forty' },
     { id => 50, data => 'fifty' },
     { id => 25, data => 'twneryfive' });
  
  my $query = { id => 30 };
  my $result = $tree->find($query);
} 'After inserting&querying';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_custom);
  map { $tree->insert($_) }
    ({ id => 10, data => 'ten' },
     { id => 20, data => 'twenty' },
     { id => 30, data => 'thirty' },
     { id => 40, data => 'forty' },
     { id => 50, data => 'fifty' },
     { id => 25, data => 'twneryfive' });  

  $tree->remove({ id => 1 }); # unsuccessful removal
  $tree->remove({ id => 10 }); # successful removal
} 'After inserting&removing';

no_leaks_ok {
  my $tree = AVLTree->new(\&cmp_custom);
  map { $tree->insert($_) }
    ({ id => 10, data => 'ten' },
     { id => 20, data => 'twenty' },
     { id => 30, data => 'thirty' },
     { id => 40, data => 'forty' },
     { id => 50, data => 'fifty' },
     { id => 25, data => 'twneryfive' });  

  my $item = $tree->first;
  while ($item = $tree->next) {}
} 'Tree traversal';


diag( "Testing memory leaking AVLTree $AVLTree::VERSION, Perl $], $^X" );

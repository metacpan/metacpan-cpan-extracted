#!perl -w

use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Clone;

use Scalar::Util qw(isweak weaken);
use Data::Dumper;
$Data::Dumper::Indent   = 0;
$Data::Dumper::Sortkeys = 1;

# hash tree

my $parent = {};
my $child  = {};

$child->{parent} = $parent;
$parent->{child} = $child;

weaken $child->{parent};

my $cloned = clone($child);
is Dumper($cloned), Dumper({ parent => undef }), 'tree structure (child)';

$cloned = clone($parent);
is Dumper($cloned), Dumper($parent), 'tree structure (parent)';

cmp_ok $cloned, '==', $cloned->{child}{parent}, 'as circular refs';
ok isweak($cloned->{child}{parent}), 'correctly weaken';

# array tree

$parent = ['is_parent'];
$child  = ['is_child'];

push @{$child},  $parent;
push @{$parent}, $child;

weaken $child->[1];

$cloned = clone($child);
is Dumper($cloned), Dumper(['is_child', undef]), 'array tree (child)';

$cloned = clone($parent);
is Dumper($cloned), Dumper($parent), 'array tree (parent)';

cmp_ok $cloned, '==', $cloned->[1][1], 'as sircular refs';
ok isweak($cloned->[1][1]), 'correctly weaken';

done_testing;

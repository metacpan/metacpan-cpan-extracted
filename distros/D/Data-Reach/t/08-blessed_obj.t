use strict;
use warnings;
use Test::More;
use Test::NoWarnings;
use Data::Reach;
use Object::MultiType;

plan tests => 25;

my %expected_plain_paths = (
  'plain,array,0'    => '',
  'plain,array,1'    => 'one',
  'plain,array,2'    => 'two',
  'plain,array,3'    => 'three',
  'plain,array,4'    => '',
  'plain,array,5'    => 'five',
  'plain,array,6'    => '',
  'plain,array,7'    => '',
  'plain,array,8'    => 'eight',
  'plain,hash,1'     => 'foo',
  'plain,hash,alpha' => 'a',
  'plain,hash,beta'  => 'b',
  'plain,hash,delta' => 'd'
 );


my %expected_multi_paths = (
  'multi,0'          => '',
  'multi,1'          => 'one',
  'multi,2'          => 'two',
  'multi,3'          => 'three',
  'multi,4'          => '',
  'multi,5'          => 'five',
  'multi,6'          => '',
  'multi,7'          => '',
  'multi,8'          => 'eight',
 );

my %expected_all_paths = (%expected_plain_paths, %expected_multi_paths);

# NOTE: 'multi,alpha', 'multi,beta', etc. are not in %expected_all_paths -- this is normal,
# array subtrees are tried first, then hash subtrees are ignored.



my %expected_multi_4 = (
  'multi,1' => 'one',
  'multi,2' => 'two',
  'multi,3' => 'three',
  'multi,4' => '',
 );



# test exceptions
sub dies_ok (&$;$) {
  my ($coderef, $regex, $message) = @_;
  eval {$coderef->()};
  like $@, $regex, $message;
}



my %args = ( array => ['', 'one', 'two', 'three', '', 'five', '', '', 'eight'],
             hash  => {alpha => 'a', beta => 'b', delta => 'd', 1 => 'foo'} );

my $multi = Object::MultiType->new(%args);

my $tree = {plain => \%args, multi => $multi};


is(reach($tree, qw/plain array 1/), 'one',   'defaults plain array 1');
is(reach($tree, qw/multi 0/), '',            'defaults multi 0');
is(reach($tree, qw/multi 1/), 'one',         'defaults multi 1');
is(reach($tree, qw/multi alpha/), 'a',       'defaults multi alpha');

my %all_paths  = map_paths {join(",", @_) => $_} $tree;
is_deeply(\%all_paths, \%expected_all_paths, 'defaults all_paths');


%all_paths = ();
my $next_path = each_path $tree;
while (my ($path, $leaf) = $next_path->()) {$all_paths{join ",", @$path} = $leaf}
is_deeply(\%all_paths, \%expected_all_paths, 'defaults each_path');


{ no Data::Reach qw/peek_blessed/;

  # cannot peek into objects, but can use overloaded methods

  is(reach($tree, qw/plain array 1/), 'one',   'no peek_blessed plain array 1');
  is(reach($tree, qw/multi 0/), '',            'no peek_blessed multi 0');
  is(reach($tree, qw/multi 1/), 'one',         'no peek_blessed multi 1');
  is(reach($tree, qw/multi alpha/), 'a',       'no peek_blessed multi alpha');

  %all_paths  = map_paths {join(",", @_) => $_} $tree;
  is_deeply(\%all_paths, \%expected_all_paths, 'no peek_blessed all_paths');

  %all_paths = ();
  my $next_path = each_path $tree;
  while (my ($path, $leaf) = $next_path->()) {$all_paths{join ",", @$path} = $leaf}
  is_deeply(\%all_paths, \%expected_all_paths, 'no peek_blessed each_path');
}



{ no Data::Reach qw/peek_blessed use_overloads/;

  # overloaded methods are disallowed

  is(reach($tree, qw/plain array 1/), 'one',            'no peek_blessed no use_overloads plain array 1');
  dies_ok {reach($tree, qw/multi 0/)} qr/cannot reach/, 'no peek_blessed no use_overloads multi 0';

  %all_paths = map_paths {join(",", @_) => $_} $tree;
  my $path_multi = delete $all_paths{multi};
  is_deeply(\%all_paths, \%expected_plain_paths, 'no peek_blessed no use_overloads all_paths');
  isa_ok($path_multi, 'Object::MultiType',       'no peek_blessed no use_overloads opaque object');


  %all_paths = ();
  my $next_path = each_path $tree;
  while (my ($path, $leaf) = $next_path->()) {$all_paths{join ",", @$path} = $leaf}
  $path_multi = delete $all_paths{multi};
  is_deeply(\%all_paths, \%expected_plain_paths, 'no peek_blessed no use_overloads each_path');
  isa_ok($path_multi, 'Object::MultiType',       'no peek_blessed no use_overloads opaque object');
}





{ no Data::Reach  qw/peek_blessed use_overloads/;
  use Data::Reach reach_method => 'dig', paths_method => 'grab';

  no warnings 'once';
  *{Object::MultiType::dig} = sub {
    my ($self, $k) = @_;
    return $k =~ /^-?\d+$/ ? $self->[$k] : $self->{$k};
  };
  *{Object::MultiType::grab} = sub { return (1 .. 4)};


  is(reach($tree, qw/plain array 1/), 'one', 'reach_method plain array 1');
  is(reach($tree, qw/multi 0/), '',          'reach_method multi 0');
  is(reach($tree, qw/multi 1/), 'one',       'reach_method multi 1');
  is(reach($tree, qw/multi alpha/), 'a',     'reach_method multi alpha');

  %all_paths = map_paths {join(",", @_) => $_} $tree;
  delete $all_paths{$_} for grep {/^plain/} keys %all_paths;
  is_deeply(\%all_paths, \%expected_multi_4, 'map_paths paths_method multi');

  %all_paths = ();
  my $next_path = each_path $tree;
  while (my ($path, $leaf) = $next_path->()) {$all_paths{join ",", @$path} = $leaf}
  delete $all_paths{$_} for grep {/^plain/} keys %all_paths;
  is_deeply(\%all_paths,  \%expected_multi_4, 'each_path paths_method multi');
}


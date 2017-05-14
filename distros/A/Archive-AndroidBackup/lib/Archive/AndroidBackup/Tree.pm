package Archive::AndroidBackup::Tree;
use Moose;

our $VERSION = '1.3';

=head1 NAME

  Archive::AndroidBackup::Tree

=head1 SYNOPSIS

  my $trunk = Tree->new;
  $trunk->node('root');
  $trunk = $trunk->get_or_add_child('branch.1');
  $trunk = $trunk->get_or_add_child('branch.1');

=head1 DESCRIPTION

  There are many other more mature implementations of trees out there
  Tree, Tree::Fast, Tree::Simple, Forrest::Tree and I can't think of a reason that makes mine better
  I just wanted to spend the time writing a tree class with moose using weak refs and attribute traits

=cut

has 'node' => (
  is => 'rw',
  isa => 'Any',
  predicate => 'has_node',
  lazy => 1,
  default => sub { die "cannot initialize node with no value";} ,
);

has 'root' => (
  is => 'ro',
  isa => 'Archive::AndroidBackup::Tree',
  weak_ref    => 1,
  lazy => 1,
  default => sub {
    my $leaf = shift;
    while ($leaf->has_parent) {
      $leaf = $leaf->parent;
    }
    $leaf;
  },
);

has 'level' => (is => 'rw', isa => 'Num', default => 0);

after 'node' => sub {
  my ($self, $value) = @_;
  
  $self->set_sibling($self->node => $self) if $self->has_parent and defined $value;
};

has 'parent' => (
    is          => 'ro',
    isa         => 'Archive::AndroidBackup::Tree',
    weak_ref    => 1,
    predicate   => 'has_parent',
    handles     => {
      parent_node => 'node',
      siblings    => 'children',
      set_sibling => 'set_child',
      }
    );

has '_children' => (
    traits  => ['Hash'],
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
      children => 'values',
      child_nodes => 'keys',
      total_children => 'count',
      has_no_children => 'is_empty',
      get_child => 'get',
      set_child => 'set',
      orphan_child => 'delete',
      has_child_node => 'exists',
    },
    );

sub has_children
{
  my $self = shift;
  not $self->has_no_children;
}

=head2 add_child(;$node)

  add a new child to tree

=cut
sub add_child
{
  my ($self, $node) = @_;

  my $class = (ref $self)? ref $self : $self;
  my $branch = $class->new( parent => $self );
  $branch->level($self->level + 1);
  if (defined $node) {
    $branch->node($node);
  }
  $branch;
}

=head2 get_or_add_child($node);

  adds a child with $node as its data or get an existing child 
  returns an un-intialized orphan if node is undef
    *this will be added to the family upon setting node

=cut

sub get_or_add_child {
  my ($self,$key) = @_;

  my ($child) = (undef);
  if (defined $key) {
    if ($self->has_child_node($key)) {

      $child = $self->get_child($key);
    } else {
      $child = $self->add_child($key);
    }
  } else {
    print "child with no node\n";
    $child = $self->add_child;
  }
  return $child;
}

=head2 node_as_string()

  represent node value as string

=cut
sub node_as_string
{
  my $self = shift;
#  sprintf "%*s%s", $self->level * 4, "", $self->node;
  my @ancestors = ($self->node);
  my $branch = $self;
  while ($branch->has_parent) {
    $branch = $branch->parent;
    unshift @ancestors, $branch->node;
  }
  return join('/', @ancestors);
} 

=head2 as_string

  print node via node_as_string, then recurse to children

=cut
sub as_string {
  my $self = shift;
  my @out = ( $self->node_as_string );
  foreach my $child ($self->children) {
    push @out, $child->as_string;
  }
  return join("\n", @out); 
}

sub traverse_breadth
{
  my $self = shift;
  my @q =( $self );
  my @resultSet;
  while ($#q >= 0) {
    my $node = shift @q;

    push @resultSet, $node;

    @q = (@q, $node->children);

  }
  @resultSet;
}


=head2 traverse_depth(;sortCallback)

  returns array of nodes with a depth first search
  if a sort function is passed, every node's children will be sorted prior to recursion

  to perform a search while sorting on first the existence of grand children
  then alphabetically on node's value

  my $sortFunc = sub($$) {
      $_[0]->has_children <=> $_[1]->has_children
        ||
      $_[0]->node cmp $_[1]->node;
    };
  
  my @list = grep {
    /(some|keyword)/
  } map {
    $_->node_as_string
  } $self->traverse_depth($sortFunc);

=cut
sub traverse_depth
{
  my ($self, $sortFunc ) = @_;
  my @resultSet;
  my $branch = $self;

  push @resultSet, $branch;

  my @children = $branch->children;
  if (defined $sortFunc) {
    @children = sort $sortFunc @children;
  }
  foreach my $child (@children) {
    @resultSet = (@resultSet, $child->traverse_depth($sortFunc));
  }
  @resultSet;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

package Archive::AndroidBackup::Tree;
use Moose;

=head1 NAME

  Archive::AndroidBackup::Tree

  I admit there are many other more mature implementations of trees out there
  Tree, Tree::Fast, Tree::Simple, Forrest::Tree and I can't think of a reason that makes mine better

=head1 SYNOPSIS

  my $trunk = Tree->new;
  $trunk->node('root');
  $trunk = $trunk->get_or_add_child('branch.1');
  $trunk = $trunk->get_or_add_child('branch.1');

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

package Archive::AndroidBackup::DirTree;

=head1 NAME

  DirTree

  subclass of Tree specifically for unix paths

=cut

use Moose;
extends 'Archive::AndroidBackup::Tree';

=head1 METHODS

=head2 build_from_str($unixPath);

  splits on / and add children as appropriate
  ie.  ->build_from_str('apps/com.your.namespace/_manifest');

=cut
sub build_from_str
{
  my ($self, $str) = @_;

  my $trunk = $self;
  foreach my $dirPart (split(/\//, $str)) {
    if (not $trunk->has_node or $trunk->node eq $dirPart) {
      $trunk->node($dirPart);
    } else {
      $trunk = $trunk->get_or_add_child($dirPart);
    }
  }
  $trunk;
}

=head2 build_from_file($fh)

  build tree from STDIN
  ie. ->build_from_file(FileHandle->new_from_fd(0, "r")); 

=cut
sub build_from_file {
  my ($self,$input) = @_;
  $input->isa("IO::Handle") or die "input not IO::handle";

  while (<$input>) {
    chomp;
    $self->build_from_str($_);
  }
}

=head2 node_as_string

  print fully qualified path

=cut
sub node_as_string
{
  my $self = shift;
 
  my $str = ($self->has_parent) ? $self->parent->node_as_string : undef;
  if (defined $str and $self->has_node) {
    return join("/", $str, $self->node);
  } elsif ($self->has_node) {
    return $self->node;
  }
}

package Archive::AndroidBackup::TarIndex;
use Moose;

extends 'Archive::AndroidBackup::DirTree';

our $VERSION = '2.1';

=head1 NAME
  Archive::AndroidBackup::TarIndex

=head1 SYNOPSIS
  
  open (CMD, 'find apps/', '|') || die "no find?!";
  my $tree = new Archive::AndroidBackup::TarIndex;
  while (<CMD>) { 
    chomp;
    $tree->build_from_str($_);
  };
  print $tree->as_string;

=cut

has namespace => (
  is => 'rw',
  isa => 'Str',
  predicate => 'has_namespace',
  lazy => 1,
  default => sub { ''; },
);

sub as_array
{
  my $self = shift;
  return "invalid android backup: missing _manifest"
    unless ($self->root->has_namespace);

  #  adb restore will break if you try to 
  #  create an exiting private directory (at least on moto x)
  #
  my $ns = $self->root->namespace;
  my %specialDirs = (
      apps => 0,
      "apps/$ns" => 0,
      "apps/$ns/_manifest" => 0,
      "apps/$ns/a" => 0,
      "apps/$ns/f" => 0,
      "apps/$ns/db" => 0,
      "apps/$ns/ef" => 0,
      "apps/$ns/sp" => 0,
      );
 
  my $sortFunc = sub($$) {
      $_[0]->has_children <=> $_[1]->has_children
        ||
      $_[0]->node cmp $_[1]->node;
    };
  my @files = grep { 
    not exists $specialDirs{$_}
  } map {
    $_->node_as_string
  } $self->traverse_depth($sortFunc);

  unshift @files, "apps/$ns/_manifest";

  return @files;
}

override as_string => sub {
  my $self = shift;

  return join("\n", @{ $self->as_array });
};

=head2 build_from_str

  augments super->build_from_str to
    infer package namespace from _manifest entry,
  *also serve as validation on list of files to have _manifest
=cut
around 'build_from_str' => sub {
  my ($orig, $self, $str) = @_;

  my $leaf = $self->$orig($str);
  if ($leaf->node eq '_manifest') {
     $self->root->namespace($leaf->parent->node);
  }
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;

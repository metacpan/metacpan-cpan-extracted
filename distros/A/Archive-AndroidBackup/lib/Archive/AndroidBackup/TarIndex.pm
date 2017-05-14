package Archive::AndroidBackup::TarIndex;
use Moose;

extends 'Archive::AndroidBackup::DirTree';

our $VERSION = '2.1';

=head1 NAME

  Archive::AndroidBackup::TarIndex

=head1 DESCRIPTION

  build a properly sorted and culled archive manifest for android backup
  will infer namespace from _manifest entry

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

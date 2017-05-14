package Archive::AndroidBackup::DirTree;
use Moose;
extends 'Archive::AndroidBackup::Tree';

our $VERSION = '1.0';

=head1 NAME

  Archive::AndroidBackup::DirTree

=head1 DESCRIPTION

  subclass of Tree specifically to ease use of unix paths

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

no Moose;
__PACKAGE__->meta->make_immutable;
1;

package Pod::Elemental::Transformer::TF_CAPI;
# ABSTRACT: Transformer for TF_CAPI links

use Moose;
use Pod::Elemental::Transformer 0.101620;
with 'Pod::Elemental::Transformer';

use Pod::Elemental::Element::Pod5::Command;

use namespace::autoclean;

has command_name => (
  is  => 'ro',
  init_arg => undef,
);

sub transform_node {
  my ($self, $node) = @_;

  for my $i (reverse(0 .. $#{ $node->children })) {
    my $para = $node->children->[ $i ];
    next unless $self->__is_xformable($para);
    my @replacements = $self->_expand( $para );
    splice @{ $node->children }, $i, 1, @replacements;
  }
}

my $command_dispatch = {
  'tf_capi'     => \&_expand_capi,
  'tf_version'  => \&_expand_version,
};

sub __is_xformable {
  my ($self, $para) = @_;

  return unless $para->isa('Pod::Elemental::Element::Pod5::Command')
         and exists $command_dispatch->{ $para->command };

  return 1;
}

sub _expand {
  my ($self, $parent) = @_;
  $command_dispatch->{ $parent->command }->( @_ );
};

sub _expand_version {
  my ($self, $parent) = @_;
  my @replacements;

  my $content = $parent->content;

  die "Not a version string: $content"
    unless $content =~ /\A v [0-9.]+ \Z/x;

  push @replacements, Pod::Elemental::Element::Pod5::Ordinary->new(
    content => 'C<libtensorflow> version: ' . $content
  );

  return @replacements;
}

sub _expand_capi {
  my ($self, $parent) = @_;
  my @replacements;


  my $content = $parent->content;

  my @ids = split /,\s*/, $content;
  my $doc_name = 'AI::TensorFlow::Libtensorflow::Manual::CAPI';
  my $new_content = "B<C API>: "
    . join ", ", map {
      die "$_ does not look like a TensorFlow identifier" unless /^TF[E]?_\w+$/;
      "L<< C<$_>|$doc_name/$_ >>"
    } @ids;

  push @replacements, Pod::Elemental::Element::Pod5::Ordinary->new(
    content => $new_content,
  );

  return @replacements;
}

1;

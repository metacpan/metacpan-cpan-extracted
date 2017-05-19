package Imager::CommandLine::UntagImages {
  use MooseX::App;
  use ARGV::Struct;
  use CloudDeploy::AMIDB;
  use Data::Printer;
  use v5.10;

  has find_args => (
    is => 'ro',
    isa => 'HashRef[Str]',
    lazy => 1,
    default => sub {
      my $self = shift;
      return ARGV::Struct->new(argv => [ '{', @{ $self->extra_argv }, '}' ])->parse;
    }
  );

  parameter tag => (
    is => 'ro',
    isa => 'Str',
    documentation => 'The tag to assign',
    required => 1,
  );

  sub run {
    my ($self) = @_;

    die "You have to specify a filter to tag an AMI" if (keys %{ $self->find_args } == 0);

    my $db = CloudDeploy::AMIDB->new;

    my $tagged = $db->unset_tag_from($self->tag, %{ $self->find_args });

    foreach (@$tagged) { say "UnTagged $_" }
  }
}

1;


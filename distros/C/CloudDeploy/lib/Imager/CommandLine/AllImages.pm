package Imager::CommandLine::AllImages {
  use MooseX::App;
  use ARGV::Struct;
  use CloudDeploy::AMIDB;
  use CloudDeploy::Config;
  use v5.10;
  use Moose::Util::TypeConstraints;
  use Imager::TabularDisplay;
  
  has find_args => (
    is => 'ro',
    isa => 'HashRef[Str]',
    lazy => 1,
    default => sub {
      my $self = shift;
      return ARGV::Struct->new(argv => [ '{', @{ $self->extra_argv }, '}' ])->parse;
    }
  );

  option cols => (
    is => 'ro',
    isa => 'Str',
    documentation => 'List of comma-separated names of columns to display',
    default => 'Account,Name,Version,ImageId,Tags,Date,Type,Arch,Root'
  );

  has _cols => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub { [ split /,/,shift->cols ] }
  );

  sub run {
    my ($self) = @_;

    my $search = CloudDeploy::AMIDB->new;

    my %criterion = %{ $self->find_args };

    my @res = $search->search(%criterion);

    my @cols = @{ $self->_cols };

    Imager::TabularDisplay::print_table(\@cols, \@res);
  }
}

1;


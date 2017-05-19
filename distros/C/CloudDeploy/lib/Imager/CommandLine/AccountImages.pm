package Imager::CommandLine::AccountImages {
  use MooseX::App;
  use ARGV::Struct;
  use CloudDeploy::AMIDB;
  use CloudDeploy::Config;
  use Imager::TabularDisplay;
  use v5.10;
  use Moose::Util::TypeConstraints;

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
    default => 'Account,Region,Name,ImageId,Tags,Date'
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
    if (not defined $criterion{Account}){
      $criterion{Account} = CloudDeploy::Config->new->account;
    } elsif ($criterion{Account} eq '-') {
      # list for all accounts
      delete $criterion{Account};
    }

    my @res = $search->search(%criterion);

    my @cols = @{ $self->_cols }; 

    my $table = Imager::TabularDisplay::generate_table(\@cols, \@res);
    
    print($table->render, "\n");
  }
}

1;


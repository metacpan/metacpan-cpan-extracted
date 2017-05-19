package Imager::CommandLine::FindImage {
  use MooseX::App;
  use ARGV::Struct;
  use CloudDeploy::AMIDB;
  use Data::Printer;
  use Imager::TabularDisplay;
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

  option cols => (
    is => 'ro',
    isa => 'Str',
    documentation => 'List of comma-separated names of columns to display',
    default => 'Account,Name,ImageId,Tags,Date'
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
    my $image = $search->find(%{ $self->find_args });
	my @res = ( $image );

    my @cols = @{ $self->_cols };

    my $table = Imager::TabularDisplay::generate_table(\@cols, \@res);
    
    print($table->render, "\n");
  }
}

1;


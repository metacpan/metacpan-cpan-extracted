package DBIx::Cookbook::Skinny::Command::fetch_all;
use Moose;
extends qw(MooseX::App::Cmd::Command);

has order_by => (
		 traits => [qw(Getopt)],
		 isa => "Str",
		 is  => "rw",
		);


sub execute {
  my ($self, $opt, $args) = @_;

  my @attr = $opt->{order_by} ? (sort_by => $opt->{order_by} ) : () ;

  use Sakila;
  my $result = Sakila->search(actor => $opt);

  while (my $row = $result->next) {
    use Data::Dumper;
    warn Dumper($row->{row_data});
  }
}

1;

# Another way to get all rows:
# my @rows = Sakila->search...

package DBIx::Cookbook::DBIC::Command::predefined_search;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dump;

has 'starts_with' => (
	       traits => [qw(Getopt)],
	       isa => "Str",
	       is  => "rw",
	       documentation => "first letter(s) that country starts with"
	      );

has 'max_id' => (
	       traits => [qw(Getopt)],
	       isa => "Int",
	       is  => "rw",
	       documentation => "maximum acceptable id"
	      );

sub execute {
  my ($self, $opt, $args) = @_;

  my $rs = $self->app->schema->resultset('Country')->search_country
    ($opt->{starts_with}, $opt->{max_id});


  while (my $row = $rs->next) {
      use Data::Dump qw(dump);
      my %data = $row->get_columns;
      warn dump(\%data);
    }


}

1;

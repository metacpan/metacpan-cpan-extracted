package DBIx::Cookbook::DBIC::Command::distinct_count;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dump;

has 'count' => (
	       traits => [qw(Getopt)],
	       isa => "Bool",
	       is  => "rw",
	       documentation => "count rows"
	      );

sub execute {
  my ($self, $opt, $args) = @_;

  my $rs = do {
    
    my $where = { last_name => { LIKE => 'A%' } } ;
    my $attr = {
		columns =>  [ qw(last_name) ],
		distinct => 1  # or: { group_by => last_name }
	       };

    $self->app->schema->resultset('Actor')->search($where, $attr);
  };

  if ($opt->{count}) {
    warn $rs->count;
  } else {

    while (my $row = $rs->next) {
      use Data::Dump qw(dump);
      my %data = $row->get_columns;
      warn dump(\%data);
    }

  }

}

1;

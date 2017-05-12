package DBIx::Cookbook::DBIC::Command::paged;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dump;

has 'rows' => (
	       traits => [qw(Getopt)],
	       isa => "Int",
	       is  => "rw",
	       documentation => "number of rows per page"
	      );

has 'page' => (
	       traits => [qw(Getopt)],
	       isa => "Int",
	       is  => "rw",
	       documentation => "page to start output from"
	      );


sub execute {
  my ($self, $opt, $args) = @_;


  $opt->{rows} ||= 10;

  my $rs = do {

    my $where = {};
    my $attr = { 
		order_by => 'last_name' ,
		page => $opt->{page} ? $opt->{page} : 1 ,
		rows => $opt->{rows} 
	       };

    $self->app->schema->resultset('Actor')->search($where, $attr);

  } ;

  my $pager = $rs->pager;

  while (my $row = $rs->next) {

    warn $row->first_name . " " . $row->last_name . "\n" ;

  }

  printf "  -- Page %d of %d --\n", $pager->current_page, $pager->last_page;

  if (my $next_page = $pager->next_page) {
    $opt->{page} = $next_page;
    $self->execute($opt);
  }

}

1;

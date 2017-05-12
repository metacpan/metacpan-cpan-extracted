package DBIx::Cookbook::DBIC::Command::subquery;
use Moose;
extends qw(MooseX::App::Cmd::Command);


sub execute {
  my ($self, $opt, $args) = @_;

=for SQL

SELECT * FROM film f 
WHERE film_id 
   IN ( SELECT film_id FROM film_category fc WHERE fc.film_category IN (6,11) );

=cut

# I think a view is much simpler dont you :)

  my $sub_rs = do { 
    my $where = { category_id => [qw/6 11/] } ;
    my $attr = {};
    $self->app->schema->resultset('FilmCategory')->search($where, $attr);
  };

  my $rs = do {
    my $where = { film_id => { IN => $sub_rs->get_column('film_id')->as_query } } ;
    my $attr = {};
    $self->app->schema->resultset('Film')->search($where, $attr);
  };

  while (my $row = $rs->next) {
    use Data::Dumper;
    my %data = $row->get_columns;
    warn Dumper(\%data);
  }
}

1;

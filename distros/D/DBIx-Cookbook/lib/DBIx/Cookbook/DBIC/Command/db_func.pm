package DBIx::Cookbook::DBIC::Command::db_func;
use Moose;
extends qw(MooseX::App::Cmd::Command);

=for NOTE

  the as attribute has absolutely *NOTHING* to do with 
  the SQL syntax  SELECT foo AS bar

  it is used to specify how the columns will be accessed

=cut

sub execute {
  my ($self, $opt, $args) = @_;

  

  my $rs = do {

    my $where = {};
    my $attr = {
		select => [ 'first_name', { LENGTH => 'first_name' } ],
		as     => [ qw/first_name first_name_length/ ]
	       };

    $self->app->schema->resultset('Actor')->search($where, $attr);

  } ;

  while (my $row = $rs->next) {
    use Data::Dumper;
    my %data = $row->get_columns;
    warn Dumper(\%data);
    
  }
}

1;

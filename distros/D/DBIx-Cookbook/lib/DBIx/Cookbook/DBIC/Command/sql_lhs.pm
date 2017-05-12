package DBIx::Cookbook::DBIC::Command::sql_lhs;
use Moose;
extends qw(MooseX::App::Cmd::Command);


sub execute {
  my ($self, $opt, $args) = @_;


  my $rs = do { 

    my $where = { 
		 'YEAR(payment_date)' => 2006,
		 amount => { '<' => 2.50 }
		};
    my $attr  = {};

    $self->app->schema->resultset('Payment')->search($where, $attr);

  };

  while (my $row = $rs->next) {
    use Data::Dumper;
    my %data = $row->get_columns;
    warn Dumper(\%data);
  }
}

1;

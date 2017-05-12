package DBIx::Cookbook::DBIC::Command::complex_where;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dumper;

sub execute {
  my ($self, $opt, $args) = @_;


 $self->app->schema->storage->debug(1);

  my $rs = do {

    my $where = 
      {
       -or => [
	       -and => [
			description => { 'like' , '%drama%' },
			title => { 'like', 'bikini%' }
		       ],
	       title => 'BANG KWAI'
	      ]
      };

    my $attr = { order_by => 'title' };

    $self->app->schema->resultset('Film')->search($where, $attr);

  };

  while (my $row = $rs->next) {
    my %data = $row->get_columns;
    warn Dumper(\%data);
  }

}

1;

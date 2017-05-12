package DBIx::Cookbook::DBIC::Command::grouping;
use Moose;
extends qw(MooseX::App::Cmd::Command);

=for comment

if the $attr below is confusing, see 
http://search.cpan.org/~ribasushi/DBIx-Class-0.08120/lib/DBIx/Class/ResultSet.pm#ATTRIBUTES

=cut

sub execute {
  my ($self, $opt, $args) = @_;

  my $where = {};

  my $attr = {
	      join   => [ 'film_actors' ],
	      select => [ qw/first_name last_name/, { count => 'film_actors.actor_id' } ],
	      as     => [ qw/first_name last_name film_count/ ],
	      group_by => [ 'film_actors.actor_id' ]
	     };

  my $rs = $self->app->schema->resultset('Actor')->search($where, $attr);

  while (my $row = $rs->next) {
    use Data::Dumper;
    my %data = $row->get_columns;
    warn Dumper(\%data);
    
  }
}

1;

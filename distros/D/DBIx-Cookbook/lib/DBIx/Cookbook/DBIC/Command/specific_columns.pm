package DBIx::Cookbook::DBIC::Command::specific_columns;
use Moose;
extends qw(MooseX::App::Cmd::Command);

use Data::Dump;

sub execute {
  my ($self, $opt, $args) = @_;

  my $where = {};
  my $attr = { columns => [qw(first_name last_name)] };
  my $rs = $self->app->schema->resultset('Actor')->search($where, $attr);

  my $row = $rs->first;

  my %data = $row->get_columns;
  warn Data::Dump::dump(\%data);

}

1;

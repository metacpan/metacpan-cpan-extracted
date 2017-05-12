package DBIx::Cookbook::Simple;
use Moose;
extends qw(MooseX::App::Cmd);

has 'simple' => (is => 'rw', lazy_build => 1);


sub _build_simple {
  my ($self)=@_;

  use DBIx::Cookbook::DBH;

  DBIx::Cookbook::DBH::dbh;

}

1;

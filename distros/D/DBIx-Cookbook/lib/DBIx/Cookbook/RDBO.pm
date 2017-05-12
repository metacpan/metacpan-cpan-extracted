package DBIx::Cookbook::RDBO;
use Moose;
extends qw(MooseX::App::Cmd);

use Rose::DB::Object::Helpers qw(as_tree);

1;

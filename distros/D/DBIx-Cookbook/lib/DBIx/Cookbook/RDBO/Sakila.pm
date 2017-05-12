package DBIx::Cookbook::RDBO::Sakila;

# This is a package I manually created so that I could use the helper methods

use base 'Rose::DB::Object';

use DBIx::Cookbook::RDBO::RoseDB;
sub init_db { DBIx::Cookbook::RDBO::RoseDB->new() }

use Rose::DB::Object::Helpers qw(as_tree);

1;


=head1 NAME


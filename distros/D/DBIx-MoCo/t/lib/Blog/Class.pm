package Blog::Class;
use strict;
use warnings;
use base qw 'DBIx::MoCo';
use Blog::DataBase;

__PACKAGE__->db_object('Blog::DataBase');

1;

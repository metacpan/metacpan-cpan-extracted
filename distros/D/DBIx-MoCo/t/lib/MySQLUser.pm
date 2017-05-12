package MySQLUser;
use strict;
use warnings;
use base qw 'DBIx::MoCo';
use MySQLDB;

__PACKAGE__->db_object('MySQLDB');
__PACKAGE__->table('user');

1;

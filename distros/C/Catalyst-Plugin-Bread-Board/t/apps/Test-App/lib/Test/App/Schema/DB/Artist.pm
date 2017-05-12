package Test::App::Schema::DB::Artist;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(qw[
     id
     name
]);
__PACKAGE__->set_primary_key('id');

1;
package Articulate::Storage::DBIC::Simple::Schema::Result::Articulate::Item;
use strict;
use warnings;
use base qw/DBIx::Class::Core/;

__PACKAGE__->table('item');
__PACKAGE__->add_columns(
  meta     => { type => 'string' },
  content  => { type => 'string' },
  location => { type => 'string' },
);

1;

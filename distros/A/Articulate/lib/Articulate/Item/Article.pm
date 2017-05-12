package Articulate::Item::Article;
use strict;
use warnings;

use Moo;
extends 'Articulate::Item';

#with 'Articulate::Role::Item::Format';

sub original_format {
  shift->_meta_accessor('schema/core/originalFormat')->(@_);
}

sub article_id {
  my $self = shift;
  $self->location->[-1];
}

1;

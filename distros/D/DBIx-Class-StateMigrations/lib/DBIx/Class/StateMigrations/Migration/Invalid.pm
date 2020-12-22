package 
  DBIx::Class::StateMigrations::Migration::Invalid;

use strict;
use warnings;

# ABSTRACT: Internal class stand in for an "invalid" migration

use Moo;
use Types::Standard qw(:all);

sub invalid { 1 }
has 'reason', is => 'ro', isa => Str, required => 1;
has 'fatal',  is => 'ro', isa => Bool, default => sub { 0 };

1;

package DB::Pluggable::Role::Initializer;
use strict;
use warnings;
use 5.010;
use Role::Basic;
with qw(Brickyard::Role::Plugin);
requires qw(initialize);
our $VERSION = '1.112001';
1;

=pod

=head1 NAME

DB::Pluggable::Role::Initializer - Something that initializes the plugin system

=head1 IMPLEMENTING

The C<Initializer> role indicates that a plugin wants to do something
when the plugin handler starts to run. The plugin must provide the
C<initialize()> method.

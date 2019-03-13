package do;

use 5.014;

use strict;
use warnings;

use parent 'Data::Object::Config';

our $VERSION = '0.90'; # VERSION

# BUILD
# METHODS

1;

=encoding utf8

=head1 NAME

do

=cut

=head1 ABSTRACT

Minimalist Perl Development Framework

=cut

=head1 SYNOPSIS

  package Cli;

  use do cli;

  has 'user';

  method main(:$args) {
    say "Hello @{[$self->user]}, how are you?";
  }

  method specs(:$args) {
    'user|u=s'
  }

  run Cli;

=cut

=head1 DESCRIPTION

The "do" module is focused on simplicity and productivity. It encapsulates the
Data-Object framework features, is minimalist, and is designed for scripting.

=cut

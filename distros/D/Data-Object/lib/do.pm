package do;

use 5.014;

use strict;
use warnings;

use parent 'Data::Object::Config';

our $VERSION = '0.95'; # VERSION

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

  #!perl

  use do;

  my $phrase = do('cast', 'hello world');

  $phrase->titlecase->say;

=cut

=head1 DESCRIPTION

The "do" module is focused on simplicity and productivity. It encapsulates the
L<Data::Object> framework features, is minimalist, and is designed for
scripting.

=cut

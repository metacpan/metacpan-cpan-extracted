package Acme::Frog;
# ABSTRACT: An amphibian wrapper around Carp

use strict;
use warnings;

use Carp ();

use Exporter qw(import);

our @EXPORT = qw(ribbit croak);

*ribbit = \&Carp::carp;
*croak = \&Carp::croak;

1;
__END__

=head1 NAME

Acme::Frog - An amphibian wrapper around L<Carp>

=head1 SYNOPSIS

  use Acme::Frog;

  ribbit("Something went wrong!"); # Carp::carp(...)

  croak("Something went really wrong!"); # Carp::croak(...)

=head1 DESCRIPTION

L<Acme::Frog> is a simple amphibian wrapper around L<Carp>, providing
access to L<Carp/carp> through L</ribbit> and L<Carp/croak> through
L</croak>.

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=cut

=head1 NAME

Acme::CuckooMith - lays an egg in another bird's nest

=head1 DESCRIPTION

This modules is a basic test to see if it is possible to have the toolchain
recognize a module under one name, while the actual distribution installs it
under a completely different name, as well as seamlessly loads it under a
different package name in Perl.

If successful this will be a proof-of-concept of forking a module into a
different public name, while still providing the end user most of the advantages
of having the code in the original namespace.

=cut

# ABSTRACT: lays an egg in another bird's nest

use strictures 2;
package Acme::CuckooMith;
$INC{ do { $_ = __PACKAGE__; s|::|/|g; "$_.pm" } } = 1;

our $VERSION = 41;

package #
  DBIx::Class;

our $VERSION = 42;

1;

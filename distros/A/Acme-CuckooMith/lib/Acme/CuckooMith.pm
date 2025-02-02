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

Preliminary result: Even under the Acme namespace there are plenty smokers who
will result alse fails because of this. The correct solution in the future will
be to install the modules into a harmless sub-path of lib which can then either
be added to @INC via a module, or copied over into the proper location via user
action.

=cut

# ABSTRACT: lays an egg in another bird's nest

package Acme::CuckooMith;

our $VERSION = 42;

1;

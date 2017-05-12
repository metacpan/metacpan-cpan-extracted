package Clustericious::Command::generate;

use strict;
use warnings;
use Mojo::Base 'Mojolicious::Command::generate';

# ABSTRACT: Clustericious code generation commands.
our $VERSION = '1.24'; # VERSION


has namespaces =>
      sub { [qw/Clustericious::Command::generate
                Mojolicious::Command::generate
                Mojo::Command::generate/] };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Clustericious::Command::generate - Clustericious code generation commands.

=head1 VERSION

version 1.24

=head1 SYNOPSIS

 % clustericious generate app MyApp
 % clustericious generate client MyApp

=head1 DESCRIPTION

This is the base class for all Clustericious code generation commands.
It inherits from L<Mojolicious::Command::generate> instead of
L<Clustericious::Command>.

=head1 SEE ALSO

L<Clustericious>

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

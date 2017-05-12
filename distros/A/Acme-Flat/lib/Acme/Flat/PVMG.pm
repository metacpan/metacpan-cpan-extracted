use 5.006;
use strict;
use warnings;

package Acme::Flat::PVMG;

# ABSTRACT: A Value with Magic

our $VERSION = '0.001001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY
use parent qw( Acme::Flat::PVNV );
use Class::Tiny;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Flat::PVMG - A Value with Magic

=head1 VERSION

version 0.001001

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

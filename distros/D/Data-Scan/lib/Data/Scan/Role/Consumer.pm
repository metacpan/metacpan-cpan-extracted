use strict;
use warnings FATAL => 'all';

package Data::Scan::Role::Consumer;
use Moo::Role;

# ABSTRACT: Data::Scan consumer role

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


requires 'dsstart';
requires 'dsopen';
requires 'dsread';
requires 'dsclose';
requires 'dsend';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Scan::Role::Consumer - Data::Scan consumer role

=head1 VERSION

version 0.009

=head1 DESCRIPTION

This the role that every consumer used by L<Data::Scan> must provide. Please refer to L<Data::Scan> for the expected methods signature and return value.

=head1 REQUIRED SUBROUTINES/METHODS

=head2 dsstart

Implementation that will be called when the scanning is starting.

=head2 dsopen

Implementation that will be called when an unfolded content is opened.

=head2 dsread

Implementation that will be called when any item is looked at.

=head2 dsclose

Implementation that will be called when an unfolded content is closed.

=head2 dsend

Implementation that will be called when the scanning is ending.

=head1 SEE ALSO

L<Data::Scan>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

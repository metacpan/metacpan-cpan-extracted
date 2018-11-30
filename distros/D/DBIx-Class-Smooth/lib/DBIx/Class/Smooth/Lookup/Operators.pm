use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0101';

use parent qw/
    DBIx::Class::Smooth::Lookup::Operators::gt
    DBIx::Class::Smooth::Lookup::Operators::gte
    DBIx::Class::Smooth::Lookup::Operators::lt
    DBIx::Class::Smooth::Lookup::Operators::lte
    DBIx::Class::Smooth::Lookup::Operators::in
    DBIx::Class::Smooth::Lookup::Operators::like
    DBIx::Class::Smooth::Lookup::Operators::not_in
/;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::Operators - Short intro

=head1 VERSION

Version 0.0101, released 2018-11-29.

=head1 SOURCE

L<https://github.com/Csson/p5-DBIx-Class-Smooth>

=head1 HOMEPAGE

L<https://metacpan.org/release/DBIx-Class-Smooth>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

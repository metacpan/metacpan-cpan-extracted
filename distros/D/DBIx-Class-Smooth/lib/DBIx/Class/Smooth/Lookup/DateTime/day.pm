use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::day;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0102';

use parent 'DBIx::Class::Smooth::Lookup::DateTime::datepart';
use experimental qw/signatures postderef/;

sub smooth__lookup__day($self, $column_name, $value, @rest) {
    return $self->smooth__lookup__datepart($column_name, $value, ['day_of_month']);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::DateTime::day - Short intro

=head1 VERSION

Version 0.0102, released 2019-12-22.

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

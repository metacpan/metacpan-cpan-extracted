use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Operators::in;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0108';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use experimental qw/signatures postderef/;

sub smooth__lookup__in($self, $column, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_arrayref('in', $value);

    return { sql_operator => 'IN', operator => '-in', value => $value };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::Operators::in - Short intro

=head1 VERSION

Version 0.0108, released 2020-11-29.

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

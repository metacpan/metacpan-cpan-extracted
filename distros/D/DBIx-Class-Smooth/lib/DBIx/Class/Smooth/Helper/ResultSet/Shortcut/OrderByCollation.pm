use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Helper::ResultSet::Shortcut::OrderByCollation;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0108';

use parent 'DBIx::Class::Smooth::ResultSetBase';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

# This only expects calls like ->order_by_collation('utf8mb4_swedish_ci', 'name', '!other_name')
sub order_by_collation($self, $collation, @column_names) {

    if(!defined $collation) {
        return $self->order_by(@column_names);
    }

    my $sql_order_by_args = join ', ' => map { $self->smooth__helper__orderbycollation__prepare_for_sql($collation, $_) } @column_names;

    return $self->search(undef, { order_by => \$sql_order_by_args });
}

# This is based on DBIx::Class::Helper::ResultSet::Shortcut::OrderByMagic::order_by
sub smooth__helper__orderbycollation__prepare_for_sql($self, $collation, $column_name) {
    my $direction = 'ASC';
    if(substr($column_name, 0, 1) eq '!') {
        $column_name = substr $column_name, 1;
        $direction = 'DESC';
    }

    if(index($column_name, '.') == -1) {
        $column_name = join '.' => ($self->current_source_alias, $column_name);
    }

    return "$column_name COLLATE $collation $direction";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Helper::ResultSet::Shortcut::OrderByCollation - Short intro

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

use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::ident;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0108';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup__ident($self, $column, $value, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('ident', $value);

    return { operator => '-ident', value => $self->result_source->storage->sql_maker->_quote($value) };

    my($possible_relation, $possible_column) = split /\./, $value;
    $possible_relation = undef if $possible_relation eq 'me';

    if($possible_relation && $possible_column) {
        if($self->result_source->has_relationship($possible_relation)) {
            if($self->result_source->relationship_info($possible_relation)->{'class'}->has_column($possible_column)) {
                $value = "$possible_relation.$possible_column";
            }
            else {
                confess "<ident> got '$value'; column '$possible_column' does not exist in '$possible_relation";
            }
        }
        else {
            confess "<ident> got '$value', relation '$possible_relation' does not exist in the current result source (@{[ $self->result_class ]})";
        }
    }
    else {
        $possible_column = $possible_relation if !$possible_column;
        if($self->result_source->has_column($possible_column)) {
            $value = $self->current_source_alias . ".$possible_column";
        }
        else {
            confess "<ident> got '$value', column '$possible_column' does not exist in the current result source (@{[ $self->result_class ]})";
        }
    }

    return { sql_operator => '=', value => $self->result_source->storage->sql_maker->_quote($value), quote_value => 0 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::ident - Short intro

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

use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::substring;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0103';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup__substring($self, $column_name, $value, $params, @rest) {
    $self->smooth__lookup_util__ensure_value_is_scalar('substring', $value);
    $self->smooth__lookup_util__ensure_param_count('substring', $params, { at_least => 1, at_most => 2, regex => qr/^\-?\d+$/ });

    if(scalar $params->@* < 1 || scalar $params->@* > 2) {
        confess sprintf 'substring expects one or two params, got <%s>', join (', ' => $params->@*);
    }
    my @secure_params = grep { /^\-?\d+$/ } $params->@*;
    if(scalar @secure_params != scalar $params->@*) {
        confess sprintf 'substring got faulty params: <%s>', join (', ' => $params->@*);
    }

    my $param_string = join ', ' => @secure_params;

    return { left_hand_function => { start => 'SUBSTRING(', end => ", $param_string)" } , value => $value };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::substring - Short intro

=head1 VERSION

Version 0.0103, released 2020-05-31.

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

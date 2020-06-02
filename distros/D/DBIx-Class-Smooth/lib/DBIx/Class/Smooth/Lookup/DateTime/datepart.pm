use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::DateTime::datepart;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0103';

use parent 'DBIx::Class::Smooth::Lookup::Util';
use Carp qw/carp confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup__datepart($self, $column_name, $value, $params, @rest) {
    $self->smooth__lookup_util__ensure_param_count('substring', $params, { at_least => 1, at_most => 1, regex => qr/^[a-z_]+$/i });

    my $datepart = $params->[0];

    local $SIG{'__WARN__'} = sub ($message) {
        if($message =~ m{uninitialized value within %part_map}) {
            confess "<datepart> was passed <$datepart> as the datepart, but your database don't support that";
        }
        else {
            warn $message;
        }
    };

    my $complete = $self->dt_SQL_pluck({ -ident => $column_name }, $datepart);

    my $function_call_string = $complete->$*->[0];

    return { left_hand_function => { complete => $function_call_string }, value => $value };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::DateTime::datepart - Short intro

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

use 5.20.0;
use strict;
use warnings;

package DBIx::Class::Smooth::Lookup::Util;

# ABSTRACT: Short intro
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0105';

use parent qw/
    DBIx::Class::Smooth::ResultSetBase
/;
use Carp qw/confess/;
use experimental qw/signatures postderef/;

sub smooth__lookup_util__ensure_value_is_arrayref($self, $lookup_name, $value) {
    if(ref $value ne 'ARRAY') {
        confess sprintf '<%s> expects an array, got <%s>', $lookup_name, $value;
    }
}

sub smooth__lookup_util__ensure_value_is_scalar($self, $lookup_name, $value) {
    if(ref $value) {
        confess sprintf '<%s> expects a scalar, got a <%s>', $lookup_name, ref($value);
    }
}

sub smooth__lookup_util__ensure_param_count($self, $lookup_name, $params, $ensure_options) {
    my $at_least = delete $ensure_options->{'at_least'} || 0;
    my $at_most = delete $ensure_options->{'at_most'} || 10000;
    my $regex = delete $ensure_options->{'regex'} || undef;

    if(keys $ensure_options->%*) {
        confess sprintf "Unexpected keys <%s>", join(', ', sort keys $ensure_options->%*);
    }

    if(scalar $params->@* < $at_least || scalar $params->@* > $at_most) {
        confess sprintf "<%s> expects between $at_least and $at_most params, got %d: <%s>", $lookup_name, scalar ($params->@*), join (', ' => $params->@*);
    }

    if($regex) {
        my @correct_params = grep { /$regex/ } $params->@*;
        if(scalar @correct_params != scalar $params->@*) {
            confess sprintf '<%s> got faulty params, check documentation: <%s>', $lookup_name, join (', ' => $params->@*);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::Smooth::Lookup::Util - Short intro

=head1 VERSION

Version 0.0105, released 2020-09-20.

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

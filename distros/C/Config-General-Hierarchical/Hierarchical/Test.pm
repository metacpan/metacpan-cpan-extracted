# Config::General::Hierarchical::Test.pm - Hierarchical Generic Config Test Module

package Config::General::Hierarchical::Test;

$Config::General::Hierarchical::Test::VERSION = 0.07;

use strict;
use warnings;

use base 'Config::General::Hierarchical';

sub syntax {
    my ($self) = @_;
    my %constraint = (
        array => 'aI',
        node  => {
            array => 'a',
            key   => 'u',
            value => '',
        },
        value => 'N',
    );
    return $self->merge_values( \%constraint, $self->SUPER::syntax );
}

our $count = 0;

sub DESTROY {
    $count++;
}

1;

__END__

=head1 NAME

Config::General::Hierarchical::Test - Hierarchical Generic Config Test Module

=head1 DESCRIPTION

This module is used by L<Config::General::Hierarchical> tests.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007-2009 Daniele Ricci

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Daniele Ricci <icc |AT| cpan.org>

=head1 VERSION

0.07

=cut

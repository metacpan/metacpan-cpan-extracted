package Acme::Resume::Internal;

# ABSTRACT: Moops wrapper for internal use
our $VERSION = '0.0105';

use strict;
use warnings;

use base 'MoopsX::UsingMoose';

use Types::Standard();
use Types::URI();
use Acme::Resume::Types();

sub import {
    my $class = shift;
    my %opts = @_;

    push @{ $opts{'imports'} ||= [] } => (
        'Types::Standard' => ['-types'],
        'Types::URI' => ['-types'],
        'Acme::Resume::Types' => [{ replace => 1 }, '-types'],
    );

    $class->SUPER::import(%opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Resume::Internal - Moops wrapper for internal use

=head1 VERSION

Version 0.0105, released 2021-09-29.

=head1 SOURCE

L<https://github.com/Csson/p5-Acme-Resume>

=head1 HOMEPAGE

L<https://metacpan.org/release/Acme-Resume>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

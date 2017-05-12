use 5.10.0;
use strict;
use warnings;

package CairoX::Sweet::Elk;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
# ABSTRACT: Internal Moose
our $VERSION = '0.0200';

use Moose();
use MooseX::AttributeShortcuts();
use namespace::autoclean();
use Moose::Exporter;

Moose::Exporter->setup_import_methods(also => ['Moose']);

sub init_meta {
    my $class = shift;

    my %params = @_;
    my $for_class = $params{'for_class'};
    Moose->init_meta(@_);
    MooseX::AttributeShortcuts->init_meta(for_class => $for_class);
    namespace::autoclean->import(-cleanee => $for_class);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CairoX::Sweet::Elk - Internal Moose

=head1 VERSION

Version 0.0200, released 2016-08-22.

=head1 SOURCE

L<https://github.com/Csson/p5-CairoX-Sweet>

=head1 HOMEPAGE

L<https://metacpan.org/release/CairoX-Sweet>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

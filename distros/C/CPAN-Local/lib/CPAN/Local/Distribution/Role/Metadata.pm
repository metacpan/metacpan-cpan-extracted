package CPAN::Local::Distribution::Role::Metadata;
{
  $CPAN::Local::Distribution::Role::Metadata::VERSION = '0.010';
}

# ABSTRACT: Read a distribution's metadata

use strict;
use warnings;

use Dist::Metadata;
use Moose::Role;

has metadata => ( is => 'ro', isa => 'CPAN::Meta', lazy_build => 1 );

sub _build_metadata
{
    my $self = shift;
    return Dist::Metadata->new( file => $self->filename )->meta;
}

1;


__END__
=pod

=head1 NAME

CPAN::Local::Distribution::Role::Metadata - Read a distribution's metadata

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 metadata

L<CPAN::Meta> object representing the distribution's metadata.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


package CPAN::Local::Distribution::Role::NameInfo;
{
  $CPAN::Local::Distribution::Role::NameInfo::VERSION = '0.010';
}

# ABSTRACT: CPAN::DistnameInfo for a distribution

use strict;
use warnings;
use CPAN::DistnameInfo;
use Moose::Role;

has nameinfo => ( is => 'ro', isa => 'CPAN::DistnameInfo', lazy_build => 1 );

sub _build_nameinfo
{
    my $self = shift;
    return CPAN::DistnameInfo->new($self->path);
}

1;


__END__
=pod

=head1 NAME

CPAN::Local::Distribution::Role::NameInfo - CPAN::DistnameInfo for a distribution

=head1 VERSION

version 0.010

=head1 ATTRIBUTES

=head2 nameinfo

L<CPAN::DistnameInfo> object built from the distribution's
L<CPAN::Local::Distribution/path>.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


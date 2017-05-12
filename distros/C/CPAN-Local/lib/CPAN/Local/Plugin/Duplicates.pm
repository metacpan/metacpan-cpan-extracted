package CPAN::Local::Plugin::Duplicates;
{
  $CPAN::Local::Plugin::Duplicates::VERSION = '0.010';
}

# ABSTRACT: Remove duplicates

use strict;
use warnings;

use Moose;
extends 'CPAN::Local::Plugin';
with 'CPAN::Local::Role::Prune';
use namespace::clean -except => 'meta';

sub prune
{
    my ( $self, @distros ) = @_;

    my (%paths, @needed);

    foreach my $distro ( @distros )
    {
        next if $paths{$distro->path}++;
        push @needed, $distro;
    }

    return @needed;
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Local::Plugin::Duplicates - Remove duplicates

=head1 VERSION

version 0.010

=head1 IMPLEMENTS

=over

=item L<CPAN::Local::Plugin::Clean>

=back

=head1 METHODS

=head2 clean

De-dups the distribution list. A distribution is considered a duplicate if
there is already another disribution that will write to the same path.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


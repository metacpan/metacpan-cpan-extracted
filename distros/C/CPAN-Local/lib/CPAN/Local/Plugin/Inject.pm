package CPAN::Local::Plugin::Inject;
{
  $CPAN::Local::Plugin::Inject::VERSION = '0.010';
}

# ABSTRACT: Inject a distribution into the repo

use strict;
use warnings;
use CPAN::Inject;
use Path::Class qw(file);
use Try::Tiny qw(try catch);
use Moose;
extends 'CPAN::Local::Plugin';
with 'CPAN::Local::Role::Inject';
use namespace::clean -except => 'meta';

sub inject
{
    my ( $self, @distros ) = @_;

    my @injected;

    foreach my $distro (@distros)
    {
        my $injector = CPAN::Inject->new(
            sources => $self->root,
            author  => $distro->authorid,
        );

        next unless try { $injector->add( file => $distro->filename ) }
                  catch { $self->log($_) };

        push @injected, $self->create_distribution(
            filename => file( $self->root, $distro->path )->stringify,
            authorid => $distro->authorid,
            path     => $distro->path,
        );
    }

    return @injected;
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Local::Plugin::Inject - Inject a distribution into the repo

=head1 VERSION

version 0.010

=head1 IMPLEMENTS

=over

=item L<CPAN::Local::Plugin::Inject>

=back

=head1 METHODS

=head2 inject

Writes the distributition tarballs to the repository and updates the author
checksums.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


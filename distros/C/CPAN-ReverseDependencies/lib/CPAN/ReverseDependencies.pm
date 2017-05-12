package CPAN::ReverseDependencies;
# ABSTRACT: given a CPAN dist name, find other CPAN dists that use it
$CPAN::ReverseDependencies::VERSION = '0.01';
use 5.006;
use strict;
use warnings;
use Moo;
use Carp;
use MetaCPAN::API;

my $SLICE_SIZE = 100;

has ua => (
           is      => 'ro',
           default => sub { MetaCPAN::API->new() },
          );

sub get_reverse_dependencies
{
    my $self     = shift;
    my $distname = shift;
    my @deps;
    my $offset = 0;
    my @deps_slice;

    do {
        @deps_slice = $self->_get_dependency_slice($distname, $offset);
        push(@deps, @deps_slice);
        $offset += scalar @deps_slice;
    } while (@deps_slice == $SLICE_SIZE);

    return @deps;
}

sub _get_dependency_slice
{
    my $self     = shift;
    my $distname = shift;
    my $offset   = shift;
    my $result;

    eval {

        $result = $self->ua->post('/search/reverse_dependencies/'.$distname,
                {
                    query => {
                        filtered => {
                          query  => { 'match_all' => {} },
                          filter => {
                            and => [
                              { term => { 'release.status'     => 'latest' } },
                              { term => { 'release.authorized' => \1 } },
                            ],
                          },
                        },
                    },
                    size => $SLICE_SIZE,
                    from => $offset,
                });

    };

    if ($@) {
        croak "Failed to get reverse dependencies for $distname: $@";
    }

    my @dists = map { $_->{_source}->{metadata}->{name} } @{ $result->{hits}->{hits} };

    return @dists;
}

1;

=head1 NAME

CPAN::ReverseDependencies - given a CPAN dist name, find other CPAN dists that use it

=head1 SYNOPSIS

 use CPAN::ReverseDependencies;
 
 my $revua = CPAN::ReverseDependencies->new();
 my @deps  = $revua->get_reverse_dependencies('Module-Path');

=head1 DESCRIPTION

B<CPAN::ReverseDependencies> takes the name of a CPAN distribution and
returns a list containing names of other CPAN distributions that have declared
a dependence on the specified distribution.

It uses the L<MetaCPAN|https://www.cpan.org>
L<API|https://github.com/CPAN-API/cpan-api/wiki/API-docs>
to look up the reverse dependencies, so obviously you have to be online
for this module to work.

This module will C<croak> in a number of situations:

=over 4

=item * If you request reverse dependencies for a non-existent distribution;

=item * If you're not online;

=item * If there's a problem with MetaCPAN itself.

=back

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-ReverseDependencies>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


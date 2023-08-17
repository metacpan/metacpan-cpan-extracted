package CPAN::ReverseDependencies;
# ABSTRACT: given a CPAN dist name, find other CPAN dists that use it
$CPAN::ReverseDependencies::VERSION = '0.03';
use 5.006;
use strict;
use warnings;
use Moo;
use Carp;
use MetaCPAN::Client;
use parent 'Exporter';

our @EXPORT_OK = qw/ get_reverse_dependencies /;

has ua => ( is => 'lazy' );

sub _build_ua
{
    return MetaCPAN::Client->new;
}

sub get_reverse_dependencies
{
    my $distname = pop @_;
    my $ua;

    if (@_ == 1) {
        my $self = shift;
        $ua = $self->ua;
    }
    else {
        $ua = MetaCPAN::Client->new();
    }
    my $resultset = $ua->reverse_dependencies($distname);
    my @dependents;

    # If you want more than just the names of
    # the dependent distributions, take this loop
    # and look at the doc of MetaCPAN::Client::Release
    # to see what other information is easily available
    while (my $release = $resultset->next) {
        push(@dependents, $release->distribution);
    }

    return @dependents;
}

1;

=head1 NAME

CPAN::ReverseDependencies - given a CPAN dist name, find other CPAN dists that use it

=head1 SYNOPSIS

 use CPAN::ReverseDependencies qw/ get_reverse_dependencies /;

 my @deps = get_reverse_dependencies('Module-Path');

=head1 DESCRIPTION

B<CPAN::ReverseDependencies> exports a single function,
C<get_reverse_dependencies>,
which takes the name of a CPAN distribution and
returns a list containing names of other CPAN distributions that have declared
a dependence on the specified distribution.

It uses L<MetaCPAN::Client> to look up the reverse dependencies,
so obviously you have to be online for this module to work.
If you want more than just the name of the dependent distributions,
use L<MetaCPAN::Client> directly,
and get the info you need from the L<MetaCPAN::Client::Release>
objects returned by the C<reverse_dependencies> method.

This module will C<croak> in a number of situations:

=over 4

=item * If you request reverse dependencies for a non-existent distribution;

=item * If you're not online;

=item * If there's a problem with MetaCPAN itself.

=back

=head2 OO Interface

The first release had an OO interface, which is supported for backwards compatibility:

 use CPAN::ReverseDependencies;
 
 my $revua = CPAN::ReverseDependencies->new();
 my @deps  = $revua->get_reverse_dependencies('Module-Path');


=head1 REPOSITORY

L<https://github.com/neilb/CPAN-ReverseDependencies>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


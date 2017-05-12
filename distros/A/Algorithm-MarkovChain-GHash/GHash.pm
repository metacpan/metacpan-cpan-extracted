package Algorithm::MarkovChain::GHash;
use strict;
use Algorithm::MarkovChain;
use base 'Algorithm::MarkovChain::Base', 'DynaLoader';
use fields qw(_cstuff);
use DynaLoader;
use vars qw/$VERSION/;

$VERSION = 0.01;

bootstrap Algorithm::MarkovChain::GHash $VERSION;

sub new {
    my $invocant = shift;
    my $class = ref $invocant || $invocant;
    my __PACKAGE__ $self = $class->SUPER::new(@_);
    $self->{_cstuff} = _new_cstuff();
    return $self;
}

sub DESTROY {
    my $self = shift;

    $self->_c_destroy;
    #delete $self->{_cstuff};
}

1;

=head1 NAME

Algorithm::MarkovChain::GHash - Object oriented Markov chain generator, glib/C storage

=head1 SYNOPSIS

 use Algorithm::MarkovChain::GHash;

 my $mc = new Algorithm::MarkovChain::GHash;

See L<Algorithm::MarkovChain> for full details

=head1 DESCRIPTION

This module implements glib storage for Algorithm::MarkovChain.

You'll need C<glib> installed to make this happy.

=head1 HISTORY

This was originally written using Inline, but never released due to
lack of round tuits.  Recently a tuit supply arrived so I converted it
into XS to reduce dependencies.

=head1 BUGS

None known, maybe after I write some tests.

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=cut


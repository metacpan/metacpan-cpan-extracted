package Algorithm::MarkovChain;
use strict;
use warnings;
use Carp;

require v5.6;
our $VERSION = '0.06';

use base 'Algorithm::MarkovChain::Base';
use fields qw( chains totals );

sub new {
    my $invocant = shift;
    my %args = @_;

    my $class = ref $invocant || $invocant;
    my Algorithm::MarkovChain $self = $class->SUPER::new(@_);

    $self->{chains} = {};
    $self->{totals} = {};
    if ($args{chains}) {
        croak "can't use non-hashref as storage"
          unless ref $args{chains} eq 'HASH';

        $self->{chains} = $args{chains};
    }

    return $self;
}


sub increment_seen {
    my Algorithm::MarkovChain $self = shift;
    my ($sequence, $symbol) = @_;

    $self->{totals}{$sequence}++;
    $self->{chains}{$sequence}{$symbol}++;
}


sub get_options {
    my Algorithm::MarkovChain $self = shift;
    my ($sequence) = @_;

    my %res = map {
        $_ => $self->{chains}{$sequence}{$_} / $self->{totals}{$sequence}
    } keys %{ $self->{chains}{$sequence} };

    return %res;
}


sub longest_sequence {
    my Algorithm::MarkovChain $self = shift;

    local $; = $self->{seperator};

    my $l = 0;
    for (keys %{ $self->{chains} }) {
        my @tmp = split $;, $_;
        my $length = scalar @tmp;
        $l = $length if $length > $l;
    }
    return $l;
}


sub sequence_known  {
    my Algorithm::MarkovChain $self = shift;
    my ($sequence) = @_;

    return $self->{chains}{$sequence};
}


sub random_sequence {
    my Algorithm::MarkovChain $self = shift;

    my @h = keys %{ $self->{chains} };
    return $h[ rand @h ];
}


1;
__END__

=head1 NAME

Algorithm::MarkovChain - Object oriented Markov chain generator

=head1 SYNOPSIS

  use Algorithm::MarkovChain;

  my $chain = Algorithm::MarkovChain::->new();

  # learn about things from @symbols
  $chain->seed(symbols => \@symbols,
               longest => 6);

  # attempt to tell me something about the sky
  my @newness = $chain->spew(length   => 20,
                             complete => [ qw( the sky is ) ]);

=head1 DESCRIPTION

Algorithm::MarkovChain is an implementation of the Markov Chain
algorithm within an object container.

It is implemented as a base class, C<Algorithm::MarkovChain::Base>,
with storage implementations of a hash (C<Algorithm::MarkovChain>),
and an fairly memory efficent implementation using C<glib>
(C<Algorithm::MarkovChain::GHash>).  DBI and MLDBM-friendly versions
are planned.

Deriving alternate representations is intended to be straightforward.

=head1 METHODS

=over

=item Algorithm::MarkovChain::->new() or $obj->new()

Creates a new instance of the Algorithm::MarkovChain class.

Takes one optional parameter: C<recover_symbols>

C<recover_symbols> has meaning if your symbols differ from their true
values when stringifyed.  With this option enabled steps are taken to
ensure that the original values for symbols are returned by the
I<spew> method.


=item $obj->seed()

Seeds the markov chains from an example symbol stream.

Takes two parameters, one required C<symbols>, one optional C<longest>

C<symbols> presents the symbols to seed from

C<longest> sets an upper limit on the longest chain to
construct. (defaults to 4)


=item $obj->spew()

Uses the constructed chains to produce symbol streams

Takes four optional parameters C<complete>, C<length>,
C<longest_subchain>, C<force_length>, C<stop_at_terminal> and
C<strict_start>

C<complete> provides a starting point for the generation of output.
Note: the algorithm will discard elements of this list if it does not
find a starting chain that matches it, this is infinite-loop avoidance.

C<length> specifies the minimum number of symbols desired (default is 30)

C<stop_at_terminal> directs the spew to stop chaining at the first
terminal point reached

C<force_length> ensures you get exactly C<length> symbols returned
(note this overrides the behaviour of C<stop_at_terminal>)

C<strict_start> makes the spew operation always take a known start
state rather than selecting a sequence at random

=item $obj->increment_seen($sequence, $symbol)

Increments the seeness of a symbol following a sequence.


=item $obj->recompute($sequence)

Recompute the probabilities for a branch of the tree.  Called towards
the end of the seed operation for 'dirty' sequences.


=head2 $obj->get_options($sequence)

Returns possible next symbols and probablities as a hash.

=back

=head1 TODO

=over 4

=item Documentation

I need to explain Markov Chains, and flesh out the examples some more.

=item Fix bugs/respond to feature requests

Just email me <richardc@unixbeard.net> and I'll hit it with hammers...

=back

=head1 BUGS

Hopefully not, though if they probably arise from my not understanding
Markov chaining as well as I thought I did when coding commenced.

That or they're jst stupid mistakes :)

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 SEE ALSO

perl(1).

=cut

# eww - it's a Base.pm
package Algorithm::MarkovChain::Base;
use strict;
use warnings;
use Carp;

use fields qw(seperator _symbols _recover_symbols _start_states);

sub new {
    my $invocant = shift;
    my %args = @_;

    my $class = ref $invocant || $invocant;
    my Algorithm::MarkovChain::Base $self = fields::new($class);

    $self->{seperator} = $;;
    $self->{_symbols} = {};
    $self->{_recover_symbols} = $args{recover_symbols};

    return $self;
}


sub seed {
    my Algorithm::MarkovChain::Base $self = shift;
    my %args = @_;

    local $; = $self->{seperator};

    croak 'seed: no symbols'  unless $args{symbols};
    croak 'seed: bad symbols' unless ref($args{symbols}) eq 'ARRAY';

    my $longest = $args{longest} || 4;

    our @symbols;
    *symbols = $args{symbols};

    push @{ $self->{_start_states} }, $symbols[0];

    if ($self->{_recover_symbols}) {
        $self->{_symbols}{$_} = $_ for @symbols;
    }

    for my $length (1..$longest) {
        for (my $i = 0; ($i + $length) < @symbols; $i++) {
            my $link = join($;, @symbols[$i..$i + $length - 1]);
            $self->increment_seen($link, $symbols[$i + $length]);
        }
    }
}


sub spew {
    my Algorithm::MarkovChain::Base $self = shift;
    my %args = @_;

    local $; = $self->{seperator};

    my $longest_sequence = $self->longest_sequence()
      or croak "don't appear to be seeded";

    my $length   = $args{length} || 30;
    my $subchain = $args{longest_subchain} || $length;

    my @fin; # final chain
    my @sub; # current sub-chain
    if ($args{complete} && ref $args{complete} eq 'ARRAY') {
        @sub = @{ $args{complete} };
    }

    while (@fin < $length) {
        if (@sub && (!$self->sequence_known($sub[-1]) || (@sub > $subchain))) { # we've gone terminal
            push @fin, @sub;
            @sub = ();
            next if $args{force_length}; # ignore stop_at_terminal
            last if $args{stop_at_terminal};
        }

        unless (@sub) {
            if ($args{strict_start}) {
                our @starts;
                *starts = $self->{_start_states};
                @sub = $starts[rand $#starts];
            }
            else {
                @sub = split $;, $self->random_sequence();
            }
        }

        my $consider = 1;
        if (@sub > 1) {
            $consider = int rand ($longest_sequence - 1);
        }

        my $start = join($;, @sub[-$consider..-1]);

        next unless $self->sequence_known($start); # loop if we missed

        my $cprob;
        my $target = rand;

        my %options = $self->get_options($start);
        for my $word (keys %options) {
            $cprob += $options{$word};
            if ($cprob >= $target) {
                push @sub, $word;
                last;
            }
        }
    }

    $#fin = $length
      if $args{force_length};

    @fin = map { $self->{_symbols}{$_} } @fin
      if $self->{_recover_symbols};

    return @fin;
}


sub increment_seen   { croak "virtual method call" }
sub get_options      { croak "virtual method call" }
sub longest_sequence { croak "virtual method call" }
sub sequence_known   { croak "virtual method call" }
sub random_sequence  { croak "virtual method call" }


1;
__END__

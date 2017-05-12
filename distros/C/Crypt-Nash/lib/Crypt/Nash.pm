package Crypt::Nash;
use strict;

our $DEBUG   = 0;
our $VERSION = 0.1;

=head1 NAME

Crypt::Nash - Implementation of Nash Cryptosystem

=head1 DESCRIPTION

This is a self-synchronizing cipher feedback stream cipher
proposed by John Nash in 1950, just recently declassified.

=head1 NOTES

-- Nash doesn't say anything about the initial state of the bits
  in the system; here we allow an initial state as part of the key
  It would be reasonable and interesting to consider other 
  possibilities, such as having a fixed initial state (all zeros),
  or running the system with "0"'s as input for a while to arrive
  at an initial state, or ... ??

-- We implement the example given in his note.  There is one arrow
  missing a label; we assume here the missing label is a "+".
  We also choose an arbitrary starting state as part of the key.

-- There are many interesting open questions about this system; 
  here are some as ``food for thought'':
  (a) Are there ``weak keys''?  (Keys that shouldn't be used?)
  (b) If the system receives periodic input, it will exhibit
      periodic output.  (E.g. input 001001001001001...)
      What can be said about the periodicities?
  (c) How do different guesses about what Nash intended
      for the starting state affect security?
  (d) How long can a given bit circulate internally?
  (e) Can you figure out the permutations and bit-flips if you are allowed
      to specify inputs to the system, and to reset it to
      the initial state whenever you like?  (Effectively, a
      chosen ciphertext attack)
  (f) Is the output of the system balanced (equal number of 0's and 1's)
      or unbalanced (biased somehow)?

=head1 METHODS

=cut      

  
=head2 new <n>, <red permutation>, <red bits>, <blue permutation>, <blue bits>, <initial permutation>

=over 4

=item n                    - number of state bits (not counting D, P entry point, or output bit)

=item red permutation      - specifies the red permutation: redp[i] says where bit i comes from, in the red permutation

=item red bits             - 1 = complement, 0 = no complement

=item blue permutation     - blue permutation

=item blue bits            - same as for redbits

=item initial permuatation - initial state P[0...n] and P[n+1]=output bit.  P[0] is entry point

=back

=cut
sub new {
    my $class     = shift;
    my $n         = shift;
    my $red_p     = shift;
    my $red_bits  = shift;
    my $blue_p    = shift;
    my $blue_bits = shift;
    my $initial_p = shift;

    use Data::Dumper;
    die "Red p is not $n+2" unless $n+2  == scalar(@$red_p);
    die "Red b is not $n+2" unless $n+2  == scalar(@$red_bits);
    die "Blue p is not $n+2" unless $n+2 == scalar(@$blue_p);
    die "Blue b is not $n+2" unless $n+2 == scalar(@$blue_bits);
    die "Init p is not $n+2" unless $n+2 == scalar(@$initial_p);
    
    return bless {
        n         => $n,
        red_p     => $red_p,
        red_bits  => $red_bits,
        blue_p    => $blue_p,
        blue_bits => $blue_bits,
        p         => $initial_p, 
    }, $class;
}

# advance state for one tick, with input ciphertext bit c.
sub _tick {
    my $self = shift;
    my $c    = shift;
    if (0==$c) {
        # use blue permutation
        # copy P[bluep[[i]] to P[i], complementing if bluebits[i]==1   (a "-" label on the blue arrow)
        $self->{p} = [ map { $self->{p}->[$self->{blue_p}->[$_]] ^ $self->{blue_bits}->[$_] } (0..$self->{n}+1) ];
    } else {
        # use red permutation
        # copy P[redp[[i]] to P[i], complementing if redbits[i]==1   (a "-" label on the red arrow)
        $self->{p} = [ map { $self->{p}->[$self->{red_p}->[$_]] ^ $self->{red_bits}->[$_] } (0..$self->{n}+1) ];
    }
    # entry point of P gets new bit
    $self->{p}->[0] = $c;
    _DEBUG("State: ".$c." ".join("", @{$self->{p}}));
}

=head2 encrypt <bit stream>

Encrypt bitstring, return ciphertext string

=cut
sub encrypt {
    my $self = shift;
    my $bs   = shift;
    my $cs   = [];
    _DEBUG("Encrypt: encrypting string bs = ".join("", @$bs));
    foreach my $b (@$bs) {
        my $c = $b ^ $self->{p}->[-1];
        push @$cs, $c;
        $self->_tick($c);
    }
    _DEBUG("Encrypt: ciphertext string cs = ".join("", @$cs));
    return $cs;
}

=head2 decrypt

Decrypt bitstring, return ciphertext string

=cut
sub decrypt {
    my $self = shift;
    my $cs   = shift;
    my $bs   = [];
    _DEBUG("Decrypt: decrypting string cs = ".join("", @$cs));
    foreach my $c (@$cs) {
        my $b = $self->{p}->[-1] ^ $c;
        $self->_tick($c);
        push @$bs, $b;
    }
    _DEBUG("Decrypt: plaintext string bs = ".join("", @$bs));
    return $bs;
    
}


sub _DEBUG {
    my $mess = shift;
    warn $mess if $DEBUG;
}

=head1 AUTHOR

Python Implementation by Ronald L. Rivest (2/17/2012)

Available here http://courses.csail.mit.edu/6.857/2012/files/nash.py

Perl port by Simon Wistow

=head1 LICENSE

Distributed under the same terms as Perl itself

=cut

1;
package Crypt::PerfectPaperPasswords;

use warnings;
use strict;
use Carp;
use Crypt::Rijndael;
use Digest::SHA256;
use Time::HiRes qw(time);
use Scalar::Util qw(refaddr);

=head1 NAME

Crypt::PerfectPaperPasswords - Steve Gibson's Perfect Paper Passwords

=head1 VERSION

This document describes Crypt::PerfectPaperPasswords version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Crypt::PerfectPaperPasswords;

    my $pass_phrase  = 'Fromage';
    my $ppp          = Crypt::PerfectPaperPasswords->new;
    my $sequence_key = $ppp->sequence_from_key( $pass_phrase );
    my $first        = 1;
    my $count        = 100;
    my @passcodes    = $ppp->passcodes( $first, $count, $sequence_key );

=head1 DESCRIPTION

From L<https://www.grc.com/ppp.htm>

    GRC's "Perfect Paper Passwords" (PPP) system is a straightforward,
    simple and secure implementation of a paper-based One Time Password
    (OTP) system. When used in conjunction with an account name &
    password, the individual "passcodes" contained on PPP's "passcards"
    serve as the second factor ("something you have") of a secure multi-
    factor authentication system.

This is a Perl implementation of the PPP passcode generator.

=head1 INTERFACE 

=head2 C<< new >>

Create a new C<Create::PerfectPaperPasswords> instance. Options may
be passed:

    my $ppp = Crypt::PerfectPaperPasswords->new(
        alphabet => '0123456789abcdef',
        codelen  => 2
    );

The following options are supported:

=over

=item C<alphabet>

The alphabet to use for encoding. Defaults to Steve Gibson's:

    23456789!@#%+=:?abcdefghijkmnopq
    rstuvwxyzABCDEFGHJKLMNPRSTUVWXYZ

The size of the alphabet need not be a power of two.

=item C<codelen>

The number of raw bytes in each passcode. You must have L<Math::BigInt>
installed to handle values greater than 4.

=back

=cut

{
  my %DEFAULT_ARGS;

  BEGIN {
    %DEFAULT_ARGS = (
      alphabet => '23456789!@#%+=:?'
       . 'abcdefghijkmnopqrstuvwxyz'
       . 'ABCDEFGHJKLMNPRSTUVWXYZ',
      codelen => 3,
    );

    for my $method ( keys %DEFAULT_ARGS ) {
      no strict 'refs';
      *{ __PACKAGE__ . '::' . $method } = sub {
        my $self = shift;
        croak "Can't set $method" if @_;
        return $self->{$method};
      };
    }
  }

  sub new {
    my $class = shift;
    my %args = ( %DEFAULT_ARGS, @_ );

    my $alphabet = delete $args{alphabet};

    croak "Alphabet must be at least two characters long"
     unless length( $alphabet ) >= 2;

    my %got = ();
    $got{$_}++ for split //, $alphabet;
    my @dups = sort grep { $got{$_} > 1 } keys %got;
    croak "Duplicate characters in alphabet: ", join( ', ', @dups )
     if @dups;

    my $codelen = delete $args{codelen};

    croak "Code length must be between 1 and 32"
     if $codelen < 1 || $codelen > 32;

    if ( $codelen > 4 && !_got_bigint() ) {
      croak "Please install Math::BigInt to handle code lengths > 4";
    }

    my $self = bless {
      alphabet => $alphabet,
      codelen  => $codelen,
      seed     => time(),
    }, $class;

    croak "Unknown options: ", join( ', ', sort keys %args ), "\n"
     if keys %args;

    return $self;
  }
}

=head2 C<< alphabet >>

Get the alphabet used by this object.

    my $alphabet = $ppp->alphabet;

=head2 C<< codelen >>

Get the code length for this object.

    my $codelen = $ppp->codelen;

=head2 C<< sequence_from_key >>

Generate a sequence key from a passphrase.

    my $seq_key = $ppp->sequence_from_key( 'Fromage' );

=cut

sub sequence_from_key {
  my $self = shift;
  my $key  = shift;

  my $sha = Digest::SHA256::new( 256 );
  $sha->add( $key );
  my $digest = $sha->hexdigest;
  $digest =~ s/\s+//g;
  return $digest;
}

=head2 C<< random_sequence >>

Generate a random sequence key.

    my $seq_key = $ppp->random_sequence;

Relies on the output of C<random_data> for its entropy.

=cut

sub random_sequence {
  my $self = shift;
  return $self->sequence_from_key( $self->random_data );
}

=head2 C<< random_data >>

Returns some random data. This is the entropy source for
C<random_sequence>. This implementation returns a string
that is the concatenation of

=over

=item * The real time (using the microsecond clock)

=item * The next seed value

=item * Address of C<$self>

=item * Address of a newly allocated scalar

=item * Process ID

=back

The seed value is the microsecond time when this object was created and
is incremented by one each time it's used.

For a lot of uses this is probably an adequate entropy source - but I'm
not a cryptographer. If you'd like better entropy consider subclassing
and provding a C<random_data> that reads from /dev/urandom.

=cut

sub random_data {
  my $self = shift;
  return join( ':',
    time(), $self->{seed}++,
    refaddr( $self ),
    refaddr( \my $dummy ), $$ );
}

=head2 C<< passcodes >>

Get an array of passcodes.

    my @passcodes = $ppp->passcodes(1, 70, $seq_key);

The first two arguments are the starting position (1 .. n) and the
number of passcodes to generate.

Returns an array of strings containing the generated passcodes.

=cut

sub passcodes {
  croak "passcodes requires 3 args" unless @_ == 4;
  my ( $self, $first, $count, $sequence ) = @_;

  croak "Sequence must be 64 characters long"
   unless length( $sequence ) == 64;

  my @passcodes = ();

  croak "Starting index is 1" if $first <= 0;
  $first--;

  $first *= $count;

  my $codelen = $self->codelen;

  my $rij = Crypt::Rijndael->new( pack( 'H*', $sequence ),
    Crypt::Rijndael::MODE_ECB );

  while ( @passcodes < $count ) {
    my $pos     = $first * 8 * $codelen;
    my $n       = $pos / 128;
    my $offset  = $pos % 128;
    my $desired = int( $offset / 8 ) + $codelen;
    my $raw     = '';

    for my $j ( 0 .. 1 ) {
      my $n_bits = pack( "V*", "$n" );    # $n_bits .= ;
      $raw .= $rij->encrypt(
        $n_bits . "\0" x ( 16 - length( $n_bits ) % 16 ) );
      last if length( $raw ) >= $desired;
      $n++;
    }

    push @passcodes,
     $self->_alpha_encode( substr( $raw, $offset / 8, $codelen ),
      $codelen );

    $first++;
  }

  return @passcodes;
}

{
  my $GOT_BIGINT;

  sub _got_bigint {
    defined $GOT_BIGINT and return $GOT_BIGINT;
    return $GOT_BIGINT = eval 'use Math::BigInt; 1' ? 1 : 0;
  }
}

sub _alpha_encode {
  my ( $self, $data, $bytes ) = @_;
  my $code;

  if ( _got_bigint() && $bytes > 4 ) {
    # Make a big hex constant
    $code = Math::BigInt->new(
      '0x'
       . join( '',
        map { sprintf( "%02x", ord( $_ ) ) } reverse split //, $data )
    );
  }
  else {
    $code = unpack( 'V', $data . "\0" x ( 4 - length $data ) );
  }

  my $limit = 2**( $bytes * 8 );

  my @alphabet   = split //, $self->alphabet;
  my $code_space = @alphabet;
  my @out        = ();
  my $max        = 1;

  while ( $max < $limit ) {
    push @out, $alphabet[ $code % $code_space ];
    $code = int( $code / $code_space );
    $max *= $code_space;
  }

  return join '', @out;
}

1;
__END__

=head1 CONFIGURATION AND ENVIRONMENT
  
Crypt::PerfectPaperPasswords requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Crypt::Rijndael>

L<Digest::SHA256>

L<Scalar::Util>

L<Time::HiRes>

L<Math::BigInt> (optional)


=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-crypt-perfectpaperpasswords@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

Original Perfect Paper Passwords implementation by Steve Gibson. More details
here:

    http://www.grc.com/ppp.htm

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

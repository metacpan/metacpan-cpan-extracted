package Algorithm::MinPerfHashTwoLevel;
use strict;
use warnings;
our $VERSION = '0.10';
our $DEFAULT_VARIANT = 2;

use Exporter qw(import);

no warnings "portable";
my %constant;
BEGIN {
    %constant= (
        NOT_UTF8 => 0,
         IS_UTF8 => 1,
        WAS_UTF8 => 2,

        UINT64_MAX => 0xFFFFFFFFFFFFFFFF,
        UINT32_MAX => 0xFFFFFFFF,
        INT32_MAX  => 0x7FFFFFFF,
        UINT16_MAX => 0xFFFF,
        UINT8_MAX  => 0xFF,
    );
}
use constant \%constant;

our %EXPORT_TAGS = (
    'all' => [
        '$DEFAULT_VARIANT',
        qw(
            seed_state
            hash_with_state
        ), sort keys %constant
    ],
    'utf8_flags' => [ grep /UTF8/, sort keys %constant],
    'uint_max'   => [ grep /_MAX/, sort keys %constant]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();


require XSLoader;
XSLoader::load('Algorithm::MinPerfHashTwoLevel', $VERSION);

# Preloaded methods go here.

use Carp ();

sub new {
    my ($class,%opts)= @_;
    my $o= bless \%opts, $class;
    $o->{state} = seed_state($o->{seed})
        if $o->{seed};
    $o->{variant}= $DEFAULT_VARIANT unless defined $o->{variant};
    $o->{variant}= int(0+$o->{variant});
    $o->{compute_flags}=0;
    $o->{compute_flags} += 1 if delete $o->{filter_undef};
    $o->{compute_flags} += 2 if delete $o->{deterministic};
    die "Unknown variant '$o->{variant}' in constructor new(), max known is 2"
        if ($o->{variant} > 2);
    return $o;
}

# find a suitable initial seed for
sub _compute_first_level {
    my ($self)= @_;
    my $source_hash= $self->{source_hash};
    my $debug= $self->{debug} ||= 0;

    printf"computing first level hash information for %d keys\n",
        0+keys %$source_hash
        if $debug;

    # find the number of keys we have to deal with
    my $n= $self->{n}= 0+keys %$source_hash;
    my $max_tries= $self->{max_tries} || 100;
    my $min_tries= $self->{min_tries} || 1;


    # Find the base seed and build a map of the keys to the buckets that they will reside in
    SEED1:
    for my $counter ( 1 .. $max_tries ) {
        if (!defined $self->{seed}) {
            $self->{seed}= join "", map { chr(rand 256) } 1 .. 16;
        }
        if (!defined $self->{state}) {
            $self->{state} = seed_state($self->{seed});
        }
        my $buckets= $self->_compute_first_level_inner();
        if ($buckets) {
            return $buckets;
        } else {
            print "seed failed, trying new seed\n" if $debug;
            delete $self->{seed};
            delete $self->{state};
        }
    }
    Carp::confess("This is unexpected. We tried $max_tries times to find a seed with the appropriate properties, and we failed.\n",
        join " ", sort keys(%$source_hash));
}

sub _compute_first_level_inner {
    my ($self)= @_;
    my $debug= $self->{debug};

    printf "checking seed %s => state: %s\n", 
        unpack("H*",$self->{seed}), 
        unpack("H*",$self->{state}), 
        if $debug;

    my $bad_idx= compute_xs($self);
    if ($bad_idx) {
        printf " Index '%d' not solved, new seed required.\n", $bad_idx-1 if $debug;
        return undef;
    }

    return $self->{buckets};
}

sub compute {
    my ($self,$source_hash)= @_;
    $self->{source_hash}= $source_hash if $source_hash;

    return $self->_compute_first_level();
}

sub state {
    return $_[0]->{state};
}

1;
__END__

=head1 NAME

Algorithm::MinPerfHashTwoLevel - construct a "two level" minimal perfect hash

=head1 SYNOPSIS

  use Algorithm::MinPerfHashTwoLevel;
  my $buckets= Algorithm::MinPerfHashTwoLevel->compute(\%source_hash);

=head1 DESCRIPTION

This module implements an algorithm to construct (relatively efficiently) a
minimal perfect hash using the "two level" algorithm. A perfect hash is one
which has no collisions for any keys, a minimal perfect hash has exactly the
same number of buckets as it has keys. The "two level" algorithm involves
computing two hash values for each key. The first is used as an initial lookup
into the bucket array to find a mask value which is used to modify the second
hash value to determine the actual bucket to read from. This module computes
the appropriate mask values.

In this implementation only one 64 bit hash value is computed, but the high
and low 32 bits are used as if there were two hash values. The hash function
used is stadtxhash. (The full 64 bit hash is called h0, the high 32 bits are
called h1, and the low 32 bits are called h2.)

Computing the hash and mask is done in C (via XS).

The process for looking up a value in a two level hash with n buckets is
as follows:

    0. compute the h0 for the key. (giving: h1 = h0 >> 32; h2 = h0 & 0xFFFFFFFF;)
    1. compute idx1 = h1 % n;
    2. find the xor_val for bucket[idx1]
    3. if the xor_val is zero we are done, the key is not in the hash
    4. compute idx2:
        if variant > 0 and int(xor_val) < 0
            idx2 = -xor_val-1
        else
            idx2 = INTHASH(h2 ^ xor_val) % n;
    5. compare the key data associated with bucket[idx2] with the key provided
    6. if they match return the desired value, otherwise the key is not in the hash.

In essence this module performs the task of computing the xor_val for
each bucket such that the idx2 for every element is unique, it does it in C/XS so
that it is fast.

The INTHASH() function used depends by variant, with variant 2 it is:

    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x) * 0x45d9f3b;
    x = ((x >> 16) ^ x);

which is just a simple 32 bit integer hash function I found at
https://stackoverflow.com/a/12996028, but any decent reversible
integer hash function would do. For variant 0 and 1 it is the identity
function. The default is variant 2.

*NOTE* in Perl a given string may have differing binary representations
if it is encoded as utf8 or not. This module uses the same conventions
as Perl itself, which is that keys are stored in their minimal form when
possible, and are only stored in their unicode (utf8) form when they
cannot be downgraded to latin-1. This ensures that the unicode and latin-1
representations of a given string are treated as the same key. This module
deals with this by "normalizing" the keys and values into latin-1, but
tracking the representation as a flag. See key_normalized and key_is_utf8
(and their 'val' equivalents) documented in the construct method.

=head2 METHODS

=over 4

=item new

Construct a new Algorithm::MinPerfHashTwoLevel object. Optional arguments
which may be provided are 'source_hash' which is a hash reference to use
as the source for the minimal perfect hash, 'seed' which is expected to be
a 16 byte string, and 'debug' which is expected to be 0 or 1, as well
as variant, which may be 0, 1 or 2. The default is 2.

=item compute

Compute the buckets for a two level minimal perfect hash. Either operates
on the 'source_hash' passed into the constructor, or requires one to passed
in as an argument.

Returns an array of hashes containing information about each bucket:

          {
            "h1_keys" => 2,
            "h0" => "17713559403787135240",
            "idx" => 0,
            "key" => "\x{103}",
            "key_is_utf8" => 1,
            "key_normalized" => "\304\203",
            "val" => "\x{103}",
            "val_is_utf8" => 1,
            "val_normalized" => "\304\203",
            "xor_val" => 2
          },

The meaning of these keys is as follows:

=over 4

=item h1_keys

The number of keys which collide into this bucket and which are
disambiguated by the 'xor_val' for this bucket.

=item h0

The hash value computed for this key.

=item idx

The index of this bucket.

=item key

The key for this bucket as a perl string. (See key_normalized.)

=item key_is_utf8

Whether this key is encoded as utf8. Will be one of
0 for "not utf8", 1 for "is utf8", and 2 for "was utf8"
meaning the key is stored as latin-1, but will be upgraded
when fetched.

=item key_normalized

The raw bytes of the normalized key. (See key_is_utf8.)

=item val

The value for this bucket as a perl string. (See val_normalized.)

=item val_is_utf8

Whether this key is encoded as utf8. Will be either
0 for "not utf8" or 1 for "is utf8".

=item val_normalized

The raw bytes of the normalized key. (See val_is_utf8).

=item xor_val

The mask to be xor'ed with the second hash (h2) to determine
the actual lookup bucket. If the xor_val for a given bucket
is 0 then the key is not in the hash.

=back

=back

=head2 EXPORT

None by default.

=head1 SEE ALSO

Tie::Hash::MinPerfHashTwoLevel::OnDisk

=head1 AUTHOR

Yves Orton

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Yves Orton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

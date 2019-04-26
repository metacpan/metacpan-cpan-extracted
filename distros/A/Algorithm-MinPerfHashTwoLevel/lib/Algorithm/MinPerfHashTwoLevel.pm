package Algorithm::MinPerfHashTwoLevel;
use strict;
use warnings;
our $VERSION = '0.08';
our $DEFAULT_VARIANT = 1;


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
    'all' => [ qw(
        seed_state
        hash_with_state
    ), sort keys %constant ],
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
    $o->{variant} //= $DEFAULT_VARIANT;
    $o->{variant}= int(0+$o->{variant});
    die "Unknown variant '$o->{variant}' in constructor new()"
        if ($o->{variant} > 1);
    return $o;
}

sub _utf8_normalize {
    my ($str,$downgrade)= @_;
    if (!defined $str) {
        return (undef, 0);
    }
    my $is_utf8;
    if (utf8::is_utf8($str)) {
        $is_utf8= IS_UTF8;
        if ($downgrade) {
            utf8::downgrade($str,1);
            if (!utf8::is_utf8($str)) {
                $is_utf8= WAS_UTF8;
            }
        }
        utf8::encode($str) if $is_utf8 == IS_UTF8;
    } else {
        $is_utf8= NOT_UTF8;
    }
    return ($str, $is_utf8);
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

sub __compute_max_xor_val {
    my ($n,$variant)= @_;
    # if $n is a power of two then flipping higher bits
    # wont change the distribution of the keys, so we set
    # max_xor_val to $n, on the other hand if it is not,
    # then we can set it to UINT32_MAX.
    my $n_bits= sprintf "%b", $n;
    my $n_bits_sum= 0;
    $n_bits_sum += $_ for split //, $n_bits;
    if ($n_bits_sum == 1) {
        return $n;
    } else {
        return $variant ? INT32_MAX : UINT32_MAX;
    }
}

sub _compute_first_level_inner {
    my ($self)= @_;
    my $debug= $self->{debug};
    my $state= $self->{state};

    my $variant= $self->{variant};

    printf "checking seed %s => state: %s\n", 
        unpack("H*",$self->{seed}), 
        unpack("H*",$self->{state}), 
        if $debug;

    my $source_hash= $self->{source_hash};
    my $n= $self->{n};
    my $max_xor_val= __compute_max_xor_val($n,$variant);
    printf "max_xor_val=%d (n=%d)\n",$max_xor_val,$n
        if $debug;

    my %key_to_hash;
    my %hash_to_key;
    my @key_buckets;
    my @h2_buckets;
    foreach my $key (sort keys %$source_hash) {
        my ($normalized_key,$is_utf8)= _utf8_normalize($key,1);
        my $h0= hash_with_state($normalized_key,$state);
        if (defined(my $other_key= $hash_to_key{$h0})) {
            print "collision on full hash '%d' for '%s' and '%s'\n",
                $h0, $key, $other_key if $debug;
            return;
        }
        my $h1= $h0 >> 32;
        my $h2= $h0 & UINT32_MAX;

        $hash_to_key{$h0}= $key;
        $key_to_hash{$key}= $h0;

        my $idx1= $h1 % $n;
        $h2_buckets[$idx1] .= pack "L", $h2;
        push @{$key_buckets[$idx1]}, $key;
    }

    my @buckets;
    my $used_sv= "\0" x $n;

    my @idx1= sort {
            length($h2_buckets[$b]) <=> length($h2_buckets[$a]) ||
            $a <=> $b
        } grep {
            defined $h2_buckets[$_]
        } (0 .. ($n-1));
    my $last_size= -1;
    my $size_count= 0;
    my $used_pos= $variant == 1 ? 0 : undef;

    while (@idx1) {
        my $idx1= shift @idx1;
        my $keys= $key_buckets[$idx1];
        my $num_keys= 0+@$keys;
        if ($debug) {
            if ($last_size != $num_keys) {
                $last_size= $num_keys;
                if ($size_count) {
                    printf " (%d times)\n", $size_count;
                }
                printf "crunching buckets with %d keys", $num_keys;
                $size_count= 0;
            }
            $size_count++;
        }
        my $idx_sv;
        my $xor_val= calc_xor_val($max_xor_val,$h2_buckets[$idx1],$idx_sv,$used_sv,$used_pos);

        if ($xor_val) {
            my @idx2= unpack "L*", $idx_sv;
            foreach my $i (0 .. $#$keys) {
                my $key= $keys->[$i];
                my $val= $source_hash->{$key};
                my $idx2= $idx2[$i];

                substr($used_sv,$idx2,1,"\1");
                my $h1_bucket= $buckets[$idx1] ||= {};
                my $h2_bucket= $buckets[$idx2] ||= {};
                $h1_bucket->{xor_val}= $xor_val;
                $h1_bucket->{h1_keys}= 0+@$keys;
                my ($key_normalized, $key_is_utf8)= _utf8_normalize($key,1);
                my ($val_normalized, $val_is_utf8)= _utf8_normalize($val,0);
                $h2_bucket->{idx}= $idx2;
                $h2_bucket->{key}= $key;
                $h2_bucket->{key_normalized}= $key_normalized;
                $h2_bucket->{key_is_utf8}= $key_is_utf8;

                $h2_bucket->{val}= $val;
                $h2_bucket->{val_normalized}= $val_normalized;
                $h2_bucket->{val_is_utf8}= $val_is_utf8;
                $h2_bucket->{h0}= $key_to_hash{$key};
            }
        } else {
            printf " (%d completed, %d remaining)\nIndex '%d' not solved: %s\n",
                $size_count,0+@idx1,$idx1,join ",", map { "'$_'" } "@$keys"
                if $debug;
            return;
        }
    }

    printf " (%d times)\n", $size_count
        if $debug && $size_count;

    $self->{buckets}= \@buckets;
    return \@buckets;
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

    0. compute the h0 for the key. (h1 = h0 >> 32; h2 = h0 & 0xFFFFFFFF;)
    1. compute idx = h1 % n;
    2. find the xor_val for bucket[idx]
    3. if the xor_val is zero we are done, the key is not in the hash
    4. compute idx 
        if variant == 0 or (int)xor_val > 0
         idx = (h2 ^ xor_val) % n;
        else
         idx = -xor_val-1
    5. compare the key data associated with bucket[idx] with the key provided
    6. if they match return the desired value.

This module performs the task of computing the xor_val for each bucket.

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
a 16 byte string, and 'debug' which is expected to be 0 or 1.

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

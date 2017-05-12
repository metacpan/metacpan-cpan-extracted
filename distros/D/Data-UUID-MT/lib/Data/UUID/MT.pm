use 5.006;
use strict;
use warnings;

package Data::UUID::MT;
our $VERSION = '1.001'; # VERSION

use Config;
use Math::Random::MT::Auto;
use Scalar::Util 1.10 ();
use Time::HiRes ();

# track objects across threads for reseeding
my ($can_weaken, @objects);
$can_weaken = Scalar::Util->can('weaken');
sub CLONE { defined($_) && $_->reseed for @objects }

# HoH: $builders{$Config{uvsize}}{$version}
my %builders = (
  '8' => {
    '1'   =>  ($] ge 5.010 ? '_build_64bit_v1'  : '_build_64bit_v1_old' ),
    '4'   =>  ($] ge 5.010 ? '_build_64bit_v4'  : '_build_64bit_v4_old' ),
    '4s'  =>  ($] ge 5.010 ? '_build_64bit_v4s' : '_build_64bit_v4s_old'),
  },
  '4' => {
    '1'   =>  '_build_32bit_v1',
    '4'   =>  '_build_32bit_v4',
    '4s'  =>  '_build_32bit_v4s',
  }
);

sub new {
  my ($class, %args) = @_;
  $args{version} = 4 unless defined $args{version};
  Carp::croak "Unsupported UUID version '$args{version}'"
    unless $args{version} =~ /^(?:1|4|4s)$/;
  my $int_size = $Config{uvsize};
  Carp::croak "Unsupported integer size '$int_size'"
    unless $int_size == 4 || $int_size == 8;

  my $prng = Math::Random::MT::Auto->new;

  my $self = {
    _prng => $prng,
    _version => $args{version},
  };

  bless $self, $class;

  $self->{_iterator} = $self->_build_iterator;

  if ($can_weaken) {
    push @objects, $self;
    Scalar::Util::weaken($objects[-1]);
  }

  return $self;
}

sub _build_iterator {
  my $self = shift;
  # get the iterator based on int size and UUID version
  my $int_size = $Config{uvsize};
  my $builder = $builders{$int_size}{$self->{_version}};
  return $self->$builder;
}

sub create {
  return shift->{_iterator}->();
}

sub create_hex {
  return "0x" . unpack("H*", shift->{_iterator}->() );
}

sub create_string {
  return join "-", unpack("H8H4H4H4H12", shift->{_iterator}->());
}

sub iterator {
  return shift->{_iterator};
}

sub reseed {
  my $self = shift;
  $self->{_prng}->srand(@_ ? @_ : ());
}

#--------------------------------------------------------------------------#
# UUID algorithm closure generators
#--------------------------------------------------------------------------#

sub _build_64bit_v1 {
  my $self = shift;
  my $gregorian_offset = 12219292800 * 10_000_000;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my ($sec,$usec) = Time::HiRes::gettimeofday();
    my $raw_time = pack("Q>", $sec*10_000_000 + $usec*10 + $gregorian_offset);
    # UUID v1 shuffles the time bits around
    my $uuid  = substr($raw_time,4,4)
              . substr($raw_time,2,2)
              . substr($raw_time,0,2)
              . pack("Q>", $prng->irand);
    vec($uuid, 87, 1) = 0x1;        # force MAC multicast bit on per RFC
    vec($uuid, 13, 4) = 0x1;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

# For Perl < v5.10, can't use "Q>" in pack
sub _build_64bit_v1_old {
  my $self = shift;
  my $gregorian_offset = 12219292800 * 10_000_000;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my ($sec,$usec) = Time::HiRes::gettimeofday();
    my $time_sum = $sec*10_000_000 + $usec*10 + $gregorian_offset;
    my $raw_time = pack("N2", $time_sum >> 32, $time_sum );
    # UUID v1 shuffles the time bits around
    my $irand = $prng->irand;
    my $uuid  = substr($raw_time,4,4)
              . substr($raw_time,2,2)
              . substr($raw_time,0,2)
              . pack("N2", $irand >> 32, $irand);
    vec($uuid, 87, 1) = 0x1;        # force MAC multicast bit on per RFC
    vec($uuid, 13, 4) = 0x1;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

sub _build_32bit_v1 {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    # Adapted from UUID::Tiny
    my $timestamp = Time::HiRes::time();

    # hi = time mod (1000000 / 0x100000000)
    my $hi = int( $timestamp / 65536.0 / 512 * 78125 );
    $timestamp -= $hi * 512.0 * 65536 / 78125;
    my $low = int( $timestamp * 10000000.0 + 0.5 );

    # MAGIC offset: 01B2-1DD2-13814000
    if ( $low < 0xec7ec000 ) {
        $low += 0x13814000;
    }
    else {
        $low -= 0xec7ec000;
        $hi++;
    }

    if ( $hi < 0x0e4de22e ) {
        $hi += 0x01b21dd2;
    }
    else {
        $hi -= 0x0e4de22e;    # wrap around
    }

    # UUID v1 shuffles the time bits around
    my $uuid  = pack( 'NnnNN',
      $low, $hi & 0xffff, ( $hi >> 16 ) & 0x0fff, $prng->irand, $prng->irand
    );
    vec($uuid, 87, 1) = 0x1;        # force MAC multicast bit on per RFC
    vec($uuid, 13, 4) = 0x1;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

sub _build_64bit_v4 {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my $uuid = pack("Q>2", $prng->irand, $prng->irand);
    vec($uuid, 13, 4) = 0x4;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

# For Perl < v5.10, can't use "Q>" in pack
sub _build_64bit_v4_old {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my @irand = ($prng->irand, $prng->irand);
    my $uuid = pack("N4",
      $irand[0] >> 32, $irand[0], $irand[1] >> 32, $irand[1]
    );
    vec($uuid, 13, 4) = 0x4;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

sub _build_32bit_v4 {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my $uuid = pack("N4",
      $prng->irand, $prng->irand, $prng->irand, $prng->irand
    );
    vec($uuid, 13, 4) = 0x4;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

# "4s" is custom "random" with sequential override based on
# 100 nanosecond intervals since epoch
sub _build_64bit_v4s {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my ($sec,$usec) = Time::HiRes::gettimeofday();
    my $uuid = pack("Q>2",
      $sec*10_000_000 + $usec*10, $prng->irand
    );
    # rotate last timestamp bits to make room for version field
    vec($uuid, 14, 4) = vec($uuid, 15, 4);
    vec($uuid, 15, 4) = vec($uuid, 12, 4);
    vec($uuid, 12, 4) = vec($uuid, 13, 4);
    vec($uuid, 13, 4) = 0x4;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

# "4s" is custom "random" with sequential override based on
# 100 nanosecond intervals since epoch
# For Perl < v5.10, can't use "Q>" in pack
sub _build_64bit_v4s_old {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    my ($sec,$usec) = Time::HiRes::gettimeofday();
    my @parts = ($sec*10_000_000 + $usec*10, $prng->irand);
    my $uuid = pack("N4",
      $parts[0] >> 32, $parts[0], $parts[1] >> 32, $parts[1]
    );
    # rotate last timestamp bits to make room for version field
    vec($uuid, 14, 4) = vec($uuid, 15, 4);
    vec($uuid, 15, 4) = vec($uuid, 12, 4);
    vec($uuid, 12, 4) = vec($uuid, 13, 4);
    vec($uuid, 13, 4) = 0x4;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}


# "4s" is custom "random" with sequential override based on
# 100 nanosecond intervals since epoch
sub _build_32bit_v4s {
  my $self = shift;
  my $prng = $self->{_prng};
  my $pid = $$;

  return sub {
    if ($$ != $pid) {
      $prng->srand();
      $pid = $$;
    }
    # Adapted from UUID::Tiny
    my $timestamp = Time::HiRes::time();

    # hi = time mod (1000000 / 0x100000000)
    my $hi = int( $timestamp / 65536.0 / 512 * 78125 );
    $timestamp -= $hi * 512.0 * 65536 / 78125;
    my $low = int( $timestamp * 10000000.0 + 0.5 );

    # MAGIC offset: 01B2-1DD2-13814000
    if ( $low < 0xec7ec000 ) {
        $low += 0x13814000;
    }
    else {
        $low -= 0xec7ec000;
        $hi++;
    }

    if ( $hi < 0x0e4de22e ) {
        $hi += 0x01b21dd2;
    }
    else {
        $hi -= 0x0e4de22e;    # wrap around
    }

    my $uuid = pack("N4", $hi, $low, $prng->irand, $prng->irand);
    # rotate last timestamp bits to make room for version field
    vec($uuid, 14, 4) = vec($uuid, 15, 4);
    vec($uuid, 15, 4) = vec($uuid, 12, 4);
    vec($uuid, 12, 4) = vec($uuid, 13, 4);
    vec($uuid, 13, 4) = 0x4;        # set UUID version
    vec($uuid, 35, 2) = 0x2;        # set UUID variant
    return $uuid;
  }
}

1;

# ABSTRACT: Fast random UUID generator using the Mersenne Twister algorithm


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Data::UUID::MT - Fast random UUID generator using the Mersenne Twister algorithm

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  use Data::UUID::MT;
  my $ug1 = Data::UUID::MT->new( version => 4 ); # "1", "4" or "4s"
  my $ug2 = Data::UUID::MT->new();               # default is "4"

  # method interface
  my $uuid1 = $ug->create();        # 16 byte binary string
  my $uuid2 = $ug->create_hex();
  my $uuid3 = $ug->create_string();

  # iterator -- avoids some method call overhead
  my $next = $ug->iterator;
  my $uuid4 = $next->();

=head1 DESCRIPTION

This UUID generator uses the excellent L<Math::Random::MT::Auto> module
as a source of fast, high-quality (pseudo) random numbers.

Three different types of UUIDs are supported.  Two are consistent with
RFC 4122 and one is a custom variant that provides a 'sequential UUID'
that can be advantageous when used as a primary database key.

B<Note>: The Mersenne Twister pseudo-random number generator has excellent
statistical properties, but it is not considered cryptographically secure.
Pseudo-random UUIDs are not recommended for use as security authentication
tokens in cookies or other user-visible session identifiers.

=head2 Version 1 UUIDs

The UUID generally follows the "version 1" spec from the RFC, however the clock
sequence and MAC address are randomly generated each time.  (This is
permissible within the spec of the RFC.)  The generated MAC address has the
the multicast bit set as mandated by the RFC to ensure it does not
conflict with real MAC addresses.  This UUID has 60 bits of timestamp data,
61 bits of pseudo-random data and 7 mandated bits (multicast bit, "variant"
field and "version" field).

=head2 Version 4 UUIDs

The UUID follows the "version 4" spec, with 122 pseudo-random bits and
6 mandated bits ("variant" field and "version" field).

=head2 Version 4s UUIDs

This is a custom UUID form that resembles "version 4" form, but that overlays
the first 60 bits with a timestamp akin to "version 1",  Unlike "version 1",
this custom version preserves the ordering of bits from high to low, whereas
"version 1" puts the low 32 bits of the timestamp first, then the middle 16
bits, then multiplexes the high bits with version field.  This "4s" variant
provides a "sequential UUID" with the timestamp providing order and the
remaining random bits making collision with other UUIDs created at the exact
same microsecond highly unlikely.  This UUID has 60 timestamp bits, 62
pseudo-random bits and 6 mandated bits ("variant" field and "version" field).

=head2 Unsupported: Versions 2, 3 and 5

This module focuses on generation of UUIDs with random elements and does not
support UUID versions 2, 3 and 5.

=head1 METHODS

=head2 new

  my $ug = Data::UUID::MT->new( version => 4 );

Creates a UUID generator object.  The only allowed versions are
"1", "4" and "4s".  If no version is specified, it defaults to "4".

=head2 create

  my $uuid = $ug->create;

Returns a UUID packed into a 16 byte string.

=head2 create_hex

  my $uuid = $ug->create_hex();

Returns a UUID as a lowercase hex string, prefixed with "0x", e.g.
C<0xb0470602a64b11da863293ebf1c0e05a>

=head2 create_string

  my $uuid = $ug->create_string(); #

Returns UUID as a lowercase string in "standard" format, e.g.
C<b0470602-a64b-11da-8632-93ebf1c0e05a>

=head2 iterator

  my $next = $ug->iterator;
  my $uuid = $next->();

Returns a reference to the internal UUID generator function.  Because this
avoids method call overhead, it is slightly faster than calling C<create>.

=head2 reseed

  $ug->reseed;

Reseeds the internal pseudo-random number generator.  This happens
automatically after a fork or thread creation (assuming Scalar::Util::weaken),
but may be called manually if desired for some reason.

Any arguments provided are passed to Math::Random::MT::Auto::srand() for
custom seeding.

  $ug->reseed('hotbits' => 250, '/dev/random');

=for Pod::Coverage method_names_here

=head1 UUID STRING REPRESENTATIONS

A UUID contains 16 bytes.  A hex string representation looks like
C<0xb0470602a64b11da863293ebf1c0e05a>. A "standard" representation
looks like C<b0470602-a64b-11da-8632-93ebf1c0e05a>.  Sometimes
these are seen in upper case and on Windows the standard format is
often seen wrapped in parentheses.

Converting back and forth is easy with C<pack> and C<unpack>.

  # string to 16 bytes
  $string =~ s/^0x//i;            # remove leading "0x"
  $string =~ tr/()-//d;           # strip '-' and parentheses
  $binary = pack("H*", $string);

  # 16 bytes to uppercase string formats
  $hex = "0x" . uc unpack("H*", $binary);
  $std = uc join "-", unpack("H8H4H4H4H12", $binary);

If you need a module that provides these conversions for you, consider
L<UUID::Tiny>.

=head1 COMPARISON TO OTHER UUID MODULES

At the time of writing, there are five other general purpose UUID generators on
CPAN that I consider potential alternatives.  Data::UUID::MT is included in
the discussion below for comparison.

=over 4

=item *

L<Data::GUID> - version 1 UUIDs (wrapper around Data::UUID)

=item *

L<Data::UUID> - version 1 or 3 UUIDs (derived from RFC 4122 code)

=item *

L<Data::UUID::LibUUID> - version 1 or 4 UUIDs (libuuid)

=item *

L<UUID> - version 1 or 4 UUIDs (libuuid)

=item *

L<UUID::Tiny> - versions 1, 3, 4, or 5 (pure perl)

=item *

L<Data::UUID::MT> - version 1 or 4 (or custom sequential "4s")

=back

C<libuuid> based UUIDs may generally be either version 4 (preferred) or version
1 (fallback), depending on the availability of a good random bit source (e.g.
/dev/random).  C<libuuid> version 1 UUIDs could also be provided by the
C<uuidd> daemon if available.

UUID.pm leaves the choice of version up to C<libuuid>.  Data::UUID::LibUUID
does so by default, but also allows specifying a specific version.  Note that
Data::UUID::LibUUID incorrectly refers to version 1 UUIDs as version 2 UUIDs.
For example, to get a version 1 binary UUID explicitly, you would call
C<Data::UUID::LibUUID::new_uuid_binary(2)>.

In addition to differences mentioned below, there are additional slight
difference in how the modules (or C<libuuid>) treat the "clock sequence" field
and otherwise attempt to keep state between calls, but this is generally
immaterial.

=head2 Use of Ethernet MAC addresses

Version 1 UUID generators differ in whether they include the Ethernet MAC
address as a "node identifier" as specified in RFC 4122.  Including the MAC
has security implications as Version 1 UUIDs can then be traced to a
particular machine at a particular time.

For C<libuuid> based modules, Version 1 UUIDs will include the actual MAC
address, if available, or will substitute a random MAC (with multicast bit
set).

Data::UUID version 1 UUIDs do not contain the MAC address, but replace
it with an MD5 hash of data including the hostname and host id (possibly
just the IP address), modified with the multicast bit.

Both UUID::Tiny and Data::UUID::MT version 1 UUIDs do not contain the actual
MAC address, but replace it with a random multicast MAC address.

=head2 Source of random bits

All the modules differ in the source of random bits.

C<libuuid> based modules get random bits from C</dev/random> or C</dev/urandom>
or fall back to a pseudo-random number generator.

Data::UUID only uses random data to see the clock sequence and gets bits from
the C C<rand()> function.

UUID::Tiny uses Perl's C<rand()> function.

Data::UUID::MT gets random bits from L<Math::Random::MT::Auto>, which uses the
Mersenne Twister algorithm.  Math::Random::MT::Auto seeds from system sources
(including Win32 specific ones on that platform) if available and falls back to
other less ideal sources if not.

=head2 Fork and thread safety

Pseudo-random number generators used in generating UUIDs should be reseeded if
the process forks or if threads are created.

Data::UUID::MT checks if the process ID has changed before generating a UUID
and reseeds if necessary.  If L<Scalar::Util> is installed and provides
C<weaken()>, Data::UUID::MT will also reseed its objects on thread creation.

Data::UUID::LibUUID will reseed on fork on Mac OSX.

I have not explored further whether other UUID generators are fork/thread safe.

=head2 Benchmarks

The F<examples/bench.pl> program included with this module does some simple
benchmarking of UUID generation speeds.  Here is the output from my desktop
system (AMD Phenom II X6 1045T CPU).  Note that "v?" is used where the choice
is left to C<libuuid> -- which will result in version 4 UUIDs on my system.

 Benchmark on Perl v5.14.0 for x86_64-linux with 8 byte integers.

 Key:
   U     => UUID 0.02
   UT    => UUID::Tiny 1.03
   DG    => Data::GUID 0.046
   DU    => Data::UUID 1.217
   DULU  => Data::UUID::LibUUID 0.05
   DUMT  => Data::UUID::MT 0.001

 Benchmarks are marked as to which UUID version is generated.
 Some modules offer method ('meth') and function ('func') interfaces.

         UT|v1    85229/s
         UT|v4   110652/s
       DULU|v1   177495/s
       DULU|v?   178629/s
 DUMT|v4s|meth   274905/s
  DUMT|v1|meth   281942/s
          U|v?   288136/s
       DULU|v4   295107/s
 DUMT|v4s|func   307575/s
  DUMT|v1|func   313538/s
    DG|v1|func   335333/s
    DG|v1|meth   373515/s
  DUMT|v4|meth   450845/s
  DUMT|v4|func   588573/s
         DU|v1  1312946/s

=head1 SEE ALSO

=over 4

=item *

L<RFC 4122 A Universally Unique IDentifier (UUID) URN Namespace|http://www.apps.ietf.org/rfc/rfc4122.html>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/data-uuid-mt/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/data-uuid-mt>

  git clone git://github.com/dagolden/data-uuid-mt.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

Matt Koscica <matt.koscica@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

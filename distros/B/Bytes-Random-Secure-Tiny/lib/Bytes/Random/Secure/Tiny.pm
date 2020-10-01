## no critic (ProhibitMultiplePackages,RequireFilenameMatchesPackage)

# Bytes::Random::Secure::Tiny: A single source file implementation of
# Bytes::Random::Secure, and its dependencies.

# Crypt::Random::Seed::Embedded, adapted with consent from  #
# Crypt::Random::Seed, by Dana Jacobson.                    #

package Crypt::Random::Seed::Embedded;
use strict;
use warnings;
use Fcntl;
use Carp qw/croak/;

## no critic (constant)
our $VERSION = '1.011';
use constant UINT32_SIZE => 4;

sub new {
    my ($class, %params) = @_;
    $params{lc $_} = delete $params{$_} for keys %params;
    $params{nonblocking}
        = defined $params{nonblocking} ? $params{nonblocking} : 1;
    my $self = {};
    my @methodlist
        = ( \&_try_win32, \&_try_dev_random, \&_try_dev_urandom );
    foreach my $m (@methodlist) {
        my ($name, $rsub, $isblocking, $isstrong) = $m->();
        next unless defined $name;
        next if $isblocking && $params{nonblocking};
        @{$self}{qw( Name    SourceSub  Blocking      Strong    )}
                 = ( $name,  $rsub,     $isblocking,  $isstrong );
        last;
    }
    return defined $self->{SourceSub} ? bless $self, $class : ();
}

sub random_values {
    my ($self, $nvalues) = @_;
    return unless defined $nvalues && int($nvalues) > 0;
    my $rsub = $self->{SourceSub};
    return unpack( 'L*', $rsub->(UINT32_SIZE * int($nvalues)) );
}

sub _try_dev_urandom {
    return unless -r "/dev/urandom";
    return ('/dev/urandom', sub { __read_file('/dev/urandom', @_); }, 0, 0);
}

sub _try_dev_random {
    return unless -r "/dev/random";
    my $blocking = $^O eq 'freebsd' ? 0 : 1;
    return ('/dev/random', sub {__read_file('/dev/random', @_)}, $blocking, 1);
}

sub __read_file {
    my ($file, $nbytes) = @_;
    return unless defined $nbytes && $nbytes > 0;
    sysopen(my $fh, $file, O_RDONLY);
    binmode $fh;
    my($s, $buffer, $nread) = ('', '', 0);
    while ($nread < $nbytes) {
        my $thisread = sysread $fh, $buffer, $nbytes-$nread;
        croak "Error reading $file: $!\n"
            unless defined $thisread && $thisread > 0;
        $s .= $buffer;
        $nread += length($buffer);
    }
    croak "Internal file read error: wanted $nbytes, read $nread"
        unless $nbytes == length($s);  # assert
    return $s;
}

sub _try_win32 {
    return unless $^O eq 'MSWin32';
    eval { require Win32; require Win32::API; require Win32::API::Type; 1; }
        or return;
    use constant CRYPT_SILENT      => 0x40;       # Never display a UI.
    use constant PROV_RSA_FULL     => 1;          # Which service provider.
    use constant VERIFY_CONTEXT    => 0xF0000000; # Don't need existing keepairs
    use constant W2K_MAJOR_VERSION => 5;          # Windows 2000
    use constant W2K_MINOR_VERSION => 0;
    my ($major, $minor) = (Win32::GetOSVersion())[1, 2];
    return if $major < W2K_MAJOR_VERSION;

    if ($major == W2K_MAJOR_VERSION && $minor == W2K_MINOR_VERSION) {
        # We are Windows 2000.  Use the older CryptGenRandom interface.
        my $crypt_acquire_context_a =
            Win32::API->new('advapi32', 'CryptAcquireContextA', 'PPPNN','I');
        return unless defined $crypt_acquire_context_a;
        my $context = chr(0) x Win32::API::Type->sizeof('PULONG');
        my $result = $crypt_acquire_context_a->Call(
             $context, 0, 0, PROV_RSA_FULL, CRYPT_SILENT | VERIFY_CONTEXT );
        return unless $result;
        my $pack_type = Win32::API::Type::packing('PULONG');
        $context = unpack $pack_type, $context;
        my $crypt_gen_random =
            Win32::API->new( 'advapi32', 'CryptGenRandom', 'NNP', 'I' );
        return unless defined $crypt_gen_random;
        return ('CryptGenRandom',
            sub {
                my $nbytes = shift;
                my $buffer = chr(0) x $nbytes;
                my $result = $crypt_gen_random->Call($context, $nbytes, $buffer);
                croak "CryptGenRandom failed: $^E" unless $result;
                return $buffer;
            }, 0, 1);  # Assume non-blocking and strong
    } else {
        my $rtlgenrand = Win32::API->new( 'advapi32', <<'_RTLGENRANDOM_PROTO_');
INT SystemFunction036(
  PVOID RandomBuffer,
  ULONG RandomBufferLength
)
_RTLGENRANDOM_PROTO_
        return unless defined $rtlgenrand;
        return ('RtlGenRand',
            sub {
                my $nbytes = shift;
                my $buffer = chr(0) x $nbytes;
                my $result = $rtlgenrand->Call($buffer, $nbytes);
                croak "RtlGenRand failed: $^E" unless $result;
                return $buffer;
            }, 0, 1);  # Assume non-blocking and strong
    }
    return;
}

1;

# Math::Random::ISAAC::PP::Embedded: Adapted from  #
# Math::Random::ISAAC and Math::Random::ISAAC::PP. #

## no critic (constant,unpack)

package Math::Random::ISAAC::PP::Embedded;

use strict;
use warnings;

our $VERSION = '1.011';
use constant {
    randrsl => 0, randcnt => 1, randmem => 2,
    randa   => 3, randb   => 4, randc   => 5,
};

sub new {
    my ($class, @seed) = @_;
    my $seedsize = scalar(@seed);
    my @mm;
    $#mm = $#seed = 255;                # predeclare arrays with 256 slots
    $seed[$_] = 0 for $seedsize .. 255; # Zero-fill unused seed space.
    my $self = [ \@seed, 0, \@mm, 0, 0, 0 ];
    bless $self, $class;
    $self->_randinit;
    return $self;
}

sub irand {
    my $self = shift;
    if (!$self->[randcnt]--) {
        $self->_isaac;
        $self->[randcnt] = 255;
    }
    return sprintf('%u', $self->[randrsl][$self->[randcnt]]);
}

## no critic (RequireNumberSeparators,ProhibitCStyleForLoops)

sub _isaac {
    my $self = shift;
    use integer;
    my($mm, $r, $aa) = @{$self}[randmem,randrsl,randa];
    my $bb = ($self->[randb] + (++$self->[randc])) & 0xffffffff;
    my ($x, $y); # temporary storage
    for (my $i = 0; $i < 256; $i += 4) {
        $x = $mm->[$i  ];
        $aa = (($aa ^ ($aa << 13)) + $mm->[($i   + 128) & 0xff]);
        $aa &= 0xffffffff; # Mask out high bits for 64-bit systems
        $mm->[$i  ] = $y = ($mm->[($x >> 2) & 0xff] + $aa + $bb) & 0xffffffff;
        $r->[$i  ] = $bb = ($mm->[($y >> 10) & 0xff] + $x) & 0xffffffff;

        $x = $mm->[$i+1];
        $aa = (($aa ^ (0x03ffffff & ($aa >> 6))) + $mm->[($i+1+128) & 0xff]);
        $aa &= 0xffffffff;
        $mm->[$i+1] = $y = ($mm->[($x >> 2) & 0xff] + $aa + $bb) & 0xffffffff;
        $r->[$i+1] = $bb = ($mm->[($y >> 10) & 0xff] + $x) & 0xffffffff;

        $x = $mm->[$i+2];
        $aa = (($aa ^ ($aa << 2)) + $mm->[($i+2 + 128) & 0xff]);
        $aa &= 0xffffffff;
        $mm->[$i+2] = $y = ($mm->[($x >> 2) & 0xff] + $aa + $bb) & 0xffffffff;
        $r->[$i+2] = $bb = ($mm->[($y >> 10) & 0xff] + $x) & 0xffffffff;

        $x = $mm->[$i+3];
        $aa = (($aa ^ (0x0000ffff & ($aa >> 16))) + $mm->[($i+3 + 128) & 0xff]);
        $aa &= 0xffffffff;
        $mm->[$i+3] = $y = ($mm->[($x >> 2) & 0xff] + $aa + $bb) & 0xffffffff;
        $r->[$i+3] = $bb = ($mm->[($y >> 10) & 0xff] + $x) & 0xffffffff;
    }
    @{$self}[randb, randa] = ($bb,$aa);
    return;
}

sub _randinit {
    my $self = shift;
    use integer;
    my ($c, $d, $e, $f, $g, $h, $j, $k) = (0x9e3779b9)x8; # The golden ratio.
    my ($mm, $r) = @{$self}[randmem,randrsl];
    for (1..4) {
        $c ^= $d << 11;                     $f += $c;       $d += $e;
        $d ^= 0x3fffffff & ($e >> 2);       $g += $d;       $e += $f;
        $e ^= $f << 8;                      $h += $e;       $f += $g;
        $f ^= 0x0000ffff & ($g >> 16);      $j += $f;       $g += $h;
        $g ^= $h << 10;                     $k += $g;       $h += $j;
        $h ^= 0x0fffffff & ($j >> 4);       $c += $h;       $j += $k;
        $j ^= $k << 8;                      $d += $j;       $k += $c;
        $k ^= 0x007fffff & ($c >> 9);       $e += $k;       $c += $d;
    }
    for (my $i = 0; $i < 256; $i += 8) {
        $c += $r->[$i  ];   $d += $r->[$i+1];
        $e += $r->[$i+2];   $f += $r->[$i+3];
        $g += $r->[$i+4];   $h += $r->[$i+5];
        $j += $r->[$i+6];   $k += $r->[$i+7];
        $c ^= $d << 11;                     $f += $c;       $d += $e;
        $d ^= 0x3fffffff & ($e >> 2);       $g += $d;       $e += $f;
        $e ^= $f << 8;                      $h += $e;       $f += $g;
        $f ^= 0x0000ffff & ($g >> 16);      $j += $f;       $g += $h;
        $g ^= $h << 10;                     $k += $g;       $h += $j;
        $h ^= 0x0fffffff & ($j >> 4);       $c += $h;       $j += $k;
        $j ^= $k << 8;                      $d += $j;       $k += $c;
        $k ^= 0x007fffff & ($c >> 9);       $e += $k;       $c += $d;
        $mm->[$i  ] = $c;   $mm->[$i+1] = $d;
        $mm->[$i+2] = $e;   $mm->[$i+3] = $f;
        $mm->[$i+4] = $g;   $mm->[$i+5] = $h;
        $mm->[$i+6] = $j;   $mm->[$i+7] = $k;
    }
    for (my $i = 0; $i < 256; $i += 8) {
        $c += $mm->[$i  ];  $d += $mm->[$i+1];
        $e += $mm->[$i+2];  $f += $mm->[$i+3];
        $g += $mm->[$i+4];  $h += $mm->[$i+5];
        $j += $mm->[$i+6];  $k += $mm->[$i+7];
        $c ^= $d << 11;                     $f += $c;       $d += $e;
        $d ^= 0x3fffffff & ($e >> 2);       $g += $d;       $e += $f;
        $e ^= $f << 8;                      $h += $e;       $f += $g;
        $f ^= 0x0000ffff & ($g >> 16);      $j += $f;       $g += $h;
        $g ^= $h << 10;                     $k += $g;       $h += $j;
        $h ^= 0x0fffffff & ($j >> 4);       $c += $h;       $j += $k;
        $j ^= $k << 8;                      $d += $j;       $k += $c;
        $k ^= 0x007fffff & ($c >> 9);       $e += $k;       $c += $d;
        $mm->[$i  ] = $c;   $mm->[$i+1] = $d;
        $mm->[$i+2] = $e;   $mm->[$i+3] = $f;
        $mm->[$i+4] = $g;   $mm->[$i+5] = $h;
        $mm->[$i+6] = $j;   $mm->[$i+7] = $k;
    }
    $self->_isaac;
    $self->[randcnt] = 256;
    return;
}

1;

package Math::Random::ISAAC::Embedded;

use strict;
use warnings;

our $VERSION = '1.011';
use constant _backend => 0;

my %CSPRNG = (
    XS  => 'Math::Random::ISAAC::XS',
    PP  => 'Math::Random::ISAAC::PP',
    EM  => 'Math::Random::ISAAC::PP::Embedded',
);

sub new {
    my ($class, @seed) = @_;
    our $EMBEDDED_CSPRNG =
        defined $EMBEDDED_CSPRNG             ? $EMBEDDED_CSPRNG             :
        defined $ENV{'BRST_EMBEDDED_CSPRNG'} ? $ENV{'BRST_EMBEDDED_CSPRNG'} : 0;
    my $DRIVER =
        $EMBEDDED_CSPRNG                          ? $CSPRNG{'EM'} :
        eval {require Math::Random::ISAAC::XS; 1} ? $CSPRNG{'XS'} :
        eval {require Math::Random::ISAAC::PP; 1} ? $CSPRNG{'PP'} :
                                                    $CSPRNG{'EM'};
    return bless [$DRIVER->new(@seed)], $class;
}

sub irand {shift->[_backend]->irand}

1;

package Bytes::Random::Secure::Tiny;

use strict;
use warnings;
use 5.006000;
use Carp qw(croak);
use Hash::Util;

our $VERSION = '1.011';

# See Math::Random::ISAAC https://rt.cpan.org/Public/Bug/Display.html?id=64324
use constant SEED_SIZE => 256; # bits; eight 32-bit words.

sub new {
    my($self, $class, %args) = ({}, @_);
    $args{lc $_} = delete $args{$_} for keys %args; # Convert args to lc names
    my $bits = SEED_SIZE; # Default: eight 32bit words.
    $bits = delete $args{bits} if exists $args{bits};
    croak "Number of bits must be 64 <= n <= 8192, and a multipe in 2^n: $bits"
        if $bits < 64 || $bits > 8192 || !_ispowerof2($bits);
    return Hash::Util::lock_hashref bless {
        bits => $bits,
        _rng => Math::Random::ISAAC::Embedded->new(do{
            my $source = Crypt::Random::Seed::Embedded->new(%args)
                or croak 'Could not get a seed source.';
            $source->random_values($bits/32);
        }),
    }, $class;
}

sub _ispowerof2 {my $n = shift; return ($n >= 0) && (($n & ($n-1)) ==0 )}
sub irand {shift->{'_rng'}->irand}
sub bytes_hex {unpack 'H*', shift->bytes(shift)} # lc Hex digits only, no '0x'

sub bytes {
      my($self, $bytes) = @_;
    $bytes  = defined $bytes ? int abs $bytes : 0; # Default 0, coerce to UINT.
    my $str = q{};
    while ($bytes >= 4) {                  # Utilize irand()'s 32 bits.
        $str .= pack("L", $self->irand);
        $bytes -= 4;
    }
    if ($bytes > 0) { # Handle 16b and 8b respectively.
        $str .= pack("S", ($self->irand >> 8) & 0xFFFF) if $bytes >= 2;
        $str .= pack("C", $self->irand & 0xFF) if $bytes % 2;
    }
    return $str;
}

sub string_from {
    my($self, $bag, $bytes) = @_;
    $bag           = defined $bag ? $bag : q{};
    $bytes         = defined $bytes ? int abs $bytes : 0;
    my $range      = length $bag;
    croak 'Bag size must be at least one character.' unless $range;
    my $rand_bytes = q{}; # We need an empty, defined string.
    $rand_bytes .= substr $bag, $_, 1
        for @{$self->_ranged_randoms($range, $bytes)};
    return $rand_bytes;
}

sub shuffle {
    my($self, $aref) = @_;
    croak 'Argument must be an array reference.' unless 'ARRAY' eq ref $aref;
    return $aref unless @$aref;
    for (my $i = @$aref; --$i;) {
        my $r = $self->_ranged_randoms($i+1, 1)->[0];
        ($aref->[$i],$aref->[$r]) = ($aref->[$r], $aref->[$i]);
    }
    return $aref;
}

sub _ranged_randoms {
    my ($self, $range, $count) = @_;
    $_ = defined $_ ? $_ : 0 for $count, $range;
    croak "$range exceeds irand max limit of 2^^32." if $range > 2**32;
    # Find nearest factor of 2**32 >= $range.
    my $divisor = do {
        my ($n, $d) = (0,0);
        while ($n <= 32 && $d < $range) {$d = 2 ** $n++}
        $d;
    };
    my @randoms;
    $#randoms = $count-1; @randoms = (); # Microoptimize: Preextend & purge.
    for my $n (1 .. $count) { # re-roll if r-num is out of bag range (modbias)
        my $rand = $self->irand % $divisor;
        $rand    = $self->irand % $divisor while $rand >= $range;
        push @randoms, $rand;
    }
    return \@randoms;
}

1; # POD contained in Bytes/Random/Secure/Tiny.pod


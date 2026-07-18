package Crypt::FPE::FF1::Format;
use strict;
use warnings;
use Crypt::FPE::FF1 ();   # your XS class

# The lib's internal digit alphabet (first $radix chars are used)
my $LIB = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';

# mode => 'strict' (default): each character class (digits, lowercase,
#   uppercase) is FF1-encrypted separately, but any class run whose domain
#   (radix^length) falls below NIST SP 800-38G's 1,000,000 minimum raises
#   an exception rather than being silently left in plaintext or weakly
#   "encrypted". This is the only mode that is NIST-compliant by default;
#   it will reject plenty of realistic short/mixed strings (e.g. a single
#   leading capital letter in a name) -- that's the security floor working
#   as intended, not a bug.
#
# mode => 'combined': a single radix-62 FF1 pass over every alphanumeric
#   position (digits + lower + upper together), which reaches the NIST
#   floor far more often for short/mixed strings because the domain is
#   much larger per call. Trade-off: it preserves the string's length and
#   the position of non-alphanumeric formatting characters, but does NOT
#   preserve each position's digit/lower/upper "shape" -- a digit may come
#   back as a letter after encryption, and vice versa.
#
# mode => 'permissive': restores the old per-class behavior of allowing
#   domains below the NIST floor (weak protection, or a silent plaintext
#   pass-through for single-character classes). Requires unsafe => 1 to
#   construct, so it can't be reached by accident.
sub new {
  my ($class, %opt) = @_;
  my $mode = $opt{mode} // 'strict';
  die "Format: mode must be 'strict', 'combined', or 'permissive' (got '$mode')\n"
    unless $mode =~ /\A(?:strict|combined|permissive)\z/;
  if ($mode eq 'permissive' && !$opt{unsafe}) {
    die "Format: mode => 'permissive' allows FF1 domains below NIST SP 800-38G's "
      . "1,000,000 minimum, which is only weakly protected (or not protected at "
      . "all for single-character runs). Pass unsafe => 1 to acknowledge this and "
      . "proceed.\n";
  }

  my %base = (
    (exists $opt{key_hex}   ? (key_hex   => $opt{key_hex})   : (key => $opt{key})),
    (exists $opt{tweak_hex} ? (tweak_hex => $opt{tweak_hex}) : (tweak => $opt{tweak})),
  );

  my $self = bless { mode => $mode }, $class;
  if ($mode eq 'combined') {
    $self->{combined} = Crypt::FPE::FF1->new(%base, radix => 62);
  } else {
    $self->{d}  = Crypt::FPE::FF1->new(%base, radix => 10);  # digits
    $self->{lc} = Crypt::FPE::FF1->new(%base, radix => 26);  # a-z
    $self->{uc} = Crypt::FPE::FF1->new(%base, radix => 26);  # A-Z
  }
  return $self;
}

sub encrypt_masked   { _transform(shift, 'encrypt',   @_) }
sub decrypt_masked   { _transform(shift, 'decrypt',   @_) }

# --- internals ---

sub _transform {
  my ($self, $op, $s) = @_;
  $s = "$s"; # copy

  return _map_run($self, $self->{combined}, $s, $LIB, $op)
    if $self->{mode} eq 'combined';

  # Pass 1: digits
  $s = _map_run($self, $self->{d},  $s, '0123456789', $op);

  # Pass 2: lowercase letters
  $s = _map_run($self, $self->{lc}, $s, 'abcdefghijklmnopqrstuvwxyz', $op);

  # Pass 3: uppercase letters
  $s = _map_run($self, $self->{uc}, $s, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', $op);

  return $s;
}

# Map only characters from $alphabet, leave others unchanged.
# Uses the lib's first-$radix alphabet as the working "digits", then maps back.
sub _map_run {
  my ($self, $ff1, $s, $alphabet, $op) = @_;
  my $radix = length $alphabet;
  my $lib_d = substr($LIB, 0, $radix);

  # Build lookup tables
  my %alpha_to_n; my @n_to_alpha;
  for my $i (0..$radix-1) {
    my $ch = substr($alphabet, $i, 1);
    $alpha_to_n{$ch} = $i;
    $n_to_alpha[$i]  = $ch;
  }
  my %lib_to_n; for my $i (0..$radix-1) { $lib_to_n{substr($lib_d,$i,1)} = $i }

  # Collect positions belonging to this alphabet and encode them into lib digits
  my @ch   = split //, $s;
  my @pos; my @lib_in;
  for my $i (0..$#ch) {
    my $c = $ch[$i];
    next unless exists $alpha_to_n{$c};
    push @pos, $i;
    my $n = $alpha_to_n{$c};
    push @lib_in, substr($lib_d, $n, 1);
  }
  return $s unless @pos; # nothing of this class present

  my $in = join('', @lib_in);
  my $out = $self->{mode} eq 'permissive'
    ? ($op eq 'encrypt' ? $ff1->_encrypt_below_floor($in) : $ff1->_decrypt_below_floor($in))
    : ($op eq 'encrypt' ? $ff1->encrypt($in)              : $ff1->decrypt($in));

  # Map back to requested alphabet at original positions
  my @lib_out = split //, $out;
  for my $j (0..$#pos) {
    my $d = $lib_out[$j];
    my $n = $lib_to_n{$d};
    $ch[$pos[$j]] = $n_to_alpha[$n];
  }
  return join('', @ch);
}

1;

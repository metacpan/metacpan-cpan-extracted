package BitStreamTest;

use strict;
use warnings;

#use Test::More;
#use Data::Dumper;
#use List::Util qw(shuffle);

use base qw(Exporter);
our @EXPORT = qw(
  full_testing
  new_stream
  encoding_list
  is_universal
  impl_list
  stream_encode_array
  stream_decode_array
  stream_encode_mixed
  stream_decode_mixed
  sub_for_string
);

# Skip some tests unless this is 1
sub full_testing   { 0; }


# The string implementation must be available and working.
use Data::BitStream::String;

my %stream_constructors = (
  'string', sub { return Data::BitStream::String->new(); },
);

# Other implementations may or may not be available.
# If they're not, we just won't test them.

# Vec -- deprecated to WordVec
if (full_testing && eval {require Data::BitStream::Vec}) {
  $stream_constructors{'vector'} = sub { return Data::BitStream::Vec->new(); };
}
# BitVec -- no faster than WordVec, and cpan tests indicate Bit::Vector is
# failing for us on some machines.
if (full_testing && eval {require Data::BitStream::BitVec}) {
  $stream_constructors{'bitvector'} = sub { return Data::BitStream::BitVec->new(); };
}

# MinimalVec should let us test all of the functionality in Base.pm
if (eval {require Data::BitStream::MinimalVec}) {
  $stream_constructors{'minimalvec'} = sub { return Data::BitStream::MinimalVec->new(); };
}
# WordVec is the fast Pure Perl implementation
if (eval {require Data::BitStream::WordVec}) {
  $stream_constructors{'wordvec'} = sub {return Data::BitStream::WordVec->new();};
}
# BLVec wraps Data:BitStream:XS if it is installed
if (eval {require Data::BitStream::BLVec}) {
  $stream_constructors{'blvec'} = sub {return Data::BitStream::BLVec->new();};
}
# Direct XS -- currently none of the testing uses features this can't handle.
# The big item would be any MOP (meta object protocol) handling, since the XS
# class isn't Moose/Mouse/Moo.
if (eval {require Data::BitStream::XS}) {
  if ($Data::BitStream::XS::VERSION >= 0.04) {
    $stream_constructors{'xs'} = sub {return Data::BitStream::XS->new();};
  }
}

sub impl_list {
  my $sorder = 'default string wordvec blvec vector bitvector xs';
  my @ilist = sort {
                     index($sorder,$a) <=> index($sorder,$b);
                   } keys %stream_constructors;
  @ilist;
}
  
sub new_stream {
  my $type = lc shift;
  $type =~ s/[^a-z]//g;
  my $constructor = $stream_constructors{$type};
  die "Unknown stream type: $type" unless defined $constructor;
  my $stream = $constructor->();
  return $stream;
}

my $maxbits = Data::BitStream::String::maxbits();

sub is_universal {
  my $enc = lc shift;
  return 1 if $enc =~ /^(gamma|delta|omega|evenrodeh|fib|fibc2|gg|eg|lev|bvzeta|baer|arice)\b/;
  return 1 if $enc =~ /^(delta|omega|fib|fibc2|er)gol\b/;
  return 1 if $enc =~ /^binword\($maxbits\)$/;
  # TODO: figure this out
  #return 0 if $enc =~ /^blocktaboo\(.\)$/;
  #return 0 if $enc =~ /^comma\(1\)$/;
  #return 1 if $enc =~ /^(blocktaboo|comma)\b/;
  return 0;
}

# We should add BER and Varint, but XS doesn't support them yet.
sub encoding_list {
  my @e = qw|
              Unary Unary1 Gamma Delta Omega Fib Fib(3)
              EvenRodeh Levenstein
              GoldbachG1 GoldbachG2
              Golomb(10) Golomb(16) Golomb(14000)
              Rice(2) Rice(9)
              GG(3) GG(128) EG(5)
              DeltaGol(21) OmegaGol(21) FibGol(21) ERGol(890)
              BVZeta(2) Baer(0) Baer(-2) Baer(2)
              SSS(3-3-99) SS(1-0-1-0-2-12-99)
              Comma(2) Comma(3)
              BlockTaboo(00) BlockTaboo(10011)
              ARice(9)
            |;
  unshift @e, "Binword($maxbits)";
  @e; 
}

my $sub_put_delta = sub { shift->put_delta(@_); };
my $sub_put_omega = sub { shift->put_omega(@_); };
my $sub_put_er    = sub { shift->put_evenrodeh(@_); };
my $sub_put_fib   = sub { shift->put_fib(@_); };
my $sub_get_delta = sub { shift->get_delta(@_); };
my $sub_get_omega = sub { shift->get_omega(@_); };
my $sub_get_er    = sub { shift->get_evenrodeh(@_); };
my $sub_get_fib   = sub { shift->get_fib(@_); };

my %esubs = (
  # Universal
  'gamma'  => sub { my $stream=shift; my $p=shift; $stream->put_gamma(@_) },
  'delta'  => sub { my $stream=shift; my $p=shift; $stream->put_delta(@_) },
  'omega'  => sub { my $stream=shift; my $p=shift; $stream->put_omega(@_) },
  'levenstein'=>sub{my $stream=shift; my $p=shift; $stream->put_levenstein(@_)},
  'evenrodeh'=>sub{ my $stream=shift; my $p=shift; $stream->put_evenrodeh(@_) },
  'ber'    => sub { my $stream=shift; my $p=shift; $stream->put_BER(@_) },
  'varint' => sub { my $stream=shift; my $p=shift; $stream->put_varint(@_) },
  'fib'    => sub { my $stream=shift; my $p=shift;
                    if (defined $p) { $stream->put_fibgen($p,@_); }
                    else            { $stream->put_fib(@_);       } },
  'fibc2'  => sub { my $stream=shift; my $p=shift; $stream->put_fib_c2(@_) },
  'binword'=> sub { my $stream=shift; my $p=shift; $stream->put_binword($p,@_)},
  'gg'     => sub { my $stream=shift; my $p=shift; $stream->put_gammagolomb($p,@_) },
  'deltagol'=>sub { my $stream=shift; my $p=shift; $stream->put_golomb($sub_put_delta,$p,@_) },
  'omegagol'=>sub { my $stream=shift; my $p=shift; $stream->put_golomb($sub_put_omega,$p,@_) },
  'ergol'  => sub { my $stream=shift; my $p=shift; $stream->put_golomb($sub_put_er,$p,@_) },
  'fibgol' => sub { my $stream=shift; my $p=shift; $stream->put_golomb($sub_put_fib,$p,@_) },
  'eg'     => sub { my $stream=shift; my $p=shift; $stream->put_expgolomb($p,@_) },
  'bvzeta' => sub { my $stream=shift; my $p=shift; $stream->put_boldivigna($p,@_) },
  'baer'   => sub { my $stream=shift; my $p=shift; $stream->put_baer($p,@_) },
  'arice'  => sub { my $stream=shift; my $p=shift; $stream->put_arice($p,@_) },
  # Non-Universal
  'unary'  => sub { my $stream=shift; my $p=shift; $stream->put_unary(@_) },
  'unary1' => sub { my $stream=shift; my $p=shift; $stream->put_unary1(@_) },
  'golomb' => sub { my $stream=shift; my $p=shift; $stream->put_golomb($p,@_) },
  'rice'   => sub { my $stream=shift; my $p=shift; $stream->put_rice($p,@_) },
  'goldbachg1'=>sub{ my $stream=shift; my $p=shift; $stream->put_goldbach_g1(@_) },
  'goldbachg2'=>sub{ my $stream=shift; my $p=shift; $stream->put_goldbach_g2(@_) },
  'blocktaboo' => sub { my $stream=shift; my $p=shift; $stream->put_blocktaboo($p,@_) },
  'comma'  => sub { my $stream=shift; my $p=shift; $stream->put_comma($p,@_) },
  'sss'    => sub { my $stream=shift; my $p=shift; $stream->put_startstepstop([split('-',$p)],@_) },
  'ss'     => sub { my $stream=shift; my $p=shift; $stream->put_startstop([split('-',$p)],@_) },
  'escape' => sub { my $stream=shift; my $p=shift; $stream->put_escape([split('-',$p)],@_) },
);
my %dsubs = (
  # Universal
  'gamma'  => sub { my $stream=shift; my $p=shift; $stream->get_gamma(@_) },
  'delta'  => sub { my $stream=shift; my $p=shift; $stream->get_delta(@_) },
  'omega'  => sub { my $stream=shift; my $p=shift; $stream->get_omega(@_) },
  'levenstein'=>sub{my $stream=shift; my $p=shift; $stream->get_levenstein(@_)},
  'evenrodeh'=>sub{ my $stream=shift; my $p=shift; $stream->get_evenrodeh(@_) },
  'ber'    => sub { my $stream=shift; my $p=shift; $stream->get_BER(@_) },
  'varint' => sub { my $stream=shift; my $p=shift; $stream->get_varint(@_) },
  'fib'    => sub { my $stream=shift; my $p=shift;
                    if (defined $p) { $stream->get_fibgen($p,@_); }
                    else            { $stream->get_fib(@_);       } },
  'fibc2'  => sub { my $stream=shift; my $p=shift; $stream->get_fib_c2(@_) },
  'binword'=> sub { my $stream=shift; my $p=shift; $stream->get_binword($p,@_)},
  'gg'     => sub { my $stream=shift; my $p=shift; $stream->get_gammagolomb($p,@_) },
  'deltagol'=>sub { my $stream=shift; my $p=shift; $stream->get_golomb($sub_get_delta,$p,@_) },
  'omegagol'=>sub { my $stream=shift; my $p=shift; $stream->get_golomb($sub_get_omega,$p,@_) },
  'ergol'  => sub { my $stream=shift; my $p=shift; $stream->get_golomb($sub_get_er,$p,@_) },
  'fibgol' => sub { my $stream=shift; my $p=shift; $stream->get_golomb($sub_get_fib,$p,@_) },
  'eg'     => sub { my $stream=shift; my $p=shift; $stream->get_expgolomb($p,@_) },
  'bvzeta' => sub { my $stream=shift; my $p=shift; $stream->get_boldivigna($p,@_) },
  'baer'   => sub { my $stream=shift; my $p=shift; $stream->get_baer($p,@_) },
  'arice'  => sub { my $stream=shift; my $p=shift; $stream->get_arice($p,@_) },
  # Non-Universal
  'unary'  => sub { my $stream=shift; my $p=shift; $stream->get_unary(@_) },
  'unary1' => sub { my $stream=shift; my $p=shift; $stream->get_unary1(@_) },
  'golomb' => sub { my $stream=shift; my $p=shift; $stream->get_golomb($p,@_) },
  'rice'   => sub { my $stream=shift; my $p=shift; $stream->get_rice($p,@_) },
  'goldbachg1'=>sub{ my $stream=shift; my $p=shift; $stream->get_goldbach_g1(@_) },
  'goldbachg2'=>sub{ my $stream=shift; my $p=shift; $stream->get_goldbach_g2(@_) },
  'blocktaboo' => sub { my $stream=shift; my $p=shift; $stream->get_blocktaboo($p,@_) },
  'comma'  => sub { my $stream=shift; my $p=shift; $stream->get_comma($p,@_) },
  'sss'    => sub { my $stream=shift; my $p=shift; $stream->get_startstepstop([split('-',$p)],@_) },
  'ss'     => sub { my $stream=shift; my $p=shift; $stream->get_startstop([split('-',$p)],@_) },
  'escape' => sub { my $stream=shift; my $p=shift; $stream->get_escape([split('-',$p)],@_) },
);

sub sub_for_string {
  my $encoding = lc shift;
  my $param;
  $param = $1 if $encoding =~ s/\((.+)\)$//;
  return ($esubs{$encoding}, $dsubs{$encoding}, $param);
}

sub stream_encode_array {
  my $type = shift;
  my $encoding = shift;

  my $stream = new_stream($type);
  return unless defined $stream;
  my ($esub, $dsub, $param) = sub_for_string($encoding);
  return unless defined $esub;

  #foreach my $d (@_) { $esub->($stream, $param, $d); }
  $esub->($stream, $param, @_);
  return $stream;
}
sub stream_decode_array {
  my $encoding = shift;
  my $stream = shift;
  return unless defined $stream;
  my ($esub, $dsub, $param) = sub_for_string($encoding);
  return unless defined $dsub;
  $stream->rewind_for_read;

  if (wantarray) {
    return $dsub->($stream, $param, -1);
  } else {
    return $dsub->($stream, $param, 1);
  }
}

# Expects an array like:
#   ( ['Unary', 2],  ['GG(3)', 500],  ['Gamma', 14], ... )
sub stream_encode_mixed {
  my $type = shift;

  my $stream = new_stream($type);
  return unless defined $stream;

  foreach my $aref (@_) {
    my $estr = $aref->[0];
    my $d    = $aref->[1];
    die "Numbers must be >= 0" if $d < 0;
    my ($esub, $dsub, $param) = sub_for_string($estr);
    return unless defined $esub;
    warn "Unary coding not recommended for large numbers ($d)"
         if $d > 100_000 and $estr =~ /^unary$/i;
    $esub->($stream, $param, $d);
  }
  return $stream;
}

sub stream_decode_mixed {
  my $stream = shift;
  return unless defined $stream;
  $stream->rewind_for_read;
  foreach my $aref (@_) {
    my $estr = $aref->[0];
    my $d    = $aref->[1];
    die "Numbers must be >= 0" if $d < 0;
    my ($esub, $dsub, $param) = sub_for_string($estr);
    return unless defined $dsub;
    my $v = $dsub->($stream, $param);
    return 0 if $v != $d;
  }
  1;
}

1;

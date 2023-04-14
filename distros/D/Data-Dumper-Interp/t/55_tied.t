#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug/; # Test::More etc.

use Data::Dumper::Interp;
use Clone qw/clone/;

#
# Verify handling of tied items (basically: Do no clone & substitute
#  because any write to tied objects, even if cloned, has unknowable effects)
#

package main::TieHash;
require Tie::Hash;

#use parent -norequire, 'Tie::StdHash';
our @ISA = ('Tie::StdHash'); # https://github.com/rjbs/Dist-Zilla/issues/705
use Carp;

sub STORE {
  confess "Write to tied Hash" unless $main::Initializing;
  my $self = shift;
  $self->SUPER::STORE(@_);
}

package main::TieArray;
require Tie::Array;
#use parent -norequire, 'Tie::StdArray';
our @ISA = ('Tie::StdArray'); # https://github.com/rjbs/Dist-Zilla/issues/705
use Carp;

sub STORE {
  confess "Write to tied Array" unless $main::Initializing;
  my $self = shift;
  $self->SUPER::STORE(@_);
}

package main::TieScalar;
require Tie::Scalar;
#use parent -norequire, 'Tie::StdScalar';
our @ISA = ('Tie::StdScalar'); # https://github.com/rjbs/Dist-Zilla/issues/705
use Carp;

sub STORE {
  confess "Write to tied Scalar" unless $main::Initializing;
  my $self = shift;
  $self->SUPER::STORE(@_);
}

package main::TieHandle;
require Tie::Handle;
#use parent -norequire, 'Tie::StdHandle';
our @ISA = ('Tie::StdHandle');
use Carp;
sub _checkwrite {
  my ($self, @args) = @_;
  my ($methname) = ((caller(1))[3]);
  $methname =~ s/.*:://;
  confess "Write to tied filehandle" unless $main::Initializing;
  eval "\$self->SUPER::${methname}(\@args)"; die $@ if $@;
}
sub STORE { &_checkwrite }
sub WRITE { &_checkwrite }
sub PRINT { &_checkwrite }
sub PRINTF { &_checkwrite }

######################### MAIN IS HERE #####################3

package main;

our $Initializing = 1;

sub specified_bignum($) {
  my $value = shift;
  use bignum;
  return ($value+0);
}
sub sample_bignum($) {
  my $addon = shift;
  use bignum;
  return (999999999999999999543210000.123450000000007 + $addon);
}

my ($scal, $scal0, @ary, %hash);

my $tscal0 = "PRE-TIED tscal0";
my $tscal = "PRE-TIED tscal";
my @tary = ("PRE-TIED tary[0]", "PRE-TIED tary[1]");
my %thash= (k1 => "PRE-TIED thash{k1}", k2 => "PRE-TIED thash{k2}");

tie $tscal0, 'main::TieScalar';

tie $tscal,  'main::TieScalar';
tie @tary,   'main::TieArray';
tie %thash,  'main::TieHash';

# I don't know how to test this, but probably not that important:
#   tie *FH, 'main::TieHandle', ">", "/dev/null" or die $!;
#   ...

$scal  = specified_bignum(123);
$scal0 = 888;
$tscal0 = 1999;

$tscal = specified_bignum(1123);

@ary  = (0..9, 3.14, sample_bignum(1));
@tary = (1000..1009, 1003.14, sample_bignum(1001));

%hash  = (a => 111, b => 3.14, c => sample_bignum(3));
%thash = (a => 1111, b => 1003.14, c => sample_bignum(1003));

$Initializing = 0;  # writes to tied items will now throw

#$Data::Dumper::Interp::Debug = 1;

$Data::Dumper::Interp::Foldwidth = 0; # disable wrap

is( vis(\42), "\\42", "\\42" );
is( vis(\"abc"), "\\\"abc\"", "\\\"abc\"" );

foreach (
         ['$scal',  qr/^\Q(Math::Big\E\w+\Q)123\E$/],
         ['$tscal', qr/^\Q(Math::Big\E\w+\Q)1123\E$/],

         ['[ $scal ]', qr/^\Q[(Math::Big\E\w+\Q)123]\E$/],
         ['[ $tscal ]', qr/^\Q[(Math::Big\E\w+\Q)1123]\E$/],

         ['\@ary', qr/^\Q[0,1,2,3,4,5,6,7,8,9,3.14,(Math::Big\E\w+\Q)999999999999999999543210001.123450000000007]\E$/ ],
         ['\@tary', qr/^\Q[1000,1001,1002,1003,1004,1005,1006,1007,1008,1009,1003.14,(Math::Big\E\w+\Q)999999999999999999543211001.123450000000007]\E$/ ],

         ['\%hash', qr/^\Q{a => 111,b => 3.14,c => (Math::Big\E\w+\Q)999999999999999999543210003.123450000000007}\E$/ ],
         ['\%thash', qr/^\Q{a => 1111,b => 1003.14,c => (Math::Big\E\w+\Q)999999999999999999543211003.123450000000007}\E$/ ],

        )
{
  my ($expr, $exp_re) = @$_;
  my $got = eval "vis($expr)";
  like($got, $exp_re, $expr);
}

done_testing();
#12345;

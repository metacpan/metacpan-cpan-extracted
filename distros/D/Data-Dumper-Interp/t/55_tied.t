#!/usr/bin/perl
use strict; use warnings  FATAL => 'all'; use feature qw(state say); use utf8;
#use open IO => ':locale';
use open ':std', ':encoding(UTF-8)';
STDOUT->autoflush();
STDERR->autoflush();
select STDERR;

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
  croak "Write to tied Hash" unless $main::Initializing;
  my $self = shift;
  $self->SUPER::STORE(@_);
}

package main::TieArray;
require Tie::Array;
#use parent -norequire, 'Tie::StdArray';
our @ISA = ('Tie::StdArray'); # https://github.com/rjbs/Dist-Zilla/issues/705
use Carp;

sub STORE {
  croak "Write to tied Array" unless $main::Initializing;
  my $self = shift;
  $self->SUPER::STORE(@_);
}

package main::TieScalar;
require Tie::Scalar;
#use parent -norequire, 'Tie::StdScalar';
our @ISA = ('Tie::StdScalar'); # https://github.com/rjbs/Dist-Zilla/issues/705
use Carp;

sub STORE {
  croak "Write to tied Scalar" unless $main::Initializing;
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
  croak "Write to tied filehandle" unless $main::Initializing;
  eval "\$self->SUPER::${methname}(\@args)"; die $@ if $@;
}
sub STORE { &_checkwrite }
sub WRITE { &_checkwrite }
sub PRINT { &_checkwrite }
sub PRINTF { &_checkwrite }

######################### MAIN IS HERE #####################3

package main;

use Test::More;
use Data::Dumper::Interp;
use Carp;

our $Initializing = 1;

sub get_bignum(;$) { 
  state $count = 0;
  use bignum; 
  @_ ? 0+shift()+0 
     : 999999999999999999999990000.123450000000007 + $count++;
}

my ($scal, @ary, %hash);
my ($tscal, @tary, %thash);

tie $tscal, 'main::TieScalar'; 
tie @tary,  'main::TieArray';  
tie %thash, 'main::TieHash';   

# I don't know how to test this, but probably not relevant
#tie *FH, 'main::TieHandle', ">", "/dev/null" or die $!;

$scal  = get_bignum(123);
$tscal = get_bignum(123);

@ary  = (0..9, 3.14, get_bignum());
@tary = (0..9, 3.14, get_bignum());

%hash  = (a => 111, b => 3.14, c => get_bignum());
%thash = (a => 111, b => 3.14, c => get_bignum());

$Initializing = 0;  # write to tied item will now throw

#$Data::Dumper::Interp::Debug = 1;

$Data::Dumper::Interp::Foldwidth = 0; # disable wrap
is( vis(\42), "\\42", "\\42" );
is( vis(\"abc"), "\\\"abc\"", "\\\"abc\"" );

foreach (
         #['$scal', '(Math::BigInt)123'],
         ['\$scal', '\(Math::BigInt)123'],
         ['\@ary', '[0,1,2,3,4,5,6,7,8,9,3.14,(Math::BigFloat)999999999999999999999990000.123450000000007]' ],
         ['\%hash', '{a => 111,b => 3.14,c => (Math::BigFloat)999999999999999999999990002.123450000000007}' ],
        )
{
  my ($untied_item, $untied_expected) = @$_;
  is (eval "vis($untied_item)", $untied_expected, 
      "vis($untied_item): $untied_expected");

  (my $tied_item = $untied_item) =~ s/([a-zA-Z])/t$1/ or die;
  my $s = eval "vis($tied_item)";
  ok ( !$@, "vis($tied_item) : tied item not modified" );
}

done_testing();
exit 0;


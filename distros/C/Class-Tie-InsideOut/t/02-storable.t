#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval "use Storable qw( freeze thaw dclone );";

plan skip_all => "Storable is not installed" if ($@);

our %a;
our @METHODS;

BEGIN {
  @METHODS = ('b'..'j');
  foreach my $method (@METHODS) {
    no strict 'refs';
    *$method = { };
  }
}

plan tests => 4 + (2*(1+scalar(@METHODS)));

use_ok("Tie::InsideOut", 0.05);

tie my %hash, 'Tie::InsideOut';

my $count = 1000;
foreach my $x ('a',@METHODS) { $hash{$x} = $count++; }

ok( (keys %a) == 1 );

my $frozen = freeze( \%hash );
my $thawed = thaw( $frozen );
my %copy = %{ $thawed };

ok( (keys %a) == 2 );

foreach my $x ('a',@METHODS) { ok($hash{$x} == $copy{$x}); }

my $clone_ref = dclone(\%hash);
my %clone     = %{ $clone_ref };

ok( (keys %a) == 3 );

foreach my $x ('a',@METHODS) { ok($hash{$x} == $clone{$x}); }



#!perl -T

use Test::More tests => 2;
use Config::Param;
use Storable qw(dclone);

use strict;

# Testing the array assignment syntax with selected separator.

my %default =
(
  'arr'=>[1,2,3]
, 'has'=>{bla=>'ble'}
);

my @pardef =
(
  'arr', $default{arr}, 'a', 'an array'
, 'has', $default{has}, 'H', 'a hash'
);

my @args = ('--arr/,/=buff,1,kra', '-a.=42', '--arr///.=over/out', '--arr/ /.=still more');
push(@args,
  '--has/,/=name=fritz,age=172,height=199.9'
, '-H.=weight=89'
, '--has///.=state=sleeping/temper=temperate'
, '--has/ /.=psi=none handicap=capped_hand'
);

my $p;
my %config = (verbose=>0);
my $builtins = Config::Param::builtins(\%config);

#$Config::Param::verbose = 1;

$config{nofile} = 1; # yeah, looks funny
$p = Config::Param::get(\%config,dclone(\@pardef),dclone(\@args));
for my $b (keys %{$builtins}){ delete $p->{$b}; }

# cmd line changes
my %afterfact = %{dclone(\%default)};
$afterfact{arr} = ['buff', 1, 'kra'];
push(@{$afterfact{arr}}, 42);
push(@{$afterfact{arr}}, 'over', 'out');
push(@{$afterfact{arr}}, 'still', 'more');
$afterfact{has} = {name=>'fritz',age=>172,height=>199.9};
$afterfact{has}{weight} = 89;
$afterfact{has}{state} = 'sleeping';
$afterfact{has}{temper} = 'temperate';
$afterfact{has}{psi} = 'none';
$afterfact{has}{handicap} = 'capped_hand';

is_deeply($p, \%afterfact, "compact array/hash from command line");

# Now from config file.
delete $config{nofile};
$p = Config::Param::get(\%config,dclone(\@pardef),[]);
for my $b (keys %{$builtins}){ delete $p->{$b}; }
is_deeply($p, \%afterfact, "compact array/hash from config file");

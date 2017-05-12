#!perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use Crypt::RS14_PP; # "ok_use" performed in 00-load.t

# Test vectors supplied by referenced algorithm description
my %vectors = (
    'ABC'     => "779a8e01f9e9cbc0",
    'spam'    => "f0609a1df143cebf",
    'arcfour' => "1afa8b5ee337dbc7",
);

my $nv = keys %vectors;
plan tests => 1 + (2 * $nv);

diag( "Testing cipher stream: Crypt::RS14_PP $Crypt::RS14_PP::VERSION, Perl $], $^X" );

my $c = new_ok('Crypt::RS14_PP') or BAIL_OUT('new failed');

my $w = ''; # holds intercepted warning message

while (my ($key, $xt) = each %vectors)
{
    {
        local $SIG{__WARN__} = sub { $w = $_[0] };
        $c->set_key($key);
    }
    if (($w eq '') or ($w =~ /key too short/))
    {
        pass("set_key($key)")
    }
    else
    {
        BAIL_OUT("set_key($key) failed: $w");
    }
    my $pt = "\0" x (length($xt) / 2); # string of nulls of same length as expected cipher stream
    my $ct = unpack('H*', $c->encrypt($pt));
    is($ct, $xt, "encrypt with $key");
}

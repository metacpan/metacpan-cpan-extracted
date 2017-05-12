#!perl -T

use strict;
use warnings;

use Test::More tests => 2;

use lib 't/lib';

use Acme::CPANAuthors;

local @INC = grep $_ ne '.', @INC;

our $test_loaded;
local $test_loaded = 0;

my $err = do {
 local $SIG{__WARN__} = sub {
  my $msg = join "\n", @_;
  if ($msg =~ /cabbage/) {
   die "$msg\n";
  } else {
   diag $msg;
  }
 };
 eval { Acme::CPANAuthors->new("You're_using") };
 $@;
};

is $test_loaded, 1,  'naughty module was actually loaded';
is $err,         '', 'naughty module did not make us croak';

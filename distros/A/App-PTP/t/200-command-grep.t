#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 17;

{
  my $data = ptp([qw(--grep oo)], 'default_data.txt');
  is($data, "foobar=\nfoobaz\n", 'simple');
}{
  my $data = ptp([qw(-g a(b|z))], 'default_data.txt');
  is($data, "ab/cd\nfoobaz\n", 'regex');
}{
  my $data = ptp([qw(-g b)], 'default_data.txt');
  is($data, "foobar=\nab/cd\nfoobaz\n", 'no case insensitive');
}{
  my $data = ptp([qw(-I -g b)], 'default_data.txt');
  is($data, "foobar=\nab/cd\nBe\nfoobaz\n", 'case insensitive');
}{
  my $data = ptp([qw(-V -g b)], \"ab\ncd\nabc\nef\n");
  is($data, "cd\nef\n", 'inverted');
}{
  my $data = ptp([qw(-I -S -g b)], 'default_data.txt');
  is($data, "foobar=\nab/cd\nfoobaz\n", 'case sensitive');
}{
  my $data = ptp([qw(-g b -I)], 'default_data.txt');
  is($data, "foobar=\nab/cd\nfoobaz\n", 'case insensitive too late');
}{
  my $data = ptp([qw(-g c.)], 'default_data.txt');
  is($data, "ab/cd\n", 'no quote');
}{
  my $data = ptp([qw(-Q -g c.)], 'default_data.txt');
  is($data, '', 'quoted');
}{
  my $data = ptp([qw(-Q -g .\+)], 'default_data.txt');
  is($data, ".\\+\n", 'quoted2');
}{
  my ($data, $err) = ptp(['-Q', '-g', '(b)'], \"a(b)c\nabc\n");
  is($data, "a(b)c\n", 'quoted with paren') or diag $err;
}{
  my $data = ptp(['-Q', '-g', '{b}'], \"a{b}c\nabc\n");
  is($data, "a{b}c\n", 'quoted with brace');
}{
  my $data = ptp(['-g', '{b}'], \"a{b}c\nabc\n");
  is($data, "a{b}c\n", 'non quoted with brace');
}{
  my $data = ptp(['-Q', '-g', '[b]'], \"a[b]c\nabc\n");
  is($data, "a[b]c\n", 'quoted with bracket');
}{
  my $data = ptp(['-g', '[b]'], \"a[b]c\nabc\n");
  is($data, "a[b]c\nabc\n", 'non quoted with bracket');
}

SKIP: {
  eval { require re::engine::GNU };
  skip 're::engine::GNU not installed', 2 if $@;
  
  {  
    my $data = ptp(['-re', 'GNU', '-g', '\n'], \"ned\nbar\n");
    is($data, "ned\n", 'new line GNU');  
  }{
    my $data = ptp(['-re', 'perl', '-g', '\n'], \"ned\nbar\n");
    is($data, "", 'new line perl');  
  }
}

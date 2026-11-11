#!/usr/bin/perl
# Hostile input: linear time, and no header injection through make.
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use lib 'lib', 't/lib';
use Data::JSEmail;

# a long run of spaces inside a header value: \s*$ made this quadratic
{
  my $m = "From: a\@b\r\nSubject: a" . (" " x 320_000) . "b\r\n\r\nx\r\n";
  my $t0 = time;
  my $e = Data::JSEmail::parse($m, 'x');
  cmp_ok(time - $t0, '<', 2, 'a 320KB run of spaces in Subject parses in linear time');
  like($e->{subject}, qr/^a {320000}b$/, 'and the subject is kept');
}

# make: disposition and language go into part headers as they are, so
# anything but a token or a language tag is refused
{
  my %base = (from => [{ email => 'a@example.com' }], subject => 's',
              bodyStructure => { type => 'text/plain', partId => '1' }, bodyValues => { 1 => { value => 'x' } });
  my $att = sub { my ($k, $v) = @_; +{ %base, bodyStructure => { type => 'multipart/mixed', subParts => [
    { type => 'text/plain', partId => '1' }, { type => 'text/plain', partId => '2', $k => $v } ] },
    bodyValues => { 1 => { value => 'x' }, 2 => { value => 'y' } } } };
  ok(eval { Data::JSEmail::make($att->(disposition => 'attachment')); 1 }, 'a disposition token') or diag $@;
  ok(!eval { Data::JSEmail::make($att->(disposition => "attachment\rX-Evil: 1")); 1 }, 'a CR in disposition is refused');
  ok(eval { Data::JSEmail::make($att->(language => ['en-AU'])); 1 }, 'a language tag') or diag $@;
  ok(!eval { Data::JSEmail::make($att->(language => ["en\rX-Lang: 1"])); 1 }, 'a CR in a language is refused');
}

done_testing;

#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use File::Spec::Functions 'catfile';
use Test::More tests => 38;


for my $use_safe (0..2) {
  my $s = $use_safe ? ' safe' : '';
  $s = ' very'.$s if $use_safe eq 2;
  my $run = sub { ptp(['--safe', "${use_safe}", @_], 'default_small.txt'); };
  {
    my $data = $run->(qw(--load module.pm -n $var++.$_));
    is($data, "42foobar\n43foobaz\n44\n45last\n", 'load and perl'.$s);
  }{
    my $data = $run->(qw(-e $var=42 -n $var++.$_));
    is($data, "42foobar\n43foobaz\n44\n45last\n", 'execute and perl'.$s);
  }{
    my $data = $run->(qw(-p $a[$n]=/o/ -f $a[$n]));
    is($data, "foobar\nfoobaz\n", 'perl and filter'.$s);
  }{
    my $data = $run->(qw(-p $a[$n]=/o/ --ml $a[$n] --delete-marked));
    is($data, "\nlast\n", 'perl, mark and delete'.$s);
  }{
    my $data = $run->(qw(-p ($a[$n])=/ooba(.)/g --ml $a[$n] --insert-after
                         $a[$n]));
    is($data, "foobar\nr\nfoobaz\nz\n\nlast\n", 'perl, mark and insert'.$s);
  }{
    my $data = $run->(qw(-e $a='o' -g $a));
    is($data, "foobar\nfoobaz\n", 'grep with var'.$s);
  }{
    my $data = $run->(qw(-e $a='o' -s $a i));
    is($data, "fiibar\nfiibaz\n\nlast\n", 'substitute match on var'.$s);
  }{
    my $data = $run->(qw(-e $a='i' -s o $a));
    is($data, "fiibar\nfiibaz\n\nlast\n", 'substitute with var'.$s);
  }{
    my $data = $run->(qw(-g foo -n ++$a.$_ default_small.txt -));
    is($data, "1foobar\n2foobaz\n1foobar\n2foobaz\n", 'env is reset'.$s);
  }{
    my $data = $run->(qw(--preserve-perl-env -g foo -n ++$a.$_
                         default_small.txt -));
    is($data, "1foobar\n2foobaz\n3foobar\n4foobaz\n", 'env is preserved'.$s);
  }{
    my $data = $run->(qw(-g foo -n $I.'-'.$n.$_ default_small.txt -));
    is($data, "1-1foobar\n1-2foobaz\n2-1foobar\n2-2foobaz\n", '$I'.$s);
  }
}

{
  eval { ptp(['--safe', '1', '-e', 'exec("foo")']) };
  ok($@ =~ /Perl code failed.*trapped by operation mask/,
     'exec forbidden with --safe 1');
}{
  eval { ptp(['--safe', '1', '-e',
              'use Tie::Scalar; my $a; tie $a, "Tie::StdScalar";']) };
  ok(!$@, 'tie allowed with --safe 1');
}{
  eval { ptp(['--safe', '2', '-e',
              'use Tie::Scalar; my $a; tie $a, "Tie::StdScalar";']) };
  ok($@ =~ /Perl code failed.*trapped by operation mask/,
     'tie disallowed with --safe 2');
}{
  is(ptp(['--pivot', '-M', 'File::Spec', '-n', 'File::Spec->catfile("foo", "bar")', 'src/fake.h']), catfile('foo', 'bar')."\n", 'load module');
}{
  is(ptp(['--pivot', '-n', 'dirname($f)', 'src/fake.h']), "src\n", 'default module');
}

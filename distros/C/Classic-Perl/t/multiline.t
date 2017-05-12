#!./perl

use Test::More tests => 24;
#use warnings;
no warnings < deprecated syntax >;

$* = 1;
$old = "\nfoo" =~ /^foo/;
$* = 0;

use Classic'Perl;
$* = 1;
ok "\nfoo" =~ /^foo/, '$* affects match';
$_ = "\nfoo";
s/^foo/bar/;
is $_, "\nbar", '$* affects s///';
ok "\nfoo" =~ qr/^foo/, '$* affects qr';
$* = 0;
ok "\nfoo" !~ /^foo/, '$* = 0 affects match';
$_ = "\nfoo";
s/^foo/bar/;
is $_, "\nfoo", '$* = 0 affects s///';
ok "\nfoo" !~ qr/^foo/, '$* = 0 affects qr';

{
 local $* = 1;
 ok "\nfoo" =~ /^foo/, 'local $* affects match';
 $_ = "\nfoo";
 s/^foo/bar/;
 is $_, "\nbar", 'local $* affects s///';
 ok "\nfoo" =~ qr/^foo/, 'local $* affects qr';
}

ok "\nfoo" !~ /^foo/, 'old m restored when local $* falls out of scope';
$_ = "\nfoo";
s/^foo/bar/;
is $_, "\nfoo", 'old s/// restored when local $* falls out of scope';
ok "\nfoo" !~ qr/^foo/, 'old qr restored when local $* falls out of scope';

{
 local ($*) = 1;
 ok "\nfoo" =~ /^foo/, 'local ($*) affects match';
 $_ = "\nfoo";
 s/^foo/bar/;
 is $_, "\nbar", 'local ($*) affects s///';
 ok "\nfoo" =~ qr/^foo/, 'local ($*) affects qr';
}

($*) = 1;
ok "\nfoo" =~ /^foo/, '($*) = 1 affects match';
$_ = "\nfoo";
s/^foo/bar/;
is $_, "\nbar", '($*) = 1 affects s///';
ok "\nfoo" =~ qr/^foo/, '($*) = 1 affects qr';

$* = 0;

no Classic'Perl;
$* = 1;
is "\nfoo" =~ /^foo/, $old, 'no CP restores the prev $* behaviour';

use Classic'Perl;
$* = 1;
no Classic'Perl;
is "\nfoo" =~ /^foo/, $old, 'no CP restores the prev $* when set to 1';

use Classic'Perl 'split';
$* = 1;
is "\nfoo" =~ /^foo/, $old, 'other CP pragmata leave multiline off';

{
 use Classic'Perl
}
$* = 1;
is "\nfoo" =~ /^foo/, $old, 'CP lasts only till the end of the block';

{
 use Classic::::Perl 5.009;
 $* = 1;
 is "\nfoo" =~ /^foo/, $old, 'Classic::::Perl 5.009 leaves $* off';
 use Classic::::Perl 5.008999;
 $* = 1;
 ok "\nfoo" =~ /^foo/, 'Classic::::Perl 5.008999 enables $*';
}

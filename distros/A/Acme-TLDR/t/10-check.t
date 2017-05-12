#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

BEGIN { @ENV{qw{DEBUG NOCACHE}} = qw(1 1) };

use Acme::TLDR;
use D::MD5;

my $md5 = D::MD5->new;
isa_ok($md5, q(Digest::MD5));

$md5->add(q(hello world));
is($md5->hexdigest, q(5eb63bbbe01eeed093cb22bb8f5acdc3), q(checksum match));

done_testing 2;

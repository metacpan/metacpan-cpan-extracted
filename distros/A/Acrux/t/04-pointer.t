#!/usr/bin/perl -w
#########################################################################
#
# Serż Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2026 D&D Corporation
#
# This program is distributed under the terms of the Artistic License 2.0
#
#########################################################################
use Test::More;
use Acrux::Pointer;

is(Acrux::Pointer->new(data => 'just a string')->get, 'just a string', 'Get text');
ok(Acrux::Pointer->new(data => 'just a string')->contains, 'Text');

my $d = {foo => 'bar', baz => [4, 5, 6], qux => {quux => 'test'}};
my $p = Acrux::Pointer->new(data => $d);

is($p->get('/foo'), 'bar', 'Get text value');
is($p->get('/baz/0'), 4, 'Get first value');
is($p->get('/baz/2'), 6, 'Get last value');
is($p->get('foo'), 'bar', 'Get text value by simple path1');
is($p->get('qux/quux'), 'test', 'Get text value by simple path2');

# True
ok($p->contains('/foo'), '/foo is found');
ok($p->contains('/baz/1'), '/baz/1 is found');

# False
ok(!$p->contains('/bar'), '/bar is not found');
ok(!$p->contains('/baz/9'), '/baz/9 is not found');

done_testing;

1;

__END__

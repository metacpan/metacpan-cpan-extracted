# $Id: anon.t,v 1.2 2006/10/19 18:18:22 sullivan Exp $

use Test::More tests => 3;
BEGIN { use_ok('Class::Simple') };		##

use Class::Simple;

my $foo = Class::Simple->new();
isa_ok($foo, 'Class::Simple');			##
$foo->set_bar(1);
is($foo->bar, 1, 'Anonymous setting.');		##

1;

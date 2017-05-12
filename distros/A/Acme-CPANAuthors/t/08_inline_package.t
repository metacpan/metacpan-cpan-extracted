use strict;
use warnings;
use Test::More tests => 2;

package # hide from pause
  Acme::CPANAuthors::TestInline;
use Acme::CPANAuthors::Register (
  ISHIGAKI => 'Kenichi Ishigaki',
);

package main;
use Acme::CPANAuthors;

my $authors = eval { Acme::CPANAuthors->new('TestInline') };
ok !$@, "no errors";
ok $authors && $authors->name('ISHIGAKI') eq 'Kenichi Ishigaki', "got a correct name";

use strict;
use warnings;
use Test::More tests => 4;
use Acme::CPANAuthors;

my $authors = new_ok('Acme::CPANAuthors' => [ 'GitHub' ]);
ok $authors->count, 'found authors';
# Force list context.
ok 1 <= (() = $authors->id), 'author ids';
ok $authors->name('GRAY'), 'author name';

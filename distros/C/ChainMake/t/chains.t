#!/usr/bin/perl

use strict;
use Test::More tests => 75;
use File::Touch;

BEGIN {
    use_ok('ChainMake::Tester',":all");
    use_ok('ChainMake::Functions',":all")
};

ok(configure(
    verbose => 0,
    silent  => 1,
    timestamps_file => 'test-chains.stamps',
),'configure');

unlink ('A.test','B.test','C.test','E.test','F.test');

ok(unlink_timestamps(),'clean timestamps');

ok((target 'A',
    timestamps   => ['A.test'],
    handler => sub {
        touch 'A.test';
        have_made('A');
        1;
    }),
"declare target A");

ok((target 'B',
    timestamps   => ['B.test'],
    requirements => ['A'],
    handler => sub {
        touch 'B.test';
        have_made('B');
        1;
    }),
"declare target B");

ok((target 'C',
    timestamps   => ['C.test'],
    requirements => ['B'],
    handler => sub {
        touch 'C.test';
        have_made('C');
        1;
    }),
"declare target C");

ok((target 'D',
    timestamps   => 'once',
    requirements => ['B'],
    handler => sub {
        have_made('D');
        1;
    }),
"declare target D");

ok((target 'E',
    timestamps   => ['E.test'],
    requirements => ['D'],
    handler => sub {
        touch 'E.test';
        have_made('E');
        1;
    }),
"declare target E");

ok((target 'F',
    timestamps   => ['F.test'],
    requirements => ['C','E'],
    handler => sub {
        touch 'F.test';
        have_made('F');
        1;
    }),
"declare target F");

ok((target 'G',
    timestamps   => 'once',
    requirements => ['D'],
    handler => sub {
        have_made('G');
        1;
    }),
"declare target G");

note "Nomenclature:";
note "[A] timestamps is missing";
note "[a] timestamps is up-to-date";
note "[a/A] timestamps is present but out of date";

note "\nfirst we test the branch A->B->C";

my_ok('C','ABC','A->B->C');
my_ok('C','','a->b->c');

sleep(1); # filesystem modify timestamp has a resolution of 1s (2s on Fat32)
ok((unlink 'C.test'),'unlink C.test');
my_ok('C','C','a->b->C');
my_ok('C','','a->b->c');

sleep(1);
ok((unlink 'B.test'),'unlink B.test');
my_ok('C','BC','a->B->c/C');
my_ok('C','','a->b->c');

sleep(1);
ok((unlink 'A.test'),'unlink A.test');
my_ok('C','ABC','A->b/B->c/C; see a->B->c below');
my_ok('C','','a->b->c');
my_ok('B','','a->b->c');
my_ok('A','','a->b->c');

sleep(1);
ok((unlink 'A.test'),'unlink A.test');
ok((unlink 'B.test'),'unlink B.test');
ok((unlink 'C.test'),'unlink C.test');
my_ok('A','A','A->B->C');
my_ok('B','B','a->B->C');
my_ok('C','C','a->b->C');

sleep(1);
ok((unlink 'A.test'),'unlink A.test');
ok((unlink 'B.test'),'unlink B.test');
ok((unlink 'C.test'),'unlink C.test');
my_ok('B','AB','A->B->C');

sleep(1);
ok((unlink 'A.test'),'unlink A.test');
ok((unlink 'B.test'),'unlink B.test');
my_ok('C','ABC','a->b->C');

sleep(1);
ok((unlink 'A.test'),'unlink A.test');
my_ok('C','ABC','A->b/B->c/C');

sleep(1);
ok((unlink 'B.test'),'unlink B.test');
my_ok('B','B','a->B->c/C');
my_ok('C','C','a->b->c/C (because b is newer)');

note "\nnow we test the branch A->B->D->E";
note "where D is timestamps   => 'once'";

my_ok('E','DE','a->b->D->E');
my_ok('E','','a->b->d->e'); ###!!! 44
my_ok('D','','a->b->d->e');

sleep(1);
ok(!delete_timestamp('E'),'remove timestamp E returns 0');
ok(delete_timestamp('D'),'remove timestamp D');
ok(!delete_timestamp('D'),'remove timestamp D a second time returns 0');

my_ok('D','D','a->b->D->e/E');
my_ok('E','E','a->b->d->e/E');

note "\nnow we test combinations of the branches";
note "A->B->D->E and A->B->C";

sleep(1);
ok((unlink 'B.test'),'unlink B.test');
my_ok('C','BC','a->B->c/C; a->B->d/D->e/E');
my_ok('D','D','a->b->c; a->b->d/D->e/E');
my_ok('E','E','a->b->c; a->b->d->e/E');

sleep(1);
ok(delete_timestamp('D'),'remove timestamp D');
my_ok('E','DE','a->b->c; a->b->D->e/E');

note "\nnow we test C,E->F";

sleep(1);
ok((unlink 'A.test'),'unlink A.test');
ok((unlink 'B.test'),'unlink B.test');
ok((unlink 'C.test'),'unlink C.test');
ok(delete_timestamp('D'),'remove timestamp D');
ok((unlink 'E.test'),'unlink E.test');
my_ok('F','ABCDEF','A->B->C->F; A->B->D->E->F (includes build order)');
my_ok('F','','a->b->c->f; a->b->d->e->f');

sleep(1);
ok(delete_timestamp('D'),'remove timestamp D');
my_ok('F','DEF','a->b->c->f; a->b->D->e/E->f/F');

note "\nnow we test the branch D->G";
note "where D and G are both timestamps   => 'once'";

sleep(1);
ok(delete_timestamp('D'),'remove timestamp D');
my_ok('G','DG','a->b->D->G');
my_ok('G','','a->b->d->g');

sleep(1);
ok(delete_timestamp('D'),'remove timestamp D');
ok(!delete_timestamp('D'),'remove timestamp D a second time returns 0');
ok(delete_timestamp('G'),'remove timestamp G');
ok(!delete_timestamp('G'),'remove timestamp G a second time returns 0');
my_ok('D','D','a->b->D->G');
my_ok('G','G','a->b->d->G');

ok(unlink_timestamps(),'clean timestamps');
unlink ('A.test','B.test','C.test','E.test','F.test');




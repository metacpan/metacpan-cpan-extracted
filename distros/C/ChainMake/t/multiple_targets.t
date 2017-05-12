#!/usr/bin/perl

# this tests targets with multiple names

use strict;
use Test::More tests => 48;
use File::Touch;

BEGIN {
    use_ok('ChainMake::Functions',":all");
    use_ok('ChainMake::Tester',":all")
};

ok(configure(
    verbose => 0,
    silent  => 1,
    timestamps_file => 'test-multiple.stamps',
),'configure');

ok((targets ['A1','A2'],
    timestamps   => 'once',
    handler => sub {
        my $t_name=shift;
        have_made($t_name);
        1;
    }),
"declare targets A1, A2");

my_ok('A1','A1','Targettype with names A1, A2');
my_ok('A2','A2','Targettype with names A1, A2');
my_nok('A','','Targettype with names A1, A2');
my_nok('A3','','Targettype with names A1, A2');

ok((targets ['B',qr/^B\d$/],
    timestamps   => 'once',
    handler => sub {
        my $t_name=shift;
        have_made($t_name);
        1;
    }),
"declare targets B, B\\d");

my_ok('B','B','Targettype with names B, B\d');
my_ok('B3','B3','Targettype with names B, B\d');
my_ok('B0','B0','Targettype with names B, B\d');
my_nok('B00','','Targettype with names B, B\d');
my_nok('Bx','','Targettype with names B, B\d');
my_nok(' B4','','Targettype with names B, B\d');
my_nok('b2','','Targettype with names B, B\d');

ok((targets [qr/^CC[^c]*CC$/,qr/C\d/],
    timestamps   => 'once',
    handler => sub {
        my $t_name=shift;
        have_made($t_name);
        1;
    }),
"declare targets C");

my_nok('C','','Targettype with two regexp names CC*CC, C\d');
my_ok('C2','C2','Targettype with two regexp names CC*CC, C\d');
my_ok('C2','','Targettype with two regexp names CC*CC, C\d');
my_ok('C00','C00','Targettype with two regexp names CC*CC, C\d');
my_nok('Cx','','Targettype with two regexp names CC*CC, C\d');
my_ok(' C4',' C4','Targettype with two regexp names CC*CC, C\d');
my_nok('c2','','Targettype with two regexp names CC*CC, C\d');
my_ok('CCCC','CCCC','Targettype with two regexp names CC*CC, C\d');
my_nok('xCCCC','','Targettype with two regexp names CC*CC, C\d');
my_nok('CCCC ','','Targettype with two regexp names CC*CC, C\d');
my_ok('CCssadCC','CCssadCC','Targettype with two regexp names CC*CC, C\d');
my_ok('CCäöüßCC','CCäöüßCC','Targettype with two regexp names CC*CC, C\d');
my_ok('CCäöüßCC','','Targettype with two regexp names CC*CC, C\d');

ok((targets ['D'],
    timestamps   => 'once',
    requirements => ['CC$t_nameCC','C2'],
    handler => sub {
        my $t_name=shift;
        have_made($t_name);
        1;
    }),
"declare targets D");

my_ok('D','CCDCCD','CCDCC,C2->D');
my_ok('D','','CCDCC,C2->D');

ok(unlink_timestamps(),'clean timestamps');
my_ok('D','CCDCCC2D','CCDCC,C2->D');

sleep(1);
ok(delete_timestamp('D'),'Remove timestamp D');
my_ok('D','D','CCDCC,C2->D');

sleep(1);
ok(delete_timestamp('C2'),'Remove timestamp C2');
my_ok('D','C2D','CCDCC,C2->D');

sleep(1);
ok(delete_timestamp('CCDCC'),'Remove timestamp CCDCC');
my_ok('D','CCDCCD','CCDCC,C2->D');

ok((targets ['E.1','E.2'],
    requirements => ['CCE$t_extECC'],
    handler => sub {
        my $t_name=shift;
        have_made($t_name);
        1;
    }),
"declare targets E.1, E.2");

my_ok('E.1','CCE1ECCE.1','CCE$t_extECC->E.1,E.2');
my_ok('E.2','CCE2ECCE.2','CCE$t_extECC->E.1,E.2');

ok((targets [qr/^F\.\d{2}$/],
    requirements => ['CC$t_base$t_ext$t_baseCC'],
    handler => sub {
        my $t_name=shift;
        have_made($t_name);
        1;
    }),
"declare targets F.\\d\\d");

my_ok('F.01','CCF01FCCF.01','CCF$t_extFCC->F.\d\d');
my_ok('F.32','CCF32FCCF.32','CCF$t_extFCC->F.\d\d');

ok(unlink_timestamps(),'clean timestamps');

#!perl
use strict;
use warnings;
use Test::More tests => 69;
use Test::Expect;

expect_run
(
    command => "$^X -Ilib -MCarp::REPL=noprofile t/scripts/02-lexicals.pl",
    prompt  => '$ ',
    quit    => 'exit',
);

expect_send('1 + 1');
expect_like(qr/\b2\b/, 'in the REPL');

expect_send('$pi');
expect_like(qr/\b3\.1415\b/, 'simple scalar works');

expect_send('$pi_ref');
expect_like(qr/\bSCALAR\b/, 'simple scalar ref works 1/2');

expect_send('$$pi_ref');
expect_like(qr/\b3\.1415\b/, 'simple scalar ref works 2/2');

expect_send('@grades');
expect_like(qr/\bA B C D F\b/, 'simple array works');

expect_send('$grades');
expect_like(qr/\bARRAY\b/, 'simple array ref works 1/4');

expect_send('$grades2');
expect_like(qr/\bARRAY\b/, 'simple array ref works 2/4');

expect_send('@$grades');
expect_like(qr/\bA B C D F\b/, 'simple array ref works 3/4');

expect_send('@$grades2');
expect_like(qr/\bA B C D F\b/, 'simple array ref works 4/4');

expect_send('%grade_of');
expect_like(qr/\bAbe A\b/, 'simple hash works 1/5');
expect_like(qr/\bBo B\b/,  'simple hash works 2/5');
expect_like(qr/\bCal C\b/, 'simple hash works 3/5');
expect_like(qr/\bDoy D\b/, 'simple hash works 4/5');
expect_like(qr/\bFun F\b/, 'simple hash works 5/5');

expect_send('$grade_of');
expect_like(qr/\bHASH\b/, 'simple hash ref works 1/6');

expect_send('$grade_of2');
expect_like(qr/\bHASH\b/, 'simple hash ref works 2/6');

expect_send('%$grade_of');
expect_like(qr/\bAbe A\b/, 'simple hash works 3/6');

expect_send('%$grade_of2');
expect_like(qr/\bAbe A\b/, 'simple hash works 4/6');

expect_send('$grade_of->{Bo}');
expect_like(qr/\bB\b/, 'simple hash works 5/6');

expect_send('$grade_of2->{Cal}');
expect_like(qr/\bC\b/, 'simple hash works 6/6');

expect_send('$closure');
expect_like(qr/\bCODE\b/, 'simple code ref works 1/3');

expect_send('$closure->("Abe")');
expect_like(qr/\bA\b/, 'simple code ref works 2/3');

expect_send('$closure->("Doy")');
expect_like(qr/\bD\b/, 'simple code ref works 3/3');

expect_send('$deep');
expect_like(qr/\bHASH\b/, 'deep references work 1/7');

expect_send('$deep->{eidolos}');
expect_like(qr/\bARRAY\b/, 'deep references work 2/7');

expect_send('$deep->{eidolos}[0]');
expect_like(qr/\bHASH\b/, 'deep references work 3/7');

expect_send('$deep->{eidolos}[0]{role}');
expect_like(qr/\bWiz\b/, 'deep references work 4/7');

expect_send('$deep->{marvin}');
expect_like(qr/\bARRAY\b/, 'deep references work 5/7');

expect_send('$deep->{marvin}[-1]');
expect_like(qr/\bHASH\b/, 'deep references work 6/7');

expect_send('$deep->{marvin}[-1]{death}');
expect_like(qr/\bkilled by a plains centaur\b/, 'deep references work 7/7');

expect_send('$regex');
expect_like(qr/\bbb\b/, 'qr works');

expect_send('$object');
expect_like(qr/\bPoint=HASH\b/, 'objects work 1/5');

expect_send('$object->x');
expect_like(qr/\b80\b/, 'objects work 2/5');

expect_send('$object->y');
expect_like(qr/\b24\b/, 'objects work 3/5');

expect_send('$object->y(25)');
expect_like(qr/\b25\b/, 'objects work 4/5');

expect_send('$object->can("x")');
expect_like(qr/\bCODE\b/, 'objects work 5/5');


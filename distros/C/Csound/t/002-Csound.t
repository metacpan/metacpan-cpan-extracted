use strict;
use warnings;
use utf8;

use Test::More   tests => 29;
# use Test::Files;

use Csound;

is(Csound::is_note('d5' ), 1, 'd5 is a note'     );
is(Csound::is_note('f11'), 1, 'f11 is a note'    );
is(Csound::is_note('h11'), 0, 'h11 is not a note');
is(Csound::is_note('foo'), 0, 'foo is not a note');
is(Csound::is_note('c♯4'), 1, 'c#4 is a note'    );
is(Csound::is_note('b♭9'), 1, 'bb9 is a note'    );
is(Csound::is_note('foo'), 0, 'foo is not a note');

is(Csound::note_to_pch('c1' ), '1.00', 'note c1  is pch 1.00');
is(Csound::note_to_pch('c♯1'), '1.01', 'note c#1 is pch 1.01');
is(Csound::note_to_pch('c♭1'), '0.11', 'note c#1 is pch 0.11');
                                                            
is(Csound::note_to_pch('d1' ), '1.02', 'note d1  is pch 1.02');
is(Csound::note_to_pch('d♭1'), '1.01', 'note db1 is pch 1.01');
is(Csound::note_to_pch('d♯1'), '1.03', 'note d#1 is pch 1.03');
                                                            
is(Csound::note_to_pch('e1' ), '1.04', 'note e1  is pch 1.04');
is(Csound::note_to_pch('e♭1'), '1.03', 'note eb1 is pch 1.03');
is(Csound::note_to_pch('e♯1'), '1.05', 'note e#1 is pch 1.05');
                                                            
is(Csound::note_to_pch('f1' ), '1.05', 'note f1  is pch 1.05');
is(Csound::note_to_pch('f♭1'), '1.04', 'note fb1 is pch 1.04');
is(Csound::note_to_pch('f♯1'), '1.06', 'note f#1 is pch 1.06');
                                                            
is(Csound::note_to_pch('g1' ), '1.07', 'note g1  is pch 1.07');
is(Csound::note_to_pch('g♭1'), '1.06', 'note gb1 is pch 1.06');
is(Csound::note_to_pch('g♯1'), '1.08', 'note g#1 is pch 1.08');
                                                            
is(Csound::note_to_pch('a1' ), '1.09', 'note a1  is pch 1.09');
is(Csound::note_to_pch('a♭1'), '1.08', 'note ab1 is pch 1.08');
is(Csound::note_to_pch('a♯1'), '1.10', 'note a#1 is pch 1.10');
                                                            
is(Csound::note_to_pch('b1' ), '1.11', 'note b1  is pch 1.11');
is(Csound::note_to_pch('b♭1'), '1.10', 'note bb1 is pch 1.10');
is(Csound::note_to_pch('b♯1'), '2.00', 'note b#1 is pch 2.00');

is(Csound::note_to_pch('c4' ), '4.00', 'note c4  is pch 4.00');

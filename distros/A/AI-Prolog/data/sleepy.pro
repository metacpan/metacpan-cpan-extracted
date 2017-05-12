/* "Sleepy" -- a sample adventure game, by David Matuszek. */

% http://www.csc.vill.edu/~dmatusze/resources/prolog/sleepy.html
/* In standard Prolog, all predicates are "dynamic": they
   can be changed during execution. SWI-Prolog requires such
   predicates to be specially marked. */

% :- dynamic at/2, i_am_at/1, i_am_holding/1, alive/1,
%           lit/1, visible_object/1.

/* This routine is purely for debugging purposes. */

%dump :- listing(at), listing(i_am_at), listing(i_am_holding),
%        listing(alive), listing(lit), listing(visible_object).

/* This defines my current location. */

i_am_at(bedroom).

i_am_holding(nothing).

/* These facts describe how the rooms are connected. */

path(bedroom, n, den) :- lit(bedroom).
path(bedroom, n, den) :-
    print('You trip over something in the dark.'), nl,
    !, fail.
path(den, s, bedroom).

path(bedroom, d, bed).
path(bed, u, bedroom).


% These facts tell where the various objects in the game
%   are located.

at(flyswatter, den).
at(fly, bedroom).
at('light switch', den).
at('light switch', bedroom).


/* These facts specify some game-specific information. */

alive(fly).

lit(bedroom).
lit(den).

visible_object('light switch').

/* These rules describe how to pick up an object. */

take(fly) :-
    print('It is too fast for you!'), nl,
    !, fail.

take('light switch') :-
    take(switch).

take(switch) :-
    print('It is firmly embedded in the wall!'), nl,
    !, fail.

take(X) :-
        i_am_holding(X),
        print('You are already holding it!'),
        nl.

take(X) :-
        i_am_at(Place),
        at(X, Place),
        retract(at(X, Place)),
        assert(i_am_holding(X)),
        print('OK.'),
        nl.

take(_) :-
        print('I do not see it here.'),
        nl.


/* These rules describe how to put down an object. */

drop(X) :-
        i_am_holding(X),
        i_am_at(Place),
        retract(i_am_holding(X)),
        assert(at(X, Place)),
        print('OK.'),
        nl.

drop(_) :-
        print('You are not holding it!'),
        nl.


/* These rules define the six direction letters as calls to go/1. */

n :- go(n).

s :- go(s).

e :- go(e).

w :- go(w).

u :- go(u).

d :- go(d).


/* This rule tells how to move in a given direction. */

go(Direction) :-
        i_am_at(Here),
        path(Here, Direction, There),
        retract(i_am_at(Here)),
        assert(i_am_at(There)),
        look.

go(_) :-
        print('You can not go that way.'), nl.


/* This rule tells how to look about you. */

look :-
        i_am_at(Place),
        describe(Place),
        nl,
        notice_objects_at(Place),
        nl.


/* These rules set up a loop to mention all the objects in your vicinity. */

notice_objects_at(Place) :-
    lit(Place),
        at(X, Place),
    visible_object(X),
        print('There is a '), print(X), print(' here.'), nl,
        fail.

notice_objects_at(_).


/* These rules are specific to this particular game. */

use(flyswatter) :-
    swat(fly).

use(bed) :-
    i_am_at(bedroom),
    d.

use(bed) :-
    print('It is in the bedroom!'), nl,
    !, fail.

use(switch) :-
    i_am_at(Place),
    lit(Place),
    off.

use(switch) :-
    on.

on :-
    i_am_at(bed),
    print('You can not reach the light switch from here.'), nl,
    !, fail.

on :-
    i_am_at(Place),
    lit(Place),
    print('The lights are already on.'), nl.

on :-
    i_am_at(Place),
    assert(lit(Place)),
    print('The room lights come on.'), nl,
    optional_buzz_off,
    look.

off :-
    i_am_at(bed),
    print('You can not reach the light switch from here.'), nl,
    !, fail.

off :-
    i_am_at(Place),
    retract(lit(Place)),
    optional_buzz_off,
    print('It is now dark in here.'), nl.

off :-
    print('The lights are already off.'), nl.

sleep :-
    not(i_am_at(bed)),
    print('You find it hard to sleep standing up.'), nl,
    !, fail.

sleep :-
    lit(bedroom),
    print('You can not get to sleep with the light on.'), nl,
    !, fail.

sleep :-
    lit(den),
    print('The light from the den is keeping you awake.'), nl,
    !, fail.

sleep :- 
    or(i_am_holding(flyswatter), at(flyswatter, bed)),
    print('What? Sleep with a dirty old flyswatter?'), nl,
    !, fail.

sleep :-
    alive(fly),
    print('As soon as you start to doze off, a fly lands'), nl,
    print('on your face and wakes you up again.'), nl,
    make_visible(fly),
    make_visible(flyswatter),
    !, fail.

sleep :-
    print('Ahhh...you (yawn) made...it...zzzzzzzz.'), nl, nl,
    finish.

swat(fly) :-
    swat.

swat :-
    i_am_at(Place),
    not(lit(Place)),
    print('You flail aimlessly in the dark!'), nl.

swat :-
    not(i_am_holding(flyswatter)),
    print('You are not holding the flyswatter.'), nl,
    !, fail.

swat :-
    not(alive(fly)),
    print('He is dead, Jim.'), nl.

swat :-
    i_am_at(Place),
    not(at(fly, Place)),
    print('You swish the flyswatter through the air.'), nl.

    /* Have flyswatter, room is lit, fly is here and alive. */

swat :-
    buzz_off,
    print('The fly escapes into the other room.'), nl.

swat :-
    print('Success! You killed that pesky fly!'), nl,
    retract(alive(fly)).

swat :- /* For debugging... */
    print('You must have forgotten a case!', nl).

make_visible(X) :-
    visible_object(X).

make_visible(X) :-
    assert(visible_object(X)).

buzz_off :-
    at(fly, bedroom),
    lit(den),
    retract(at(fly, bedroom)),
    assert(at(fly, den)).

buzz_off :-
    at(fly, den),
    lit(bedroom),
    retract(at(fly, den)),
    assert(at(fly, bedroom)).

optional_buzz_off :-
    buzz_off.

optional_buzz_off.


/* Under UNIX, the "halt." command quits Prolog but does not
   remove the output window. On a PC, however, the window
   disappears before the final output can be seen. Hence this
   routine requests the user to perform the final "halt." */

finish :-
        nl,
        print('The game is over. Please enter the "halt." command.'),
        nl.


/* This rule just prints out game instructions. */

instructions :-
        nl,
        print('Enter commands using standard Prolog syntax.'), nl,
        print('Available commands are:'), nl,
        print('start.                   -- to start the game.'), nl,
        print('n.  s.  e.  w.  u.  d.   -- to go in that direction.'), nl,
        print('take(Object).            -- to pick up an object.'), nl,
        print('drop(Object).            -- to put down an object.'), nl,
        print('use(Object).             -- to manipulate an object.'), nl,
        print('look.                    -- to look around you again.'), nl,
        print('on.  off.                -- to control the room lights.'), nl,
        print('sleep.                   -- to try to go to sleep.'), nl,
        print('instructions.            -- to see this message again.'), nl,
        print('halt.                    -- to end the game and quit.'), nl,
        nl.


/* This rule prints out instructions and tells where you are. */

start :-
        instructions,
        look.


/* These rules describe the various rooms.  Depending on
   circumstances, a room may have more than one description. */

describe(bedroom) :-
    lit(bedroom),
    print('You are in a bedroom with a large, comfortable bed.'), nl,
    print('It has been a long, tiresome day, and you would like'), nl,
    print('nothing better than to go to sleep.'), nl.

describe(bedroom) :-
        print('You are in your bedroom. It is nice and dark.'), nl.

describe(bed) :-
        print('You are in bed, and it feels great!'), nl.

describe(den) :-
    lit(den),
        print('You are in your den. There is a lot of stuff here,'), nl,
    print('but you are too sleepy to care about most of it.'), nl.

describe(den) :-
        print('You are in your den. It is dark.'), nl.

/* This is a special form, to call predicates during load time. */

% :- retractall(i_am_holding(_)), start.

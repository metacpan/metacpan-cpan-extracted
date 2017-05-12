%"Spider" -- A Sample Adventure Game in Prolog
% David Matuszek, Villanova University
% http://www.csc.vill.edu/~dmatusze/resources/prolog/spider.html

% This defines my current location

i_am_at(meadow).

% These facts describe how the rooms are connected.

path(spider, d, cave).
path(cave, u, spider).

path(cave, w, cave_entrance).
path(cave_entrance, e, cave).

path(cave_entrance, s, meadow).
path(meadow, n, cave_entrance) :- at(flashlight, in_hand).
path(meadow, n, cave_entrance) :-
        print('Go into that dark cave without a light?  Are you crazy?'), nl,
        fail.

path(meadow, s, building).
path(building, n, meadow).

path(building, w, cage).
path(cage, e, building).

path(closet, w, building).
path(building, e, closet) :- at(key, in_hand).
path(building, e, closet) :-
        print('The door appears to be locked.'), nl,
        fail.

% These facts tell where the various objects in the game are located.

at(ruby, spider).
at(key, cave_entrance).
at(flashlight, building).
at(sword, closet).

% This fact specifies that the spider is alive.

alive(spider).

% These rules describe how to pick up an object.

take(X) :-
        at(X, in_hand),
        print('You are already holding it!'),
        nl.

take(X) :-
        i_am_at(Place),
        at(X, Place),
        retract(at(X, Place)),
        assert(at(X, in_hand)),
        print('OK.'),
        nl.

take(_) :-
        print('I do not see it here.'),
        nl.

% These rules describe how to put down an object.

drop(X) :-
        at(X, in_hand),
        i_am_at(Place),
        retract(at(X, in_hand)),
        assert(at(X, Place)),
        print('OK.'),
        nl.

drop(_) :-
        print('You are not holding it!'),
        nl.

% These rules define the six direction letters as calls to go.

n :- go(n).

s :- go(s).

e :- go(e).

w :- go(w).

u :- go(u).

d :- go(d).

% This rule tells how to move in a given direction.

go(Direction) :-
        i_am_at(Here),
        path(Here, Direction, There),
        retract(i_am_at(Here)),
        assert(i_am_at(There)),
        look.

go(_) :-
        print('You cannot go that way.').


% This rule tells how to look about you.

look :-
        i_am_at(Place),
        describe(Place),
        nl,
        notice_objects_at(Place),
        nl.


% These rules set up a loop to mention all the objects in your vicinity.

notice_objects_at(Place) :-
        at(X, Place),
        print('There is a '), print(X), print(' here.'), nl,
        fail.

notice_objects_at(_).

% These rules tell how to handle killing the lion and the spider.

kill :-
        i_am_at(cage),
        print('Oh, bad idea!  You have just been eaten by a lion.'), nl,
        die.

kill :-
        i_am_at(cave),
        print('This is not working.  The spider leg is about as tough'), nl,
        print('as a telephone pole, too.'), nl.

kill :-
        i_am_at(spider),
        at(sword, in_hand),
        retract(alive(spider)),
        print('You hack repeatedly at the back of the spider.  Slimy ichor'), nl,
        print('gushes out of the back of the spider, and gets all over you.'), nl,
        print('I think you have killed it, despite the continued twitching.'),
        nl.

kill :-
        i_am_at(spider),
        print('Beating on the back of the spider with your fists has no'), nl,
        print('effect.  This is probably just as well.'), nl.

kill :-
        print('I see nothing inimical here.'), nl.


% This rule tells how to die.

die :-
        finish.

finish :-
        nl,
        print('Game over.'),
        nl.


% This rule just prints out game instructions.

help :-
        instructions.

instructions :-
        nl,
        print('Enter commands using standard Prolog syntax.'), nl,
        print('Available commands are:'), nl,
        print('start.                   -- to start the game.'), nl,
        print('n.  s.  e.  w.  u.  d.   -- to go in that direction.'), nl,
        print('take(Object).            -- to pick up an object.'), nl,
        print('drop(Object).            -- to put down an object.'), nl,
        print('kill.                    -- to attack an enemy.'), nl,
        print('look.                    -- to look around you again.'), nl,
        print('instructions.            -- to see this message again.'), nl,
        print('halt.                    -- to end the game and quit.'), nl,
        nl.


% This rule prints out instructions and tells where you are.

start :-
        instructions,
        look.


% These rules describe the various rooms.  Depending on
% circumstances, a room may have more than one description.

describe(meadow) :-
        at(ruby, in_hand),
        print('Congratulations!!  You have recovered the ruby'), nl,
        print('and won the game.'), nl,
        finish.

describe(meadow) :-
        print('You are in a meadow.  To the north is the dark mouth'), nl,
        print('of a cave; to the south is a small building.  Your'), nl,
        print('assignment, should you decide to accept it, is to'), nl,
        print('recover the famed Bar-Abzad ruby and return it to'), nl,
        print('this meadow.'), nl.

describe(building) :-
        print('You are in a small building.  The exit is to the north.'), nl,
        print('There is a barred door to the west, but it seems to be'), nl,
        print('unlocked.  There is a smaller door to the east.'), nl.

describe(cage) :-
        print('You are in a den of the lion!  The lion has a lean and'), nl,
        print('hungry look.  You better get out of here!'), nl.

describe(closet) :-
        print('This is nothing but an old storage closet.'), nl.

describe(cave_entrance) :-
        print('You are in the mouth of a dank cave.  The exit is to'), nl,
        print('the south; there is a large, dark, round passage to'), nl,
        print('the east.'), nl.

describe(cave) :-
        alive(spider),
        at(ruby, in_hand),
        print('The spider sees you with the ruby and attacks!!!'), nl,
        print('    ...it is over in seconds....'), nl,
        die.

describe(cave) :-
        alive(spider),
        print('There is a giant spider here!  One hairy leg, about the'), nl,
        print('size of a telephone pole, is directly in front of you!'), nl,
        print('I would advise you to leave promptly and quietly....'), nl.

describe(cave) :-
        print('Yecch!  There is a giant spider here, twitching.'), nl.

describe(spider) :-
        alive(spider),
        print('You are on top of a giant spider, standing in a rough'), nl,
        print('mat of coarse hair.  The smell is awful.'), nl.

describe(spider) :-
        print('Oh, gross!  You are on top of a giant dead spider!'), nl.

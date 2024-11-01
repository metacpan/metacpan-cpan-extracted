# tarotplane
![tarotplane](demo.gif)
**tarotplane** is a TUI flashcard program written in Perl using the Curses
module. It reads cards from specially formatted text files consisting of terms
and definitions, then displays them in a TUI.

## Building
**tarotplane** has been tested to run on Linux, FreeBSD, and NetBSD systems.
Other operating systems should work as long as they support dependencies listed
below.

To use **tarotplane**, you need the following:
* Perl (>= 5.16)
* Curses Perl module

To build and install:
```
perl Makefile.PL
make
make test
make install
```
View the documentation for `ExtUtils::MakeMaker` for more information on
configuring the build process.

## Usage
**tarotplane** works by reading flash cards from card files given to it as
arguments. Please read the manual for more in-depth documentation on the usage
of **tarotplane**.

### Card Files
A **tarotplane** card file consists of lines that contain terms and their
respective definitions seperated by a colon (:). Text preceding the colon is
considered the term, text following the colon is considered the term's
definition.

Lines starting with a hash (#) are treated as comments and are ignored. Blank
lines are also ignored.

*example.cards* shows how one could format a card file.

#### Escape Sequences
An escape sequence is a pair of characters, a forward slash (\\) and some other
character, that enables special behavior in **tarotplane** when
reading/displaying cards. Below is a list of all the escape sequences
**tarotplane** supports:

| Escape Sequence | Behavior                  |
| --------------- | ------------------------- |
| \\\\            | Single back slash (\\)    |
| \\:             | Colon (:)                 |
| \\n             | Force linebreak           |

### Controls

| Key                       | Action        |
| ------------------------- | ------------- |
| Right Arrow, l            | Next card     |
| Left Arrow, h             | Previous card |
| Space, Up/Down Arrow, j/k | Flip card     |
| Page Down, End            | Last card     |
| Page Up, Home             | First card    |
| q                         | Quit          |
| ?                         | Help screen   |

## History
This program is a rewrite of one of my older programs,
[nncards](https://codeberg.org/1-1sam/nncards), but written using Perl and
Curses rather than C and Termbox2. This provides various improvements over the
original, such as better unicode support, greater portability, and easier
maintainability.

As for the origin of the name **tarotplane**:
```
curses cards
occult cards
tarot cards
tarot.pl
tarotplane (the Beefheart one)
```

## Copyright
Copyright (C) 2024 Samuel Young

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See *https://dev.perl.org/licenses/* for more information.

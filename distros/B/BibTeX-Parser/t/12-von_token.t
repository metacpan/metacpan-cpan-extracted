#!/usr/bin/perl -w

use Test::More tests => 5;

use BibTeX::Parser::Author;
use IO::File;

is(BibTeX::Parser::Author::_is_von_token('von'),1);
is(BibTeX::Parser::Author::_is_von_token('Von'),0);
is(BibTeX::Parser::Author::_is_von_token('\noop{von}Von'),1);
is(BibTeX::Parser::Author::_is_von_token('\noop{Von}von'),0);
is(BibTeX::Parser::Author::_is_von_token('\noop{AE}{\AE}schylus'),0);

#!/bin/sh

cover --delete
PERL5OPT=-MDevel::Cover=+select_re,Class\/DBI\/Lite.+,+ignore,.*\.t,-ignore,prove prove t -r
cover


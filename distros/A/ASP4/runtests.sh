#!/bin/sh

cover --delete
PERL5OPT=-MDevel::Cover=+select_re,/tmp/PAGE_CACHE/DefaultApp+select_re,ASP4,+select_re,handlers,+select_re,htdocs,+ignore,.*\.t,-ignore,prove prove t -r
cover


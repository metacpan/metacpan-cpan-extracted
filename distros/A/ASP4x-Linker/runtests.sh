#!/bin/sh

cover --delete
PERL5OPT=-MDevel::Cover=+select_re,/tmp/PAGE_CACHE/ASP4xLinker,+select_re,handlers,+select_re,htdocs,+ignore,.*\.t,-ignore,prove prove t -r
cover


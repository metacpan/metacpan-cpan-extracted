#!/bin/sh
/usr/lib/rpm/find-requires $* | grep -v 'perl(Coro)' | grep -v 'perl(base)' | \
grep -v 'perl(strict)' | grep -v 'perl(utf8)' | grep -v 'perl(warnings)' | \
grep -v 'perl(DR::Tarantool)'

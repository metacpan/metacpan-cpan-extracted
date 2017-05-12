# Copyright (c) 1999-2007 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl exact.t'

use strict;

$| = 1;

print "1..2\n";

my $present = eval {
    require Date::Gregorian::Exact;
    1;
};

print $present? '': 'not ', "ok 1\n";

my $usable = eval {
    Date::Gregorian::Exact->import();
    1;
};

print $usable? 'not ': '', "ok 2\n";

__END__

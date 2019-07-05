#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Sergey Lepenkov), <abalama@cpan.org>
#
# Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-storage.t 86 2019-06-14 19:15:08Z abalama $
#
#########################################################################
use Test::More tests => 2;
use App::MBUtiny::Storage;
ok(App::MBUtiny::Storage->VERSION,'Version');

my $storage = new App::MBUtiny::Storage();
my $test = $storage->test(dummy => 1);
ok($test, sprintf("Storage testing: %s", $test ? $test < 0 ? "SKIP" : "PASS" : "FAIL" ));

1;

__END__

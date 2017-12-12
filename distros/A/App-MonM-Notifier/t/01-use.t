#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <abalama@cpan.org>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 3 2017-10-11 13:40:44Z abalama $
#
#########################################################################
use Test::More tests => 2;
use lib qw(inc);
BEGIN { use_ok('App::MonM::Notifier') };
use FakeCTK;
ok(App::MonM::Notifier::void(),'App::MonM::Notifier::void()');
1;

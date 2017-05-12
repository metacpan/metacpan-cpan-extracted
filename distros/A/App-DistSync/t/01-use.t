#!/usr/bin/perl -w
#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 2 2014-10-04 12:57:12Z abalama $
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('App::DistSync') };
ok(App::DistSync->VERSION,'VERSION method');
1;

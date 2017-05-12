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
# $Id: 02-lock.t 5 2014-10-08 16:24:59Z abalama $
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('App::DistSync::Lock') };
ok(App::DistSync::Lock->VERSION,'VERSION method');
diag( "Testing App::DistSync::Lock, Perl $], $^X" );

1;

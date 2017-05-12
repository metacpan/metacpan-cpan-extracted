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
# $Id: 01-use.t 7 2014-09-18 14:45:01Z abalama $
#
#########################################################################
use Test::More tests => 1;
BEGIN { use_ok('App::MonM') };
1;

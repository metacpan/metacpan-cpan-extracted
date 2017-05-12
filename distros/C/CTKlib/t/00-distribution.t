#!/usr/bin/perl -w
#########################################################################
#
# Sergey Lepenkov (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 00-distribution.t 141 2017-01-21 12:22:25Z minus $
#
#########################################################################
use strict;
use Test::More;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
eval "use Test::Distribution('only' => [qw(pod sig description versions use)])";
plan skip_all => 'Test::Distribution not installed' if($@);

1;
__END__

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
# $Id: 00-distribution.t 81 2019-06-10 10:34:51Z abalama $
#
#########################################################################
use strict;
use Test::More;

plan skip_all => "Currently a developer-only test" unless -d '.svn' || -d ".git";
eval "use Test::Distribution('only' => [qw(pod sig description)])";
plan skip_all => 'Test::Distribution not installed' if($@);

1;
__END__

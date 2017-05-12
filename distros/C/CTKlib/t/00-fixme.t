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
# $Id: 00-fixme.t 249 2017-04-12 15:38:51Z minus $
#
#########################################################################
use strict;
use Test::More;

eval "use Test::Fixme";
plan skip_all => "requires Test::Fixme to run" if $@;
run_tests(
    where => [qw/bin lib/],
    match => qr/\s+([T]ODO|[F]IX(ME|IT)?|[B]UG)\:\W/,
    warn => 1,
);

1;
__END__

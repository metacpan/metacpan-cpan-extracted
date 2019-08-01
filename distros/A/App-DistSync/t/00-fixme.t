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
# $Id: 00-fixme.t 60 2019-07-14 09:57:26Z abalama $
#
#########################################################################
use strict;
use Test::More;

eval "use Test::Fixme";
plan skip_all => "requires Test::Fixme to run" if $@;
run_tests(
    where => [qw/bin lib/],
    match => qr/\s+([T]ODO|[F]IX(ME|IT)?|[B]UG)\W/,
    warn => 1,
);

1;
__END__

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
# $Id: 03-collector-dbi.t 89 2019-06-16 21:01:43Z abalama $
#
#########################################################################
use Test::More tests => 1;
use App::MBUtiny::Collector::DBI qw/COLLECTOR_DB_FILENAME/;

my $dbi = new App::MBUtiny::Collector::DBI(
        file => COLLECTOR_DB_FILENAME,
    );
ok(!$dbi->error, "DBI errors") or diag($dbi->error);

1;

__END__

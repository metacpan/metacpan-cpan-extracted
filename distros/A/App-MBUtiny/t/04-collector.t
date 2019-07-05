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
# $Id: 04-collector.t 89 2019-06-16 21:01:43Z abalama $
#
#########################################################################
use Test::More tests => 2;
use App::MBUtiny::Collector;
use App::MBUtiny::Collector::DBI qw/COLLECTOR_DB_FILENAME/;

use constant COLLECTROR_CONFIG => {
	comment => "Test"
};

my $dbi = new App::MBUtiny::Collector::DBI(
        file => COLLECTOR_DB_FILENAME,
    );
ok(!$dbi->error, "DBI errors") or diag($dbi->error);

my $collector = new App::MBUtiny::Collector(
        collector_config => [COLLECTROR_CONFIG],
        dbi => $dbi,
    );
my $colstat = $collector->fixup(
        status  => 1,
        error   => "",
        name    => "foo",
        file    => "foo-2019-06-16.tar.gz",
        size    => 531,
        md5     => "79abd1a450c22923a6e62e156aa89b61",
        sha1    => "6786bcfd14b056e3e329fba20ad464f8678d94fc",
        comment => "All right!",
    );
ok($colstat, "Collector error") or diag($collector->error);

1;

__END__

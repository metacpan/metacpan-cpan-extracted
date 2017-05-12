use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use Test::FailWarnings;

my @backends = map { "CPAN::Common::Index::$_" } qw(
  Mux::Ordered
  Mirror
  LocalPackage
  MetaDB
);

my @required = qw(
  search_packages
  search_authors
);

for my $mod (@backends) {
    require_ok($mod);
    can_ok( $mod, @required );
}

done_testing;
#
# This file is part of CPAN-Common-Index
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#
# vim: ts=4 sts=4 sw=4 et:

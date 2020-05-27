#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use v5.10.1;
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Require::AuthorTesting;
use Test::Pod::Coverage 0.08;

my %global_exceptions = ( also_private => [qw< BUILDARGS FOREIGNBUILDARGS BUILD DEMOLISH >] );

my %exceptions = (
    'DBIx::OnlineDDL::Helper::Base'   => { trustme => [qw< child_fks_need_adjusting dbms_name progress >] },
    'DBIx::OnlineDDL::Helper::MySQL'  => { also_private => [ qr/.+/ ] },
    'DBIx::OnlineDDL::Helper::SQLite' => { also_private => [ qr/.+/ ] },
);

my @modules = all_modules();

plan tests => scalar @modules;

foreach my $module (@modules) {
    my %exceptions = ( %global_exceptions, %{ $exceptions{$module} || {} } );
    pod_coverage_ok($module, \%exceptions);
}

done_testing;

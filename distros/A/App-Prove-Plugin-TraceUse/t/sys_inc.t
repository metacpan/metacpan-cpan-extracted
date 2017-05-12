#!/usr/bin/perl

use strict;
use warnings;
use Test::Most tests => 3;
use Cwd qw/realpath/;

use App::Prove::Plugin::TraceUse;

my @i = App::Prove::Plugin::TraceUse::_system_inc;

cmp_deeply
  (
   [@i] , subsetof(@INC),
   "_system_inc returns a reasonable list of directories"
  );

my $h = $ENV{HOME};

{

    local %ENV;
    $ENV{PERL5LIB} = "/foo:/bar";

    cmp_bag( [App::Prove::Plugin::TraceUse::_system_inc(1)],
             ["/foo", "/bar", "."],
             "non-system INC"
           );

}

SKIP: {

    skip "home dir not found", 1 unless -d $h;

    my $home_found = [grep /^$h/, @i];

    cmp_deeply( $home_found, [], 'home not found in @INC' );

}

done_testing();

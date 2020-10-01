#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use ExtUtils::Manifest;

if ($ENV{RELEASE_TESTING}) {
    plan tests => 2;
}
else {
    plan skip_all => "Author tests not required for installation";
}

note 'MANIFEST test.';
is_deeply [ExtUtils::Manifest::manicheck()], [], 'No items missing from manifest';
is_deeply [ExtUtils::Manifest::filecheck()], [], 'No extra items in manifest';

__END__

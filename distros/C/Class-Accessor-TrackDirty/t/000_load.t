#!perl -w
use strict;
use Test::More tests => 1;

BEGIN {
    use_ok 'Class::Accessor::TrackDirty';
}

diag "Testing Class::Accessor::TrackDirty/$Class::Accessor::TrackDirty::VERSION";

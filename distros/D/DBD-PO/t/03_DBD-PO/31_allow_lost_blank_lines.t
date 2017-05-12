#!perl -T

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
    require_ok('DBD::PO');
}

ok(
    ! $DBD::PO::Locale::PO::ALLOW_LOST_BLANK_LINES,
    'allow blank lines is off at DBD::PO::Locale::PO',
);
ok(
    ! $DBD::PO::Text::PO::ALLOW_LOST_BLANK_LINES,
    'allow blank lines is off at DBD::PO::Text::PO',
);
DBD::PO->init(qw(allow_lost_blank_lines));
ok (
    $DBD::PO::Locale::PO::ALLOW_LOST_BLANK_LINES,
    'allow blank lines is on at DBD::PO::Locale::PO',
);
ok (
    $DBD::PO::Text::PO::ALLOW_LOST_BLANK_LINES,
    'set allow blank lines is on at DBD::PO::Text::PO',
);

#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/lib";

use Test::More tests => 9;
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;
ok(defined $mech);

$mech->get_ok('http://localhost/form/first');

$mech->content_like(
    qr{
        <input
        \s+
        name="first_text"
        \s+
        type="text"
        \s*
        />
    }xms,
    q{form not re-filled}
);

$mech->content_unlike(
    qr{
        <input
        \s+
        value="foo"
        \s+
        name="first_text"
        \s+
        type="text"
        \s*
        />
    }xms,
    q{form not re-filled}
);

$mech->get_ok('http://localhost/form/first?first_text=foo');

$mech->content_like(
    qr{
        <input
        \s+
        value="foo"
        \s+
        name="first_text"
        \s+
        type="text"
        \s*
        />
    }xms,
    q{form re-filled}
);

$mech->get_ok('http://localhost/form/first');
$mech->field('first_text', 'banana');
$mech->submit_form_ok(undef, q{submit filled form});
$mech->content_like(
   qr{
        <input
        \s+
        value="banana"
        \s+
        name="first_text"
        \s+
        type="text"
        \s*
        />
    }xms,
    q{form re-filled}
);

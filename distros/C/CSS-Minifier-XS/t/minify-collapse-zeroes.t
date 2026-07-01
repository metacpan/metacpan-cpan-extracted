#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use CSS::Minifier::XS qw(minify);

###############################################################################
# When collapsing "zeroes", we ONLY want to collapse ones that are genuine
# numeric values.  We should NOT be collapsing identifier/filename fragments
# that simply happen to begin with a "0" (e.g. "status-0.png").
subtest 'identifiers w/zeroes are preserved' => sub {
  is minify('a{background:url(0.png)}'),            'a{background:url(0.png)}',            'paren: 0.png';
  is minify('a{background:url(001.png)}'),          'a{background:url(001.png)}',          'paren: 001.png';
  is minify('a{background:url(img/0.png)}'),        'a{background:url(img/0.png)}',        'slash: img/0.png';
  is minify('a{background:url(a.png),url(0.png)}'), 'a{background:url(a.png),url(0.png)}', 'comma list: 0.png';
};

###############################################################################
# Verify that leading-zeroes in identifiers are preserved.
subtest 'leading zeroes in identifiers are preserved' => sub {
  is minify('.grid-001{color:red}'),       '.grid-001{color:red}',       'class .grid-001';
  is minify('.icon-007{color:red}'),       '.icon-007{color:red}',       'class .icon-007';
  is minify('#item-001{color:red}'),       '#item-001{color:red}',       'id #item-001';
  is minify(':root{--spacing-001:5px}'),   ':root{--spacing-001:5px}',   'custom property name';
  is minify('a{animation-name:spin-001}'), 'a{animation-name:spin-001}', 'animation name';
};

###############################################################################
# Verify that leading-zeroes in url() paths are preserved
subtest 'leading zeroes in url() paths are preserved' => sub {
  is minify('a{background:url(cache/00/x.png)}'),  'a{background:url(cache/00/x.png)}',  'numeric cache dir /00/';
  is minify('a{background:url(v1/007/icon.png)}'), 'a{background:url(v1/007/icon.png)}', 'numeric path segment /007/';
};

###############################################################################
# Double-check that numeric values collapse as expected.
#
# While yes, this is somewhat duplicative to tests already done in "minify.t",
# I'm leaving them here as well for mental context.
subtest 'numeric values collapse as expected' => sub {
  is minify('a{margin:0px}'),            'a{margin:0}',             '0px -> 0';
  is minify('a{opacity:0.5}'),           'a{opacity:.5}',           '0.5 -> .5';
  is minify('a{opacity:0.50}'),          'a{opacity:.50}',          '0.50 -> .50';
  is minify('a{margin:0.0px}'),          'a{margin:0}',             '0.0px -> 0';
  is minify('a{margin:0px}'),            'a{margin:0}',             '0px -> 0';
  is minify('a{margin:-0.5px}'),         'a{margin:-.5px}',         'negative -0.5px -> -.5px';
  is minify('a{color:rgba(0,0,0,0.5)}'), 'a{color:rgba(0,0,0,.5)}', 'rgba alpha 0.5 -> .5';
};

###############################################################################
done_testing();

#!/usr/bin/perl -T

use strict;
use warnings;

use Data::SimplePath;

BEGIN {
	use Test::More;
	use Test::NoWarnings;
	use Test::Warn;
	plan ('tests' => 3);
}

# if warnings are enabled:
warning_like { Data::SimplePath::_warn ('Test warning'); } qr/^Test warning/, 'Test warning #1';

# disable warnings:
no warnings 'Data::SimplePath';
Data::SimplePath::_warn ('Test warning #2');

# if warnings are enabled again:
use warnings 'Data::SimplePath';
warning_like { Data::SimplePath::_warn ('Test warning'); } qr/^Test warning/, 'Test warning #3';

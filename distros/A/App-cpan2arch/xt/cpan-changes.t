#!perl

use v5.42.0;

use strict;
use warnings;

use Test2::Require::Module qw< Test::CPAN::Changes >;
use Test::CPAN::Changes;

changes_ok();

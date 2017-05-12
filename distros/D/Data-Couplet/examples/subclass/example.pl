#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use My::DataCouplet;

my $dc = My::DataCouplet->new(qw( foo bar ));

print $dc->useless_routine;


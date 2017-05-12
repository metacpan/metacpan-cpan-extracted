#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

require B::RecDeparse;

for (qw<new init pp_gv pp_entersub pp_const coderef2text>) {
 ok(B::RecDeparse->can($_), 'BRD can ' . $_);
}

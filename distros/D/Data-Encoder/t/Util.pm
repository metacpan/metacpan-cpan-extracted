package t::Util;
use strict;
use warnings;
use base 'Exporter';
use Test::More;

our @EXPORT = qw(show_version);

sub show_version {
    my $module = shift;
    diag "$module: ", $module->VERSION;
}

1;

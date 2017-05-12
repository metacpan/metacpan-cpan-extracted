#!/usr/bin/perl

use strict;
use warnings;

use Cwd qw(realpath);
use DateTime::Format::Natural::Test qw(_find_modules);
use File::Spec::Functions qw(catfile updir);
use FindBin qw($Bin);
use Test::More;

BEGIN
{
    my @modules;
    _find_modules(realpath(catfile($Bin, updir, 'lib')), \@modules, []);
    @modules = sort @modules;
    plan tests => scalar @modules;
    use_ok($_) foreach @modules;
}

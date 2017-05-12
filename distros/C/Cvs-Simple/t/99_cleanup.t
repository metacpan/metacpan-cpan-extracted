#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use File::Spec::Functions qw(catdir);
use Test::More qw(no_plan);
require Cvs_Test;

BEGIN {
    use_ok('Cvs::Simple');
}

my($cwd) = getcwd();
unless ($cwd=~m{/t\z}) {
    $cwd = catdir($cwd, 't');
}
chdir($cwd) or die "Can\'t chdir to $cwd:$!";

Cvs_Test::cvs_clean($cwd);

exit;


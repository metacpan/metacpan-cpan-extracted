#!/usr/bin/perl
use strict;
use warnings;

use Carp 'confess';
$SIG{__DIE__} = \&confess;

BEGIN {
    chdir 't' if -d 't';
    use lib '../lib', '../blib/lib', 'lib';
}

use ShellTest;
use Code::Statistics::ConfigTest;
use Code::Statistics::FileTest;

exit $ARGV[0]->runtests if $ARGV[0];

Test::Class->runtests;

exit;

#!perl
use strict;
use warnings;

use Test::More tests => 4;

BEGIN {
    use_ok('App::CmdDirs');
    use_ok('App::CmdDirs::Traverser::Base');
    use_ok('App::CmdDirs::Traverser::Git');
    use_ok('App::CmdDirs::Traverser::Subversion');
}

diag("Testing App-CmdDirs $App::CmdDirs::VERSION, Perl $], $^X");

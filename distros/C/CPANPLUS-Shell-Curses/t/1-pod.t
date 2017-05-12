# -*- perl -*-
# Testing Plain old Documentation for CPANPLUS::Shell::Curses
# 2003 (c) by Marcus Thiesen
# marcus@cpan.org

use strict;
use FindBin;
use Test::Pod (tests => 1);

my $dir = "$FindBin::RealBin/../lib/CPANPLUS/Shell/";

pod_file_ok( "$dir/Curses.pm", "POD Documentation" );

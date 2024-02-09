#<<<
use strict; use warnings;
#>>>

use Test::More import => [ qw( note pass ) ], tests => 1;

use Data::Dumper qw( Dumper );
local $Data::Dumper::Indent = 0;    # explain() has indentation style 1
local $Data::Dumper::Terse  = 1;
note Dumper \@ARGV;

pass( __FILE__ );

use Test::More tests => 9;

use strict;
use FindBin;
use lib "$FindBin::RealBin/fakelib";

$ENV{LINES} = 25;
$ENV{COLUMNS} = 80;

BEGIN { use_ok( "Curses::UI");
	use_ok( "Curses::UI::Common"); }

# initialize
my $cui = new Curses::UI("-clear_on_exit" => 0);
$cui->leave_curses();
isa_ok($cui, "Curses::UI");

# create window
my $mainw = $cui->add("testw","Window");
isa_ok($mainw, "Curses::UI::Window");

# misc original tests
ok($mainw->root eq $cui, "root()");
my $data = { KEY => "value", FOO => "bar"  };
Curses::UI::Common::keys_to_lowercase($data);
is ($data->{key}, 'value', "keys_to_lowercase 1");
is ($data->{foo}, 'bar', "keys_to_lowercase 2");

#-------------------------------------------------------------------- scrlength
is (Curses::UI::Common::scrlength("foo bar"),
    length("foo bar"), "scrlength == 7");
isnt (Curses::UI::Common::scrlength("foo\tbar"),
      length("foo bar"), "scrlength > 7");


## TODO:
## split_to_lines
## text_dimension
## wrap stuff

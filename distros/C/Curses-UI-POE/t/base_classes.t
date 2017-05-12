use strict;
use Test;
use FindBin;
use lib "$FindBin::RealBin/../lib";


BEGIN { plan tests => 6 }

foreach my $class (qw(
    Curses::UI
    Curses::UI::Common
    Curses::UI::Container
    Curses::UI::Widget
    Curses::UI::Searchable
    Curses::UI::Color
	 )) {

    my $file = $class;
    $file =~ s|::|/|g;
    $file .= '.pm';

    require $file;
    ok(1);
}


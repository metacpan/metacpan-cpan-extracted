package Bar::Baz;
use Config::Constants 'FOO', 'BAR';
sub test_FOO { "Bar::Baz -> FOO is (" . FOO . ")"  }
sub test_BAR { "Bar::Baz -> BAR is (" . BAR . ")"  }
1;
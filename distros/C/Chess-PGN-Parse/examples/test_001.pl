#! /usr/bin/perl 
use strict; 
use warnings; 
use Chess::PGN::Parse; 

my $pgn; 

$pgn = Chess::PGN::Parse->new(undef, "["); 
$pgn->read_game(); 

# At this point, the entire module is hosed. Try to e.g. parse a valid game: 

my $text = <<"EOF";
[Event "78th Tata Steel GpA"] 
[Site "Wijk aan Zee NED"] 
[Date "2016.01.16"] 
[White "Navara, David"] 
[Black "Carlsen, Magnus"] 
[Result "*"] 

1. e4 * 

EOF

$pgn = Chess::PGN::Parse->new(undef, $text); 
if ($pgn->read_game()) { 
print "Success\n"; 
} else { 
print "Failure\n"; 
} 

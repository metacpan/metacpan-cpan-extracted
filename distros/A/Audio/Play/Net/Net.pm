package Audio::Play::Net;
# PerlIO calls used in .xs code
require 5.00302;  
require Audio::Play;
@ISA = qw(Audio::Play);
$VERSION = "0.001";
bootstrap Audio::Play::Net $VERSION;

*new = \&OpenServer;
*play = \&Play;
*flush = \&Flush;

1;



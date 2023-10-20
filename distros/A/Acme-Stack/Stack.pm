package Acme::Stack;
use strict;
use warnings;

require DynaLoader;

$Acme::Stack::VERSION = '0.02';

Acme::Stack->DynaLoader::bootstrap($Acme::Stack::VERSION);
sub dl_load_flags {0} # Prevent DynaLoader from complaining and croaking

1;
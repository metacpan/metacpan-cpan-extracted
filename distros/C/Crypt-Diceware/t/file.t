use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
use FindBin qw($Bin);

use Crypt::Diceware words => { file => "$Bin/files/dicewarekit.txt" };

isnt(
    join( " ", words(5) ),
    join( " ", words(5) ),
    "words(N) != words(N) (default)"
);

done_testing;
#
# This file is part of Crypt-Diceware
#
# This software is Copyright (c) 2013 by David Golden.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

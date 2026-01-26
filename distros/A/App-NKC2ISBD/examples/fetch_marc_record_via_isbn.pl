#!/usr/bin/env perl

use strict;
use warnings;

use App::NKC2ISBD;

# Arguments.
@ARGV = (
        '978-80-7370-353-0',
);

# Run.
exit App::NKC2ISBD->new->run;

# Output:
# Record for '978-80-7370-353-0' was saved to 'cnb002751696.txt'.

# `cat cnb002751696.txt`
# Vědomá prostitutka : tipy a triky profesionálky / Veronica Monet ; z anglického originálu Sex secrets of escort přeložila Hana Vysloužilová  -- Vydání první  -- 256 stran ; 21 cm
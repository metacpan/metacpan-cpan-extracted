package App::perlzonji;
use strict;
use warnings;
our $VERSION = '2.07';

1;

# This package just exists so users who already have App::perlzonji
# installed from before it was renamed to "perlfind" can upgrade it,
# and they'll get the new bin/perlzonji, which will tell them that it
# is deprecated and direct them to bin/perlfind, but it will continue
# to work. In the unlikely case that someone is using App::perlzonji
# directly, they have to rename it to App::perlfind.

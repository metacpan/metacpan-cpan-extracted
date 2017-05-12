use strict;
use warnings;
use Test::More;
use DOM::Tiny::Entities ();

is(\&DOM::Tiny::Entities::html_escape, \&Mojo::DOM58::Entities::html_escape);
is(\&DOM::Tiny::Entities::html_unescape, \&Mojo::DOM58::Entities::html_unescape);

done_testing;

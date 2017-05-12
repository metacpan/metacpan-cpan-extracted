package MyHelpers;

use strict;
use warnings;

use parent 'Dancer::Template::Handlebars::Helpers';

sub shout :Helper { uc $_[1] }

sub w :Helper(whisper) { lc $_[1] }

1;


#!/usr/bin/env perl

use strict;
use warnings;

use App::Tickit::Hello;

# Run.
exit App::Tickit::Hello->new->run;

# Output like:
# Green text 'Hello world!' in the middle of screen.
#!/usr/bin/env perl

use strict;
use warnings;

use App::CPAN::Get;

# Arguments.
@ARGV = (
        'App::Pod::Example',
);

# Run.
exit App::CPAN::Get->new->run;

# Output like:
# Package on 'http://cpan.metacpan.org/authors/id/S/SK/SKIM/App-Pod-Example-0.19.tar.gz' was downloaded.
#!/usr/bin/env perl

use strict;
use warnings;

use App::CPAN::Search;

# Arguments.
@ARGV = (
        'Library',
);

# Run.
App::CPAN::Search->new->run;

# Output like:
# Reading '/home/skim/.local/share/.cpan/Metadata'
#   Database was generated on Tue, 29 Dec 2015 21:53:32 GMT
# Module id = Library::CallNumber::LC
#     CPAN_USERID  DBWELLS (Dan Wells <CENSORED>)
#     CPAN_VERSION 0.23
#     CPAN_FILE    D/DB/DBWELLS/Library-CallNumber-LC-0.23.tar.gz
#     MANPAGE      Library::CallNumber::LC - Deal with Library-of-Congress call numbers
#     INST_FILE    /home/skim/perl5/lib/perl5/Library/CallNumber/LC.pm
#     INST_VERSION 0.23
#!/usr/bin/env perl
# -*- cperl; cperl-indent-level: 4 -*-
# Copyright (C) 2025, Roland van Ipenburg
use strict;
use warnings;

#use Log::Log4perl qw(:resurrect :easy get_logger);
use FindBin;
use utf8;
use 5.020000;
use open    qw(:std :utf8);
use autodie qw(open close);
use English qw( -no_match_vars );
BEGIN { our $VERSION = q{v0.0.1}; }
use HTTP::Tiny;
use Readonly;
## no critic (ProhibitCallsToUnexportedSubs)
Readonly::Scalar my $EMPTY => q{};
Readonly::Scalar my $FILE => $FindBin::Bin
  . q{/../lib/Crypt/Diceware/Wordlist/Nl.pm};
Readonly::Scalar my $URL =>
  q{https://mko.re/diceware/diceware-wordlist-composites-nl.txt};
## use critic

## no critic (ProhibitCommentedOutCode)
###l4p Log::Log4perl->easy_init($ERROR);
###l4p my $log = get_logger();
## use critic

my $response = HTTP::Tiny->new()->get($URL);
if ( ${$response}{'success'} ) {
    my $wordlist = ${$response}{'content'};
    unshift @ARGV, $FILE;
    my $module = $EMPTY;
    while ( my $line = <> ) {
        $module .= $line;
    }
    $module =~ s{(.*__DATA__\s*).*}{$1$wordlist}gimsx;
    binmode STDOUT, ':encoding(UTF-8)';
    my $fh;
    open $fh, '>', $FILE;
    print {$fh} $module
## no critic (RequireUseOfExceptions)
      or die "can't print to file, $ERRNO\n";
## use critic
    close $fh;
}
else {
## no critic (RequireUseOfExceptions)
    die "can't get wordlist from $URL, $ERRNO\n";
## use critic
}

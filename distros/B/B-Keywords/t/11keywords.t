#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';

use Config;
use File::Spec;
use lib qw( ../lib lib );
use B::Keywords ':all';

# Translate control characters into ^A format
# Leave others alone.
my @control_map = (undef, "A".."Z");
sub _map_control_char {
    my $char = shift;
    my $ord = ord $char;

    return "^".$control_map[$ord] if $ord <= 26;
    return $char;
}

# Test everything in keywords.h is covered.
{
    my $keywords = File::Spec->catfile( $Config{archlibexp}, 'CORE', 'keywords.h' );
    open FH, "< $keywords\0" or die "Can't open $keywords: $!";
    local $/;
    chomp( my @keywords = <FH> =~ /^\#define \s+ KEY_(\S+) /xmsg );
    close FH;

    my %covered = map { $_ => 1 } @Symbols, @Barewords;

    for my $keyword (@keywords) {
        ok $covered{$keyword}, "keyword: $keyword";
    }
}


# Test all the single character globals in main
{
    my @globals = map  { _map_control_char($_) }
                  grep { length $_ == 1 and /\W/ }
                       keys %main::;

    my %symbols = map { s/^.//; $_ => 1 } (@Scalars, @Arrays, @Hashes);
    for my $global (@globals) {
        ok $symbols{$global}, "global: $global";
    }
}

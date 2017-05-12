#!/usr/bin/perl

use strict;
use warnings;

use DateTime::Format::Natural;
use Test::More tests => 1;

{
    # Expected to fail with first parse ('31/09/2009'), because
    # parse_datetime_duration() retains the first failing state.
    my $string = '31/09/2009 to 31/10/2009';
    my $parser = DateTime::Format::Natural->new;
    $parser->parse_datetime_duration($string);
    ok(!$parser->success && defined $parser->error, $string);
}

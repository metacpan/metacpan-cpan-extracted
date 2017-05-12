#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok "AnyEvent::RTPG";
};

require_ok "AnyEvent::RTPG";

done_testing;

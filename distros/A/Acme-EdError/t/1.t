#!perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Command;

local @Test2::Tools::Command::command = ( $^X, '-MAcme::EdError', '-e' );

command { args => ['warn "warning"'], stderr => qr/^\?$/ };
command {
    args         => ['die "error"'],
    munge_status => 1,
    status       => 1,
    stderr       => qr/^\?$/
};

done_testing

#!/usr/bin/env perl -w

use strict;
use warnings;
use utf8;

use Test::More skip_all => "All parsed conditions supported. Waiting for support in App::BatParser for more conditions";
use English qw( -no_match_vars );
use Bat::Interpreter;

use Test::Exception;

my $interpreter = Bat::Interpreter->new;

my $cmd_file = $PROGRAM_NAME;
$cmd_file =~ s/\.t/\.cmd/;

throws_ok( sub { $interpreter->run($cmd_file) },
           qr/Condition type Exists not implemented/,
           "Should die when condition type is not implemented" );

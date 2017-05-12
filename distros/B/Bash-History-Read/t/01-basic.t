#!perl

use 5.010;
use strict;
use warnings;
use FindBin '$Bin';

use Bash::History::Read qw(parse_bash_history_file);
use Test::More 0.98;

is_deeply(parse_bash_history_file("$Bin/data/bash_history_1"),
          [
              [1426173906, "one\n"],
              [undef, "two\n"],
              [undef, "  three\n"],
              [undef, "four\n"],
              [1426173906, "five\n"],
          ]
      );
done_testing;

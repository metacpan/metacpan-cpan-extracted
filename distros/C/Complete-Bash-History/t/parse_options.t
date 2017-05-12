#!perl

use 5.010;
use strict;
use warnings;
#use Log::Any '$log';

use Complete::Bash::History;
use Test::More 0.98;

sub _l {
    my $line = shift;
    my $point = index($line, '^');
    die "BUG: No caret in line <$line>" unless $point >= 0;
    $line =~ s/\^//;
    ($line, $point);
}

my $res;

$res = Complete::Bash::History::parse_options(cmdline=>q[cmd --help --opt val arg1 arg2 -- --arg3], point=>16);
is_deeply(
    $res,
    {
        argv      => ["arg1", "arg2", "--arg3"],
        cword     => 2,
        opts      => { help => [undef], opt => ["val"] },
        word_type => "opt_name",
        words     => ["cmd", "--help", "--opt", "val", "arg1", "arg2", "--", "--arg3"],
    },
) or diag explain $res;

$res = Complete::Bash::History::parse_options(cmdline=>q[cmd -abc -MData::Dump], point=>1),
is_deeply(
    $res,
    {
        argv      => [],
        cword     => 0,
        opts      => { a => [undef], b => [undef], c => [undef], M => ["Data::Dump"] },
        word_type => "command",
        words     => ["cmd", "-abc", "-MData::Dump"],
    },
) or diag explain $res;

DONE_TESTING:
done_testing;

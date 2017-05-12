#!perl -T
#
# $Id: /svn/DateTime-Event-Klingon/tags/VERSION_1_0_1/t/gdtd.t 323 2008-04-01T06:37:25.246199Z jaldhar  $
#
use strict;
use warnings;
use DateTime;
use DateTime::Event::Klingon qw/Heghlu'meH QaQ jajvam'a'/;
use English qw/-no_match_vars/;
use Test::More tests => 3;

ok(Heghlu'meH QaQ jajvam'a'(DateTime->now) == 1, q{Heghlu'meH QaQ jajvam'a'});

my $notadatetime = q{};
eval { Heghlu'meH QaQ jajvam'a'($notadatetime); };
ok($EVAL_ERROR =~ /^Hab\ SoSlI'\ Quch!/mx, q{Hab SoSlI' Quch!}) ||
    diag "  Eval error was $EVAL_ERROR";

my $orig = q{'a'mavjaj QaQ Hem'ulhgeH};
ok($orig eq (scalar reverse q{Heghlu'meH QaQ jajvam'a'}), 'filter in quotes') ||
    diag '  Failed with ', (scalar reverse q{Heghlu'meH QaQ jajvam'a'});

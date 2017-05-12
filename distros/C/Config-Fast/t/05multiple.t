#!/usr/bin/perl -I. -I.. -w

# 05multiple - read and reread multiple files

use strict;
use Test;

# use a BEGIN block so we print our plan before module is loaded
BEGIN { plan tests => 32 }

use FindBin;

my $conf = "$FindBin::Bin/config.cf1";
my $conf2 = "$FindBin::Bin/config.cf3";

use Config::Fast;
@Config::Fast::DEFINE = [no => 'yes'];

my %cf = fastconfig($conf);

ok($cf{one}, 1);
ok($cf{two}, 2);
ok($cf{three}, 3);
ok($cf{support}, 'nate@wiger.org');
ok($cf{website}, 'http://nate.wiger.org');
ok($cf{date}, "today don't you know");
ok($cf{time}, "today don't you know 11:31");
ok($cf{animals}, 'Rhino, Giraffe, Magical Elephant');
ok($cf{mixedcase}, 'no$problemo');
ok($ENV{ANIMALS}, $cf{animals});
ok($cf{_source}, 'file');

my @n = keys %cf;
my $n = @n;
ok($n, 15);

undef %ENV;

%cf = fastconfig($conf2);

ok($cf{'why-not'}, "Hooka' Brutha' Up!!");
ok($cf{'999+disembodied+heads'}, q{who doesn't love late\-night \\\- horror flix?});
ok($cf{'===?===?==='}, "If this works, it's official, I\\\'m a PIMP with mad \$\$");
ok($cf{'1|2|3'}, "Ain't nobody that should fix ta' use \"this\"");
ok($cf{'$3.50'}, 'Damn you loch ness monster!');
ok($cf{_source}, 'file');

# This count will include @DEFINE from above
@n = keys %cf;
$n = @n;
ok($n, 14);

# back to the first one
%cf = fastconfig($conf);

ok($cf{one}, 1);
ok($cf{two}, 2);
ok($cf{three}, 3);
ok($cf{support}, 'nate@wiger.org');
ok($cf{website}, 'http://nate.wiger.org');
ok($cf{date}, "today don't you know");
ok($cf{time}, "today don't you know 11:31");
ok($cf{animals}, 'Rhino, Giraffe, Magical Elephant');
ok($cf{mixedcase}, 'no$problemo');
ok($ENV{ANIMALS}, $cf{animals});
my $gone = exists $cf{'1|2|3'} ? 0 : 1;
ok($gone, 1);
ok($cf{_source}, 'cache');

@n = keys %cf;
$n = @n;
ok($n, 15);


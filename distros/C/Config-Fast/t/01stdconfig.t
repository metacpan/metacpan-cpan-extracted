#!/usr/bin/perl -I. -I.. -w

# 01stdconfig - read the first config file, which is "standard"

use strict;
use Test;

# use a BEGIN block so we print our plan before module is loaded
BEGIN { plan tests => 30 }

use FindBin;

my $conf = "$FindBin::Bin/config.cf1";

use Config::Fast;

# XXX silence warning used by importvars
@Config::Fast::Define = [no => 'yes'];

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
ok($cf{total}, 'Grand total is $14.59');
ok($cf{yes}, 'yes');

# Count number of keys in config
my @n = keys %cf;
my $n = @n;
ok($n, 15);

# Just make sure our MixedCase aliases work >= 1.07
my @notreadonly = qw($Arrays @Define $Delim %Convert $EnvCaps $KeepCase);
my $i = 1;
for my $var (@notreadonly) {
    no strict;
    $var =~ s/^(.)//;   # strip $var @type
    my $type = $1;
    if ($type eq '$') {
        eval "$type\{Config::Fast::$var} = 'yup'"; $i++;
        ok($@ ? 0 : 1);
        my $yup;
        eval '$yup = '.$type.'{Config::Fast::'.uc($var).'}'; $i++;
        ok($@ ? 0 : 1);
        ok($yup, 'yup');
    } elsif ($type eq '@') {
        eval "$type\{Config::Fast::$var} = ('yup','yup')"; $i++;
        ok($@ ? 0 : 1);
        my $yup;
        eval '$yup = @{Config::Fast::'.uc($var).'}'; $i++;
        ok($@ ? 0 : 1);
        ok($yup, 2);
    } elsif ($type eq '%') {
        eval "$type\{Config::Fast::$var} = ('yup','yup')"; $i++;
        ok($@ ? 0 : 1);
        my $yup;
        eval '$yup = ${Config::Fast::'.uc($var).'}{yup}'; $i++;
        ok($@ ? 0 : 1);
        ok($yup, 'yup');
    }
}



#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::sfx_threshold';
    use_ok $pkg;
}

my $this_year = [ localtime ]->[5] + 1900;
my $two_years_ago = $this_year - 2;

#---
my $parsed = $pkg->new('holding')->fix({holding => 'Available from 2012. Most recent 1 year(s) not available.'});

ok $parsed , 'parsing: Available from 2012. Most recent 1 year(s) not available.';

is $parsed->{holding}->{limit}->{num} , 1 , 'we have a limit';

is_deeply
    $parsed->{holding}->{years} ,
    [ (2012 .. $two_years_ago )] ,
    "correct years";

is $parsed->{holding}->{human} , "2012 - $two_years_ago" , "correct human string";

#---

$parsed = $pkg->new('holding')->fix({holding => 'Available from 2011.'});

ok $parsed , 'parsing: Available from 2011.';

ok ! $parsed->{holding}->{limit}->{num} , 'we have no limit';

is_deeply
    $parsed->{holding}->{years} ,
    [ (2011 .. $this_year )] ,
    "correct years";

is $parsed->{holding}->{human} , "2011 - " , "correct human string";

#---
$parsed = $pkg->new('holding')->fix({holding => 'Available from 2012 volume: 1.'});

ok $parsed , 'parsing: Available from 2012 volume: 1.';

ok ! $parsed->{holding}->{limit}->{num} , 'we have no limit';

is_deeply
    $parsed->{holding}->{years} ,
    [ (2012 .. $this_year )] ,
    "correct years";

is $parsed->{holding}->{human} , "2012 - " , "correct human string";

#---
$parsed = $pkg->new('holding')->fix({holding => 'Available from 1997 volume: 501 issue: 1. Most recent 1 year(s) not available.'});

ok $parsed , 'parsing: Available from 1997 volume: 501 issue: 1. Most recent 1 year(s) not available.';

ok $parsed->{holding}->{limit}->{num} , 'we have a limit';

is_deeply
    $parsed->{holding}->{years} ,
    [ (1997 .. $two_years_ago )] ,
    "correct years";

is $parsed->{holding}->{human} , "1997 - $two_years_ago" , "correct human string";

#---
$parsed = $pkg->new('holding')->fix({holding => 'Most recent 1 year(s) available.'});

ok $parsed , 'parsing: Most recent 1 year(s) available.';

ok $parsed->{holding}->{limit}->{num} , 'we have a limit';

is_deeply
    $parsed->{holding}->{years} ,
    [ $this_year ] ,
    "correct years";

is $parsed->{holding}->{human} , "$this_year" , "correct human string";

#---
$parsed = $pkg->new('holding')->fix({holding => 'Most recent 2 month(s) not available.'});

ok $parsed , 'parsing: Most recent 2 month(s) not available.';


ok $parsed->{holding}->{limit}->{num} , 'we have a limit';

is_deeply
    $parsed->{holding}->{years} ,
    [ $this_year ] ,
    "correct years";

is $parsed->{holding}->{human} , "$this_year" , "correct human string";

done_testing 25;

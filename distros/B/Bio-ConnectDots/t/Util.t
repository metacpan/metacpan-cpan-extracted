#!/usr/bin/perl
use lib qw(./t blib/lib);
use strict;
no warnings;
use Test::More qw(no_plan);
use Data::Dumper;
use Bio::ConnectDots::Util;


# test joindef
my $ret; my @list = (1,2,3,4);
$ret = Bio::ConnectDots::Util::joindef(',', @list);
is ($ret, '1,2,3,4', 'check joindef()');

# test value_as_String
$ret = undef;
my $atomic = 10000;
$ret = Bio::ConnectDots::Util::value_as_string($atomic);
is ($ret eq '10000', 1, 'check value_as_string($atomic)');

$ret = undef;
$ret = Bio::ConnectDots::Util::value_as_string(\@list);
is ($ret, '[1, 2, 3, 4]', 'check value_as_string(\@list)');

$ret = undef;
my %hash = (dave=>'tom', emily=>'nina');
$ret = Bio::ConnectDots::Util::value_as_string(\%hash);
is ($ret, '{emily=>nina, dave=>tom}', 'check value_as_string(\%hash)');

# test is_number()
$ret = undef;
$ret = Bio::ConnectDots::Util::is_number($atomic);
is ($ret, 1, 'check is_number(number)');

$ret = undef; my $non_number = 'majortomisajunkie';
$ret = Bio::ConnectDots::Util::is_number($non_number);
is ($ret, '', 'check is_number(!number)');


# test is_alpha()
$ret = undef;
$ret = Bio::ConnectDots::Util::is_alpha($non_number);
is ($ret, 1, 'check is_alpha(alpha)');

$ret = undef; 
$ret = Bio::ConnectDots::Util::is_alpha($atomic);
is ($ret, '', 'check is_number(!alpha)');


# test min
$ret = undef; 
my @list = (5,7,2,6);
$ret = Bio::ConnectDots::Util::min(\@list);
is ($ret, 2, 'check min(list)');

# test max
$ret = undef; 
$ret = Bio::ConnectDots::Util::max(\@list);
is ($ret, 7, 'check max(list)');

# test minmax
$ret = undef; my $ret2;
($ret, $ret2) = Bio::ConnectDots::Util::minmax(\@list);
is ($ret == 2 && $ret2 == 7, 1, 'check minmax(list)');


# test mina
$ret = undef; 
my @list = ('l','a','d');
$ret = Bio::ConnectDots::Util::mina(@list);
is ($ret, 'a', 'check mina(list)');

# test maxa
$ret = undef; 
$ret = Bio::ConnectDots::Util::maxa(\@list);
is ($ret, 'l', 'check maxa(list)');

# test minmaxa
$ret = undef; $ret2 = undef;
($ret, $ret2) = Bio::ConnectDots::Util::minmaxa(@list);
is ($ret == 'a' && $ret2 == 'l', 1, 'check minmaxa(list)');


# test minb
$ret = undef; 
my @list = (5, 'isthatallthereis', 7, 2, 'a', 6);
$ret = Bio::ConnectDots::Util::minb(\@list);
is ($ret, 2, 'check minb(list)');

# test maxb
$ret = undef; 
$ret = Bio::ConnectDots::Util::maxb(\@list);
is ($ret, 'isthatallthereis', 'check maxb(list)');

# test minmaxb
$ret = undef; $ret2=undef;
($ret, $ret2) = Bio::ConnectDots::Util::minmaxb(\@list);
is ($ret == 2 && $ret2 == 'isthatallthereis', 1, 'check minmaxb(list)');


# test avg
$ret = undef;
my @list = (1,2,3,4,5);
$ret = Bio::ConnectDots::Util::avg(@list);
is ($ret, 3, 'check avg()');

# test mean
$ret = undef;
$ret = Bio::ConnectDots::Util::mean(@list);
is ($ret, 3, 'check mean()');

# test sum
$ret = undef;
$ret = Bio::ConnectDots::Util::sum(@list);
is ($ret, 15, 'check mean()');

# test eq_list
$ret=undef; my @list2 = (1,2,3,4,5);
$ret = Bio::ConnectDots::Util::eq_list(\@list, \@list2);
is ($ret, 1, 'check eq_list() on equal lists');

$ret=undef; my @list2 = (1,2,3,4,6);
$ret = Bio::ConnectDots::Util::eq_list(\@list, \@list2);
is ($ret, undef, 'check eq_list() on unequal lists of same length');

$ret=undef; my @list2 = (1,2,3,4);
$ret = Bio::ConnectDots::Util::eq_list(\@list, \@list2);
is ($ret, undef, 'check eq_list() on unequal lists of different length');


# test uniq
$ret=undef; my @list = (1,3,3,3,1,'a','b','a');
$ret = Bio::ConnectDots::Util::uniq(@list);
is ($ret->[0] == 1 &&
	$ret->[1] eq 'a' &&
	$ret->[2] eq 'b' &&
	$ret->[3] == 3,
	1, 'check uniq(list)');


1;
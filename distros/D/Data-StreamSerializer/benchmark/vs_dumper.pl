#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);

use lib qw(blib/lib blib/arch);
use Getopt::Std qw(getopts);
use Time::HiRes qw(time);
use Data::Dumper;
use Data::StreamSerializer;

$Data::Dumper::Indent = 0;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;
$Data::Dumper::Deepcopy = 1;

sub compare_object($$);
sub usage();
sub min(@);
sub max(@);
sub sum(@);
sub avg(@);

$| = 1;
getopts 'hn:b:' => \my %opts or usage;
usage if $opts{h};
my $file = $ARGV[0] or usage;
die "File not found: $file\n" unless -f $file;
my $data = `cat $file`;
my $iterations = $opts{n} || 1000;
my $block_size = $opts{b} || 512;

printf "%s bytes were read\n", length $data;

print "First serializing by eval...";
my $object = eval $data;
die "Can't eval input data: $@" if $@;
print " done\n";

print "First serializing by Data::StreamSerializer... ";
my $sr = new Data::StreamSerializer($object);
my $dsld = '';
while(defined(my $str = $sr->next)) {
    $dsld  .= $str;
}
my $dobject = eval $dsld;
die $dsld if $@;

die "Serialize error" unless compare_object $dobject, $object;
print "done\n";


my @dumper_time;
my $time = time;
printf "Starting %d iterations for Dumper... ", $iterations;

for (1 .. $iterations) {
    my $start_time = time;
    my $str = Dumper($object);
    push @dumper_time, time - $start_time;
}

my $dumper_time = time - $time;

printf "done (%2.3f seconds)\n", $dumper_time;


my @ss_time;
$time = time;
printf "Starting %d iterations for Data::StreamSerializer... ", $iterations;

my $counter = 0;

for (1 .. $iterations) {
    my $start_time = time;

    $sr = new Data::StreamSerializer($object);
    $sr->block_size($block_size);
    $counter++ while defined $sr->next;
    push @ss_time, time - $start_time;
}

my $ss_time = time - $time;

printf "done (%2.3f seconds)\n", $ss_time;


print  "\nDumper statistic:\n";
printf "\t%d iterations were done\n", $iterations;
printf "\tmaximum serialization time: %2.4f seconds\n", max(@dumper_time);
printf "\tminimum serialization time: %2.4f seconds\n", min(@dumper_time);
printf "\taverage serialization time: %2.4f seconds\n", avg(@dumper_time);

print  "\nData::StreamSerializer statistic:\n";
printf "\t%d iterations were done\n", $iterations;
printf "\t%d SUBiterations were done\n", $counter;
printf "\tmaximum serialization time: %2.4f seconds\n", max(@ss_time);
printf "\tminimum serialization time: %2.4f seconds\n", min(@ss_time);
printf "\taverage serialization time: %2.4f seconds\n", avg(@ss_time);
printf "\taverage subiteration  time: %2.5f seconds\n", $ss_time / $counter;

sub compare_object($$)
{
    my ($o1, $o2) = @_;
    return 0 unless ref($o1) eq ref $o2;
    return $o1 eq $o2 unless ref $o1;                        # SCALAR
    return $o1 eq $o2 if 'Regexp' eq ref $o1;                # Regexp
    return compare_object $$o1, $$o2 if 'SCALAR' eq ref $o1; # SCALARREF
    return compare_object $$o1, $$o2 if 'REF' eq ref $o1;    # REF

    if ('ARRAY' eq ref $o1) {
        return 0 unless @$o1 == @$o2;
        for (0 .. $#$o1) {
            return 0 unless compare_object $o1->[$_], $o2->[$_];
        }
        return 1;
    }

    if ('HASH' eq ref $o1) {
        return 0 unless keys(%$o1) == keys %$o2;

        for (keys %$o1) {
            return 0 unless exists $o2->{$_};
            return 0 unless compare_object $o1->{$_}, $o2->{$_};
        }
        return 1;
    }


    die ref $o1;
}

sub usage()
{
    print <<eof;

    usage: perl $0 [OPTIONS] test_file

    OPTIONS:

        -h              - this helpscreen
        -n count        - iterations (default 1000)
        -b count        - bytes in one subiteration (default 512),
                            see perldoc Data::StreamDeserializer
                                hint: block_size
eof
    exit 0;
}

sub min(@) {
    my $min = shift;
    for (@_) {
        $min = $_ if $min > $_;
    }
    return $min;
}

sub max(@) {
    my $max = shift;
    for (@_) {
        $max = $_ if $max < $_;
    }
    return $max;
}

sub sum(@)
{
    my $sum = 0;
    $sum += $_ for @_;
    return $sum;
}

sub avg(@)
{
    return sum(@_) / @_;
}

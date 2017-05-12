#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open qw(:std :utf8);

use lib qw(blib/lib blib/arch);
use Getopt::Std qw(getopts);
use Time::HiRes qw(time);
use Data::StreamDeserializer;

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

print "First deserializing by eval...";
my $object = eval $data;
die "Can't eval input data: $@" if $@;
print " done\n";

print "First deserializing by Data::DeSerializer...";
my $dsf = new Data::StreamDeserializer
    data => $data, block_size => $block_size;
1 until $dsf->next;
die "Can't deserialize input data: " . $dsf->error if $dsf->is_error;
print " done\n";

print "Check if deserialized objects are same...";
die "deserialized object aren't the same\n"
    unless compare_object $dsf->result, $object;
print " done\n";

my (@delay, @delay_dsr);
my $time = time;
printf "\nStarting %d iterations for eval...", $iterations;
for (1 .. $iterations) {
    my $start = time;
    my $res = eval $data;
    push @delay, time - $start;
}
my $eval_time = time - $time;
printf " done (%3.3f seconds)\n", $eval_time;

printf "Starting %d iterations for Data::StreamDeserializer...", $iterations;

$time = time;
my $partcounter = 0;
for (1 .. $iterations) {
    my $start = time;
    my $dsr = new Data::StreamDeserializer
        data => $data, block_size => $block_size;

    $partcounter++ until $dsr->next;
    $partcounter++;

    push @delay_dsr, time - $start;
}

my $ds_time = time - $time;
printf " done (%3.3f seconds)\n", $ds_time;

print  "\nEval statistic:\n";
printf "\t%d iterations were done\n", $iterations;
printf "\tmaximum deserialization time: %2.4f seconds\n", max(@delay);
printf "\tminimum deserialization time: %2.4f seconds\n", min(@delay);
printf "\taverage deserialization time: %2.4f seconds\n", avg(@delay);

print  "\nStreamDeserializer statistic:\n";
printf "\t%d iterations were done\n", $iterations;
printf "\t%d SUBiterations were done\n", $partcounter;
printf "\t%d bytes in one block in one iteration\n", $block_size;
printf "\tmaximum deserialization time: %2.4f seconds\n", max(@delay_dsr);
printf "\tminimum deserialization time: %2.4f seconds\n", min(@delay_dsr);
printf "\taverage deserialization time: %2.4f seconds\n", avg(@delay_dsr);
printf "\taverage subiteration time:    %2.5f seconds\n",
    sum(@delay_dsr) / $partcounter;

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

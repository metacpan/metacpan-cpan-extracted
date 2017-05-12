#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(blib/lib ../blib/lib blib/arch ../blib/arch);

use Test::More tests    => 8;
use Encode qw(decode encode);
use Data::Dumper;

BEGIN {
    my $builder = Test::More->builder;
    use_ok 'Data::StreamDeserializer';
    $| = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Deepcopy = 1;
}


sub compare_object($$);
sub first_part_tests();
sub second_part_tests();
sub rand_hash($);


my $h = rand_hash 7;
ok 'HASH' eq ref $h, 'Generate big random hash';

my $str = Dumper($h);
ok $str, sprintf 'Serialize big hash using Dumper, length: %s', length($str);

my $dsr = new Data::StreamDeserializer data => $str;

ok $dsr, 'Create Data::StreamDeserializer object';

1 until $dsr->next;

ok !$dsr->is_error, 'Deserialize using Data::StreamDeserializer';

ok compare_object($h, $dsr->result),
    'Deserialized and source objects are the same';

$dsr = new Data::StreamDeserializer;
for (my $i = 0; $i < length $str; $i += 30) {
    my $substr = substr $str, $i,
        (($i + 30) < length $str) ? 30 : length($str)-$i - 1;
    $dsr->block_size(10 + int rand 300);
    $dsr->next($substr);
}

$dsr->next(undef);
1 until $dsr->next;

ok !$dsr->is_error, 'Stream deserialize using Data::StreamDeserializer';
ok compare_object($h, $dsr->result),
    'Deserialized (stream) and source objects are the same';




############ service functions

sub rand_string()
{
    my $rstr = '';
    my @letters = (
        qw(й ц у к е н г ш щ з х ъ ф ы в а п р о л д ж э я ч с м и т ь б ю),
        map { chr $_ } 0x20 .. 0x7e
    );
    $rstr .= $letters[rand @letters] for  0 .. -1 + int rand 20;
    return $rstr;
}

sub rand_array($);
sub rand_hash($);

sub rand_hash($)
{
    my ($deep) = @_;
    my %h;
    return rand_string if $deep <= 0;
    for ( 0 .. $deep ) {
        my $key = rand_string;
        if (3 > rand 10) {
            $h{$key} =  rand_string;
        } elsif (5 > rand 10) {
            $h{$key} =  rand_hash($deep - 1);
        } else {
            $h{$key} =  rand_array($deep - 1);
        }
    }
    return \%h;
}


sub rand_array($)
{
    my @array;
    my ($count) = @_;
    return rand_string if $count <= 0;
    for (0 .. $count) {
        if (3 > rand 10) {
            push @array, rand_string;
        } elsif (5 > rand 10) {
            push @array, rand_hash($count - 1);
        } else {
            push @array, rand_array($count - 1);
        }

    }
    return \@array;
}

sub compare_object($$)
{
    my ($o1, $o2) = @_;
    return 0 unless ref($o1) eq ref $o2;
    return $o1 eq $o2 unless ref $o1;                        # SCALAR
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


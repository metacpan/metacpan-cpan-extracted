#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(blib/lib ../blib/lib blib/arch ../blib/arch);

use Test::More tests => 9;
use Encode qw(decode encode);


BEGIN {
    use_ok 'Data::StreamDeserializer';
}

sub compare_object($$);
my $str = q#
    { "a" => "b", "c=" => [ "d", "e", "f" ] }
#;
my $obj = eval $str;

ok $obj, "Eval test string";

my $dsr = new Data::StreamDeserializer
    block_size => 100,
    data    => $str;

ok $dsr, "Constructor";
ok $dsr->block_size == 100, "Constructor's block_size";
ok $dsr->block_size(10) == 10, "Set block size";

1 until $dsr->next;
# note explain $dsr;
# diag $dsr->error;
ok !$dsr->is_error, "parse result";

ok compare_object($dsr->result, $obj), "Results of parser and eval are equal";

my $error_tail = "abrakadabra]kondelabra";
$dsr = new Data::StreamDeserializer
    data => $str . $error_tail;
1 until $dsr->next;

ok $dsr->is_error, "Detect error";
ok $dsr->tail eq $error_tail, "Find error tail";

# note explain [ $dsr->tail, $error_tail ];
# note explain $dsr;

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

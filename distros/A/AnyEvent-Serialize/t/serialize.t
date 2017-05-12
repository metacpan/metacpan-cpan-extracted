use warnings;
use strict;

use Time::HiRes qw(time);
use Data::Dumper;
use AnyEvent;
local $Data::Dumper::Indent   = 0;
local $Data::Dumper::Terse    = 1;
local $Data::Dumper::Useqq    = 1;
local $Data::Dumper::Deepcopy = 1;

use Test::More tests => 54;
BEGIN {
    use_ok 'AnyEvent';
    use_ok('AnyEvent::Serialize', ':all', 'block_size' => 10);
};

sub rand_array($);
sub compare_object($$);
sub rand_hash($);

my @a;
for (0 .. 9) {
    push @a, (50 < rand 100) ? rand_hash 6 : rand_array 6;
#     push @a, (50 < rand 100) ? [1,2] : {1,2};
}

$_ = { str => Dumper($_), orig => $_ } for @a;

{
    my $counter = 0;
    my $cv = condvar AnyEvent;

    my (@res, @sres);
    for my $i (0 .. $#a) {
        deserialize $a[$i]{str} =>
            sub {
                $res[$i] = { obj => \@_, time => time, order => $counter++ };
                $cv->send if $counter == @a * 2;
            };

        serialize $a[$i]{orig} =>
            sub {
                my ($s, $rd) = @_;
                $sres[$i] = {
                    str       => $s,
                    recursion => $rd,
                    time      => time,
                    order     => $counter++
                };
                $cv->send if $counter == @a * 2;
            };
    }


    $cv->recv;


    for (0 .. $#res) {
        ok compare_object($res[$_]{obj}[0], $a[$_]{orig}),
            "$_: object deserialized";

        ok !$res[$_]{obj}[1], "$_: no error detected";
        ok !$res[$_]{obj}[2], "$_: undeserialized tail is empty";

        my $dsr = eval $sres[$_]{str};
        ok compare_object($dsr, $a[$_]{orig}),
            "$_: object serialized";

        ok !$sres[$_]{recursion}, "$_: no recursion detected";
    }


    ok grep({$res[$_]{time} < $res[$_+1]{time} } 0 .. $#res - 1) > 0,
        "Random finish time";
    ok grep({$res[$_]{order} < $res[$_+1]{order} } 0 .. $#res - 1) > 0,
        "Random order";
}


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


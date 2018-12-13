#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Char::Replace;

our ( $STR, @MAP );

=pod

 initialize a map:

    the map should be read as replace the characters X
    by the string stored at $MAP[ ord('X') ]
  
 Note: the value stored $MAP[ ord('X') ] can be a single char (string length=1) or a string
 at this time any other value is not handled: IVs, NVs, ...

=cut

BEGIN {    # not necessery but if you know your map, consider initializing it at compile time

    $MAP[$_] = chr($_) for 0 .. 255;

    # or you can also initialize the identity MAP like this
    @MAP = @{ Char::Replace::identity_map() };

=pod

Set your replacement characters

=cut

    $MAP[ ord('a') ] = 'AA';    # replace all 'a' characters by 'AA'
    $MAP[ ord('d') ] = '5';     # replace all 'd' characters by '5'
}

# we can now use our map to replace the string

is Char::Replace::replace( q[abcd], \@MAP ), q[AAbc5], "a -> AA ; d -> 5";

{
    note "benchmark";
    use Benchmark;

    # just a sample latin text
    my $latin = <<'EOS';
Lorem ipsum dolor sit amet, accumsan patrioque mel ei. 
Sumo temporibus ad vix, in veri urbanitas pri, rebum 
nusquam expetendis et eum. Et movet antiopam eum, 
an veri quas pertinax mea. Te pri propriae consequuntur, 
te solum aeque albucius ius. 
Ubique everti recusabo id sea, adhuc vitae quo ea.
EOS

    {
        note "transliterate like";
        my $subs = {

            transliteration => sub {
                my $str = $STR;
                $str =~ tr|abcd|ABCD|;
                return $str;
            },
            replace_xs => sub {
                return Char::Replace::replace( $STR, \@MAP );
            },
            substitute => sub {
                my $str = $STR;
                $str =~ s/(.)/$MAP[ord($1)]/og;
                return $str;
            },
        };

        # set our replacement map
        @MAP             = @{ Char::Replace::identity_map() };
        $MAP[ ord('a') ] = 'A';
        $MAP[ ord('b') ] = 'B';
        $MAP[ ord('c') ] = 'C';
        $MAP[ ord('d') ] = 'D';

        # sanity check
        $STR = $latin;
        is $subs->{replace_xs}->(), $subs->{transliteration}->(), "replace_xs eq transliteration" or die;
        is $subs->{substitute}->(), $subs->{transliteration}->(), "substitute eq transliteration" or die;

        Benchmark::cmpthese( -5 => $subs );

=pod
                    Rate      substitute transliteration      replace_xs
substitute        7245/s              --            -97%            -98%
transliteration 214237/s           2857%              --            -50%
replace_xs      431960/s           5862%            102%              --
=cut

    }

    {

        note "two substitutes 1 char => 3 char: a -> AAA; d -> DDD";
        my $subs = {

            substitute_x2 => sub {
                my $str = $STR;

                $str =~ s|a|AAA|og;
                $str =~ s|d|DDD|og;

                return $str;
            },
            replace_xs => sub {
                return Char::Replace::replace( $STR, \@MAP );
            },
            substitute => sub {
                my $str = $STR;
                $str =~ s/(.)/$MAP[ord($1)]/og;
                return $str;
            },            
        };

        # sanity check
        @MAP             = @{ Char::Replace::identity_map() };
        $MAP[ ord('a') ] = 'AAA';
        $MAP[ ord('d') ] = 'DDD';

        $STR = $latin;

        is $subs->{replace_xs}->(), $subs->{substitute_x2}->(), "replace_xs eq substitute_x2" or die;
        is $subs->{substitute}->(), $subs->{substitute}->(), "replace_xs eq substitute_x2" or die;

        note "short string";
        $STR = q[abcdabcd];
        Benchmark::cmpthese( -5 => $subs );

=pod
                   Rate    substitute substitute_x2    replace_xs
substitute     207162/s            --          -70%          -93%
substitute_x2  685956/s          231%            --          -75%
replace_xs    2796596/s         1250%          308%            --
=cut

        note "latin string";
        $STR = $latin;
        Benchmark::cmpthese( -5 => $subs );

=pod
                  Rate    substitute substitute_x2    replace_xs
substitute      7229/s            --          -93%          -98%
substitute_x2 109237/s         1411%            --          -72%
replace_xs    395958/s         5377%          262%            --
=cut

        note "longer string: latin string x100";
        $STR = $latin x 100;
        Benchmark::cmpthese( -5 => $subs );

=pod
                Rate    substitute substitute_x2    replace_xs
substitute    74.0/s            --          -95%          -99%
substitute_x2 1518/s         1951%            --          -70%
replace_xs    5022/s         6685%          231%            --
=cut

    }

}

done_testing;

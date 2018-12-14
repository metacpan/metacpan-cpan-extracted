#!perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;

use Char::Replace;
use Benchmark;

our ($STR);

{

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

            pp_naive_trim => sub {
                my $str = $STR;
                return pp_naive_trim($str);
            },
            pp_trim => sub {
                my $str = $STR;
                return pp_trim($str);
            },
            xs_trim => sub {
                my $str = $STR;
                return Char::Replace::trim($str);
            },
        };

        # sanity check
        note "a simple string";
        $STR = " abcd ";
        my @to_test = (
            "no-spaces",
            " leading-trailing ",
            "                  multiple spaces in front",
            " \t\r\n \t\r\n \t\r\n \t\r\nmultiple chars in front and end \t\r\n \t\r\n \t\r\n \t\r\n \t\r\n",
            " a long string $latin $latin $latin $latin $latin    ",
        );

        foreach my $t (@to_test) {
            note "Testing ", $t;
            $STR = $t;

            is $subs->{xs_trim}->(),       $subs->{pp_trim}->(), "xs_trim eq pp_trim"       or die;
            is $subs->{pp_naive_trim}->(), $subs->{pp_trim}->(), "pp_naive_trim eq pp_trim" or die;
            is $STR, $t, 'str preserved';

            note "Benchmark for string '$t'";
            Benchmark::cmpthese( -5 => $subs );
        }
    }

}

ok 1, 'done';

done_testing;

sub pp_naive_trim {
    my $s = shift;
    $s =~ s{^\s+}{};
    $s =~ s{\s+$}{};

    return $s;
}

my $ws_chars;

sub pp_trim {
    my ($str) = @_;

    return unless defined $str;
    $ws_chars //= { "\r" => undef, "\n" => undef, " " => undef, "\t" => undef, "\f" => undef };

    if ( $str =~ tr{\r\n \t\f}{} ) {
        $str =~ s/^\s+// if exists $ws_chars->{ substr( $str, 0,  1 ) };
        $str =~ s/\s+$// if exists $ws_chars->{ substr( $str, -1, 1 ) };
    }

    return $str;
}


__END__

Benchmark results from above


# Benchmark for string 'no-spaces'
                   Rate pp_naive_trim       pp_trim       xs_trim
pp_naive_trim 1522387/s            --          -11%          -57%
pp_trim       1705156/s           12%            --          -52%
xs_trim       3554380/s          133%          108%            --

# Benchmark for string ' leading-trailing '
                   Rate       pp_trim pp_naive_trim       xs_trim
pp_trim        328327/s            --          -41%          -90%
pp_naive_trim  558317/s           70%            --          -83%
xs_trim       3356254/s          922%          501%            --

# Benchmark for string '                  multiple spaces in front'
                   Rate       pp_trim pp_naive_trim       xs_trim
pp_trim        469042/s            --          -25%          -86%
pp_naive_trim  626328/s           34%            --          -81%
xs_trim       3369067/s          618%          438%            --

# Benchmark for string '
#
#
#
# multiple chars in front and end
#
#
#
#
# '
                   Rate       pp_trim pp_naive_trim       xs_trim
pp_trim        273091/s            --          -35%          -89%
pp_naive_trim  417669/s           53%            --          -83%
xs_trim       2463892/s          802%          490%            --

# Benchmark for string ' a long string Lorem ipsum dolor sit amet, accumsan patrioque mel ei.
# Sumo temporibus ad vix, in veri urbanitas pri, rebum
# nusquam expetendis et eum. Et movet antiopam eum,
# an veri quas pertinax mea. Te pri propriae consequuntur,
# te solum aeque albucius ius.
# Ubique everti recusabo id sea, adhuc vitae quo ea.
#  Lorem ipsum dolor sit amet, accumsan patrioque mel ei.
# Sumo temporibus ad vix, in veri urbanitas pri, rebum
# nusquam expetendis et eum. Et movet antiopam eum,
# an veri quas pertinax mea. Te pri propriae consequuntur,
# te solum aeque albucius ius.
# Ubique everti recusabo id sea, adhuc vitae quo ea.
#  Lorem ipsum dolor sit amet, accumsan patrioque mel ei.
# Sumo temporibus ad vix, in veri urbanitas pri, rebum
# nusquam expetendis et eum. Et movet antiopam eum,
# an veri quas pertinax mea. Te pri propriae consequuntur,
# te solum aeque albucius ius.
# Ubique everti recusabo id sea, adhuc vitae quo ea.
#  Lorem ipsum dolor sit amet, accumsan patrioque mel ei.
# Sumo temporibus ad vix, in veri urbanitas pri, rebum
# nusquam expetendis et eum. Et movet antiopam eum,
# an veri quas pertinax mea. Te pri propriae consequuntur,
# te solum aeque albucius ius.
# Ubique everti recusabo id sea, adhuc vitae quo ea.
#  Lorem ipsum dolor sit amet, accumsan patrioque mel ei.
# Sumo temporibus ad vix, in veri urbanitas pri, rebum
# nusquam expetendis et eum. Et movet antiopam eum,
# an veri quas pertinax mea. Te pri propriae consequuntur,
# te solum aeque albucius ius.
# Ubique everti recusabo id sea, adhuc vitae quo ea.
#     '
                   Rate       pp_trim pp_naive_trim       xs_trim
pp_trim         12350/s            --          -37%          -99%
pp_naive_trim   19610/s           59%            --          -99%
xs_trim       1810099/s        14556%         9130%            --
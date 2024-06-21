
use v5.14;
use warnings;

use Benchmark qw( cmpthese );
use List::Util qw( shuffle );

use Data::Enum;

my @values = shuffle qw( red green blue ultraviolet yellow black magenta bluegreen );
my $class  = Data::Enum->new(@values);
my $str    = $values[0];
my $member  = $class->new($str);

cmpthese(
    2_000_000,
    {
        'Data::Enum' => sub {
            $_ = $member->is_red;
            $_ = $member->is_blue;
            $_ = $member->is_green;
        },
        'eq' => sub {
            $_ = $str eq 'red';
            $_ = $str eq 'blue';
            $_ = $str eq 'green';
        },

    }
);

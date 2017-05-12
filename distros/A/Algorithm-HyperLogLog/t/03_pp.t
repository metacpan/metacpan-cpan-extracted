use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);

BEGIN {
    $Algorithm::HyperLogLog::PERL_ONLY = 1;
}
use Algorithm::HyperLogLog;
my $hll = Algorithm::HyperLogLog->new(16);

isa_ok $hll, 'Algorithm::HyperLogLog';

ok !$hll->XS, 'is Pure Perl?';

my $error_sum = 0;
my $repeat    = 100;

for ( 1 .. $repeat ) {

    my %unique;
    for ( 0 .. 999 ) {
        my $str = q{};
        while ( exists $unique{$str} ) {
            $str = random_string(10);
        }
        $unique{$str} = 1;
    }

    $hll->add( keys %unique );
    my $num = scalar keys %unique;
    my $error_sum += abs( $num - $hll->estimate() );
}
my $error_avg   = $error_sum / $repeat;
my $error_ratio = $error_avg / 1000 * 100;
ok $error_ratio < 1;

done_testing();

sub random_string {
    my $n   = shift;
    my $str = q{};
    for ( 1 .. $n ) {
        my $rand = rand(26);
        $str .= chr( ord('A') + $rand );
    }
    return $str;
}

1;
__END__

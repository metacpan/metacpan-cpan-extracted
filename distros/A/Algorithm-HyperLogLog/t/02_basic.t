use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use Algorithm::HyperLogLog;
use Algorithm::HyperLogLog::PP;

plan skip_all => 'No XS' unless Algorithm::HyperLogLog->XS;

my $error_sum = 0;
my $repeat    = 100;

for ( 1 .. $repeat ) {

    my $hll   = Algorithm::HyperLogLog->new(16);
    my $hllpp = Algorithm::HyperLogLog::PP->new(16);

    my %unique = ( q{} => 1 );

    for ( 0 .. 999 ) {
        my $str = q{};
        while ( exists $unique{$str} ) {
            $str = random_string(10);
        }
        $unique{$str} = 1;
        $hll->add($str);
        $hllpp->add($str);
    }

    $unique{'foo'} = 1;
    for ( 0 .. 999 ) {
        $hll->add('foo');
        $hllpp->add('foo');
    }

    $unique{'bar'} = 1;
    for ( 0 .. 999 ) {
        $hll->add('bar');
        $hllpp->add('bar');
    }

    my $cardinality   = $hll->estimate;
    my $cardinalitypp = $hllpp->estimate;

    if ( int($cardinality) == int($cardinalitypp) ) {
        ok 1, 'XS and PP compatibility test';
    }
    else {
        diag $cardinality;
        diag $cardinalitypp;
        fail();
    }

    my $unique = scalar keys %unique;

    $error_sum += abs( $unique - $cardinality );

}

my $error_avg   = $error_sum / $repeat;
my $error_ratio = $error_avg / 10001 * 100;

ok $error_ratio < 1.0, 'Error ratio less than 1.0%';

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

__END__


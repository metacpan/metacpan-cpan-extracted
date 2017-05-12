use strict;
use warnings;
use Test::More;
use Test::Fatal qw(exception lives_ok);
use File::Temp;
BEGIN {
    $Algorithm::HyperLogLog::PERL_ONLY = 1;
}
use Algorithm::HyperLogLog;

subtest 'dump and restore - immediately after initialize' => sub {
    my $hll      = Algorithm::HyperLogLog->new(5);
    my $dumpfile = File::Temp->new();
    lives_ok {
        $hll->dump_to_file( $dumpfile->filename );
    };

    my $hll_r = Algorithm::HyperLogLog->new_from_file( $dumpfile->filename );

    is $hll_r->register_size, $hll->register_size;
    is $hll_r->estimate(), $hll->estimate();

};

subtest 'dump and restore' => sub {
    my $hll      = Algorithm::HyperLogLog->new(16);
    
    $hll->add('foo');
    $hll->add('bar');
    $hll->add('baz');
    
    my $dumpfile = File::Temp->new();
    lives_ok {
        $hll->dump_to_file( $dumpfile->filename );
    };

    my $hll_r = Algorithm::HyperLogLog->new_from_file( $dumpfile->filename );

    is $hll_r->register_size, $hll->register_size;
    is $hll_r->estimate(), $hll->estimate();
};

done_testing();
1;

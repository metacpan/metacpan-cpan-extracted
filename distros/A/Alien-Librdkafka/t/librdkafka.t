use strict;
use warnings;
use Test::More;

use Alien::Librdkafka;
use version;

my $alien = Alien::Librdkafka->new;
ok defined( $alien->libs ),   "libs directory defined";
ok defined( $alien->cflags ), "cflags defined";

subtest ffi => sub {
    plan skip_all => 'test requires FFI::Platypus'
      unless eval "use FFI::Platypus; 1;";

    my $ffi = FFI::Platypus->new;
    $ffi->lib( Alien::Librdkafka->dynamic_libs );
    my $ver_func = $ffi->function( rd_kafka_version_str => [] => 'string' );
    ok $ver_func, "found rd_kafka_version_str function";
    ok(version->parse( $ver_func->() ) >=
      version->parse($Alien::Librdkafka::VERSION),
      "library version is at least $Alien::Librdkafka::VERSION");
    diag "Version is ", $ver_func->();
};

done_testing;

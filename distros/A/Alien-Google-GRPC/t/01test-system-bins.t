## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

BEGIN {
  my $cmd_result = qx(protoc --version);
  if ($cmd_result !~ /libprotoc.3/){
    print qq{1..0 # SKIP these tests because gRPC is installed as share install.\n};
    exit
  }
}
use Test::More;
use Data::Dumper;

print Dumper(\%ENV);

like (qx(grpc_cpp_plugin  --bogus 2>&1), 
        qr/unknown/i, "Does grpc_cpp_plugin run");

done_testing();

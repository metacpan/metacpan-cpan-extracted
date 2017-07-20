## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;

BEGIN {
  my $cmd_result = qx(protoc --version);
  if ($cmd_result =~ /libprotoc.3/){
    print qq{1..0 # SKIP these tests because gRPC is already installed as system install.\n};
    exit
  }
}
use Test::More;
use Data::Dumper;

print Dumper(\%ENV);

like (qx(pwd), qr/Alien-Google-GRPC/, "Path Check");
like (qx(find . -name protoc), qr/protoc/, "Find protoc");

like (qx(./blib/lib/auto/share/dist/Alien-Google-GRPC/bin/protoc  --version), 
        qr/libprotoc 3/, "Does protoc run");

like (qx(find . -name grpc_cpp_plugin), qr/grpc_cpp_plugin/, 
        "Find grpc_cpp_plugin");

like (qx(./blib/lib/auto/share/dist/Alien-Google-GRPC/bin/grpc_cpp_plugin  --bogus 2>&1), 
        qr/unknown/i, "Does grpc_cpp_plugin run");

done_testing();

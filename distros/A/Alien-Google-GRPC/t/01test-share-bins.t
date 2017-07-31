## no critic(RCS,VERSION,explicit,Module)
use strict;
use warnings;
use Capture::Tiny ':all';
use Test::More;
use Data::Dumper;

BEGIN {
  my ($cmd_result) = capture {
    system( 'protoc', '--version');
  };

  if ($cmd_result =~ /libprotoc.3/){
    print qq{1..0 # SKIP these tests because gRPC is already installed as system install.\n};
    exit
  }
}

print Dumper(\%ENV);

my ($std_out, $error_out);

($std_out) = capture {
  system( 'pwd' );
};
like ($std_out, qr/Alien-Google-GRPC/, "Path Check");

($std_out) = capture {
  system( 'find', '.', '-name', 'protoc' );
};
like ($std_out, qr/protoc/, "Find protoc");

($std_out) = capture {
  system( './blib/lib/auto/share/dist/Alien-Google-GRPC/bin/protoc', '--version' );
};
like ($std_out, 
        qr/libprotoc 3/, "Does protoc run");

($std_out) = capture {
  system( 'find', '.', '-name', 'grpc_cpp_plugin' );
};
like ($std_out, qr/grpc_cpp_plugin/, 
        "Find grpc_cpp_plugin");

($std_out, $error_out) = capture {
  system( './blib/lib/auto/share/dist/Alien-Google-GRPC/bin/grpc_cpp_plugin', '--bogus');
};
like ($error_out,
        qr/unknown/i, "Does grpc_cpp_plugin run");

done_testing();

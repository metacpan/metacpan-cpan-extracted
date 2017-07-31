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

  if ($cmd_result !~ /libprotoc.3/){
    print qq{1..0 # SKIP these tests because gRPC is not installed as a system install.\n};
    exit
  }
}

print Dumper(\%ENV);

my ($std_out, $error_out) = capture {
  system( 'grpc_cpp_plugin', '--bogus');
};
like ($error_out, 
        qr/unknown/i, "Does grpc_cpp_plugin run");

done_testing();

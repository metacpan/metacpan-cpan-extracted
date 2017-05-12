#!perl

use strict;
use warnings;
use Test::More qw(no_plan);
use Test::Exception;
use Test::Warn;
use blib;
use lib "t/tlib";
use CGI::JSONRPC;
use CGI::JSONRPC::Dispatcher::Test;

my $request = {
  id => 1,
  method => "test_good",
  params => [ 'CGI.JSONRPC.Dispatcher.Test', 2 ],
};
   
my $rpc = CGI::JSONRPC->new;
is($rpc->run_data_request($request), '{"id":1,"result":[[1," so there ",2]]}', "Good request is dispatched");
$request->{method} = "test_protected";

my $rv;
my $error = "CGI::JSONRPC::Dispatcher::Test::test_protected may not be dispatched";

warning_like
  { $rv = $rpc->run_data_request($request) }
  qr/\Q$error\E/, "Fatal errors are warned";

like($rv, qr/\Q"error":"$error\E/, "Protected method is not dispatched");

$request->{method} = "test_missing";

$error = qq{Can't locate object method "test_missing" via package "CGI::JSONRPC::Dispatcher::Test};

warning_like
  { $rv = $rpc->run_data_request($request) }
  qr/\Q$error\E/, "Missing method warns with an error";

$error =~ s{"}{\\"}g;

like($rv, qr/\Q"error":"$error\E/, "Error will be returned to the browser");
unlike($rv, qr/line \d+/, "Line number is *not* returned to the browser");

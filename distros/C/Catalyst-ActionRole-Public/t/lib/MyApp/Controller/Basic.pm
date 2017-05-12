package MyApp::Controller::Basic;

use Moose;
use MooseX::MethodAttributes;

extends  'Catalyst::Controller';

sub absolute_path :Path('/example1') Args(0) Does(Public) At(/example.txt) { }
sub relative_path :Path('/example2') Args(0) Does(Public) At(example.txt) { }
sub set_content_type :Path('/example3') Args(0) Does(Public) ContentType(application/json) ContentType(text/html,application/javascript)
  At(/:namespace/relative_path/example.js) { }

sub css :Local Does(Public) At(/:namespace/*) { }
sub static :Local Does(Public) { }

sub chainbase :Chained(/) PathPrefix CaptureArgs(1) { }

  sub link1 :Chained(chainbase) PathPart(aaa) CaptureArgs(0) { }

    sub link2 :Chained(link1) Args(2) Does(Public) { }

sub chainbase2 :Chained(/)  CaptureArgs(1) { }

  sub link3 :Chained(chainbase2) PathPart(aaa) CaptureArgs(1) Does(Public) { }

    sub link4 :Chained(link3) Args(1)  { }

sub cache_control_1 :Local Args(0) Does(Public) CacheControl(private, max-age=600) At(/example.txt) { }
1;


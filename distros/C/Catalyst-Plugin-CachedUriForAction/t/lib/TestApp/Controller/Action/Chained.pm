package TestApp::Controller::Action::Chained;

use strict;
use warnings;

use HTML::Entities;

use base qw/Catalyst::Controller/;

#
#   Simple parent/child action test
#
sub foo  :PathPart('chained/foo')  :CaptureArgs(1) :Chained('/') {
}
sub endpoint  :PathPart('end')  :Chained('/action/chained/foo')  :Args(1) { }

#
#   Parent/child test with two args each
#
sub foo2 :PathPart('chained/foo2') :CaptureArgs(2) :Chained('/') { }
sub endpoint2 :PathPart('end2') :Chained('/action/chained/foo2') :Args(2) { }

#
#   three chain with concurrent endpoints
#
sub one   :PathPart('chained/one') :Chained('/')                   :CaptureArgs(1) { }
sub two   :PathPart('two')         :Chained('/action/chained/one') :CaptureArgs(2) { }
sub three_end :PathPart('three')       :Chained('two') :Args(3) { }

#
#   Test multiple chained actions with no captures
#
sub empty_chain_a : Chained('/')             PathPart('chained/empty') CaptureArgs(0) { }
sub empty_chain_b : Chained('empty_chain_a') PathPart('')              CaptureArgs(0) { }
sub empty_chain_c : Chained('empty_chain_b') PathPart('')              CaptureArgs(0) { }
sub empty_chain_d : Chained('empty_chain_c') PathPart('')              CaptureArgs(1) { }
sub empty_chain_e : Chained('empty_chain_d') PathPart('')              CaptureArgs(0) { }
sub empty_chain_f : Chained('empty_chain_e') PathPart('')              Args(1)        { }

sub roundtrip_urifor : Chained('/') PathPart('chained/roundtrip_urifor') CaptureArgs(1) {}
sub roundtrip_urifor_end : Chained('roundtrip_urifor') PathPart('') Args(1) {
}

1;

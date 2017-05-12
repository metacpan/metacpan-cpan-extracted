#
# This file is part of Dancer-Plugin-RPC-MXL
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package t::lib::TestApp;

use Dancer;
use Dancer::Plugin::RPC::XML;

xmlrpc '/xmlrpc' => sub {
  my $method = params->{method};
  # ref to passed data
  my $data = params->{data};

  if ( $method eq 'testFault' ) {
    return xmlrpc_fault(100,"TestFaultMessage");
  }
  else {
    return {methodWas => $method, dataWas => $data};
  }
};


1;

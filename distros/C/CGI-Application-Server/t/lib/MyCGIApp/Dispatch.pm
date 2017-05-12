use strict;
use warnings;

package MyCGIApp::Dispatch;
use base 'CGI::Application::Dispatch';

sub dispatch_args {
  return {
    table => [
      '/foo/:rm' => { app => 'MyCGIApp' },
    ]
  }
}

1;

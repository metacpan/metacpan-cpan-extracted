package Apache::Foo::Bar;

use strict;
use warnings;

use Apache::Constants qw( OK SERVER_ERROR );

sub dispatch_baz {
    my $class = shift;
	my $r     = Apache->request;
    $r->log->debug("$class->dispatch_baz()");
	$Apache::Foo::Bar::output = "pid $$";
	$r->send_http_header('text/plain');
    $r->print("$class->dispatch_baz()");
    return OK;
}

sub post_dispatch {
  my $class = shift;
  my $r     = shift;
  $r->log->debug("$class->post_dispatch()");
  # delay printing headers until all processing is done
  $r->send_http_header('text/plain');
  $r->print($Apache::Foo::Bar::output);
}

1;

__END__

here is a sample httpd.conf entry

  PerlModule Apache::Dispatch
  PerlModule Foo

  <Location /Test>
    SetHandler perl-script
    PerlHandler Apache::Dispatch
    DispatchPrefix Foo
    DispatchExtras Pre Post Error
  </Location>

once you install it, you should be able to go to
http://localhost/Test/Foo/foo
or
http://localhost/Test/Foo/Bar/foo
etc, and get some results

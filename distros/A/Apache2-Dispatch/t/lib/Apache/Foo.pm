package Apache::Foo;

use Apache::Constants qw( OK SERVER_ERROR );

use strict;
use warnings;

sub dispatch_foo {
    my ($class, $r) = @_;
    $r->log->debug("$class->dispatch_foo()");
    
	$r->send_http_header('text/plain');
    $r->print("$class->dispatch_foo()");
    return OK;
}

sub dispatch_bad {
    my ($class, $r) = @_;

	$r->log->debug("$class->dispatch_bad()");
    return SERVER_ERROR;
}

sub pre_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("$class->pre_dispatch()");
	
	$r->send_http_header('text/plain');
    $r->print("$class->pre_dispatch()");
}

sub post_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("$class->post_dispatch()");
    $r->print("$class->post_dispatch()");
	#$r->print($Apache::Foo::output);
}

sub error_dispatch {
    my ($class, $r) = @_;
    $r->log->error("Yikes! $class->dispatch_error()");
    
	$r->send_http_header('text/plain');
    $r->print("Yikes! $class->dispatch_error()");
    return OK;
}

sub dispatch_index {
    my ($class, $r) = @_;
    $r->log->debug("$class->dispatch_index()");
    
	$r->send_http_header('text/plain');
    $r->print("$class->dispatch_index()");
    return OK;
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
http://localhost/Test/foo
and get some results

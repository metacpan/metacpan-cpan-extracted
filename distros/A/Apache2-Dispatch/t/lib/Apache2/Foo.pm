package Apache2::Foo;

use strict;

use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::RequestIO;

sub dispatch_foo {
    my ($class, $r) = @_;
    $r->log->debug("$class->dispatch_foo()");
    
	$r->content_type('text/plain');
    $r->print("$class->dispatch_foo()");
    return Apache2::Const::OK;
}

sub dispatch_bad {
    my ($class, $r) = @_;
	$r->log->debug("$class->dispatch_bad()");
    
    return Apache2::Const::SERVER_ERROR;
}

sub pre_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("$class->pre_dispatch()");
	$r->print("$class->pre_dispatch");
}

sub post_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("$class->post_dispatch()");
	$r->print("$class->post_dispatch");
}

sub error_dispatch {
    my ($class, $r) = @_;
    $r->log->debug("$class->error_dispatch()");
    
	$r->content_type('text/plain');
    $r->print("Yikes!  $class->dispatch_error()");
    return Apache2::Const::OK;
}

sub dispatch_index {
    my ($class, $r) = @_;
    $r->log->debug("$class->dispatch_index()");
    
	$r->content_type('text/plain');
    $r->print("$class->dispatch_index()");
    return Apache2::Const::OK;
}

1;

__END__

here is a sample httpd.conf entry

  PerlModule Apache2::Dispatch
  PerlModule Apache2::Foo

  <Location /Test>
    SetHandler perl-script
    PerlHandler Apache2::Dispatch
    DispatchPrefix Apache2::Foo
    DispatchExtras Pre Post Error
  </Location>

once you install it, you should be able to go to
http://localhost/Test/foo
and get some results

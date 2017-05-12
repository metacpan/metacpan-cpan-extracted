package Apache2::Foo::Bar;

use strict;
use warnings;

use Apache2::Const -compile => qw( OK SERVER_ERROR );
use Apache2::RequestRec;
use Apache2::RequestIO;

sub dispatch_baz {
    my ($class, $r) = @_;
	$r->log->debug("$class->dispatch_baz()");
    
	$r->content_type('text/plain');
    $Apache2::Foo::Foo::output = "pid $$";
    $r->print("$class->dispatch_baz()");
    return Apache2::Const::OK;
}

sub post_dispatch {
  my ($class, $r) = @_;
  $r->print($Apache2::Foo::Foo::output);
  $r->log->debug("$class->post_dispatch()");
}

1;

__END__

here is a sample httpd.conf entry

  PerlLoadModule Apache2::Dispatch
  PerlModule Apache2::Foo::Bar

  <Location /Test>
    SetHandler perl-script
    PerlHandler Apache2::Dispatch
    DispatchUpperCase On
	DispatchPrefix Foo
    DispatchExtras Pre Post Error
  </Location>

once you install it, you should be able to go to
http://localhost/Test/Foo/foo
or
http://localhost/Test/Foo/Bar/foo
etc, and get some results

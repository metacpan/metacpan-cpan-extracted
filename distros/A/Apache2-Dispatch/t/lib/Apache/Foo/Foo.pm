package Foo::Foo;

use Apache::Constants qw( OK SERVER_ERROR );
use strict;

our $AUTOLOAD;

# declare the methods you want AUTOLOAD to capture by name
# that is, AUTOLOAD will still be called, but $AUTOLOAD
# will only be populated for methods you declare here
#
# read the camel book (3rd ed) pp326-329 before treading here...

sub dispatch_baz;

$Foo::Foo::output = undef;

sub dispatch_foo {
  my $self = shift;
  my $r = shift;
  $r->send_http_header('text/plain');
  $r->print("Foo->dispatch_foo()");
  print STDERR "Foo->dispatch_foo()\n";
  return OK;
}

sub dispatch_bar {
  # test returning not OK
  print STDERR "Foo->dispatch_bar()\n";
  return SERVER_ERROR;
}

sub pre_dispatch {
  # test pre_dispatch call
  print STDERR "Foo->pre_dispatch()\n";
}

sub post_dispatch {
  # test post_dispatch call
  print STDERR "Foo->post_dispatch()\n";
}

sub error_dispatch {
  # test error_dispatch call
  my $self = shift;
  my $r = shift;
  $r->send_http_header('text/plain');
  $r->print("Yikes!  Foo->dispatch_error()");
  print STDERR "Yikes!  Foo->dispatch_error()\n";
  # you can return whatever you want...  
  return OK;
}

sub dispatch_index {
  # test calls to /index or /
  my $self = shift;
  my $r = shift;
  $r->send_http_header('text/plain');
  $r->print("Foo->dispatch_index()");
  print STDERR "Foo->dispatch_index()\n";
  return OK;
}

sub AUTOLOAD {
  my $self = shift;
  my $r = shift;

  our $AUTOLOAD;

  # this might be a good use for Damian Conway's Switch.pm
  return if $AUTOLOAD =~ m/::DESTROY$/;

  print STDERR "asked for $AUTOLOAD\n";

  if $AUTOLOAD =~ m/dispatch_baz/ {
    $r->print("method $AUTOLOAD was declared!");
    return OK;
  }

  $r->send_http_header('text/plain');
  $r->print("sorry - method $AUTOLOAD not found");
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
http://localhost/Test/Foo/foo
and get some results

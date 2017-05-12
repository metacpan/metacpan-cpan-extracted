# vim: filetype=perl

use strict;
use warnings;

our @doc;
BEGIN {
  @doc = (qw(
	#document empty empty
	#document html head title head body h1 body html
	));
}

use IO::Handle;
use IO::File;
use Data::Transform::SAXBuilder;
use XML::SAX::IncrementalBuilder::LibXML;
use Test::More;
use POE qw(
  Wheel::ReadWrite
  Driver::SysRW
);

plan tests => @doc + 1;
#plan qw(no_plan);

autoflush STDOUT 1;
my $request_number = 8;

my $session = POE::Session->create(
  inline_states => {
    _start => \&start,
    input => \&input,
    error => \&error,
  },
);

POE::Kernel->run();
exit;

sub start {
  my ($kernel, $heap) = @_[KERNEL, HEAP];

  sysseek(DATA, tell(DATA), 0);

  my $builder = XML::SAX::IncrementalBuilder::LibXML->new(godepth => 2);
  my $filter = Data::Transform::SAXBuilder->new(handler => $builder);

  my $wheel = POE::Wheel::ReadWrite->new (
    Handle => \*DATA,
    # cheat by making the blocksize exactly as big as the first document
    # multiple documents only work if you can guarantee that you never
    # feed the parser bits of two documents at once.
    Driver => POE::Driver::SysRW->new (BlockSize => 17),
    InputFilter => $filter,
    InputEvent => 'input',
    ErrorEvent => 'error',
  );
  $heap->{'wheel'} = $wheel;
}

sub input {
  my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

  my $expected = shift @doc;

  is($data->nodeName, $expected, "got correct element");
}

sub error {
  my $heap = $_[HEAP];
  my ($type, $errno, $errmsg, $id) = @_[ARG0..$#_];

  is($errno, 0, "got EOF");
  delete $heap->{wheel};
}

# below is a list of xml documents these are used to drive the tests.

__DATA__
<empty>
</empty>
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>FOO</title>
  </head>
  <body>
    <h1>FOO</h1>
  </body>
</html>

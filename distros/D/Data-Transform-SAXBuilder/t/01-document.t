# vim: filetype=perl

use strict;
use warnings;

our @doc;
BEGIN {
  @doc = (qw(
  	#document html head title head body h1 body html
	));
}

use IO::Handle;
use IO::File;
use Test::More;
use Data::Transform::Identity;
use Data::Transform::Line;
use XML::SAX::IncrementalBuilder::LibXML;
use POE qw(
  Wheel::ReadWrite
  Driver::SysRW
);

plan tests => @doc + 2;
#plan qw(no_plan);

use_ok('Data::Transform::SAXBuilder');

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
    Driver => POE::Driver::SysRW->new (BlockSize => 10),
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

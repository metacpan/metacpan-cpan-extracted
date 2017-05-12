# vim: filetype=perl

use strict;
use warnings;

our ($count, @doc);
BEGIN {
  @doc = (
	'#document'	=> 'Document',
  	html		=> 'Document',
	head		=> 'Document',
	'#text'		=> 'DocumentFragment',
	title		=> 'DocumentFragment',
	'#text'		=> 'DocumentFragment',
	head		=> 'Document',
	body		=> 'Document',
	'#text'		=> 'DocumentFragment',
	h1		=> 'DocumentFragment',
	'#text'		=> 'DocumentFragment',
	body		=> 'Document',
  	html		=> 'Document',
	);

$count = @doc + 1;
my @on_doc = grep {$_ eq 'Document'} @doc;
$count -= (@on_doc - 1) / 2;
}

use IO::Handle;
use IO::File;
use Test::More;
use Data::Transform::SAXBuilder;
use XML::SAX::IncrementalBuilder::LibXML;
use POE qw(
  Wheel::ReadWrite
  Driver::SysRW
);

plan tests => $count;
#plan qw(no_plan);

autoflush STDOUT 1;

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

  my $builder = XML::SAX::IncrementalBuilder::LibXML->new(
  		godepth => 2,
		detach => 1,
	);
  my $filter = Data::Transform::SAXBuilder->new(handler => $builder);

  my $wheel = POE::Wheel::ReadWrite->new (
    Handle => \*DATA,
    Driver => POE::Driver::SysRW->new (BlockSize => 100),
    InputFilter => $filter,
    InputEvent => 'input',
    ErrorEvent => 'error',
  );
  $heap->{'wheel'} = $wheel;
}

sub input {
  my ($kernel, $heap, $data) = @_[KERNEL, HEAP, ARG0];

  my $expected = shift @doc;
  my $owner_type = shift @doc;
  #warn $data, $data->nodeName, $expected, $owner_type;

  if ($owner_type eq 'DocumentFragment') {
  	is ($data->firstChild->nodeName, $expected,
		"got correct element ($expected)");
  } else {
	my $doc = $data->getOwner;
  	is($data->nodeName, $expected, "got correct element ($expected)");
  }
  unless ($data->can('special') and $data->special and $data->special eq 'End') {
  	isa_ok($data->getOwner, "XML::LibXML::$owner_type", "owner");
  }
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

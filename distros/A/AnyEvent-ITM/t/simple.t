#!/usr/bin/env perl
use strict;
use warnings;
use AE;
use AnyEvent::ITM;
use AnyEvent::Handle;
use AnyEvent::Util;
use Test::More;
 
my ($read_fh, $write_fh) = portable_pipe;

my @tests = (
 [ 'Sync Packet 1',            '00000000', { class => 'ITM::Sync' } ],
 [ 'Sync Packet 2',            '10000000', { class => 'ITM::Sync' } ],
 [ 'Overflow Packet',          '01110000', { class => 'ITM::Overflow' } ],
 [ 'Instrumentation Packet 1', '00000001', { class => 'ITM::Instrumentation', source => 0,  payload => chr(36) } ],
 [ 'Instrumentation Packet 2', '00000011', { class => 'ITM::Instrumentation', source => 0,  payload => chr(41).chr(39).chr(38).chr(37) } ],
 [ 'Instrumentation Packet 3', '00001010', { class => 'ITM::Instrumentation', source => 1,  payload => chr(42).chr(43) } ],
 [ 'Instrumentation Packet 4', '01000010', { class => 'ITM::Instrumentation', source => 8,  payload => chr(44).chr(45) } ],
 [ 'Instrumentation Packet 5', '01010010', { class => 'ITM::Instrumentation', source => 10, payload => chr(46).chr(47) } ],
 [ 'Hardware Source Packet 1', '00010101', { class => 'ITM::HardwareSource',  source => 2,  payload => chr(48) } ]
);

my $cv = AE::cv;

{
  my $hdl = AnyEvent::Handle->new(fh => $write_fh, on_error  => sub { die 'wtf' });
  for my $t (@tests) {
    my $header = pack('b8',join("",reverse(split("",$t->[1]))));
    my $payload = defined $t->[2]->{payload} ? $t->[2]->{payload} : "";
    my $packet = $header.$payload;
    $hdl->push_write($packet);
  }
}
 
sub read_handler;
sub read_handler {
  my ($hdl, $data) = @_;
  my $t = shift @tests;
  my $name = $t->[0];
  my $class = $t->[2]->{class};
  my $payload = $t->[2]->{payload};
  isa_ok($data,$class,$name);
  if (defined $payload) {
    is($data->payload,$payload,'Payload on '.$name);
  } else {
    ok(!$data->has_payload,'No payload on '.$name);
  }
  if (defined $t->[2]->{source}) {
    is($data->source,$t->[2]->{source},'Payload on '.$name);
  }
  $cv->send() unless @tests;
  $hdl->push_read(itm => \&read_handler) if @tests;
}
 
my $hdl = do {
  my $hdl = AnyEvent::Handle->new(fh => $read_fh, on_error  => sub { die 'wtf' });
  $hdl->push_read(itm => \&read_handler);
  $hdl;
};
 
$cv->recv();
 
done_testing;
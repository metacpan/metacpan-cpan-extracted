#!/usr/bin/perl -w

use Test::More tests => 28;
use Data::BT::PhoneBill;

my $filename = "data/phone.csv";
ok my $bill = Data::BT::PhoneBill->new($filename), "New phone bill";
isa_ok $bill => Data::BT::PhoneBill;

{
  ok my $call = $bill->next_call, "Get first call";
  isa_ok $call => Data::BT::PhoneBill::_Call;
  is $call->time, "23:00", "time";
  is $call->destination, "Mobile Phone", "destination";
  is $call->number, "07939 XXYYZZ", "number";
  is $call->type, "Mobile", "type";
  is $call->duration, 37, "duration";
  is $call->cost, 8.8, "cost";
  isa_ok $call->date => Date::Simple;
  is $call->date->format, "2003-09-12", "date";
}
{
  my $call = <$bill>;
  is $call->date->format, "2003-09-12", "date";
  is $call->time, "23:01", "time";
  is $call->destination, "Stirling", "destination";
  is $call->number, "01786 XXYYZZ", "number";
  is $call->type, "Ntnl", "type";
  is $call->duration, 1556, "duration";
  is $call->cost, 87.1, "cost";
}

#Mobile,01865723018  ,,,13/09/2003,12:53,Mobile Phone,07801 XXYYZZ      ,0000:00:08,           0.000,           0.042
{
  ok my $call = $bill->next_call, "Get third call";
  is $call->date->format, "2003-09-13", "date";
  is $call->time, "12:53", "time";
  is $call->destination, "Mobile Phone", "destination";
  is $call->number, "07801 XXYYZZ", "number";
  is $call->type, "Mobile", "type";
  is $call->duration, 8, "duration";
  is $call->cost, 4.2, "cost";
}

ok !<$bill>, "No more calls";

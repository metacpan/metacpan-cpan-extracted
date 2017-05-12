#!/usr/bin/perl

use Cisco::IPPhone;

$myerror = new Cisco::IPPhone;

$myerror->Error( { Number => "1" });

print $myerror->Content;

__END__

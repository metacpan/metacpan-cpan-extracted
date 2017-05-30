#!/usr/bin/env perl
# vim: softtabstop=4 tabstop=4 shiftwidth=4 ft=perl expandtab smarttab

use strict;
use warnings 'all';

use BZ::Client::XMLRPC();
use DateTime();

use Test::More tests => 4;

my $tz = DateTime::TimeZone->new(name => 'CET');
die 'Unable to create CET timezone' unless $tz;
my $now = DateTime->new(
           year       => 2011,
           month      => 9,
           day        => 19,
           hour       => 19,
           minute     => 9,
           second     => 3,
           nanosecond => 500000000,
           time_zone  => $tz,
      );

sub TestBasic {
    my $xmlrpc = BZ::Client::XMLRPC->new();
    my $input = [
                 '123',
                  BZ::Client::XMLRPC::int->new(345),
                  BZ::Client::XMLRPC::double->new(4.6),
                  [ 'a', 'b', 'c' ],
                  scalar($now),
                  BZ::Client::XMLRPC::base64->new('hello'),
                  {
                      'a' => BZ::Client::XMLRPC::int->new(0),
                      'b' => 'xyz'
                  }
                ];
    my $contents = $xmlrpc->create_request('someMethod', $input);
    my $expect =
      '<methodCall>'
      . '<methodName>someMethod</methodName>'
      . '<params>'
      .   '<param><value>123</value></param>'
      .   '<param><value><i4>345</i4></value></param>'
      .   '<param><value><double>4.6</double></value></param>'
      .   '<param>'
      .     '<value>'
      .       '<array>'
      .         '<data>'
      .           '<value>a</value>'
      .           '<value>b</value>'
      .           '<value>c</value>'
      .         '</data>'
      .       '</array>'
      .     '</value>'
      .   '</param>'
      .   '<param><value><dateTime.iso8601>2011-09-19T17:09:03Z</dateTime.iso8601></value></param>'
      .   '<param><value><base64>aGVsbG8=</base64></value></param>'
      .   '<param>'
      .     '<value>'
      .       '<struct>'
      .         '<member>'
      .           '<name>a</name>'
      .           '<value><i4>0</i4></value>'
      .         '</member>'
      .         '<member>'
      .           '<name>b</name>'
      .           '<value>xyz</value>'
      .         '</member>'
      .       '</struct>'
      .     '</value>'
      .   '</param>'
      . '</params>'
      ."</methodCall>\n";
    return is( $contents, $expect, 'Check return value of create_request (someMethod)');
}

sub TestGetProducts {
    my $xmlrpc = BZ::Client::XMLRPC->new();
    my $input = [ { 'ids' => [ '0', '1', '2' ] } ];
    my $contents = $xmlrpc->create_request('Product.get', $input);
    my $expect =
      '<methodCall>'
      . '<methodName>Product.get</methodName>'
      . '<params>'
      .   '<param>'
      .     '<value>'
      .     '<struct>'
      .          '<member>'
      .            '<name>ids</name>'
      .            '<value><array><data><value>0</value><value>1</value><value>2</value></data></array></value>'
      .          '</member>'
      .       '</struct>'
      .     '</value>'
      .   '</param>'
      . '</params>'
      ."</methodCall>\n";
    return is( $contents, $expect, 'Check return value of create_request (Product.get)');
}

ok(TestBasic(), 'Test Basic');
ok(TestGetProducts(), 'Test GetProducts');


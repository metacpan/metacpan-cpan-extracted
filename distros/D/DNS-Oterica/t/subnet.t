#!perl
use strict;
use warnings;
use DNS::Oterica::Network;
use Net::IP;
use Test::More;

sub prefixes {
  my ($ip) = @_;
  DNS::Oterica::Network->_class_prefixes($ip);
}

{
  my @prefixes = prefixes( Net::IP->new('1.2.3.0/24') );

  is_deeply([ sort @prefixes ], [ '1.2.3' ], "1.2.3.0/24");
}

{
  my @prefixes = prefixes( Net::IP->new('1.2.3.0/32') );

  is_deeply([ sort @prefixes ], [ '1.2.3.0' ], "1.2.3.0/32");
}

{
  my @prefixes = prefixes( Net::IP->new('1.2.3.0/25') );
  my @want     = map {; "1.2.3.$_" } (0 .. 127);

  is_deeply([ sort @prefixes ], [ sort @want ], "1.2.3.0/25");
}

{
  my @prefixes = prefixes( Net::IP->new('1.2.0/17') );
  my @want     = map {; "1.2.$_" } (0 .. 127);
  is_deeply([ sort @prefixes ], [ sort @want ], "1.2.0/17");
}

done_testing;

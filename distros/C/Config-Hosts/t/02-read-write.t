#!perl

use strict;
use warnings;

use Test::More;
use Config::Hosts;

my $hosts = Config::Hosts->new();

use Data::Dumper;

my $tmp_hosts = $^O eq 'MSWin32' ? "c:/temp/hosts" : "/tmp/hosts";

$hosts->read_hosts('t/hosts');
plan(tests => (scalar keys %{$hosts->{_hosts}} ) * 6);
for my $host (keys %{$hosts->{_hosts}}) {
	my $type = $hosts->determine_ip_or_host($host);
	if ($type == $Config::Hosts::TYPE_IP) {
		is($type, $Config::Hosts::TYPE_IP, "$host is a valid ip");
		like($hosts->{_contents}[$hosts->{_hosts}{$host}{line}], qr/$host/i, "ip preserved");
		isa_ok($hosts->{_hosts}{$host}{hosts}, 'ARRAY');
	}
	elsif ($type == $Config::Hosts::TYPE_HOST) {
		is($type, $Config::Hosts::TYPE_HOST, "$host is a valid hostname");
		like($hosts->{_contents}[$hosts->{_hosts}{$host}{line}], qr/$host/i, "hostname preserved");
		ok(Config::Hosts::is_valid_ip($hosts->{_hosts}{$host}{ip}), "ip specified ok");
	}
	else {
		fail("Invalid type $type");
	}
}

$hosts->write_hosts($tmp_hosts);
$hosts->read_hosts($tmp_hosts);
for my $host (keys %{$hosts->{_hosts}}) {
	my $type = $hosts->determine_ip_or_host($host);
	if ($type == $Config::Hosts::TYPE_IP) {
		is($type, $Config::Hosts::TYPE_IP, "$host is a valid ip");
		like($hosts->{_contents}[$hosts->{_hosts}{$host}{line}], qr/$host/, "ip preserved");
		isa_ok($hosts->{_hosts}{$host}{hosts}, 'ARRAY');
	}
	elsif ($type == $Config::Hosts::TYPE_HOST) {
		is($type, $Config::Hosts::TYPE_HOST, "$host is a valid hostname");
		like($hosts->{_contents}[$hosts->{_hosts}{$host}{line}], qr/$host/, "hostname preserved");
		ok(Config::Hosts::is_valid_ip($hosts->{_hosts}{$host}{ip}), "ip specified ok");
	}
	else {
		fail("Invalid type $type");
	}
}
unlink $tmp_hosts;

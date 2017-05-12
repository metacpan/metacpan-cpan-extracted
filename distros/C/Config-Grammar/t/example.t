#!/usr/sepp/bin/perl-5.6.1 -w

use lib 'lib';
use lib 't';
use strict;
use Test;
use DebugDump;

BEGIN {
    plan tests => 6;
}

use Config::Grammar;
ok(1);

my $RE_IP       = '\d+\.\d+\.\d+\.\d+';                 # 192.168.116.12
my $RE_MAC      = '[0-9a-f]{2}(?::[0-9a-f]{2}){5}';     # 00:50:fe:bc:65:13
my $RE_HOST     = '\S+';

my $parser = Config::Grammar->new({
	_sections => [ 'network', 'hosts', 'text' ],
	network => {
	    _vars     => [ 'dns' ],
	    _sections => [ "/$RE_IP/" ],
	    dns       => {
		_doc => "address of the dns server",
		_example => "10.12.33.2",
		_re => $RE_HOST,
		_re_error =>
		'dns must be an host name or ip address',
	    },
	    "/$RE_IP/" => {
		_doc    => "Ip Adress",
                _example => "192.168.98.3",
		_vars   => [ 'dns', 'netmask', 'gateway' ],
		dns     => {
		    _doc => "address of the dns server",
                    _example => "10.12.33.3",
		    _re => $RE_HOST,
		    _re_error =>
		    'dns must be an host name or ip address'
		},
		netmask => {
		    _doc => "Netmask",
                    _example => "255.255.255.0",
		    _re => $RE_IP,
		    _re_error =>
		    'netmask must be a dotted ip address'
		},
		gateway => {
		    _doc => "Default Gateway address in IP notation",
                    _example => "10.12.33.1",
		    _re => $RE_IP,
		    _re_error =>
		    'gateway must be a dotted ip address' },
	    },
	},
	hosts => {
	    _doc => "Details about the hosts",
	    _table  => {
		_doc => "Description of all the Hosts",
		_key => 0,
		_columns => 3,
		0 => {
		    _doc => "Ethernet Address",
                    _example => "2:3:3:a:fb:cc:12:2",
		    _re => $RE_MAC,
		    _re_error =>
		    'first column must be an ethernet mac address',
		},
		1 => {
		    _doc => "IP Address",
                    _example => "10.1.43.32",
		    _re => $RE_IP,
		    _re_error =>
		    'second column must be a dotted ip address',
		},
	    },
	},
	text => {
	    _text => {},
	}
    });

ok(2);

my $cfg = $parser->parse('t/example.conf');
defined $cfg or die "ERROR: $parser->{err}\n";
ok(2);

open(PARSED, 't/example.parsed') or do { print DebugDump::debug_dump($cfg); die; };
$/ = undef;
my $expect = <PARSED>;
close PARSED;

my $is = DebugDump::debug_dump($cfg);

ok($is, $expect);

open(POD, 't/example.pod');
my $pod_expected = <POD>;
my $pod = $parser->makepod;
ok($pod, $pod_expected);
close POD;

open(TMPL, 't/example.tmpl');
my $tmpl_expected = <TMPL>;
my $tmpl = $parser->maketmpl;
ok($tmpl, $tmpl_expected);
close TMPL;

# vi: ft=perl sw=4

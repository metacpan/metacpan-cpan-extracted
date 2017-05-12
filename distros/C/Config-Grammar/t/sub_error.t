#!/usr/sepp/bin/perl-5.6.1 -w

use lib 'lib';
use strict;
use Test::Simple tests => 3;
use Config::Grammar;

my $parser = Config::Grammar->new({
	_vars => [ 'var' ],
	_sections => [ 'table' ],
	_mandatory => [ 'var', 'table' ],
	var => {
		_sub => sub { $_[0] eq 'test' ? return undef : return 'error' },
	},
	table => {
		_table => {
			_columns => 1,
			0 => {
				_sub => sub { $_[0] eq 'test' ? return undef : return 'error'; },
			}
		}
	}
    });

ok(defined $parser, 'new works');

my $cfg = $parser->parse('t/sub_error1.conf');
if(defined $cfg) {
    ok(0, 'no error for variables'),
}
else {
    ok($parser->{err} eq 't/sub_error1.conf, line 1: error', '_sub error for variables');
}

$cfg = $parser->parse('t/sub_error2.conf');
if(defined $cfg) {
    ok(0, 'no error for table columns'),
}
else {
    ok($parser->{err} eq 't/sub_error2.conf, line 5: error', '_sub error for table columns');
}


# vi: ft=perl sw=4

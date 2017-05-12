#
# This file is part of Catalyst-Controller-ElasticSearch
#
# This software is Copyright (c) 2013 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The MIT (X11) License
#
package MyTest;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use JSON;

use base 'Exporter';
our @EXPORT = qw(test_json GET POST encode_json);

my $app = require MyApp;

sub POST {
	my ($target, %args) = @_;
	return HTTP::Request::Common::POST($target, %args, "Content-Type" => "application/json");
}

sub test_json {
	my ($req, $json, $msg) = @_;
	test_psgi $app, sub {
		my $cb = shift;
		my $res = $cb->($req);
		is($res->code, $json->{code} || 200);
		# warn $res->content;
		is_deeply( decode_json($res->content), $json, $msg );
	};
}

1;
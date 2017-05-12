use strict;
use warnings;

use Test::More tests => 29;
use ApacheLog::Compressor;

sub is_hex($$;$) {
	my ($check, $expected, $txt) = @_;
	$txt = '' unless defined $txt;
	my @hex = split / /, $expected;
	is(unpack('H*', $check), join('', @hex), $txt);
}

my $comp = new_ok('ApacheLog::Compressor' => []);

my $buffer = '';
$comp = new_ok('ApacheLog::Compressor' => [
	on_write => sub {
		my ($self, $pkt) = @_;
		isa_ok($self, 'ApacheLog::Compressor');
		$buffer .= $pkt;
	}
]);
my $exp = new_ok('ApacheLog::Compressor' => [
	on_write => sub {
		die "Should not be writing in expansion side";
	},
	on_log_line => sub {
		my ($self, $data) = @_;
		is($self->data_to_text($data), 'api.example.com 105327 123.15.16.108 - apiuser@example.com [19/Dec/2009:03:12:07 +0000] "POST /api/status.json HTTP/1.1" 200 80516 "-" "-"', 'converted line matches');
	}
]);
ok($comp->send_packet('server',
	hostname	=> 'apache-server1'
), 'send initial server packet');
is_hex($buffer, '01 61 70 61 63 68 65 2d 73 65 72 76 65 72 31 00', 'initial server packet is correct');
$exp->expand(\$buffer);
is($buffer, '', 'buffer now empty');
ok($comp->compress('api.example.com 105327 123.15.16.108 - apiuser@example.com [19/Dec/2009:03:12:07 +0000] "POST /api/status.json HTTP/1.1" 200 80516 "-" "-"'), 'compress a line');
my $copy = $buffer;
is_hex(substr($buffer, 0, 5, ''),  '02 4b 2c 44 87', 'timestamp packet is correct');
is_hex(substr($buffer, 0, 21, ''), '03 00 00 00 00 61 70 69 2e 65 78 61 6d 70 6c 65 2e 63 6f 6d 00', 'vhost packet is correct');
is_hex(substr($buffer, 0, 25, ''), '04 00 00 00 00 61 70 69 75 73 65 72 40 65 78 61 6d 70 6c 65 2e 63 6f 6d 00', 'user packet is correct');
is_hex(substr($buffer, 0, 22, ''), '07 00 00 00 00 2f 61 70 69 2f 73 74 61 74 75 73 2e 6a 73 6f 6e 00', 'URL packet is correct');
is_hex(substr($buffer, 0, 6, ''),  '0a 00 00 00 00 00', 'query packet is correct');
is_hex(substr($buffer, 0, 7, ''),  '06 00 00 00 00 2d 00', 'referer packet is correct');
is_hex(substr($buffer, 0, 7, ''),  '05 00 00 00 00 2d 00', 'useragent packet is correct');
is_hex(substr($buffer, 0, 33, ''), '00 00 00 00 01 9b 6f 7b 0f 10 6c 00 00 03 00 00 00 00 00 00 00 00 01 00 c8 00 01 3a 84 00 00 00 00', 'log packet is correct');
is(length($buffer), 0, 'buffer now empty');
my $idx = 0;
$exp->expand(\$copy) while length $copy && ++$idx < 100;

{
	my $bad_data = 'api.example.com 105327 123.15.16.108 - apiuser@example.com [19/Dec/2009:03:12:07 +0000] "SOME INVALID DATA HERE" 14124 1231 -';
	local $comp->{on_bad_data} = sub {
		my $data = shift;
		pass('have bad data event');
		is($data, $bad_data, 'data matches');
	};
	ok($comp->compress($bad_data), 'pass bad data into compressor');
}

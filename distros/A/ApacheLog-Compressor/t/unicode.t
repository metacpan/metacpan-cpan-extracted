use strict;
use warnings;
use utf8;

use Test::More tests => 7;
use ApacheLog::Compressor;
use Encode qw(is_utf8);
binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

my $buffer = '';
my $comp = new_ok('ApacheLog::Compressor' => [
	on_write	=> sub {
		my ($self, $pkt) = @_;
		$buffer .= $pkt;
	}
]);
my $exp = new_ok('ApacheLog::Compressor' => [
	on_write => sub {
		die "Should not be writing in expansion side";
	},
	on_log_line => sub {
		my ($self, $data) = @_;
		if(0) {
			is($self->data_to_text($data), 'example.com 28104 10.1.0.1 - user@example.com [11/Mar/2011:19:05:45 +0000] "GET /仕事関係.html HTTP/1.1" 200 - "Mozilla/4.0" "-"', 'converted line matches');
			is($self->from_cache('url', $data->{url}), '/仕事関係.html', 'actual URL value matches');
		} else {
			is($self->data_to_text($data), 'example.com 28104 10.1.0.1 - user@example.com [11/Mar/2011:19:05:45 +0000] "GET /%E4%BB%95%E4%BA%8B%E9%96%A2%E4%BF%82.html HTTP/1.1" 200 - "Mozilla/4.0" "-"', 'converted line matches');
			is($self->from_cache('url', $data->{url}), '/%E4%BB%95%E4%BA%8B%E9%96%A2%E4%BF%82.html', 'actual URL value matches');
		}
	}
]);
my $line = q(example.com 28104 10.1.0.1 - user@example.com [12/Mar/2011:02:05:45 +0700] "GET /%E4%BB%95%E4%BA%8B%E9%96%A2%E4%BF%82.html HTTP/1.1" 200 - "-" "Mozilla/4.0");

ok($comp->send_packet('server',
	hostname	=> 'apache-server1'
), 'send initial server packet');
ok($comp->compress($line), 'compress the line');

# Try to prove we have binary data
open my $out_fh, '>', \my $tmp or die $!;
binmode $out_fh;
print $out_fh $buffer;
close $out_fh;
$buffer = $tmp;
ok(!is_utf8($buffer), 'utf8 not set');
my $idx = 0;
$exp->expand(\$buffer) while length $buffer && ++$idx < 100;


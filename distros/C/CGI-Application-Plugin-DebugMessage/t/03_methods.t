use strict;
use warnings;
use Test::More tests => 6;

$ENV{CGI_APP_RETURN_ONLY} = 1;
my $ca;
my $output;

$ca = CGI::Application::Plugin::DebugMessage::Test->new;
$ca->run_modes('start' => 'do_start');

ok($ca->debug('test'), "add debug (string)");
ok($ca->debug([1, 2, 3]), "add debug (array)");
ok($output = $ca->run, "run");

$output =~ s/[\r\n]+//g;
$output =~ s/\s+/ /g;

my $messages = $1 if ($output =~ qr{<p>Debug Messages:<\/p><ol>(.*?)<\/ol>});
ok($messages, "debug messages");
like($messages, qr{<li>\[main\(\d+\)\] test<\/li>}, "debug message (string)");
like($messages, qr{<li>\[main\(\d+\)\] <pre>\$VAR\d+ = \[ 1, 2, 3 \];<\/pre><\/li>\E}, "debug message (array)");

package CGI::Application::Plugin::DebugMessage::Test;
use base qw(CGI::Application);
use CGI::Application::Plugin::DebugMessage;

sub do_start {
	my $self = shift;
	return $self->query->start_html . "\ntest html data\n" . $self->query->end_html;
}

1;

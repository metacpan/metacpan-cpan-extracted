package TestServer;

# A tiny forked HTTP server on the loopback interface, for tests that need a
# real socket on the other end.  Each route returns [status, \@headers, body],
# or a raw response string when the test needs bytes no well-behaved server
# would send.  Every request is answered on its own connection and closed.

use strict;
use warnings;

use IO::Socket::INET;

sub start
{
	my ($class, %routes) = @_;

	my $listener = IO::Socket::INET->new(
		LocalAddr => '127.0.0.1',
		LocalPort => 0,
		Listen    => 20,
		ReuseAddr => 1,
		Proto     => 'tcp',
	) or return;

	my $pid = fork();
	return unless defined $pid;

	if($pid == 0) {
		_serve($listener, \%routes);
		exit 0;
	}

	my $self = bless { pid => $pid, port => $listener->sockport }, $class;
	close $listener;

	return $self;
}

sub port { return $_[0]{port} }

sub url
{
	my ($self, $path) = @_;

	return "http://127.0.0.1:$self->{port}" . ($path // '/');
}

sub stop
{
	my ($self) = @_;

	if(my $pid = delete $self->{pid}) {
		kill 'KILL', $pid;
		waitpid $pid, 0;
	}

	return $self;
}

sub DESTROY { $_[0]->stop }

# The child: answer requests until killed.
sub _serve
{
	my ($listener, $routes) = @_;

	while(my $client = $listener->accept) {
		my $request = '';
		while($request !~ /\r\n\r\n/) {
			my $read = sysread($client, my $chunk, 4096);
			last unless $read;
			$request .= $chunk;
		}

		my ($method, $target) = $request =~ m{\A(\S+) (\S+) HTTP/};
		my ($path, $query) = split /\?/, $target // '/', 2;
		my $route = $routes->{$path} // $routes->{'*'};
		my $answer = ref $route eq 'CODE'
			? $route->({ method => $method, path => $path, query => $query // '', request => $request })
			: $route;

		print {$client} ref $answer ? _response(@{$answer}) : defined $answer ? $answer : _response(404, [], 'not found');
		close $client;
	}

	return;
}

sub _response
{
	my ($status, $headers, $body) = @_;

	$body //= '';

	return join("\r\n",
		"HTTP/1.1 $status X",
		@{ $headers || [] },
		'Content-Length: ' . length($body),
		'Connection: close',
		'',
		$body,
	);
}

1;

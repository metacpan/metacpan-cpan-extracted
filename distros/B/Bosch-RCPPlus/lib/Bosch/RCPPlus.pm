package Bosch::RCPPlus;

our $VERSION = '1.2';

=head1 NAME

Bosch::RCPPlus.pm -- Perl 5 implementation of the Bosch RCP+ remote procedure call.

=head1 SYNOPSIS

This package has been developed following Bosch guidelines on implemeting L<RCP+ over CGI|https://media.boschsecurity.com/fs/media/pb/media/partners_1/integration_tools_1/developer/rcpplus-over-cgi.pdf>.
Most command specification were taken from debugging the Web UI.

  # Create Bosch API client
  my $client = new Bosch::RCPPlus(
    host => $Host,
    username => $Username,
    password => $Password,
  );

  # Call a comman (see lib/Commands.pm for full command list)
  my $name = $client->cmd(Bosch::RCPPlus::Commands::name());

  # Check if command is actually an error
  if ($name->error) {
    print "name failed\n";
    return -1;
  }

  # Print command result
  print 'Name: ' . $name->result . "\n";

=cut

use strict;

use URI;
use HTTP::Request;
use LWP::UserAgent;
use Bosch::RCPPlus::Response;
use Bosch::RCPPlus::AuthError;

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my %args = @_;

	my $self = {
		ua => LWP::UserAgent->new(),
		protocol => $args{protocol} || 'http',
		host => $args{host} || 'localhost',
		username => $args{username},
		password => $args{password},
		path => $args{path} || '/rcp.xml',
	};

	bless ($self, $class);
	return $self;
}

sub uri
{
	my ($proto) = @_;
	return URI->new($proto->{path})->abs($proto->{protocol} . '://' . $proto->{host});
}

sub request
{
	my ($proto, %args) = @_;
	my @headers = ();

	push @headers, @{$args{headers}} if ($args{headers});

	my $uri = $proto->uri;
	$uri->query_form($args{query}) if ($args{query});

	my $request = HTTP::Request->new(
		$args{method} || 'GET',
		$uri,
		\@headers,
		$args{content}
	);

	return $proto->{ua}->request($request);
}

sub cmd
{
	my ($proto, %args) = @_;

	my $format = $args{format};
	delete $args{format};

	my $r = $proto->request(query => \%args);

	if ($r->code eq 401) {
		my $authenticate = $r->header('www-authenticate');

		if ($authenticate and $authenticate =~ /realm="([^"]+)"/i) {
			my $realm = $1;
			$proto->{ua}->credentials($proto->{host}, $realm, $proto->{username}, $proto->{password});
			$r = $proto->request(query => \%args);

			return new Bosch::RCPPlus::AuthError($r->content) if ($r->code eq 401);
		} else {
			return new Bosch::RCPPlus::AuthError($r->content);
		}
	}

	return new Bosch::RCPPlus::Response($r->content, \%args, $format);
}

1;

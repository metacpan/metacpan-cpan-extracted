package Bayonne::Server;

use 5.008004;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use LWP::UserAgent;
use XML::Simple;
use URI::Escape;

our @ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration       use Bayonne::Libexec ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '0.01';

sub new {
	my $invocant = shift;
	my ($class) = ref($invocant) || $invocant;
	my $self = {
		hostid => undef,
		userid => "server",
		secret => undef,
		@_,
	};
	$self->{_session} = LWP::UserAgent->new(env_proxy => 1, timeout => 30);
	return bless $self, $class;
};

sub xmlreply($$) {
	my ($self, $query) = @_;
	my $host = $self->{hostid};
	my $user = $self->{userid};
	my $secret = $self->{secret};
	my $session = $self->{_session};

	if(index($host, ":") < 1) {
		$host .= ":8055";};
	
	my $reply = undef;
	my $document = "http://" . $host . "/" . $query;
	my $request = new HTTP::Request 'GET', $document;
	if($secret) {
		$request->authorization_basic($user, $secret);};
	my $response = $session->request($request);
	my $parser = XML::Simple->new();

	if($response->is_success()) {
		$reply = $parser->XMLin($response->{_content});};
	return $reply;
};	

sub reload($) {
        my($self) = @_;
        my $reply = $self->xmlreply("reload.xml");

        if($reply) {
                return $reply->{results}->{result}->{value};};

        return "failure";
}

sub uptime($) {
        my($self) = @_;
        my $reply = $self->xmlreply("uptime.xml");

        if($reply) {
                return $reply->{results}->{result}->{value};};

        return undef;
}

sub status($) {
	my($self) = @_;
	my $reply = $self->xmlreply("status.xml");
	
	if($reply) {
		return $reply->{results}->{result}->{value};};

	return undef;
}

sub traffic($) {
        my($self) = @_;
        my $reply = $self->xmlreply("traffic.xml");
	my $result = undef;

        if($reply) {
                $result->{timestamp} =
                        $reply->{results}->{result}->{timestamp}->{value};
                $result->{active} =
                        $reply->{results}->{result}->{activeCalls}->{value};
                $result->{completed}->{incoming} =
                        $reply->{results}->{result}->{incomingComplete}->{value};
                $result->{completed}->{outgoing} =
                        $reply->{results}->{result}->{outgoingComplete}->{value};
                $result->{attempted}->{incoming} =
                        $reply->{results}->{result}->{incomingAttempts}->{value};
                $result->{attempted}->{outgoing} =
                        $reply->{results}->{result}->{outgoingAttempts}->{value};
	}
        return $result;
}

sub stop($$) {
	my($self,$sid) = @_;
	my $result = "failure";
	$sid = uri_escape($sid);
	my $reply = $self->xmlreply("stop.xml?session=$sid");
	
	if($reply) {
		$result = $reply->{results}->{result}->{value};};
	
	if($result) {
		return $result;};

	return "invalid";
}

sub session($$) {
	my($self,$sid) = @_;
	my $result = "failure";
	$sid = uri_escape($sid);
	my $reply = $self->xmlreply("status.xml?session=$sid");
	
	if($reply) {
		$result = $reply->{results}->{result}->{value};};
	
	if($result eq "success") {
		return "active";};
	
	if($result) {
		return $result;};

	return "invalid";
}

sub start($$$$$) {
	my($self, $target, $script, $caller, $display) = @_;
	my $query = "start.xml";

	if(length($caller) < 1) {
		$caller = "unknown";};

	if(length($display) < 1) {
		$display = $caller;};

	$query .= "?target=" . uri_escape($target);
	$query .= "&script=" . uri_escape($script);
	$query .= "&caller=" . uri_escape($caller);
	$query .= "&display=" . uri_escape($display);

	my $reply = $self->xmlreply($query);
	
	if($reply){
		return $reply->{results}->{result}->{value};};

	return undef;
}	
1;
__END__

=head1 NAME

Bayonne::Server - Perl extension for invoking Bayonne 2 webservices

=head1 SYNOPSOS

  use Bayonne::Server;
  $conn = new Bayonne::Server(hostid => "hostname:port", secret => "password");

=head1 DESCRIPTION

  This module is used to create an instance of the Bayonne::Server.  
  Each instance is used to connect to one running instance of Bayonne
  through it's integrated http based web service.  You can create
  multiple instances of this object, each connecting to a different
  server, if you so desire.  The default hostid to use is 
  "localhost:8055" if you are not connecting to a remote machine.  The
  methods can then be used to invoke specific webservice methods.

=head1 EXPORT

None by default.

=head1 SEE ALSO

Documentation for GNU Bayonne 2.  Support is available from the Bayonne 2
developers mailing list, bayonne-devel@gnu.org.

=head1 AUTHOR

David Sugar, E<lt>dyfet@gnutelephony.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by David Sugar, Tycho Softworks

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut




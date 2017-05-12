#!/usr/bin/perl
#
use IO::Socket;
use threads;
use Proc::Daemon;
use Sys::Syslog qw( :DEFAULT setlogsock);

use Data::Dumper;
use lib( "./" );
use ACL;

# Global config settings
my $TC = 1;
my $debug = 1;
my $port = 12345;
our $pidfile = "/var/run/postfix-policy-server.pid";
our %redirectmap;

# Param1: Client socket
# Param2: hash_ref
sub parse_postfix_input( $$ ) {
	my ($socket,$hashref) = @_;

	local $/ = "\r\n";
	while( my $line = <$socket> ){
		chomp( $line );
		$line =~ s/\r//g;
		$line =~ s/\n//g;

		return if $line =~ /^(\r|\n)*$/;
		#print "DEBUG: $line" if $debug;
		if( $line =~ /^(\w+?)=(.+)$/ ){
			$hashref->{$1} = $2;
		}
	}
}

sub convert_hashref_to_acl($){
	my( $hash_ref ) = @_;
	
	my @a;

	for( sort( keys %$hash_ref ) ) {
		my $str = "$_=\[$hash_ref->{$_}\]";
		push( @a, $str );
	}

	return( join( " ", @a ) );
}

sub process_client($){
	my ($socket) = @_;

	# Create some stuff
	my $accept_acl = ACL->new->generate_required( 'required.txt' )->parse_acl_from_file( { Filename => "acl.permit.txt" } );
	my $reject_acl = ACL->new->generate_required( 'required.txt' )->parse_acl_from_file( { Filename => "acl.reject.txt" } );

	ACCEPT: while( my $client = $socket->accept() ){
		my $hash_ref = {};
		parse_postfix_input( $client, $hash_ref );

		my $action = convert_hashref_to_acl( $hash_ref );

		print "Action: " . Dumper($action) . "\n";

		my ($rc,$regex,$comment) = $reject_acl->match( $action );
		print Dumper( $rc ) . Dumper( $regex ) . Dumper( $comment ) . "\n";

		if( $rc ){
			print $client "action=reject $comment\n\n";
			next ACCEPT;
			# Match
		}

		($rc,$regex,$comment) = $accept_acl->match( $action );
		print Dumper( $rc ) . Dumper( $regex ) . Dumper( $comment ) . "\n";
		if( $rc ){
			print $client "action=ok $comment\n\n";
			next ACCEPT;
			# Match
		}

		# Handle any redirects
		print $client "action=dunno\n\n";
	}
}

sub handle_sig_int
{
	unlink( $pidfile );
	exit(0);
}

#openlog('missed-spam-policy', '', 'mail');
#syslog('info', 'launching in daemon mode') if $ARGV[0] eq 'quiet-quick-start';
#Proc::Daemon::Init if $ARGV[0] eq 'quiet-quick-start';

# Attempt to parse in the redirect config

$SIG{INT} = \&handle_sig_int;

# Ignore client disconnects
$SIG{PIPE} = "IGNORE";

open PID, "+>", "$pidfile" or die("Cannot open $pidfile: $!\n");
print PID "$$";
close( PID );

my $server = IO::Socket::INET->new(
    LocalPort => $port,
    Type      => SOCK_STREAM,
    Reuse     => 1,
    Listen    => 10
  )
  or die
  "Couldn't be a tcp server on port $default_config->{serverport} : $@\n";

# Generate a number of listener threads
my @threads = ();
for( 1 .. $TC ){
	my $thread = threads->create( \&process_client, $server );
	push( @threads, $thread );
}

foreach my $thread ( @threads ){
	$thread->join();
}

unlink( $pidfile );
closelog;
exit( 0 );

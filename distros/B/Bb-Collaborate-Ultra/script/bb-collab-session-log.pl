use 5.10.1;
use warnings; use strict;
use Bb::Collaborate::Ultra;
use Bb::Collaborate::Ultra::Connection;
use Bb::Collaborate::Ultra::Session;
use Getopt::Long;
use Pod::Usage;

=head1 NAME

bb-collab-session-log - session log report for Blackboard Collaborate Ultra

=head1 SYNOPSIS

  bb-collab-session-log --host=URL --issuer=USER --secret=PASS [query-opts]

=head2 Authentication Options

 -h --host=<url>          # hostname or web address
 -u --issuer=<username>   # issuer/username
 -p --secret=<password>   # secret/password

=head2 Query Options

 --name=<session-name>    # filter by session name
 --session-id=<Id>        # filter by session ID
 --context-id=<Id>        # filter by context ID
 --user-id=<Id>           # filter by user ID (select only
                          # sessions attended by this user_/

=head2 Information

 -? --help                # print this help
 -v --version             # print version and exit
 --dump=yaml              # output created sessions as YAML
 --debug                  # enable debugging

=head1 DESCRIPTION

Creates meetings on an Elluminate I<Live!> Manager (ELM) server.

=head1 SEE ALSO

perldoc Bb::Collaborate::Ultra

https://metacpan.org/release/Bb-Collaborate-Ultra


=cut

my %opt;
my $ok = GetOptions(
    \%opt,
    'host|h=s',
    'issuer|username|u=s',
    'secret|password|p=s',
    'contextId|context-id=s',
    'sessionId|session-id=s',
    'userId|user-id=s',
    'name=s',
    'debug|d',
    'help|h|?',
    'version|v',
    );    

my $host = delete $opt{host};
my $issuer = delete $opt{issuer};
my $secret = delete $opt{secret};
my $debug = delete $opt{debug};
my $help = delete $opt{help};
my $version = delete $opt{version};

pod2usage(0) if $help;

if ($version) {
    print "Bb::Collaborate::Ultra v${Bb::Collaborate::Ultra::VERSION} (c) 2017\n";
    exit(0);
};

pod2usage(2)
    unless $ok && $host && $issuer && $secret;

my $connection =  Bb::Collaborate::Ultra::Connection->new({
    host => $host, issuer => $issuer, secret => $secret,
});

$connection->debug(1) if $debug;

my $context_id = "6812E6A3EA4072D1425FA583BF59C5CD";
my @sessions =  Bb::Collaborate::Ultra::Session->get($connection, \%opt);
for my $session (@sessions) {
    my @logs = $session->logs;
    if (@logs) {
	say "Session: ". $session->name;
    }
    for my $log (@logs) {
	say "\tOpened: " .(scalar localtime $log->opened);
	for my $attendee ($log->attendees) {
	    my $first_join;
	    my $elapsed = 0;
	    for my $attendance (@{$attendee->attendance}) {
		my $joined = $attendance->joined;
		$first_join = $joined
		    if !$first_join || $first_join > $joined;
		$elapsed += $attendance->left - $joined;
	    }
	    my $user_id = $attendee->externalUserId || $attendee->userId;
	    say sprintf("\tUser %s (%s) joined at %s, stayed %d minutes", $user_id, $attendee->displayName, (scalar localtime $first_join), $elapsed / 60);
	    if ($elapsed) {
	    }
	}
	say "\tClosed: " .(scalar localtime $log->closed);
    }
}

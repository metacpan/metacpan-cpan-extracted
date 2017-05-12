#!/usr/local/bin/perl

use lib qw(. .. t);
use Apache::ASP::CGI;
use T;

use strict;
use File::Basename qw(dirname basename);
#$SIG{__DIE__} = \&Carp::confess;
#$SIG{__WARN__} = \&Carp::cluck;
$SIG{__WARN__} = sub { };

$0 =~ /^(.*)$/;
$0 = $1;
chdir(dirname($0));
$0 = basename($0);

my $t = T->new();

my %config = (
	      'NoState' => 0,
	      'SessionTimeout' => 20,
	      'Debug' => 0,
	      'SessionCount' => 1,
	      'Global' => 'session_events',
	      'SessionQuery' => 1,
	      );

my $r = Apache::ASP::CGI->init($0);
map { $r->dir_config->set($_, $config{$_}) } keys %config;

my $ASP = Apache::ASP->new($r);
$ASP->Session->{MARK} = 1;
#print STDERR "HERE\n";
#sleep 5;
my @sessions = keys %{$ASP->Application};
#&session_count_ok($ASP, scalar(@sessions));

# cleanup old sessions
for my $session_id ( @sessions ) {
    next if ($session_id eq $ASP->Session->SessionID);
    my $Session = $ASP->Application->GetSession($session_id);
    $Session->Abandon;
}
$ASP->{Internal}{CleanupMaster} = undef;
$ASP->CleanupGroups('PURGE');
$ASP->{Internal}{SessionCount}  = 1;

&session_count_ok($ASP, 1);
$ASP->Session->Abandon;
&session_count_ok($ASP, 1);
$ASP->CleanupGroups('PURGE');
&session_count_ok($ASP, 0);
$ASP->DESTROY;

for(1..10) {
    $ASP = Apache::ASP->new($r);
    &session_count_ok($ASP, $_);
    $ASP->DESTROY;
}

$ASP = Apache::ASP->new($r);
&session_count_ok($ASP, 11);
$ASP->Session->Abandon;
$ASP->CleanupGroups('PURGE');
&session_count_ok($ASP, 10);
$ASP->DESTROY;

# Session_OnEnd test repeat on expired session
{
    my $abandon_session_id;
    $ASP = Apache::ASP->new($r);
    $ASP->Session->{WriteMark}++;
    $ASP->Session->Abandon();
    $abandon_session_id = $ASP->Session->SessionID;
#    print STDERR $ASP->Session->SessionID."\n";
    # do not PURGE cleanup here, let next script get initialized with old session id
    $ASP->DESTROY;

    local $ENV{QUERY_STRING} = 'session-id='.$abandon_session_id;
    $ASP = Apache::ASP->new($r);
    $t->eok($abandon_session_id ne $ASP->Session->SessionID, "abandoned session restored");
    $ASP->Session->Abandon();
#    print STDERR $ASP->Session->SessionID."\n";
    $ASP->CleanupGroups('PURGE');
    $ASP->DESTROY;

    $ASP = Apache::ASP->new($r);
    $t->eok($abandon_session_id ne $ASP->Session->SessionID, "abandoned session restored");
    $ASP->Session->Abandon();
#    print STDERR $ASP->Session->SessionID."\n";
    $ASP->CleanupGroups('PURGE');
    $ASP->DESTROY;
}

$t->done;

## helpers

sub session_count_ok {
    my($ASP, $count) = @_;
    $t->eok($ASP->Application->SessionCount == $count, 
	    "$count sessions should have been counted, found ".$ASP->Application->SessionCount);
}

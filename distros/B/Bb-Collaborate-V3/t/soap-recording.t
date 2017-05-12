#!perl -T
use warnings; use strict;
use Test::More tests => 8;
use Test::Fatal;

use lib '.';
use t::Bb::Collaborate::V3;

use Bb::Collaborate::V3;
use Bb::Collaborate::V3::Recording;
use Bb::Collaborate::V3::Recording::File;
use Bb::Collaborate::V3::Session;

SKIP: {

    my %result = t::Bb::Collaborate::V3->test_connection();
    my $auth = $result{auth};

    skip ($result{reason} || 'skipping live tests', 8)
	unless $auth;

    my $connection_class = $result{class};
    my $connection = $connection_class->connect(@$auth);
    Bb::Collaborate::V3->connection($connection);

    my $end_time = time();
    my $start_time = $end_time  -  60 * 60 * 24 * 7; # one week approx
    my $recordings;

    is( exception {
	$recordings = Bb::Collaborate::V3::Recording->list(filter => {startTime => $start_time.'000', endTime => $end_time.'000'})
	  } => undef,
	'list recordings - lives');

    die "unable to get recordings"
	unless $recordings;

    skip('Unable to find any existing recordings to test', 7)
	unless @$recordings;

    my $recording = $recordings->[-1];

    # this recording is not under our control, so don't assume too much
    # and just test a few essential properties

    ok($recording->recordingId, "recording has recordingId")
	or die "unable to continue without a recording id";
    note("working with recording: ".$recording->recordingId);

    ok($recording->recordingSize, "recording has recordingSize");

    my $recording_url;
    is (exception {$recording_url = $recording->recording_url} => undef,
	'$recording->recording_url - lives');
    ok($recording_url, "got recording_url");
    note("recording url is: $recording_url");

    TODO : {
	local $TODO = "params look OK, but error response. Server restriction?";
	my $recording_file;
	is exception {$recording_file = $recording->convert( format => 'mp3')} => undef, '$recording->convert - lives';
	isa_ok $recording_file, 'Bb::Collaborate::V3::Recording::File';
    }

    # try to find a session with associated recording(s)

    my ($session) = List::Util::first {$_->recordings} @{ Bb::Collaborate::V3::Session->list(filter => {startTime => $start_time.'000', endTime => $end_time.'000'}) };

    if ($session) {

	note "found session with recordings: ".$session->sessionId;

	my $session_recordings = $session->list_recordings;
	ok($session_recordings && $session_recordings->[0], '$session->list_recordings')
	    or diag("unable to find the purported recordings for session: ".$session->sessionId);
    }
    else {
	Test::More->builder->skip("unable to find a session with recordings");
    }
}

Bb::Collaborate::V3->disconnect;


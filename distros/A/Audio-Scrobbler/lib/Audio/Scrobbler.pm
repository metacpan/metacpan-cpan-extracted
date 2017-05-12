package Audio::Scrobbler;

use 5.006;
use strict;
use bytes;

=head1 NAME

Audio::Scrobbler - Perl interface to audioscrobbler.com/last.fm

=head1 SYNOPSIS

  use Audio::Scrobbler;

  $scrob = new Audio::Scrobbler(cfg => { ... });

  $scrob->handshake();
  $scrob->submit(artist => "foo", album => "hello", track => "world",
    length => 180);

=head1 DESCRIPTION

The C<Audio::Scrobbler> module provides a Perl interface to the track
submission API of Last.fm's AudioScrobbler -
http://www.audioscrobbler.com/.  So far, only track submissions are
handled; the future plans include access to the various statistics.

=cut

use Digest::MD5 qw/md5_hex/;
use LWP::UserAgent;

our @ISA = qw();

our $VERSION = '0.01';

sub err($ $);
sub handshake($);

sub get_ua($);

sub URLEncode($);
sub URLDecode($);

=head1 METHODS

The C<Audio::Scrobbler> class defines the following methods:

=over 4

=item * new ( cfg => { ... } )

Create a new C<Audio::Scrobbler> object and initialize it with
the provided configuration parameters.  The parameters themselves
are discussed in the description of the L<handshake> and L<submit>
methods below.

=cut

sub new
{
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $self = { };
	my %args = @_;

	if (exists($args{'cfg'}) && ref $args{'cfg'} eq 'HASH') {
		$self->{'cfg'} = $args{'cfg'};
	} else {
		$self->{'cfg'} = { };
	}
	$self->{'cfg'} = $args{'cfg'} || { };
	$self->{'ua'} = undef;
	$self->{'req'} = { };
	$self->{'err'} = undef;
	bless $self, $class;
	return $self;
}

=item * err (message)

Retrieves or sets the description of the last error encountered in
the operation of this C<Audio::Scrobbler> object.

=cut

sub err($ $)
{
	my ($self, $err) = @_;

	$self->{'err'} = $err if $err;
	return $self->{'err'};
}

=item * handshake ()

Perfors a handshake with the AudioScrobbler API via a request to
http://post.audioscrobbler.com/.

This method requires that the following configuration parameters be set:

=over 4

=item * progname

The name of the program (or plug-in) performing the AudioScrobbler handshake.

=item * progver

The version of the program (or plug-in).

=item * username

The username of the user's AudioScrobbler registration.

=back

If the handshake is successful, the method returns a true value, and
the L<submit> method may be invoked.  Otherwise, an appropriate error
message may be retrieved via the L<err> method.

If the B<fake> configuration parameter is set, the L<handshake> method
does not actually perform the handshake with the AudioScrobbler API,
just simulates a successful handshake and returns a true value.

If the B<verbose> configuration parameter is set, the L<handshake>
method reports its progress with diagnostic messages to the standard output.

=cut

sub handshake($)
{
	my ($self) = @_;
	my ($ua, $req, $resp, $c, $s);
	my (@lines);

	delete $self->{'nexturl'};
	delete $self->{'md5ch'};

	$ua = $self->get_ua() or return undef;
	$s = 'hs=true&p=1.1&c='.
	    URLEncode($self->{'cfg'}{'progname'}).'&v='.
	    URLEncode($self->{'cfg'}{'progver'}).'&u='.
	    URLEncode($self->{'cfg'}{'username'});
	print "RDBG about to send the handshake request: $s\n"
	    if $self->{'cfg'}{'verbose'};
	if ($self->{'cfg'}{'fake'}) {
		print "RDBG faking it...\n" if $self->{'cfg'}{'verbose'};
		$self->{'md5ch'} = 'furrfu';
		$self->{'nexturl'} = 'http://furrfu.furrblah/furrquux';
		return 1;
	}
	$req = new HTTP::Request('GET', "http://post.audioscrobbler.com/?$s");
	if (!$req) {
		$self->err('Could not create the handshake request object');
		return undef;
	}
	$resp = $ua->request($req);
	print "RDBG resp is $resp, success is ".$resp->is_success()."\n"
	    if $self->{'cfg'}{'verbose'};
	if (!$resp) {
		$self->err('Could not get a handshake response');
		return undef;
	} elsif (!$resp->is_success()) {
		$self->err('Could not complete the handshake: '.
		    $resp->status_line());
		return undef;
	}
	$c = $resp->content();
	print "RDBG resp content is:\n$c\nRDBG ====\n"
	    if $self->{'cfg'}{'verbose'};
	@lines = split /[\r\n]+/, $c;
	$_ = $lines[0];
SWITCH:
	{
		/^FAILED\s+(.*)/ && do {
			$self->err("Could not complete the handshake: $1");
			return undef;
		};
		/^BADUSER\b/ && do {
			$self->err('Could not complete the handshake: invalid username');
			return undef;
		};
		/^UPTODATE\b/ && do {
			$self->{'md5ch'} = $lines[1];
			$self->{'nexturl'} = $lines[2];
			last SWITCH;
		};
		/^UPDATE\s+(.*)/ && do {
			# See if we care. (FIXME)
			$self->{'md5ch'} = $lines[1];
			$self->{'nexturl'} = $lines[2];
			last SWITCH;
		};
		$self->err("Unrecognized handshake response: $_");
		return undef;
	}
	print "RDBG MD5 challenge '$self->{md5ch}', nexturl '$self->{nexturl}'\n"
	    if $self->{'cfg'}{'verbose'};
	return 1;
}

=item * submit ( info )

Submits a single track to the AudioScrobbler API.   This method may only
be invoked after a successful L<handshake>.  The track information is
contained in the hash referenced by the B<info> parameter; the following
elements are used:

=over 4

=item * title

The track's title.

=item * artist

The name of the artist performing the track.

=item * length

The duration of the track in seconds.

=item * album

The name of the album (optional).

=back

Also, the L<submit> method requires that the following configuration
parameters be set for this C<Audio::Scrobbler> object:

=over 4

=item * username

The username of the user's AudioScrobbler registration.

=item * password

The password for the AudioScrobbler registration.

=back

If the submission is successful, the method returns a true value.
Otherwise, an appropriate error message may be retrieved via the L<err>
method.

If the B<fake> configuration parameter is set, the L<submit> method
does not actually submit the track information to the AudioScrobbler API,
just simulates a successful submission and returns a true value.

If the B<verbose> configuration parameter is set, the L<submit>
method reports its progress with diagnostic messages to the standard output.

=cut

sub submit($ \%)
{
	my ($self, $info) = @_;
	my ($ua, $req, $resp, $s, $c, $datestr, $md5resp);
	my (@t, @lines);

	# A couple of sanity checks - those never hurt
	if (!defined($self->{'nexturl'}) || !defined($self->{'md5ch'})) {
		$self->err('Cannot submit without a successful handshake');
		return undef;
	}
	if (!defined($info->{'title'}) || !defined($info->{'album'}) ||
	    !defined($info->{'artist'}) || !defined($info->{'length'}) ||
	    $info->{'length'} !~ /^\d+$/) {
		$self->err('Missing or incorrect submission info fields');
		return undef;
	}

	# Init...
	@t = gmtime();
	$datestr = sprintf('%04d-%02d-%02d %02d:%02d:%02d',
	    $t[5] + 1900, $t[4] + 1, @t[3, 2, 1, 0]);
	# Let's hope md5_hex() always returns lowercase hex stuff
	$md5resp = md5_hex(
	    md5_hex($self->{'cfg'}{'password'}).$self->{'md5ch'});

	# Let's roll?
	$req = HTTP::Request->new('POST', $self->{'nexturl'});
	if (!$req) {
		$self->err('Could not create the submission request object');
		return undef;
	}
	$req->content_type('application/x-www-form-urlencoded; charset="UTF-8"');
	$s = 'u='.URLEncode($self->{'cfg'}{'username'}).
	    "&s=$md5resp&a[0]=".URLEncode($info->{'artist'}).
	    '&t[0]='.URLEncode($info->{'title'}).
	    '&b[0]='.URLEncode($info->{'album'}).
	    '&m[0]='.
	    '&l[0]='.$info->{'length'}.
	    '&i[0]='.URLEncode($datestr).
	    "\r\n";
	$req->content($s);
	print "RDBG about to send a submission request:\n".$req->content().
	    "\n===\n" if $self->{'cfg'}{'verbose'};
	if ($self->{'cfg'}{'fake'}) {
		print "RDBG faking it...\n" if $self->{'cfg'}{'verbose'};
		return 1;
	}

	$ua = $self->get_ua() or return undef;
	$resp = $ua->request($req);
	if (!$resp) {
		$self->err('Could not get a submission response object');
		return undef;
	} elsif (!$resp->is_success()) {
		$self->err('Could not complete the submission: '.
		    $resp->status_line());
		return undef;
	}
	$c = $resp->content();
	print "RDBG response:\n$c\n===\n" if $self->{'cfg'}{'verbose'};
	@lines = split /[\r\n]+/, $c;
	$_ = $lines[0];
SWITCH:
	{
		/^OK\b/ && last SWITCH;
		/^FAILED\s+(.*)/ && do {
			$self->err("Submission failed: $1");
			return undef;
		};
		/^BADUSER\b/ && do {
			$self->err('Incorrest username or password');
			return undef;
		};
		$self->err('Unrecognized submission response: '.$_);
		return undef;
	}
	print "RDBG submit() just fine and dandy!\n"
	    if $self->{'cfg'}{'verbose'};
	return 1;
}

=back

There are also several methods and functions for the module's internal
use:

=over 4

=item * get_ua ()

Creates or returns the cached C<LWP::UserAgent> object used by
the C<Audio::Scrobbler> class for access to the AudioScrobbler API.

=cut

sub get_ua($)
{
	my ($self) = @_;
	my ($ua);

	$self->{'ua'} ||= new LWP::UserAgent();
	if (!$self->{'ua'}) {
		$self->err('Could not create a LWP UserAgent object');
		return undef;
	}
	$self->{'ua'}->agent('scrobbler-helper/1.0pre1 '.
	    $self->{'ua'}->_agent());
	return $self->{'ua'};
}

=item * URLDecode (string)

Decode a URL-encoded string.

Obtained from http://glennf.com/writing/hexadecimal.url.encoding.html

=cut

sub URLDecode($) {
	my $theURL = $_[0];
	$theURL =~ tr/+/ /;
	$theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
	$theURL =~ s/<!--(.|\n)*-->//g;
	return $theURL;
}

=item * URLEncode (string)

Return the URL-encoded representation of a string.

Obtained from http://glennf.com/writing/hexadecimal.url.encoding.html

=cut

sub URLEncode($) {
	my $theURL = $_[0];
	$theURL =~ s/([^a-zA-Z0-9_])/'%' . uc(sprintf("%2.2x",ord($1)));/eg;
	return $theURL;
}

=back

=head1 TODO

=over 4

=item *

Do something with UPDATE responses to the handshake.

=item *

Honor INTERVAL in some way.

=item *

Figure out a way to cache unsuccesful submissions for later retrying.

=item *

Web services - stats!

=back

=head1 SEE ALSO

B<scrobbler-helper(1)>

=over 4

=item * http://www.last.fm/

=item * http://www.audioscrobbler.com/

=item * http://www.audioscrobbler.net/

=back

The home site of the C<Audio::Scrobbler> module is
http://devel.ringlet.net/audio/Audio-Scrobbler/

=head1 AUTHOR

Peter Pentchev, E<lt>roam@ringlet.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, 2006 by Peter Pentchev.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

$Id: Scrobbler.pm 88 2006-01-02 09:16:32Z roam $

=cut

1;

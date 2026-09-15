# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package App::FuguBench::Wiki;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use File::Spec ();
use POSIX      qw(strftime);

use Fugu::CLI qw(EXIT_SUCCESS EXIT_ERROR);
use Fugu::File;

# App::FuguBench::Wiki - the wiki verb.
#
# The verb operates the learning library: a git repository of flat
# pages, cloned below the home of wiki.origin. The subcommands are
# init, open, note, admit, close, status, and candidates. An unknown
# subcommand gives the usage error.
#
# The library is <home of wiki.origin>/<wiki.dir>. A clone under
# Projects/ holds a .toolingrc of its own without wiki.origin, so the
# walk for the key reaches the workspace, and the library of the
# workspace serves the clone (CLI-CONFIG-2).
#
# Every capture commits, and then pushes. The commit carries the
# durability, and the push carries the visibility. A failed push
# warns, and the commit stays for the next push.
#
# The race sits in open. Two sessions of one day take one page name
# when each one counts the pages of a stale clone. So open fetches
# the origin before it reads the pages of the clone, and it renames
# its page when the origin holds the name already (D-08).
#
# Git runs as a child with the clone as its working directory, and
# every message of git goes to standard error. Standard output
# carries the result line of the subcommand alone, because a hook
# reads it.

# The subcommands of the verb. An unknown word gives the usage error.
# note and admit share one body: they differ in the commit subject
# only, so the entry carries the subject word.
my %SUBCOMMAND = (
	init  => \&_init,
	open  => \&_open,
	note  => sub ( $app, @args ) { return _append( $app, 'note',  @args ) },
	admit => sub ( $app, @args ) { return _append( $app, 'admit', @args ) },
	close      => \&_close,
	status     => \&_status,
	candidates => \&_candidates,
);

# The shape of a page name (WIKI-PAGES-1, WIKI-CONFINE-1). Pages stay
# flat, so the name holds no slash. The leading letter refuses a name
# that starts with a dot, and the test of the caller refuses a parent
# segment.
my $PAGE = qr{\A[A-Za-z][A-Za-z0-9._-]*\z};

# The shape of a project token and a session token (WIKI-OPEN-5). The
# first character is a letter or a digit: a token that starts with a
# dash reaches git as an option.
my $TOKEN = qr{\A[A-Za-z0-9][A-Za-z0-9._-]*\z};

# The shape of the name of a session page (WIKI-PAGES-3). _page
# builds one name of that shape from a project token, a date, and an
# index, and this pattern reads one back.
my $SESSION =
qr{\ASession-[A-Za-z0-9][A-Za-z0-9._-]*-[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]+[.]md\z};

# The prefix that the prose lint skips. A page with it would never
# meet the prose gate (WIKI-PAGES-2).
use constant SCRATCHPAD => 'SCRATCHPAD';

# The tries of one push (WIKI-CAPTURE-5).
use constant TRIES => 3;

# The page that holds the rule candidates (WIKI-STATUS-2).
use constant CANDIDATES => 'Rule-candidates.md';

# The seconds of one day, for the age of one candidate.
use constant DAY => 86_400;

# App::FuguBench::Wiki->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'operate the learning library',
		usage   => 'init | open <project> <session>'
		    . ' | note <page> <file> | admit <page> <file>'
		    . ' | close <session> | status | candidates',
		run => sub ( $app, @argv ) { return run( $app, @argv ) },
	};
}

# run($app, $sub, @args):
#	Dispatch one subcommand, and return its exit code. The hook
#	verb calls it in process, so the dispatch takes the name as an
#	argument.
sub run ( $app, $sub = undef, @args )
{
	my $body = defined $sub ? $SUBCOMMAND{$sub} : undef;
	return $app->cli->command_usage_error('wiki') unless $body;

	return $body->( $app, @args );
}

# _library($app):
#	The exit code, the library directory, and the origin URL, in
#	that order. The code is EXIT_SUCCESS when the checkout answers,
#	and the method reports every failure itself.
#
#	The directory is undef when no .toolingrc of the walk holds
#	wiki.origin. That key has no default, so it has no home, and
#	the library has no path. init stops with a configuration error,
#	and every other subcommand reports an absent clone.
#
#	The home of wiki.origin anchors the directory (CLI-CONFIG-2). A
#	clone under Projects/ is a checkout of its own, and its root
#	holds no library.
#
#	The directory must sit below that home, so a wiki.dir of . is
#	a configuration error (CLI-CONFIG-3).
sub _library ($app)
{
	my $checkout = $app->checkout
	    or return Fugu::CLI::EXIT_CONFIG_ERROR();

	my ( $origin, $home ) = $checkout->config('wiki.origin');
	return EXIT_SUCCESS unless defined $origin;

	my $log = $app->cli->log;
	unless ( defined $checkout->url_value($origin) ) {
		$log->error( 'wiki.origin: %s', $checkout->error );
		return Fugu::CLI::EXIT_CONFIG_ERROR();
	}

	my ($value) = $checkout->config('wiki.dir');
	my $name = $checkout->dir_value($value);
	unless ( defined $name ) {
		$log->error( 'wiki.dir: %s', $checkout->error );
		return Fugu::CLI::EXIT_CONFIG_ERROR();
	}

	# A value of . resolves to the home itself, and that home is a
	# checkout. A checkout holds a .git, so _have would take it for
	# the library: open would write a session page into the
	# checkout, and the push would carry it to the origin of the
	# checkout. The method refuses that value (CLI-CONFIG-3).
	my $dir = File::Spec->catdir( $home, $name );
	if ( $dir eq $home ) {
		$log->error( 'wiki.dir: the directory is the checkout: %s',
			$name );
		return Fugu::CLI::EXIT_CONFIG_ERROR();
	}

	return ( EXIT_SUCCESS, $dir, $origin );
}

# _have($app, $dir):
#	True when the library answers a subcommand that needs it
#	(WIKI-CLONE-3). An absent key and an absent clone both report
#	on standard error and give false. The subcommand then exits
#	zero with no result line, so no hook stops a session.
sub _have ( $app, $dir )
{
	my $log = $app->cli->log;
	unless ( defined $dir ) {
		$log->notice('no library, wiki.origin is unset');
		return 0;
	}
	return 1 if -d $dir && -e "$dir/.git";

	$log->notice( 'no library at %s', $dir );

	return 0;
}

# _init($app, @argv):
#	Clone the library when it is absent, and write its directory
#	to standard output (WIKI-CLONE-1). A second run reports the
#	directory on standard error and changes nothing.
#
#	init is the one subcommand that needs wiki.origin, so an absent
#	key stops it with a configuration error that names the key
#	(CLI-CONFIG-2).
#
#	A failed clone warns and exits zero (WIKI-CLONE-2). The
#	repository can be absent, and a checkout without network access
#	is normal, so the session that follows must still start.
sub _init ( $app, @argv )
{
	return $app->cli->command_usage_error('wiki') if @argv;

	my ( $code, $dir, $origin ) = _library($app);
	return $code if $code != EXIT_SUCCESS;

	my $log = $app->cli->log;
	unless ( defined $dir ) {
		$log->error('wiki.origin is unset, and init needs the URL');
		return Fugu::CLI::EXIT_CONFIG_ERROR();
	}
	if ( -d $dir ) {
		$log->notice( 'already exists, nothing to do: %s', $dir );
		return EXIT_SUCCESS;
	}

	# git removes the directory that a failed clone made, so a
	# warning is the whole answer here.
	unless (
		defined $app->command(
			[ 'git', 'clone', '--quiet', $origin, $dir ] ) )
	{
		$log->warning( 'cannot clone %s, the library stays absent: %s',
			$origin, $app->error );
		return EXIT_SUCCESS;
	}

	say $dir;

	return EXIT_SUCCESS;
}

# _open($app, @argv):
#	Start the session page, commit it, push it, and write the page
#	name to standard output as the only line (WIKI-OPEN-4).
#
#	A page that holds the session identifier already ends the
#	subcommand: it writes that page and changes nothing
#	(WIKI-OPEN-1). The identifier lives in the page and never in
#	the name, so open stays idempotent across a resume and a
#	compact (WIKI-PAGES-4).
#
#	The fetch comes before that search and before the count
#	(WIKI-OPEN-2). The search reads the working tree, and then the
#	fetched branch. A clone that holds a commit of its own takes no
#	fast-forward, so its working tree can hide the page of the
#	session, and open would then give that session a second page.
#	A page of the fetched branch alone reaches the working tree,
#	because note and close read that tree. The rename settles a
#	name that the origin took first (WIKI-OPEN-3).
sub _open ( $app, @argv )
{
	return $app->cli->command_usage_error('wiki') if @argv != 2;
	my ( $project, $session ) = @argv;

	return $app->cli->command_usage_error('wiki')
	    unless _token( $app, 'project', $project )
	    && _token( $app, 'session', $session );

	my ( $code, $dir ) = _library($app);
	return $code if $code != EXIT_SUCCESS;
	return EXIT_SUCCESS unless _have( $app, $dir );

	my $branch = _branch( $app, $dir );
	_fetch( $app, $dir, $branch ) if defined $branch;

	my $log   = $app->cli->log;
	my $found = _page_of_session( $dir, $session )
	    // _resume( $app, $dir, $branch, $session );
	if ($found) {
		$log->notice( 'already open: %s', $found );
		say $found;
		return EXIT_SUCCESS;
	}

	my $date  = strftime( '%Y-%m-%d', gmtime );
	my %taken = map { $_ => 1 } _origin_pages( $app, $dir, $branch );
	my $n     = _free( $dir, \%taken, $project, $date );
	my $page  = _page( $project, $date, $n );

	# The tokens pass their own check, so the name above is flat by
	# construction. The check runs on it because the name reaches
	# the filesystem and git (CLI-PROGRAM-6).
	my $path = _page_path( $app, $dir, $page )
	    or return $app->cli->command_usage_error('wiki');

	my $title = _title( $project, $date, $n );
	my $now   = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime );
	my $text  = <<"PAGE";
$title

Session: $session
Project: $project
Opened: $now

## Observations
PAGE

	unless ( Fugu::File->write( $path, $text ) ) {
		$log->error( 'cannot write %s', $path );
		return EXIT_ERROR;
	}

	# The rename of WIKI-OPEN-3. A rejected push fetches the
	# branch, and the fetched branch can hold the page of the
	# commit. A rebase of that commit stops on an add/add conflict,
	# so the page takes the next free index first, and the commit
	# carries the new name and the new title.
	#
	# The closure answers 1 after a rename, 0 when the branch holds
	# no page of that name, and undef after a failure. The new name
	# reaches the result line, and a failed rename stops the
	# subcommand.
	my $rename = sub ($pages) {
		return 0 unless $pages->{$page};

		my $index = _free( $dir, $pages, $project, $date );
		my $name  = _move(
			$app, $dir, $page,
			_page( $project, $date, $index ),
			_title( $project, $date, $index ) );
		return unless defined $name;
		$page = $name;

		return 1;
	};

	$code = _save( $app, $dir, $page, "open: $page", $rename );
	return $code if $code != EXIT_SUCCESS;

	say $page;

	return EXIT_SUCCESS;
}

# _append($app, $subject, @argv):
#	Append the text of one file to one page, commit it, push it,
#	and write the page name to standard output (WIKI-CAPTURE-1).
#	note and admit share this body. They differ in the word of the
#	commit subject only, and the caller gives that word.
#
#	An empty file is an error, because a capture with no text
#	carries nothing. An absent page and an absent file are errors
#	of the same kind: the caller names a thing that is not there.
sub _append ( $app, $subject, @argv )
{
	return $app->cli->command_usage_error('wiki') if @argv != 2;
	my ( $page, $file ) = @argv;

	my ( $code, $dir ) = _library($app);
	return $code if $code != EXIT_SUCCESS;
	return EXIT_SUCCESS unless _have( $app, $dir );

	# The name reaches the filesystem and git, so it passes the
	# shape check before the path forms (CLI-PROGRAM-6).
	my $path = _page_path( $app, $dir, $page )
	    or return $app->cli->command_usage_error('wiki');

	my $log = $app->cli->log;
	unless ( -f $path ) {
		$log->error( 'no such page: %s', $page );
		return EXIT_ERROR;
	}
	unless ( -f $file ) {
		$log->error( 'no such file: %s', $file );
		return EXIT_ERROR;
	}

	my $text = Fugu::File->read($file);
	unless ( defined $text && $text =~ /\S/ ) {
		$log->error( 'no text in %s', $file );
		return EXIT_ERROR;
	}
	$text .= "\n" unless $text =~ /\n\z/;

	return EXIT_ERROR unless _add( $app, $path, $text );

	# The caller can leave the .md suffix out, and git needs the
	# name of the file. The path carries that name.
	my $name = ( File::Spec->splitpath($path) )[2];

	$code = _save( $app, $dir, $name, "$subject: $name" );
	return $code if $code != EXIT_SUCCESS;

	say $name;

	return EXIT_SUCCESS;
}

# _close($app, @argv):
#	Append the Closed: line to the page of one session, commit it,
#	push it, and write the page name to standard output
#	(WIKI-CAPTURE-2, WIKI-PAGES-3).
#
#	close carries no durability of its own: every observation
#	reached a commit through note. So a page that holds the line
#	already, and a session that has no page, both report on
#	standard error and write no result line. A session that runs no
#	campaign opens no page, and that is normal.
sub _close ( $app, @argv )
{
	return $app->cli->command_usage_error('wiki') if @argv != 1;
	my ($session) = @argv;

	return $app->cli->command_usage_error('wiki')
	    unless _token( $app, 'session', $session );

	my ( $code, $dir ) = _library($app);
	return $code if $code != EXIT_SUCCESS;
	return EXIT_SUCCESS unless _have( $app, $dir );

	my $log  = $app->cli->log;
	my $page = _page_of_session( $dir, $session );
	unless ($page) {
		$log->notice('no page for this session, nothing to do');
		return EXIT_SUCCESS;
	}

	my $path = "$dir/$page";
	if ( ( Fugu::File->read($path) // q{} ) =~ /^Closed:/m ) {
		$log->notice( 'already closed: %s', $page );
		return EXIT_SUCCESS;
	}

	my $now = strftime( '%Y-%m-%dT%H:%M:%SZ', gmtime );
	return EXIT_ERROR unless _add( $app, $path, "Closed: $now\n" );

	$code = _save( $app, $dir, $page, "close: $page" );
	return $code if $code != EXIT_SUCCESS;

	say $page;

	return EXIT_SUCCESS;
}

# _status($app, @argv):
#	Report each open session with its page, its Claim: count, and
#	its Admitted: count, and then the count of unpushed commits
#	(WIKI-STATUS-1).
#
#	A page with no text under ## Observations is no open session.
#	A hook opens a page for every session, and most sessions
#	capture nothing.
#
#	The consolidator writes one Admitted: line for each claim that
#	it moves into a library page. The difference is the work that
#	the library still waits for.
sub _status ( $app, @argv )
{
	return $app->cli->command_usage_error('wiki') if @argv;

	my ( $code, $dir ) = _library($app);
	return $code if $code != EXIT_SUCCESS;
	return EXIT_SUCCESS unless _have( $app, $dir );

	my @open;
	for my $page ( _session_pages($dir) ) {
		my $text = Fugu::File->read("$dir/$page") // q{};
		next if $text =~ /^Closed:/m;

		my $body = __PACKAGE__->observations($text);
		next unless defined $body && $body =~ /\S/;

		my $claims   = () = $body =~ /^Claim:/mg;
		my $admitted = () = $body =~ /^Admitted:/mg;
		push @open,
		    sprintf( '%-44s %d claim(s), %d admitted',
			$page, $claims, $admitted );
	}

	if (@open) {
		say 'open sessions:';
		say "  $_" for @open;
	}
	else {
		say 'open sessions: none';
	}

	# A count that git does not give is unknown, and the report
	# still ends with its last line.
	my $unpushed = _capture( $app, $dir, 'rev-list', '--count', 'HEAD',
		'--not', '--remotes' );
	$unpushed = 'unknown'
	    unless defined $unpushed && $unpushed =~ /\A[0-9]+\z/;
	say "unpushed commits: $unpushed";

	return EXIT_SUCCESS;
}

# _candidates($app, @argv):
#	Report each undelivered rule candidate with its age in days
#	and its date (WIKI-STATUS-2).
#
#	The subcommand runs inside make check, so an absent clone and
#	an absent page both report on standard error and exit zero
#	(WIKI-STATUS-3). A checkout without a library then passes the
#	gate.
sub _candidates ( $app, @argv )
{
	return $app->cli->command_usage_error('wiki') if @argv;

	my ( $code, $dir ) = _library($app);
	return $code if $code != EXIT_SUCCESS;
	return EXIT_SUCCESS unless _have( $app, $dir );

	my $log  = $app->cli->log;
	my $path = "$dir/" . CANDIDATES;
	unless ( -f $path ) {
		$log->notice( 'no %s, nothing to report', CANDIDATES );
		return EXIT_SUCCESS;
	}

	my $now   = time;
	my $found = 0;
	for my $item ( _items( Fugu::File->read($path) // q{} ) ) {
		next if index( $item->{text}, 'Delivered:' ) >= 0;

		my $age = int( ( $now - _epoch( $item->{date} ) ) / DAY );
		printf "%4d d  %s  %s\n", $age, $item->{date}, $item->{text};
		$found++;
	}
	say 'no undelivered candidate' unless $found;

	return EXIT_SUCCESS;
}

# _items($text):
#	Each candidate of the page, as a hash with a date and a text
#	(WIKI-STATUS-2). A candidate is a list item that starts with a
#	date, and the item takes its continuation lines.
#
#	The prose gate reflows the page, so Delivered: often sits on a
#	continuation line. The join brings the whole item into one
#	string, or the report holds a delivered candidate forever.
sub _items ($text)
{
	my @items;
	for my $line ( split /\n/, $text ) {
		if ( $line =~ /\A-\s+([0-9]{4}-[0-9]{2}-[0-9]{2})\s+(.*)\z/ ) {
			push @items, { date => $1, text => $2 };
		}
		elsif ( @items && $line =~ /\A\s+(\S.*)\z/ ) {
			$items[-1]{text} .= " $1";
		}
	}

	return @items;
}

# _epoch($date):
#	The epoch second of one UTC date, by the civil algorithm of
#	Howard Hinnant. It needs no module and no local time zone, so
#	the age of a candidate is the same in every zone.
sub _epoch ($date)
{
	my ( $y, $m, $d ) = split /-/, $date;

	my $year = $y - ( $m <= 2 ? 1 : 0 );
	my $era  = int( ( $year >= 0 ? $year : $year - 399 ) / 400 );
	my $yoe  = $year - $era * 400;
	my $doy =
	    int( ( 153 * ( $m + ( $m > 2 ? -3 : 9 ) ) + 2 ) / 5 ) + $d - 1;
	my $doe = $yoe * 365 + int( $yoe / 4 ) - int( $yoe / 100 ) + $doy;

	return ( $era * 146_097 + $doe - 719_468 ) * DAY;
}

# _token($app, $what, $value):
#	True when one token holds the shape of WIKI-OPEN-5. A token
#	that fails gives a message that names it, and the caller then
#	returns the usage error.
sub _token ( $app, $what, $value )
{
	return 1 if $value =~ $TOKEN;

	$app->cli->log->error( 'invalid %s: %s', $what, $value );

	return 0;
}

# _page_path($app, $dir, $page):
#	The path of one page inside the clone, or undef with a message
#	(WIKI-CONFINE-1). The name takes the .md suffix or leaves it
#	out (WIKI-PAGES-1).
sub _page_path ( $app, $dir, $page )
{
	my $log  = $app->cli->log;
	my $name = $page =~ s/[.]md\z//r;
	unless ( $name =~ $PAGE && $name !~ m{[.][.]} ) {
		$log->error( 'invalid page name: %s', $page );
		return;
	}
	if ( rindex( $name, SCRATCHPAD, 0 ) == 0 ) {
		$log->error( 'a page name must not start with %s: %s',
			SCRATCHPAD, $page );
		return;
	}

	return "$dir/$name.md";
}

# App::FuguBench::Wiki->session_page($name):
#	True when one name is the name of a session page
#	(WIKI-PAGES-3). _page builds that name, and the doctor reads
#	the shape here, so the two verbs never disagree.
sub session_page ( $, $name )
{
	return $name =~ $SESSION ? 1 : 0;
}

# App::FuguBench::Wiki->observations($text):
#	The text under the ## Observations heading of one page, or
#	undef when the page holds no such heading (WIKI-PAGES-3).
#
#	The Closed: line is no observation. close appends that line at
#	the end of the page, and the heading is the last one of the
#	template, so the line lands under it (WIKI-CAPTURE-2).
#
#	The status subcommand and the doctor verb read the body of a
#	page here, so the two never disagree.
sub observations ( $, $text )
{
	my ($body) = $text =~ /^[#][#] Observations$(.*)\z/ms;
	return unless defined $body;

	return $body =~ s/^Closed:[^\n]*\n?//mgr;
}

# _page($project, $date, $n):
#	The name of one session page (WIKI-PAGES-3).
sub _page ( $project, $date, $n )
{
	return "Session-$project-$date-$n.md";
}

# _title($project, $date, $n):
#	The title line of one session page (WIKI-PAGES-3). The name
#	and the title carry one index, so the rename writes this line
#	again.
sub _title ( $project, $date, $n )
{
	return "# Session $project $date $n";
}

# _free($dir, $taken, $project, $date):
#	The first free index of the day. The count takes the pages of
#	the working tree and the pages of the fetched branch together
#	(WIKI-OPEN-2). A stale clone alone gave two sessions one name.
sub _free ( $dir, $taken, $project, $date )
{
	my $n = 1;
	while (1) {
		my $name = _page( $project, $date, $n );
		last unless -e "$dir/$name" || $taken->{$name};
		$n++;
	}

	return $n;
}

# _session_pages($dir):
#	Each session page of the clone, in sorted order. A directory
#	that no read reaches gives the empty list.
sub _session_pages ($dir)
{
	opendir my $dh, $dir or return ();
	my @pages = sort grep { /\ASession-.*[.]md\z/ } readdir $dh;
	closedir $dh;

	return @pages;
}

# _page_of_session($dir, $session):
#	The page of the working tree that records one session, or
#	undef. open and close both read this one lookup, because
#	_resume brings the page of the fetched branch into the working
#	tree.
sub _page_of_session ( $dir, $session )
{
	for my $page ( _session_pages($dir) ) {
		my $text = Fugu::File->read("$dir/$page") // q{};
		return $page if $text =~ /^Session: \Q$session\E$/m;
	}

	return;
}

# _add($app, $path, $text):
#	Append the text to one page, after one blank line
#	(WIKI-CAPTURE-1). The method returns 0 after a failure, and it
#	reports that failure itself.
#
#	Every page that this verb writes ends with a newline, so one
#	newline in front of the text gives the blank line. The read
#	and the write take the whole page, because a page holds a few
#	thousand bytes.
sub _add ( $app, $path, $text )
{
	my $old = Fugu::File->read($path);
	return 1 if defined $old && Fugu::File->write( $path, "$old\n$text" );

	$app->cli->log->error( 'cannot append to %s', $path );

	return 0;
}

# _branch($app, $dir):
#	The branch that the clone has checked out, or undef. A
#	detached HEAD gives undef, and the verb then fetches nothing
#	and pushes nothing (WIKI-CAPTURE-6).
sub _branch ( $app, $dir )
{
	my $branch = _capture( $app, $dir, 'branch', '--show-current' );
	return unless defined $branch && length $branch;

	return $branch;
}

# _fetch($app, $dir, $branch):
#	Fetch the branch of the origin, and fast-forward a local
#	branch that holds no commit of its own (WIKI-OPEN-2).
#
#	The fast-forward moves a clone that a session left behind, so
#	its next push is a fast-forward and needs no retry. A branch
#	with a commit of its own stays, and the push loop rebases it.
#
#	A failed fetch warns. The count and the search then read the
#	ref of the last fetch, and a checkout without network access
#	is normal.
sub _fetch ( $app, $dir, $branch )
{
	unless (
		defined _git( $app, $dir, 'fetch', '--quiet', 'origin',
			$branch ) )
	{
		$app->cli->log->warning(
			'cannot fetch origin/%s, the count can be stale',
			$branch );
		return 0;
	}

	my $own =
	    _capture( $app, $dir, 'rev-list', '--count',
		"origin/$branch..HEAD" );
	_git( $app, $dir, 'merge', '--quiet', '--ff-only', "origin/$branch" )
	    if defined $own && $own eq '0';

	return 1;
}

# _origin_pages($app, $dir, $branch):
#	Each page of the fetched branch. The list is empty when no
#	fetch reached the origin, and the count is then local.
sub _origin_pages ( $app, $dir, $branch )
{
	return () unless defined $branch;

	my $out =
	    _capture( $app, $dir, 'ls-tree', '--name-only', "origin/$branch" );
	return () unless defined $out;

	return grep { /[.]md\z/ } split /\n/, $out;
}

# _origin_page_of_session($app, $dir, $branch, $session):
#	The page of the fetched branch that records one session, or
#	undef (WIKI-OPEN-1). An undefined branch gives undef, and a
#	branch without that page gives undef. A failed fetch leaves the
#	ref of the last fetch, and the search then reads it.
#
#	A clone that holds a commit of its own takes no fast-forward,
#	so its working tree can miss the page that the origin holds,
#	and open would give that session a second page (D-08). One git
#	grep reads the branch, because the library holds a page of
#	every session of every day. Of every call that this verb
#	parses, git colors the output of grep alone, so it carries
#	--no-color.
sub _origin_page_of_session ( $app, $dir, $branch, $session )
{
	return unless defined $branch;

	# The token holds letters, digits, a dot, a dash, and an
	# underscore (WIKI-OPEN-5). The dot is the one character that
	# the pattern of git reads, so the escape takes it alone.
	my $pattern = '^Session: ' . ( $session =~ s/[.]/\\./gr ) . '$';
	my $out     = _capture(
		$app,             $dir,
		'grep',           '--no-color',
		'--name-only',    '--extended-regexp',
		'-e',             $pattern,
		"origin/$branch", '--',
		'Session-*.md'
	);
	return unless defined $out && length $out;

	# One line of the output is <ref>:<page>, and the first match
	# answers.
	my $prefix = "origin/$branch:";
	my ($line) = split /\n/, $out;
	return unless rindex( $line, $prefix, 0 ) == 0;

	return substr $line, length $prefix;
}

# _resume($app, $dir, $branch, $session):
#	The page of the fetched branch that records one session,
#	brought into the working tree, or undef (WIKI-OPEN-2).
#
#	A clone that holds a commit of its own takes no fast-forward,
#	so the checkout gives it that page. note reads the file, and
#	close reads the Session: line of the file. A page of the
#	fetched branch alone serves neither one (WIKI-CAPTURE-1,
#	WIKI-CAPTURE-2).
#
#	The name comes from the tree of the origin, so it passes the
#	shape check before it reaches the filesystem and git
#	(CLI-PROGRAM-6). An invalid name and a failed checkout each
#	give undef, and open then opens a page.
sub _resume ( $app, $dir, $branch, $session )
{
	my $page = _origin_page_of_session( $app, $dir, $branch, $session )
	    or return;
	_page_path( $app, $dir, $page ) or return;

	unless (
		defined _git( $app, $dir, 'checkout', "origin/$branch", '--',
			$page ) )
	{
		$app->cli->log->error( 'cannot check out %s: %s',
			$page, $app->error );
		return;
	}

	return $page;
}

# _move($app, $dir, $page, $next, $title):
#	Rename the page of the commit, write the title of the new
#	index into it, and amend the commit with the new name
#	(WIKI-OPEN-3). The name and the title carry one index, so a
#	page of the old title would contradict its own name
#	(WIKI-PAGES-3).
#
#	The new name, or undef after a failure. The caller then reports
#	a failure of the subcommand. A failed rename changes nothing. A
#	failed title, a failed stage, and a failed amend each leave the
#	file and the commit apart, and no repair runs here.
sub _move ( $app, $dir, $page, $next, $title )
{
	my $log = $app->cli->log;
	unless ( rename "$dir/$page", "$dir/$next" ) {
		$log->error( 'cannot rename %s to %s: %s', $page, $next, $! );
		return;
	}
	$log->notice( 'the origin holds %s, renaming to %s', $page, $next );

	# The first line of every page of this verb is the title.
	my $text = Fugu::File->read("$dir/$next");
	unless ( defined $text
		&& Fugu::File->write( "$dir/$next",
			$text =~ s/\A[^\n]*/$title/r ) )
	{
		$log->error( 'cannot write the title of %s', $next );
		return;
	}

	# The pathspec covers the removal of the old name and the
	# addition of the new one.
	unless ( defined _git( $app, $dir, 'add', '-A', '--', $page, $next ) ) {
		$log->error( 'cannot stage the rename: %s', $app->error );
		return;
	}
	unless (
		defined _git(
			$app,      $dir, 'commit', '--quiet',
			'--amend', '-m', "open: $next"
		) )
	{
		$log->error( 'cannot amend the commit: %s', $app->error );
		return;
	}

	return $next;
}

# _save($app, $dir, $page, $subject, $rename):
#	Stage one page, commit it, and push it. The commit carries the
#	durability, so a failed commit gives the failure code. The push
#	carries the visibility, so a failed push warns alone
#	(WIKI-CAPTURE-4).
#
#	A failed rename is no failed push. It can leave the file and the
#	commit apart, so this method gives the failure code
#	(WIKI-OPEN-3).
#
#	Every commit of the verb carries a change (WIKI-CAPTURE-3).
#	The subcommand stops before this method when it has nothing to
#	add, so the index of each commit here holds the page.
sub _save ( $app, $dir, $page, $subject, $rename = undef )
{
	my $log = $app->cli->log;
	unless ( defined _git( $app, $dir, 'add', '--', $page ) ) {
		$log->error( 'cannot stage %s: %s', $page, $app->error );
		return EXIT_ERROR;
	}

	unless (
		defined _git( $app, $dir, 'commit', '--quiet', '-m', $subject )
	    )
	{
		$log->error( 'cannot commit %s: %s', $page, $app->error );
		return EXIT_ERROR;
	}

	return EXIT_ERROR unless defined _push( $app, $dir, $rename );

	return EXIT_SUCCESS;
}

# _push($app, $dir, $rename):
#	Push the branch, and settle a lost race (WIKI-CAPTURE-5). Two
#	checkouts push to one origin, so the loser meets a rejection.
#	The loop pushes three times at most, and it fetches, renames,
#	and rebases before each retry. The last try leaves no retry, so
#	the loop ends after it. No git call carries --force, because a
#	ruleset of the library forbids a forced push.
#
#	The method answers 1 after a push, and undef after a failed
#	rename. It answers 0 after a failed push, and after a detached
#	HEAD that pushes nothing (WIKI-CAPTURE-6).
#
#	The rename takes the pages of the fetched branch. It answers 0
#	when that branch holds no page of the commit, and undef after a
#	failure. A failed rename leaves a clone that no rebase settles,
#	so the method stops there and the caller gives the failure
#	code.
#
#	After the last try the commit stays local, and the next push
#	takes it.
sub _push ( $app, $dir, $rename = undef )
{
	my $log    = $app->cli->log;
	my $branch = _branch( $app, $dir );
	unless ( defined $branch ) {
		$log->warning('detached HEAD, not pushing');
		return 0;
	}

	for my $try ( 1 .. TRIES ) {
		return 1
		    if defined _git( $app, $dir, 'push', '--quiet', 'origin',
			$branch );
		last if $try == TRIES;

		$log->notice( 'push rejected, rebasing and retrying (%d of %d)',
			$try, TRIES );
		last
		    unless defined _git( $app, $dir, 'fetch', '--quiet',
			'origin', $branch );

		# The rename comes before the rebase: a rebase of two
		# pages of one name stops on an add/add conflict.
		if ($rename) {
			my %pages = map { $_ => 1 }
			    _origin_pages( $app, $dir, $branch );
			return unless defined $rename->( \%pages );
		}

		last unless _rebase( $app, $dir, $branch );
	}
	$log->warning('push failed, the commit stays local');

	return 0;
}

# _rebase($app, $dir, $branch):
#	Rebase the branch onto the fetched branch. A rebase that stops
#	aborts at once, so no stopped rebase stays behind
#	(WIKI-OPEN-3). The method returns 0 after a failure.
sub _rebase ( $app, $dir, $branch )
{
	return 1
	    if
	    defined _git( $app, $dir, 'rebase', '--quiet', "origin/$branch" );

	$app->cli->log->error( 'the rebase stopped: %s', $app->error );
	_git( $app, $dir, 'rebase', '--abort' ) if _rebasing( $app, $dir );

	return 0;
}

# _rebasing($app, $dir):
#	True when a rebase of the clone has stopped. The abort runs
#	under this test alone, because an abort without a rebase in
#	progress reports a failure of its own.
sub _rebasing ( $app, $dir )
{
	my $git = _capture( $app, $dir, 'rev-parse', '--absolute-git-dir' );
	return 0 unless defined $git;

	return ( -d "$git/rebase-merge" || -d "$git/rebase-apply" ) ? 1 : 0;
}

# _git($app, $dir, @args):
#	Run one git command with the clone as its working directory
#	(WIKI-CONFINE-2). The captured standard error of git reaches
#	standard error. The captured standard output stays here,
#	because standard output carries the result line alone
#	(CLI-PROGRAM-4).
sub _git ( $app, $dir, @args )
{
	return $app->command( [ 'git', @args ], cwd => $dir );
}

# _capture($app, $dir, @args):
#	The standard output of one git command, without the last
#	newline, or undef when the command fails.
sub _capture ( $app, $dir, @args )
{
	my $out = _git( $app, $dir, @args );
	return unless defined $out;
	chomp $out;

	return $out;
}

1;

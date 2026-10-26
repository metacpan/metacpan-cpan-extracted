package App::FileSync::Transport::Local;

# Runs filesync-server as a child process and speaks the wire protocol over
# its pipes.  Used by the test suite, and for a server directory that is
# local to the client (a NAS mount, say).

use App::FileSync::Platform;

use strict;
use warnings;

# Not :all - this class has a close method, and autodie replaces a package's
# subs named after the builtins it wraps.
use autodie qw(open);

use File::Basename qw(dirname);
use File::Spec;
use IPC::Open3 ();
use Readonly;
use Sub::Private { mode => 'enforce' };

use App::FileSync::Args qw(named);
use App::FileSync::Constants qw($ROLE_CLIENT $SERVER_PROGRAM);
use App::FileSync::I18N qw(throw);

use version; our $VERSION = version->declare('0.001.5');

# How far up from this file to look for a checkout's bin/filesync-server:
# lib/App/FileSync/Transport is four levels, blib/lib/... five.
Readonly my $SEARCH_DEPTH => 6;

=encoding utf8

=head1 NAME

App::FileSync::Transport::Local - run the server as a local child process

=head1 SYNOPSIS

	my $transport = App::FileSync::Transport::Local->new(
		root => '/srv/filesync', repo => 'docs', client => 'laptop',
	);
	my $connection = App::FileSync::Protocol->new(in => $transport->reader, out => $transport->writer);
	...
	$transport->close;

=head1 METHODS

=head2 new

Purpose: start a server for one session.

Args: C<root> (the server root), C<repo>, C<client>, optional C<role>
(default C<client>) and C<server_bin> (default C<FILESYNC_SERVER_BIN>, then a
F<bin/filesync-server> found above this module, then C<filesync-server> on
the PATH).

Returns: the transport.

Side Effects: starts C<$^X server_bin --root ... --repo ... --client ...
--role ...>.  The child's standard error is the parent's, never the protocol
pipe: sharing it would put diagnostics into the protocol stream.

Usage:

	my $transport = App::FileSync::Transport::Local->new(%args);

=head3 EXAMPLE

	my $t = App::FileSync::Transport::Local->new(root => $root, repo => 'docs', client => 'test-1');
	print {$t->writer} ...;

=head3 API SPECIFICATION

=head4 INPUT

	{
		root       => { type => 'string', min => 1 },
		repo       => { type => 'string', min => 1 },
		client     => { type => 'string', min => 1 },
		role       => { type => 'string', optional => 1 },
		server_bin => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Transport::Local' }

=head3 MESSAGES

	Key                 Meaning                     Resolution
	transport.missing   root, repo or client absent  pass it

=head3 FORMAL SPECIFICATION

	new(a) ⇒ ∃ child • argv(child) = ⟨perl, bin, --root, a.root, --repo, a.repo, --client, a.client, --role, role⟩

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		map({ $_ => { type => 'string', optional => 1 } } qw(root repo client role server_bin)),
	}, 'Transport::Local->new');

	for my $required (qw(root repo client)) {
		throw('transport.missing', { transport => 'Local', what => $required })
			unless defined $args->{$required} && length $args->{$required};
	}

	my @command = (
		$^X, $args->{server_bin} || _default_server_bin(),
		'--root',   $args->{root},
		'--repo',   $args->{repo},
		'--client', $args->{client},
		'--role',   $args->{role} || $ROLE_CLIENT,
	);

	# '>&STDERR' dups the parent's stderr.  Passing a filehandle here would not
	# redirect the child at all: it would write into an unread pipe, and the
	# first log line would kill it with SIGPIPE.
	my ($writer, $reader);
	my $pid = IPC::Open3::open3($writer, $reader, '>&STDERR', @command);

	return bless { pid => $pid, writer => $writer, reader => $reader }, $class;
}

=head2 reader

Documented with L</writer> below.

=head2 writer

Purpose: the pipes to and from the server.

Args: none.

Returns: the read handle (server's stdout) or write handle (its stdin).

Side Effects: none.

Usage:

	my $in = $transport->reader;

=head3 EXAMPLE

	App::FileSync::Protocol->new(in => $t->reader, out => $t->writer);

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'object' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	reader = self.reader ; writer = self.writer

=cut

sub reader {
	my ($self) = @_;

	return $self->{reader};
}

sub writer {
	my ($self) = @_;

	return $self->{writer};
}

=head2 close

Purpose: end the session's process.

Args: none.

Returns: 1.  Repeated calls do nothing.

Side Effects: closes both pipes (the server sees end of file) and reaps the
child.

Usage:

	$transport->close;

=head3 EXAMPLE

	$transport->close;	# safe to call twice

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'integer', memberof => [ 1 ] }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	closed' = 1 ∧ child ∉ processes'

=cut

sub close {	## no critic (Subroutines::ProhibitBuiltinHomonyms, Subroutines::ProhibitAmbiguousNames) -- transport interface
	my ($self) = @_;

	return 1 if $self->{closed}++;

	# Pipe close failures mean the child already went; reaping still matters.
	for my $handle (grep { defined } @{$self}{qw(writer reader)}) {
		CORE::close($handle);
	}
	waitpid($self->{pid}, 0) if $self->{pid};

	return 1;
}

=head2 error_text

Purpose: what the transport itself said, for when the protocol failed.

Args: none.

Returns: an empty string: the local server writes its diagnostics to this
process's own standard error, which the user already sees.

Side Effects: none.

Usage:

	my $text = $transport->error_text;

=head3 EXAMPLE

	print $transport->error_text, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	error_text = ""

=cut

sub error_text {
	return '';
}

# _default_server_bin
# Purpose:     find the server program when none is configured.
# Entry:       none.
# Exit:        returns FILESYNC_SERVER_BIN, a bin/filesync-server found by
#              walking up from this file (a checkout, or blib under
#              "make test"), or the bare name (installed, on the PATH).
# Side effects: none.
sub _default_server_bin :Private {
	my $configured = $ENV{FILESYNC_SERVER_BIN};
	return $configured if defined $configured && length $configured;

	my $directory = dirname(__FILE__);
	for (1 .. $SEARCH_DEPTH) {
		my $candidate = File::Spec->catfile($directory, 'bin', $SERVER_PROGRAM);
		return $candidate if -f $candidate;
		$directory = dirname($directory);
	}

	return $SERVER_PROGRAM;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The child runs with this process's privileges: a local transport
cannot enforce the separation an SSH forced command gives, so anyone who can
run it can write the server root directly anyway.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

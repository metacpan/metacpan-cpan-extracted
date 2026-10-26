package App::FileSync::Transport::SSH;

# Runs filesync-server on the server host over one ssh connection and speaks
# the wire protocol on its pipes.  The ssh argument list is built here and
# never passed through a local shell, and every value that reaches the remote
# shell is restricted to characters that are inert there, so a repo or client
# id cannot become a command.

use App::FileSync::Platform;

use strict;
use warnings;

# Not :all - this class has a close method, and autodie replaces a package's
# subs named after the builtins it wraps.
use autodie qw(open);

use File::Temp ();
use IPC::Open3 ();
use List::Util qw(any);
use Readonly;
use Sub::Private { mode => 'enforce' };

use App::FileSync qw(validate_client_id validate_repo_name);
use App::FileSync::Args qw(named);
use App::FileSync::Constants qw($PROTOCOL_VERSION $ROLE_CLIENT @ROLES $SERVER_PROGRAM);
use App::FileSync::I18N qw(throw);
use App::FileSync::IO qw(read_text);

use version; our $VERSION = version->declare('0.001.5');

# Kept for compatibility: the protocol version sent as --proto.
our $PROTO = $PROTOCOL_VERSION;

# Options every session uses: no prompts, keepalives so a dead link is
# noticed, and a bounded connect.
Readonly my @SSH_OPTIONS => (
	'-T',
	'-o', 'BatchMode=yes',
	'-o', 'ServerAliveInterval=30',
	'-o', 'ConnectTimeout=10',
);

# Host key policies a repo may choose.
Readonly my @HOST_KEY_CHECKING => qw(yes accept-new);

# The highest TCP port.
Readonly my $MAX_PORT => 65_535;

# Characters that would end or split an argument.
Readonly my $UNSAFE_ARG => qr/[\0\n]/;

# user@host, host, or a bracketed IPv6 literal.  Both the user and the host
# start with a letter or digit, so neither can be read as an ssh option.
Readonly my $SERVER => qr/\A(?:[A-Za-z0-9][A-Za-z0-9._-]*@)?
	(?:[A-Za-z0-9](?:[A-Za-z0-9._-]*[A-Za-z0-9])?|\[[0-9A-Fa-f:]+\])\z/x;

# A remote program path: only characters inert in a POSIX shell, and not
# starting with '-'.
Readonly my $PROGRAM => qr{\A[A-Za-z0-9._/][A-Za-z0-9._/-]*\z};

=encoding utf8

=head1 NAME

App::FileSync::Transport::SSH - run the server over ssh

=head1 SYNOPSIS

	my $transport = App::FileSync::Transport::SSH->new(
		server => 'filesync@files.example.com', repo => 'docs', client => 'laptop',
		identity => '~/.ssh/filesync_ed25519',
	);
	...
	$transport->close or warn $transport->error_text;

=head1 METHODS

=head2 new

Purpose: start C<filesync-server> on the server host for one session.

Args: C<server> (C<user@host>, C<host> or C<user@[v6]>), C<repo>, C<client>,
optional C<role> (default C<client>), C<server_command> (default
C<filesync-server>), C<host_key_checking> (C<yes>, the default, or
C<accept-new>), C<known_hosts>, C<identity>, C<port>, C<command> (the local
ssh program), C<extra_args> (arrayref of extra ssh arguments).

Returns: the transport.

Side Effects: runs C<ssh ... SERVER PROGRAM --repo R --client C --role X
--proto 2>.  ssh's standard error goes to a temporary file, never the
protocol pipe, and is available from L</error_text>.  On Windows a C<.cmd> or
C<.bat> ssh wrapper is started through C<COMSPEC>, since CreateProcess cannot
start one directly.

Usage:

	my $transport = App::FileSync::Transport::SSH->new(%args);

=head3 EXAMPLE

	my $t = App::FileSync::Transport::SSH->new(
		server => 'backup', repo => 'photos', client => 'nas', role => 'replica', port => 2222,
	);
	print join(' ', @{ $t->command }), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		server            => { type => 'string', matches => $SERVER },
		repo              => { type => 'string', min => 1, max => 64 },
		client            => { type => 'string', min => 1, max => 64 },
		role              => { type => 'string', optional => 1, memberof => [ 'client', 'replica' ] },
		server_command    => { type => 'string', optional => 1, matches => $PROGRAM },
		host_key_checking => { type => 'string', optional => 1, memberof => [ 'yes', 'accept-new' ] },
		known_hosts       => { type => 'string', optional => 1 },
		identity          => { type => 'string', optional => 1 },
		port              => { type => 'integer', optional => 1, min => 1, max => 65535 },
		command           => { type => 'string', optional => 1 },
		extra_args        => { type => 'arrayref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Transport::SSH' }

=head3 MESSAGES

	Key                  Meaning                                    Resolution
	transport.missing    server, repo or client absent              fix the repo config
	transport.bad_value  a value is unsafe or out of range          fix the repo config or settings
	transport.bad_id     the repo or client is not a plain id       fix the repo config
	io.write             the error file cannot be created           check the temp directory

=head3 FORMAL SPECIFICATION

	pre server ∈ SERVER ∧ repo ∈ Id ∧ client ∈ Id ∧ role ∈ ROLES ∧ program ∈ PROGRAM
	    ∧ (port = ⊥ ∨ 0 < port ≤ 65535) ∧ ∀ a : extra_args • a ∈ TEXT ∧ '\n' ∉ a
	argv = ⟨ssh⟩ ⁀ options ⁀ ⟨server, program, --repo, repo, --client, client, --role, role, --proto, PROTO⟩

=head3 PSEUDOCODE

	validate every argument
	build ssh's options: fixed ones, host key policy, known hosts, identity,
	port, extra arguments
	append the server, then the remote command
	wrap a .cmd/.bat ssh in COMSPEC on Windows
	start it with standard error going to a temporary file

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		map({ $_ => { type => 'string', optional => 1 } }
			qw(server repo client role server_command host_key_checking known_hosts identity port command)),
		extra_args => { type => 'arrayref', optional => 1 },
	}, 'Transport::SSH->new');

	for my $required (qw(server repo client)) {
		throw('transport.missing', { transport => 'SSH', what => $required })
			unless defined $args->{$required} && length $args->{$required};
	}
	_check('server', $args->{server}, valid_server($args->{server}));

	for my $check ([ repo => \&validate_repo_name ], [ client => \&validate_client_id ]) {
		my ($field, $validate) = @{$check};
		my ($ok, $reason) = $validate->($args->{$field});
		throw('transport.bad_id', { reason => $reason }) unless $ok;
	}

	my $role = $args->{role} || $ROLE_CLIENT;
	_check('role', $role, any { $_ eq $role } @ROLES);

	my $program = _given($args->{server_command}) // $SERVER_PROGRAM;
	_check('server_command', $program, valid_program($program));

	my $checking = _given($args->{host_key_checking}) // $HOST_KEY_CHECKING[0];
	_check('host_key_checking', $checking, any { $_ eq $checking } @HOST_KEY_CHECKING);

	my @command = (_given($args->{command}) // 'ssh', @SSH_OPTIONS, '-o', "StrictHostKeyChecking=$checking");

	if (defined(my $known = _given($args->{known_hosts}))) {
		_check('known_hosts', $known, $known !~ $UNSAFE_ARG);
		push @command, '-o', "UserKnownHostsFile=$known";
	}
	if (defined(my $identity = _given($args->{identity}))) {
		_check('identity', $identity, $identity !~ $UNSAFE_ARG);
		push @command, '-i', $identity;
	}
	if (defined(my $port = _given($args->{port}))) {
		_check('port', $port, $port =~ /\A\d{1,5}\z/ && $port > 0 && $port <= $MAX_PORT);
		push @command, '-p', $port;
	}
	for my $extra (@{ $args->{extra_args} || [] }) {
		_check('extra_args', $extra // '', defined $extra && !ref $extra && $extra !~ $UNSAFE_ARG);
		push @command, $extra;
	}

	# The remote shell splits this back into arguments; every value is
	# restricted (above) to characters that are inert in a POSIX shell.
	push @command, $args->{server}, $program,
		'--repo', $args->{repo}, '--client', $args->{client}, '--role', $role, '--proto', $PROTO;

	if ($^O eq 'MSWin32' && $command[0] =~ /\.(?:cmd|bat)\z/i) {
		unshift @command, _given($ENV{COMSPEC}) // 'cmd.exe', '/d', '/c';
	}

	return bless { command => \@command, status => undef, stderr => '', %{ _spawn(\@command) } }, $class;
}

=head2 reader

Documented with L</exit_status> below.

=head2 writer

Documented with L</exit_status> below.

=head2 command

Documented with L</exit_status> below.

=head2 exit_status

Purpose: the session's pipes, the argv that was run, and ssh's exit status.

Args: none.

Returns: the read and write handles; a copy of the argv (for C<--verbose> and
tests); the exit status after L</close> (undef before).

Side Effects: none.

Usage:

	my $argv = $transport->command;

=head3 EXAMPLE

	print "ran: @{ $transport->command }\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'scalar' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	command = copy(self.command) ; exit_status = self.status

=cut

sub reader {
	my ($self) = @_;

	return $self->{reader};
}

sub writer {
	my ($self) = @_;

	return $self->{writer};
}

sub command {
	my ($self) = @_;

	return [ @{ $self->{command} } ];
}

sub exit_status {
	my ($self) = @_;

	return $self->{status};
}

=head2 close

Purpose: end the ssh session.

Args: none.

Returns: 1 when ssh exited 0, else 0.  Repeated calls return 1.

Side Effects: closes both pipes, reaps ssh, records its exit status and
signal, and reads what it wrote to standard error.

Usage:

	$transport->close or warn $transport->error_text, "\n";

=head3 EXAMPLE

	unless ($transport->close) {
		printf "ssh exited %d: %s\n", $transport->exit_status, $transport->error_text;
	}

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	close = 1 ⇔ closed ∨ exit(ssh) = 0

=cut

sub close {	## no critic (Subroutines::ProhibitBuiltinHomonyms, Subroutines::ProhibitAmbiguousNames) -- transport interface
	my ($self) = @_;

	return 1 if $self->{closed}++;

	for my $handle (grep { defined } @{$self}{qw(writer reader)}) {
		CORE::close($handle);
	}

	if ($self->{pid}) {
		waitpid($self->{pid}, 0);
		my $status = $?;
		@{$self}{qw(status signal pid)} = ($status >> 8, $status & 127, 0);
	}
	$self->{stderr} = _slurp($self->{error_path});

	return ($self->{status} || 0) == 0 ? 1 : 0;
}

=head2 error_text

Purpose: what ssh or the remote shell said, for when the protocol failed.

Args: none.

Returns: the text, trimmed, with blank lines collapsed.

Side Effects: reads the error file if L</close> has not yet.

Usage:

	my $why = $transport->error_text;

=head3 EXAMPLE

	print $transport->error_text, "\n";	# "Permission denied (publickey)."

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	error_text = squeeze(trim(stderr))

=cut

sub error_text {
	my ($self) = @_;

	my $text = length $self->{stderr} ? $self->{stderr} : _slurp($self->{error_path});
	$text =~ s/\A\s+|\s+\z//g;
	$text =~ s/\n+/\n/g;
	return $text;
}

=head2 valid_server

Documented with L</valid_program> below.

=head2 valid_program

Purpose: check a server address and a remote program path.

Args: the value.

Returns: 1 or 0.

A server is C<user@host>, C<host> or C<user@[ipv6]>; the user and host must
start with a letter or digit, so neither can be read as an ssh option (a
leading C<->) and nothing can split into another word.  A program is a path of
letters, digits, C<.>, C<_>, C</> and C<->, not starting with C<->.

Side Effects: none.

Usage:

	die "bad server\n" unless App::FileSync::Transport::SSH::valid_server($server);

=head3 EXAMPLE

	App::FileSync::Transport::SSH::valid_server('filesync@files.example.com');	# 1
	App::FileSync::Transport::SSH::valid_server('-oProxyCommand=sh');		# 0
	App::FileSync::Transport::SSH::valid_server('-v@host');				# 0

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'value', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	valid_server(v) ⇔ v ∈ SERVER
	valid_program(v) ⇔ v ∈ PROGRAM

=cut

sub valid_server {
	my ($value) = @_;

	return (defined $value && $value =~ $SERVER) ? 1 : 0;
}

sub valid_program {
	my ($value) = @_;

	return (defined $value && $value =~ $PROGRAM) ? 1 : 0;
}

# _spawn
# Purpose:     start ssh with stderr going to a temporary file.
# Entry:       $command is the full argv.
# Exit:        returns { pid, writer, reader, errors, error_path }.
# Side effects: creates the error file (removed when the object goes) and
#              starts the process.  IPC::Open3 rather than fork/exec: on
#              Windows fork() is a pseudo-process whose pipe handles are
#              not always duplicated, which leaves a full-duplex session
#              waiting on a pipe end that never closes.
sub _spawn :Private {
	my ($command) = @_;

	my $errors = File::Temp->new(UNLINK => 1);
	my $error_path = $errors->filename;
	open my $err_fh, '>', $error_path;

	my ($writer, $reader);
	my $pid = IPC::Open3::open3($writer, $reader, '>&' . fileno($err_fh), @{$command});
	CORE::close($err_fh);

	return { pid => $pid, writer => $writer, reader => $reader, errors => $errors, error_path => $error_path };
}

# _check
# Purpose:     refuse an unsafe or out-of-range argument.
# Entry:       $ok is the result of the check.
# Exit:        returns 1.
# Side effects: raises transport.bad_value naming the field.
sub _check :Private {
	my ($field, $value, $ok) = @_;

	throw('transport.bad_value', { field => $field, value => $value }) unless $ok;
	return 1;
}

# _given
# Purpose:     treat an empty string like an absent value.
# Entry:       any scalar.
# Exit:        returns the value, or undef if undefined or empty.
# Side effects: none.
sub _given :Private {
	my ($value) = @_;

	return (defined $value && length $value) ? $value : undef;
}

# _slurp
# Purpose:     the error file's contents.
# Entry:       $path may be undef or gone.
# Exit:        returns the text, or ''.
# Side effects: reads the file; an unreadable one is treated as empty
#              (there is nothing better to report).
sub _slurp :Private {
	my ($path) = @_;

	return '' unless defined $path && -e $path;
	my $text = eval { read_text($path) };
	return defined $text ? $text : '';
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * C<extra_args> are passed to ssh unchecked apart from embedded NULs and
newlines: they are the user's own options, and can therefore do anything ssh
options can (C<-o ProxyCommand=...> included).  Only trusted configuration
should set them.

=item * C<known_hosts> and C<identity> are not tilde-expanded here; ssh expands
C<~> in C<-i> but not in C<UserKnownHostsFile> on every version.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

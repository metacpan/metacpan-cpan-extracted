package App::WebPerimeterScan::Scope;

use strict;
use warnings;
use autodie qw(:all);

use Data::Validate::IP qw(is_ipv4 is_ipv6 is_public_ipv4 is_public_ipv6);
use Encode qw(decode FB_CROAK LEAVE_SRC);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Socket qw(getaddrinfo getnameinfo NI_NUMERICHOST NIx_NOSERV SOCK_STREAM);
use Sub::Private { mode => 'enforce' };
use URI;

use App::WebPerimeterScan::I18N ();
use parent -norequire, 'App::WebPerimeterScan::I18N';

our $VERSION = '0.001.0';

# The scope file is the authorisation boundary.  Nothing in this distribution
# sends traffic to a host that does not appear here, so a crawler cannot
# wander onto a third party's site.

# Scope-file syntax.  A hostname label run, as accepted in a scope line.
Readonly::Scalar my $HOST_RE     => qr/[A-Za-z0-9][A-Za-z0-9._-]*/;
Readonly::Scalar my $URL_LINE    => qr{\Ahttps?://}i;
Readonly::Scalar my $WILDCARD    => qr/\A\*\.($HOST_RE)\z/;
Readonly::Scalar my $HOST_PORT   => qr/\A($HOST_RE)(?::(\d+))?\z/;
Readonly::Scalar my $COMMENT     => qr/\s*#.*/s;

# Any character outside ASCII: such a host name needs its Punycode form.
Readonly::Scalar my $NON_ASCII => qr/[^\x00-\x7f]/;

# A bare scope line split into its parts, so that only the host is converted:
# an optional "*." wildcard prefix, the host, and an optional ":port".
Readonly::Scalar my $BARE_LINE => qr/\A(\*\.)?([^:\/\s]+)(:\d+)?\z/;

# Valid TCP port numbers, for an explicit port in a scope line.
Readonly::Scalar my $MIN_PORT => 1;
Readonly::Scalar my $MAX_PORT => 65_535;

=encoding utf8

=head1 NAME

App::WebPerimeterScan::Scope - authorisation boundary for an external scan

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Load a scope file and stop at once if a host may not be scanned:

	use App::WebPerimeterScan::Scope;

	my $scope = App::WebPerimeterScan::Scope->new;
	$scope->load_file('scope.txt')->assert_target_allowed('www.example.com');

Ask before following a link, without stopping:

	for my $link ('https://api.example.com/', 'https://other.example.net/') {
		my $host = URI->new($link)->host;
		next unless $scope->allows($host);
		print "may visit $link\n";
	}

Scan a test server on your own machine.  Loopback and private addresses
are refused unless you say so:

	my $lab = App::WebPerimeterScan::Scope->new(allow_private => 1);
	$lab->load_file('lab-scope.txt');
	print "allowed\n" if $lab->allows('127.0.0.1');

List the hosts that will be scanned:

	for my $host (@{ $scope->hosts }) {
		print "$host\n";
	}

=head1 DESCRIPTION

This module decides which hosts the scanner may contact.  The scanner asks
it before every network request.

A host may be scanned only when both of these are true:

=over 4

=item 1. The host is listed in the scope file (or matches a wildcard line
in it).

=item 2. The host does not resolve to a loopback, private, link-local,
documentation or other non-public address.  The C<allow_private> option
turns this second test off, for scanning your own test servers.

=back

=head2 The scope file

The scope file is plain text, one entry per line.  Each line is one of:

	example.com                 a host name
	example.com:8443            a host name and a port
	203.0.113.10                an IPv4 address
	https://shop.example.com/   a URL: the scheme, host and any port are used
	*.example.com               a wildcard: example.com and every name below it

Blank lines are ignored.  A C<#> starts a comment, which runs to the end of
the line.  Host names are compared without regard to case, and a final dot
(C<example.com.>) is removed.  International names may be
written as they are, in UTF-8; see L</ENCODING>.  A line that cannot be understood is skipped
with a warning.  A file with no usable line at all is an error.

=head1 REQUIREMENTS

C<URI> 1.70 and C<Data::Validate::IP> 0.31, which classifies addresses
against the IANA special-purpose registries for both IPv4 and IPv6.
Addresses are resolved with C<Socket> 2.020's C<getaddrinfo>.

=head1 SUBROUTINES/METHODS

=head2 new

Purpose: create an empty scope.

Args: named C<allow_private> (boolean, default 0) and C<source> (string,
the name to quote in refusals, default C<(none)>).

Returns: the new object.

Side Effects: none.

Usage: C<< my $scope = App::WebPerimeterScan::Scope->new(allow_private => 1); >>

=head3 EXAMPLE

	my $scope = App::WebPerimeterScan::Scope->new;
	$scope->load_file('scope.txt');

=head3 API SPECIFICATION

=head4 INPUT

	{
		allow_private => { type => 'boolean', optional => 1, default => 0 },
		source        => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Scope' }

=head3 MESSAGES

	Message                     Meaning / resolution
	--------------------------  -------------------------------------
	Unknown parameter 'X'       A misspelt argument name.

=cut

sub new
{
	my $class = shift;

	my $args = validate_strict(
		schema => {
			allow_private => { type => 'boolean', optional => 1, default => 0 },
			source        => { type => 'string', optional => 1 },
		},
		input => get_params(undef, \@_) // {},
	);

	return bless {
		entries       => [],
		allow_private => $args->{allow_private} ? 1 : 0,
		source        => $args->{source} // $class->i18n('scope.no_source'),
	}, $class;
}

=head2 load_file

Purpose: read a scope file.

Args: C<$file>, the path.

Returns: C<$self>, for chaining.

Side Effects: appends the file's entries; records C<$file> as the source
quoted in refusals.  Lines that cannot be parsed are skipped with a warning.

Usage: C<< $scope->load_file('scope.txt') >>

Accepted lines, one per line, C<#> starts a comment:

	example.com
	example.com:8443
	https://example.com/
	*.example.com            (the domain and any sub-domain)
	192.0.2.10

=head3 EXAMPLE

	my $scope = eval { App::WebPerimeterScan::Scope->new->load_file($path) }
		or die App::WebPerimeterScan::I18N::clean_error($@), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{ file => { type => 'string', min => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Scope' }

=head3 MESSAGES

	Message                                     Meaning / resolution
	------------------------------------------  ------------------------------
	Cannot read scope file 'F': E (fatal)       F is missing or unreadable; E
	                                            is the operating system's text.
	Ignoring unparsable scope line: L (warning) L is not a host, host:port,
	                                            URL or *.domain; fix the line.
	Scope file 'F' contains no usable hosts     Every line was blank, a
	(fatal)                                     comment or unparsable.

=head3 PSEUDOCODE

	open the file, or croak with the operating system's reason
	for each line
		strip comments and surrounding white space; skip if empty
		parse it as a URL, a wildcard or host[:port]
		warn and skip if it does not parse
	croak if no line produced an entry
	remember the file name for refusal messages

=cut

sub load_file
{
	my ($self, @rest) = @_;

	my $file = validate_strict(
		schema => { file => { type => 'string', min => 1 } },
		input  => get_params('file', \@rest),
	)->{file};

	# autodie throws on failure; turn that into our message, keeping the
	# operating system's reason exactly as Perl reported it.
	my $fh = eval { open my $handle, '<', $file; $handle };
	$self->_throw('scope.unreadable', { file => $file, error => _os_error($@) }) unless $fh;

	my $count = 0;
	while(my $line = <$fh>) {
		$line =~ s/$COMMENT//;
		$line =~ s/\A\s+|\s+\z//g;
		next unless length $line;

		if($self->_add_entry($line)) {
			$count++;
		} else {
			$self->_warn('scope.unparsable', { line => $line });
		}
	}
	close $fh;

	$self->_throw('scope.empty', { file => $file }) unless $count;

	$self->{source} = $file;

	return $self;
}

=head2 entries

Purpose: every parsed entry, wildcards included.

Args: none.

Returns: an array reference of hash references with C<host> and, where
given, C<port>, C<scheme> and C<wildcard>.

Side Effects: none.

Usage: C<< for my $entry (@{ $scope->entries }) { ... } >>

=head3 EXAMPLE

	my @wildcards = grep { $_->{wildcard} } @{ $scope->entries };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref', element_type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub entries
{
	my ($self) = @_;

	return [ @{ $self->{entries} } ];
}

=head2 source

Purpose: where the scope came from, for messages and reports.

Args: none.

Returns: the file name given to C<load_file>, or the C<source> given to
C<new>, or C<(none)>.

Side Effects: none.

Usage: C<< print 'Scope: ', $scope->source, "\n"; >>

=head3 EXAMPLE

	printf "Loaded %s\n", $scope->source;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=cut

sub source
{
	my ($self) = @_;

	return $self->{source};
}

=head2 hosts

Purpose: the concrete hosts to scan.

Args: none.

Returns: an array reference of entries, wildcards removed and the first
entry for each host kept.  A wildcard still authorises its sub-domains, but
sub-domain names are not guessed: only links the site serves are followed.

Side Effects: none.

Usage: C<< for my $entry (@{ $scope->hosts }) { ... } >>

=head3 EXAMPLE

	print "$_->{host}\n" for @{ $scope->hosts };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref', element_type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub hosts
{
	my ($self) = @_;

	my %seen;

	return [ grep { !$_->{wildcard} && !$seen{ $_->{host} }++ } @{ $self->{entries} } ];
}

=head2 covers

Purpose: say whether a hostname is inside the authorised scope.

Args: C<$host> (string).  Case and a trailing dot are ignored.

Returns: 1 or 0.

Side Effects: none; this does not resolve the name.

Usage: C<< next unless $scope->covers($uri->host); >>

=head3 EXAMPLE

	# with "*.example.com" in the scope file
	$scope->covers('api.example.com');	# 1
	$scope->covers('notexample.com');	# 0, the match is on a label boundary

=head3 API SPECIFICATION

=head4 INPUT

	{ host => { type => 'string', optional => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub covers
{
	my ($self, $host) = @_;

	# A caller may pass an international name as text; entries are ASCII.
	$host = _ascii_host($host);
	return 0 unless defined $host && length $host;

	$host = lc $host;
	$host =~ s/\.\z//;

	# A wildcard matches on a label boundary only, so *.example.com does
	# not cover notexample.com.
	my $hit = grep {
		$host eq $_->{host} || ($_->{wildcard} && $host =~ /\.\Q$_->{host}\E\z/)
	} @{ $self->{entries} };

	return $hit ? 1 : 0;
}

=head2 is_private_target

Purpose: say whether a host resolves into address space that is not
publicly routable.

Args: C<$host>, a hostname or an IPv4 or IPv6 literal.

Returns: 1 if B<any> address the name resolves to is loopback, private
(RFC 1918, unique-local), link-local, shared (CGNAT), documentation,
benchmarking, multicast, reserved or otherwise non-public; 0 if every
address is public or the name does not resolve.

Side Effects: a DNS lookup.

Usage: C<< warn "private\n" if $scope->is_private_target($host); >>

Checking every address matters: a name with one public and one internal A
record would otherwise be judged on whichever the resolver listed first.

=head3 EXAMPLE

	$scope->is_private_target('127.0.0.1');		# 1
	$scope->is_private_target('::1');		# 1
	$scope->is_private_target('192.30.252.1');	# 0

=head3 API SPECIFICATION

=head4 INPUT

	{ host => { type => 'string', min => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub is_private_target
{
	my ($self, $host) = @_;

	my $private = grep {
		is_ipv4($_) ? !is_public_ipv4($_) : is_ipv6($_) ? !is_public_ipv6($_) : 1
	} @{ _addresses($host) };

	return $private ? 1 : 0;
}

=head2 allows

Purpose: the full authorisation test for one host: in scope, and not in
private address space unless that was permitted.

Args: C<$host> (string).

Returns: 1 or 0.

Side Effects: a DNS lookup when the host is covered and C<allow_private> is
off.

Usage: C<< next unless $scope->allows($uri->host); >>

This is what the crawler asks before following a link: a wildcard entry
covers names nobody listed by hand, and one of them resolving to an internal
address must be refused like a listed one would be.

=head3 EXAMPLE

	my @fetchable = grep { $scope->allows(URI->new($_)->host) } @links;

=head3 API SPECIFICATION

=head4 INPUT

	{ host => { type => 'string', optional => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'boolean' }

=head3 MESSAGES

None.

=cut

sub allows
{
	my ($self, $host) = @_;

	my $allowed = $self->covers($host)
		&& ($self->{allow_private} || !$self->is_private_target($host));

	return $allowed ? 1 : 0;
}

=head2 assert_target_allowed

Purpose: refuse, loudly, to scan a host that C<allows> would reject.

Args: C<$host> (string).

Returns: C<$self>, for chaining.

Side Effects: croaks when the host is out of scope or private.

Usage: C<< $scope->assert_target_allowed($host); >>

=head3 EXAMPLE

	eval { $scope->assert_target_allowed('evil.example') };
	print App::WebPerimeterScan::I18N::clean_error($@), "\n" if $@;

=head3 API SPECIFICATION

=head4 INPUT

	{ host => { type => 'string', min => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Scope' }

=head3 MESSAGES

	Message                                       Meaning / resolution
	--------------------------------------------  ----------------------------
	Refusing to scan 'H': not listed in F         Add H to the scope file F
	(fatal)                                       if you are authorised to.
	Refusing to scan 'H': it resolves into        H is loopback/private; pass
	private address space (fatal)                 --allow-private if intended.

=cut

sub assert_target_allowed
{
	my ($self, $host) = @_;

	$self->_throw('scope.not_listed', { host => $host, source => $self->{source} })
		unless $self->covers($host);

	$self->_throw('scope.private', { host => $host })
		if !$self->{allow_private} && $self->is_private_target($host);

	return $self;
}

# _add_entry
# Purpose:     parse one non-empty, comment-free scope line.
# Entry:       $line is trimmed.
# Exit:        1 if an entry was added, 0 if the line was not understood.
# Side effects: appends to $self->{entries}.
sub _add_entry :Private
{
	my ($self, $line) = @_;

	my %entry;

	# An international name is stored in its ASCII (Punycode) form, which is
	# what DNS, URI and the crawler's links all use.  The line arrives as
	# bytes from the file, so it is decoded first: URI given UTF-8 bytes
	# reads each byte as a character and produces the Punycode of a
	# different, wrong name.
	if($line =~ $NON_ASCII) {
		if($line =~ $URL_LINE) {
			$line = _characters($line);
		} else {
			my ($wildcard, $host, $port) = $line =~ $BARE_LINE or return 0;
			my $ascii = _ascii_host($host) // return 0;
			$line = ($wildcard // '') . $ascii . ($port // '');
		}
	}

	if($line =~ $URL_LINE) {
		my $uri = URI->new($line);
		my $host = eval { $uri->host };
		return 0 unless defined $host && length $host;
		$entry{host}   = lc $host;
		$entry{scheme} = lc $uri->scheme;
		# Only a port the line actually names.  URI fills in the scheme's
		# default, and recording that made every URL entry look as though
		# a port had been given, which skipped the HTTP-to-HTTPS check.
		$entry{port} = $uri->port + 0 if $uri->port != $uri->default_port;
	} elsif($line =~ $WILDCARD) {
		$entry{host}     = lc $1;
		$entry{wildcard} = 1;
	} elsif($line =~ $HOST_PORT) {
		$entry{host} = lc $1;
		if(defined $2) {
			return 0 unless $2 >= $MIN_PORT && $2 <= $MAX_PORT;
			$entry{port} = $2 + 0;
		}
	} else {
		return 0;
	}

	$entry{host} =~ s/\.\z//;
	return 0 unless length $entry{host};

	push @{ $self->{entries} }, \%entry;

	return 1;
}

# _characters
# Purpose:     a string as Perl characters, whatever form it arrived in.
# Entry:       $text is a character string, or bytes (normally UTF-8).
# Exit:        the decoded text if $text is valid UTF-8 bytes; otherwise
#              $text unchanged (it is already characters, or is in another
#              encoding that cannot be guessed).
# Side effects: none.
sub _characters :Private
{
	my ($text) = @_;

	# LEAVE_SRC: decode must not empty the caller's string.  FB_CROAK:
	# invalid UTF-8 dies inside the eval and the text is kept as it is.
	return utf8::is_utf8($text) ? $text : eval { decode('UTF-8', $text, FB_CROAK | LEAVE_SRC) } // $text;
}

# _ascii_host
# Purpose:     the ASCII (Punycode) form of a host name, so names can be
#              compared and looked up whichever way they were written.
# Entry:       $host is undef, ASCII, UTF-8 bytes or a character string.
# Exit:        the lower-case ASCII name; the name unchanged if it was
#              already ASCII; undef if it cannot be converted.
# Side effects: none.
sub _ascii_host :Private
{
	my ($host) = @_;

	return $host unless defined $host && $host =~ $NON_ASCII;

	# URI applies the IDNA rules (lower case, then Punycode per label).
	my $ascii = eval { URI->new('http://' . _characters($host) . '/')->host };

	return (defined $ascii && length $ascii && $ascii !~ $NON_ASCII) ? lc $ascii : undef;
}

# _addresses
# Purpose:     every numeric address a host resolves to, IPv4 and IPv6.
# Entry:       $host is a hostname or address literal (brackets allowed).
# Exit:        arrayref of address strings; empty if it does not resolve.
# Side effects: a DNS lookup.
sub _addresses :Private
{
	my ($host) = @_;

	# getaddrinfo needs the ASCII form of an international name.
	$host = _ascii_host($host);
	return [] unless defined $host && length $host;
	(my $name = $host) =~ s/\A\[(.*)\]\z/$1/;
	(my $literal = $name) =~ s/%.*\z//;	# an IPv6 zone index such as %eth0

	# An address literal needs no lookup, and must not depend on one: some
	# Windows builds of getaddrinfo fail on IPv6 literals, and an empty
	# result here would let ::1 through as "not private".
	return [ $literal ] if is_ipv4($literal) || is_ipv6($literal);

	my ($error, @results) = getaddrinfo($name, '', { socktype => SOCK_STREAM });
	return [] if $error;

	my %seen;
	my @addresses;
	for my $result (@results) {
		my ($name_error, $address) = getnameinfo($result->{addr}, NI_NUMERICHOST, NIx_NOSERV);
		next if $name_error || !defined $address;
		$address =~ s/%.*\z//;	# drop an IPv6 zone index such as %eth0
		push @addresses, $address unless $seen{$address}++;
	}

	return \@addresses;
}

# _os_error
# Purpose:     the operating system's reason from a failed autodie call.
# Entry:       $exception is $@ after an autodie failure (object or string).
# Exit:        the errno text as Perl stringified it, or the cleaned message.
# Side effects: none.
sub _os_error :Private
{
	my ($exception) = @_;

	# autodie::exception records $! as it was at the moment of failure;
	# reading $! here instead could give a later, unrelated error.
	my $errno = (ref $exception && $exception->can('errno')) ? $exception->errno : undef;

	return (defined $errno && length $errno) ? "$errno" : App::WebPerimeterScan::I18N::clean_error($exception);
}

1;

__END__

=head1 COMMON PITFALLS

=over 4

=item * B<A port in the scope file does not limit the ports.>
C<example.com:8443> tells the scanner where the web server is.  It does not
stop C<covers> or C<allows> from accepting C<example.com> on any other port,
and the port scan still checks every port in its list.

=item * B<A wildcard is not scanned by itself.>  C<*.example.com> lets the
scanner follow links to C<shop.example.com>, but C<hosts> does not return
it, so it is not a starting point.  A file that has only wildcard lines
loads without error, but there is nothing to scan, and
C<< App::WebPerimeterScan->run >> stops with an error.

=item * B<A wildcard also covers the name itself, and every depth below
it.>  C<*.example.com> covers C<example.com>, C<a.example.com> and
C<a.b.example.com>.  It does not cover C<notexample.com>.

=item * B<Names and addresses are separate entries.>  Listing C<example.com>
does not allow C<203.0.113.10>, even if that is its address, and listing the
address does not allow the name.

=item * B<C<load_file> adds; it does not replace.>  Loading a second file
keeps the entries of the first.  C<source> then names only the second file.
Use a new object for a different scope.

=item * B<C<undef> and the empty string are never covered.>  C<covers(undef)>,
C<allows(undef)> and C<is_private_target(undef)> return 0.  For
C<is_private_target>, 0 means "no private address was found", so do not use
it alone as a safety check: use C<allows>, which also needs the host to be
listed.

=item * B<A name that does not resolve is not private.>
C<is_private_target> returns 0 for it.  The scan of that host then fails
to connect and is reported as an error; nothing is sent.

=item * B<The answer can change.>  A name is resolved every time it is
checked, and its DNS answer can change between the check and the
connection.  See L</LIMITATIONS>.

=back

=head1 ENCODING

=over 4

=item * B<Save the scope file as UTF-8.>  A byte-order mark at the start is
not supported.  Comments may contain any text.

=item * B<International host names can be written as they are.>  A name
such as C<bE<uuml>cher.example> is stored in its ASCII (Punycode) form,
C<xn--bcher-kva.example>, which is the form DNS uses.  This works in all
three kinds of line: C<bE<uuml>cher.example>, C<*.bE<uuml>cher.example> and
C<https://bE<uuml>cher.example/>.  Writing the Punycode form yourself
gives the same entry.

C<entries> and C<hosts> return the Punycode form, so that is what the
reports show.

=item * B<A file that is not UTF-8> is read as Latin-1 (ISO 8859-1), one
character per byte.  For Western European names this gives the right
answer; for other encodings, save the file as UTF-8.

=item * B<The checks accept any form of a name.>  C<covers>, C<allows>,
C<is_private_target> and C<assert_target_allowed> accept a name in
Punycode, as UTF-8 bytes or as a Perl character string, in any case.

=item * The file name passed to C<load_file> is used as Perl bytes, as
the operating system gives them.  A name with non-ASCII characters works
when it is passed exactly as it appears on disk.

=item * Error messages contain the operating system's text, in the
language of the current locale, exactly as Perl reports it in C<$!>.

=back

=head1 LIMITATIONS

=over 4

=item * The private-address check and the connection resolve the name
separately.  A name whose DNS answer changes between the two (DNS
rebinding) can pass the check and then connect to an internal address.
Closing that needs every connection to be made to the address that was
checked, with the name carried only in SNI and the Host header; the HTTP,
TLS and port-scan layers do not do that yet.

=item * Scope lines cannot name an IPv6 literal such as C<[2001:db8::1]>,
and C<*.example.com> covers C<example.com> itself as well as its
sub-domains.

=item * The port scan resolves with C<inet_aton> and so only ever connects
over IPv4, even where the private-address check considered IPv6 addresses.

=back

=head1 FORMAL SPECIFICATION

This section states exactly what each method does, in the Z notation.  You
do not need it to use the module: the method descriptions above say the same
thing in words.  It is here for reviewers and for anyone who writes tests.

How to read a schema box:

=over 4

=item * The part above the middle line declares names.  A name that ends in
C<?> is an input.  A name that ends in C<!> is an output.

=item * The part below the middle line lists facts that are true after the
call.

=item * A name with a dash after it, such as C<items'>, is the value after
the call.  The same name without the dash is the value before the call.

=item * C<Delta X> (written with the Greek capital delta) means the call
may change the state C<X>.  C<Xi X> (the Greek capital xi) means the call
does not change it.

=back

The symbols used are:

	Δ   may change            Ξ   does not change      •   such that
	∀   for all               ∃   there is             ¬   not
	∧   and                   ∨   or                   ⇒   implies
	⇔   if and only if        ≠   not equal            ≤ ≥ at most, at least
	∈   is in                 ∉   is not in            ⊆   is a subset of
	∪   union                 ∩   intersection         ∅   the empty set
	ℙ X sets of X             ⊥   undefined (undef)    …   and so on
	⟨⟩  the empty sequence    ⁀   join sequences       ⇸   partial mapping
	↦   maps to               ⊕   override a mapping   ↾   keep only these keys
	∘   compose               →   function             × ÷ − times, divide, minus
	ℕ   0, 1, 2, ...          ℕ₁  1, 2, 3, ...         ℝ   real numbers
	𝔹   true or false         ⌊x⌋ x rounded down
	dom M  the keys of M      ran M  the values of M   #S  the size of S


=head2 new

	┌─ InitScope ─────────────────────────────────────────
	│ Scope'; allow_private? : 𝔹
	├─────────────────────────────────────────────────────
	│ entries' = ⟨⟩ ∧ allow_private' = allow_private?
	└─────────────────────────────────────────────────────

=head2 load_file

	┌─ LoadFile ──────────────────────────────────────────
	│ ΔScope; file? : PATH
	├─────────────────────────────────────────────────────
	│ readable(file?)
	│ parsed = ⟨ e : ENTRY | ∃ l ∈ lines(file?) • parse(l) = e ⟩
	│ #parsed > 0
	│ entries' = entries ⁀ parsed ∧ source' = file?
	└─────────────────────────────────────────────────────

=head2 entries

	┌─ Entries ───────────────────────────────────────────
	│ ΞScope; result! : seq ENTRY
	├─────────────────────────────────────────────────────
	│ result! = entries
	└─────────────────────────────────────────────────────

=head2 source

	┌─ Source ────────────────────────────────────────────
	│ ΞScope; result! : STRING
	├─────────────────────────────────────────────────────
	│ result! = source
	└─────────────────────────────────────────────────────

=head2 hosts

	┌─ Hosts ─────────────────────────────────────────────
	│ ΞScope; result! : seq ENTRY
	├─────────────────────────────────────────────────────
	│ concrete = entries ↾ { e | ¬ e.wildcard }
	│ result! = ⟨ e : concrete | e is the first in concrete with e.host ⟩
	└─────────────────────────────────────────────────────

=head2 covers

	┌─ Covers ────────────────────────────────────────────
	│ ΞScope; host? : HOST; result! : 𝔹
	├─────────────────────────────────────────────────────
	│ h = lower(strip_dot(host?))
	│ result! ⇔ ∃ e ∈ ran entries •
	│     h = e.host ∨ (e.wildcard ∧ (∃ p • h = p ⁀ "." ⁀ e.host))
	└─────────────────────────────────────────────────────

=head2 is_private_target

	┌─ IsPrivateTarget ───────────────────────────────────
	│ ΞScope; host? : HOST; result! : 𝔹
	├─────────────────────────────────────────────────────
	│ A = resolve(host?)
	│ result! ⇔ ∃ a ∈ A • a ∉ PUBLIC
	└─────────────────────────────────────────────────────

=head2 allows

	┌─ Allows ────────────────────────────────────────────
	│ ΞScope; host? : HOST; result! : 𝔹
	├─────────────────────────────────────────────────────
	│ result! ⇔ Covers ∧ (allow_private ∨ ¬ IsPrivateTarget)
	└─────────────────────────────────────────────────────

=head2 assert_target_allowed

	┌─ AssertTargetAllowed ───────────────────────────────
	│ ΞScope; host? : HOST
	├─────────────────────────────────────────────────────
	│ Allows ∧ result! = self
	└─────────────────────────────────────────────────────
	NotListed ≙ [ΞScope; host? : HOST | ¬ Covers] ⇒ croak
	Private   ≙ [ΞScope; host? : HOST | Covers ∧ ¬ allow_private ∧ IsPrivateTarget] ⇒ croak

=head1 STATE DIAGRAM

A scope object is empty until a file is loaded.  Loading only adds
entries.  The checks never change the object, but C<allows>,
C<is_private_target> and C<assert_target_allowed> make a DNS lookup.

	          new(allow_private => 0 or 1)
	                     |
	                     v
	            +------------------+
	            |      EMPTY       |  entries = (), source = '(none)'
	            +------------------+
	              |      |      |
	              |      |      |  covers / allows       -> 0
	              |      |      |  hosts / entries       -> empty list
	              |      |      |  assert_target_allowed -> croak (not listed)
	              |      |      +------> (no change)
	              |      |
	              |      |  load_file(f): f cannot be read, or has no
	              |      |  usable line
	              |      +------> croak; (no change)
	              |
	              |  load_file(f): at least one usable line
	              |  -> entries added; a warning per unusable line;
	              |     source = f; returns the object
	              v
	            +------------------+
	    +------>|      LOADED      |  entries >= 1
	    |       +------------------+
	    |         |       |       |
	    |         |       |       +-- covers(h) / hosts / entries / source
	    |         |       |           -> answer; (no change)
	    |         |       |
	    |         |       +---------- allows(h) / is_private_target(h)
	    |         |                   -> DNS lookup; answer; (no change)
	    |         |
	    |         |  assert_target_allowed(h)
	    |         |    h not listed          -> croak "not listed"
	    |         |    h private, not allowed -> croak "private"
	    |         |    otherwise             -> returns the object
	    |         |  (no change in every case)
	    |         |
	    +---------+  load_file(f2): at least one usable line
	                 -> more entries added; source = f2

	load_file(f2) when f2 cannot be read or has no usable line: croak,
	and the entries already loaded are kept.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

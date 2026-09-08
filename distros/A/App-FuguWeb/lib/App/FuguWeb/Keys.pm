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

use v5.36;

package App::FuguWeb::Keys;
our $VERSION = '0.4.0';

use App::FuguWeb;
use App::FuguWeb::Page;
use Digest::SHA ();
use Fugu::File;
use Fugu::KeyDir;
use Fugu::OpenPGP;
use Fugu::Signify;
use MIME::Base64 ();

# App::FuguWeb::Keys - the key directory of a site.
#
# An organization publishes its public keys under one prefix, so a
# consumer install can fetch a key and verify a release with it. This
# module is the wiring of that directory. It reads the description
# blocks and calls the Fugu modules. It answers with paths, with
# bytes, and with the problems of a check.
#
# Every generic part lives in Fugu. Fugu::KeyDir holds the name
# pattern, the publication order, and the text of the KEYS file and of
# security.txt. Fugu::OpenPGP decodes an armored key and computes a
# fingerprint and a Web Key Directory hash. Fugu::Signify parses the
# manifest. Nothing generic lives here.
#
# The module runs no command. A site build neither signs nor verifies,
# so the manifest pair is a source file and not a generated one.

# The two files of the manifest pair. The rotation workflow writes
# them, and the build copies them as they stand.
use constant {
	MANIFEST  => 'SHA256',
	SIGNATURE => 'SHA256.sig',
};

# The generated names inside the key directory. KEYS is the Apache
# form, which gpg --import reads, and index.html is the human page.
use constant {
	KEYS_FILE  => 'KEYS',
	INDEX_PAGE => 'index.html',
};

# The well-known paths, at the site root. RFC 8615 reserves the
# prefix, and both names are registered: openpgpkey is the Web Key
# Directory, and security.txt is RFC 9116. Neither one sits under the
# key directory, because a reader asks for the registered path.
use constant {
	WELL_KNOWN   => '.well-known',
	WKD_DIR      => '.well-known/openpgpkey',
	WKD_POLICY   => '.well-known/openpgpkey/policy',
	SECURITY_TXT => '.well-known/security.txt',
};

# The two names in the source directory that name no key. The check
# holds every other name to the key pattern.
my %NOT_A_KEY = map { $_ => 1 } ( MANIFEST, SIGNATURE );

# Every generated name of the key directory. A build writes each one,
# whatever the description names today.
my %GENERATED_NAME =
    map { $_ => 1 } ( MANIFEST, SIGNATURE, KEYS_FILE, INDEX_PAGE );

# A Web Key Directory name is the z-base-32 form of the SHA-1 of an
# address local part. SHA-1 holds 20 bytes, and z-base-32 writes 32
# characters of its own alphabet for them.
use constant WKD_NAME => qr{\A[ybndrfg8ejkmcpqxot1uwisza345h769]{32}\z};

# App::FuguWeb::Keys->new(%args):
#	config => $config	the site description (required)
#
#	The method dies when the description holds no keys block. A
#	caller tests keys_dir first, so an absent block is a
#	programming error and not a failure of the site.
sub new ( $class, %args )
{
	my $config = $args{config};
	die 'config parameter required'
	    unless defined $config;
	die "the description holds no keys block\n"
	    unless defined $config->keys_dir;

	return bless {
		config => $config,
		keydir => Fugu::KeyDir->new( org => $config->keys_org ),
		error  => undef,
	}, $class;
}

# $self->error:
#	The reason of the most recent failure, or undef after a
#	success.
sub error ($self)
{
	return $self->{error};
}

# App::FuguWeb::Keys->shaped($config, $path):
#	Report whether a path of the output is one that a build of the
#	key directory writes.
#
#	A stale key file needs this. The build removes what the site
#	dropped, and a key that the description no longer names is
#	exactly that. The inventory cannot answer for it, because the
#	inventory names what the site holds today.
#
#	The set is bounded, and every member takes a fixed shape: a
#	generated name of the key directory, a key file that
#	Fugu::KeyDir parses, or one of the well-known paths. A path of
#	another shape belongs to whoever made it, so a target that
#	holds keys/notes.txt is no site.
#
#	The prune and the clean read this one answer, so a build can
#	never remove a file that the clean refuses.
sub shaped ( $class, $config, $path )
{
	# A description with no keys block publishes no key directory,
	# so it owns no path of one. The well-known names are the
	# trap: a site of another maker holds security.txt too, and a
	# clean that took it would delete that site.
	#
	# A description that did not load names the block all the
	# same: App::FuguWeb::Config reads that one name out of the
	# file that failed. A description that truly names none owns
	# no path here, whether it loaded or not.
	my $dir = $config->keys_dir;
	return 0 unless defined $dir;

	return 1 if $path eq SECURITY_TXT;
	return 1 if $path eq WKD_POLICY;

	my $hu = WKD_DIR . '/hu';
	if ( my ($hash) = $path =~ m{\A\Q$hu\E/(.+)\z} ) {
		return $hash =~ WKD_NAME ? 1 : 0;
	}

	my ($name) = $path =~ m{\A\Q$dir\E/(.+)\z};
	return 0 unless defined $name;
	return 1 if $GENERATED_NAME{$name};

	# A description that did not load names no org, and the key
	# files of the output carry it. The name gives its own, and
	# Fugu::KeyDir then holds the whole shape.
	my $org = $config->keys_org // ( $name =~ /\A([a-z][a-z0-9]*)-/ )[0];
	return 0 unless defined $org;

	my $keydir = Fugu::KeyDir->new( org => $org );

	return $keydir->parse_name($name) ? 1 : 0;
}

# $self->paths:
#	Every path that the key directory adds to the output, relative
#	to the output directory. The list holds the copied files and
#	the generated ones. It reads no file: the description and the
#	file names decide it. The inventory of a site therefore costs
#	one directory listing and no more.
sub paths ($self)
{
	my @keys = $self->{config}->site_keys;

	my @paths = map { $self->_in_dir( $_->{name} ) } @keys;
	push @paths, $self->_in_dir(MANIFEST), $self->_in_dir(SIGNATURE);
	push @paths, $self->_in_dir(KEYS_FILE) if $self->_armored(@keys);
	push @paths, $self->_in_dir(INDEX_PAGE);

	my @wkd = _addresses( $self->_published(@keys) );
	if (@wkd) {
		push @paths, WKD_DIR . "/hu/$_" for @wkd;
		push @paths, WKD_POLICY;
	}
	push @paths, SECURITY_TXT if defined $self->{config}->keys_contact;

	return @paths;
}

# $self->copies:
#	Every file that the build copies as it stands, as a list of
#	hash references with from and to. The from is a path in the
#	checkout, and the to is relative to the output directory.
sub copies ($self)
{
	my $config = $self->{config};

	my @names =
	    ( ( map { $_->{name} } $config->site_keys ), MANIFEST, SIGNATURE );

	return
	    map { { from => $config->keys_path($_), to => $self->_in_dir($_) } }
	    @names;
}

# $self->generated:
#	Every file that the build writes itself, as a hash reference
#	of output path to bytes. The method returns undef on a
#	failure, and error holds the reason.
#
#	The key set reaches Fugu::KeyDir with the armored body of each
#	OpenPGP key, because the KEYS file holds that body.
sub generated ($self)
{
	$self->{error} = undef;

	my $set = $self->key_set or return;
	my %out;

	my $ordered = $self->{keydir}->order($set)
	    or return $self->_fail( $self->{keydir}->error );

	# The armor guards of Fugu::KeyDir run here, and they refuse a
	# block that is not a public key. A build that copied first
	# would leave a private key in the output of a failed build.
	if ( $self->_armored(@$set) ) {
		my $text = $self->{keydir}->keys_file($set);
		return $self->_fail( $self->{keydir}->error )
		    unless defined $text;
		$out{ $self->_in_dir(KEYS_FILE) } = $text;
	}

	# The guards of keys_file read the armored text. They hold the
	# block type and the delimiters, and they decode nothing, so a
	# body with a broken base64 or a broken checksum passes them.
	# The decoder is what proves that the bytes are a key.
	for my $key ( grep { $_->{type} eq 'openpgp' } @$ordered ) {
		my ( $binary, $why ) =
		    Fugu::OpenPGP->decode_armor( $key->{armor} );
		return $self->_fail("$key->{name}: $why")
		    unless defined $binary;
	}

	my $rows = $self->{keydir}->index_data($set)
	    or return $self->_fail( $self->{keydir}->error );
	$out{ $self->_in_dir(INDEX_PAGE) } = $self->_index_page($rows);

	# One address holds every key of that address, in publication
	# order. A rotation gives one address a current key and a next
	# key, and a reader takes the whole file. One file for each key
	# would give one path two keys, and only the last one written
	# would publish.
	my @wkd = $self->_published(@$ordered);
	for my $key (@wkd) {
		my ( $binary, $why ) =
		    Fugu::OpenPGP->decode_armor( $key->{armor} );
		return $self->_fail("$key->{name}: $why")
		    unless defined $binary;

		$out{ WKD_DIR . "/hu/$key->{wkd}" } .= $binary;
	}
	$out{ WKD_POLICY() } = $self->_policy if @wkd;

	if ( defined $self->{config}->keys_contact ) {
		my $text = $self->_security_txt($ordered) or return;
		$out{ SECURITY_TXT() } = $text;
	}

	return \%out;
}

# $self->key_set:
#	The key set for Fugu::KeyDir: every key block of the
#	description, with the armored body of each OpenPGP key read
#	from its file. The method returns undef on a failure, and
#	error holds the reason.
sub key_set ($self)
{
	$self->{error} = undef;

	my @set;
	for my $key ( $self->{config}->site_keys ) {
		my %entry = %$key;

		my $path  = $self->{config}->keys_path( $key->{name} );
		my $bytes = Fugu::File->read($path);
		return $self->_fail("cannot read $path") unless defined $bytes;

		if ( $key->{type} eq 'openpgp' ) {
			$entry{armor} = $bytes;
		}
		else {
			my $why = _signify_problem($bytes);
			return $self->_fail("$key->{name}: $why")
			    if defined $why;
		}

		push @set, \%entry;
	}

	return $self->_fail('the description holds no key block')
	    unless @set;

	return \@set;
}

# $self->problems:
#	What the key directory of the checkout is not true of, each
#	one a sentence that names the file. An empty list means the
#	directory is good.
#
#	The checks read the source directory and not the output. A
#	stray file and a stale digest are faults of the checkout, and
#	the answer must not depend on a build having run.
#
#	The method verifies no signature. That is the work of a
#	consumer install: the site build cannot sign, so a site that
#	verified its own manifest would prove nothing.
sub problems ($self)
{
	my $config = $self->{config};
	my $dir    = $config->keys_dir;

	my @keys     = $config->site_keys;
	my @problems = $self->_stray_files( \@keys );

	# Every rule below reads the whole set, so one unreadable key
	# would report the same fault once for each rule.
	my $set = $self->key_set;
	return ( @problems, "$dir: " . $self->error ) unless $set;

	unless ( $self->{keydir}->check_statuses($set) ) {
		push @problems, "$dir: " . $self->{keydir}->error;
	}

	push @problems, $self->_manifest_problems( \@keys );
	push @problems, $self->_signature_problems;
	push @problems, $self->_fingerprint_problems($set);

	return @problems;
}

# $self->_stray_files($keys):
#	Every name in the source directory that no key block names.
#	The manifest pair names no key, and every other name must be
#	a key file with a block. A key that the description forgot
#	reaches no output. A reader of the directory would still take
#	that key for published.
sub _stray_files ( $self, $keys )
{
	my $config = $self->{config};
	my $dir    = $config->keys_dir;

	my $names = App::FuguWeb::list_dir( $config->keys_path )
	    or return "$dir: cannot read the key directory: $!";

	my %declared = map { $_->{name} => 1 } @$keys;

	my @problems;
	for my $name (@$names) {
		next if $NOT_A_KEY{$name};
		next if $declared{$name};

		# The name pattern comes first, because a name that no
		# block names and that no pattern matches is one fault
		# and not two.
		unless ( $self->{keydir}->parse_name($name) ) {
			push @problems, "$dir/$name: " . $self->{keydir}->error;
			next;
		}

		push @problems, "$dir/$name: no key block names it";
	}

	return @problems;
}

# $self->_manifest_problems($keys):
#	The manifest names every key file, with the digest that the
#	file has, and it names nothing else. A digest that disagrees
#	with its file is the fault that the tier of scripts/deps rests
#	on.
#	The check therefore reads the bytes, and never the size or the
#	time.
sub _manifest_problems ( $self, $keys )
{
	my $config = $self->{config};
	my $dir    = $config->keys_dir;
	my $path   = $config->keys_path(MANIFEST);

	my $bytes = Fugu::File->read($path);
	return "$dir/" . MANIFEST . ': cannot read it'
	    unless defined $bytes;

	# The parser is the one of the consumer install, so the site
	# and the install can never disagree about a line. The object
	# needs a key file, and it runs no command for a parse.
	my $signify = Fugu::Signify->new(
		keys => [ map { $config->keys_path( $_->{name} ) } @$keys ] );

	my $digest = $signify->parse_manifest($bytes);
	return "$dir/" . MANIFEST . ': ' . $signify->error
	    unless $digest;

	my @problems;
	my %named;
	for my $key (@$keys) {
		my $name = $key->{name};
		$named{$name} = 1;

		my $recorded = $digest->{$name};
		unless ( defined $recorded ) {
			push @problems,
			    "$dir/" . MANIFEST . ": it does not name $name";
			next;
		}

		my $found = _digest_of( $config->keys_path($name) );
		unless ( defined $found ) {
			push @problems, "$dir/$name: cannot read it";
			next;
		}

		next if $found eq $recorded;
		push @problems,
		    "$dir/$name: the manifest records $recorded,"
		    . " and the file digests to $found";
	}

	push @problems,
	      "$dir/"
	    . MANIFEST
	    . ": it names $_, which is"
	    . ' not a key of the description'
	    for grep { !$named{$_} } sort keys %$digest;

	return @problems;
}

# $self->_signature_problems:
#	What the signature of the manifest is not true of. The
#	consumer install reads these bytes with signify(1), and a file
#	of another shape fails there and never here.
sub _signature_problems ($self)
{
	my $config = $self->{config};
	my $dir    = $config->keys_dir;

	my $bytes = Fugu::File->read( $config->keys_path(SIGNATURE) );
	return "$dir/" . SIGNATURE . ': cannot read it'
	    unless defined $bytes;

	my $why = _signature_problem($bytes);

	return defined $why ? "$dir/" . SIGNATURE . ": $why" : ();
}

# $self->_fingerprint_problems($set):
#	The declared fingerprint of an OpenPGP key equals the one that
#	its armored body gives. A key block that declares none is not
#	a fault. The fingerprint is a convenience for a reader, and
#	the digest of the manifest is what binds the bytes.
sub _fingerprint_problems ( $self, $set )
{
	my $dir = $self->{config}->keys_dir;

	my @problems;
	for my $key (@$set) {
		next unless $key->{type} eq 'openpgp';
		next unless defined $key->{fingerprint};

		my ( $binary, $why ) =
		    Fugu::OpenPGP->decode_armor( $key->{armor} );
		unless ( defined $binary ) {
			push @problems, "$dir/$key->{name}: $why";
			next;
		}

		my ( $found, $reason ) = Fugu::OpenPGP->fingerprint($binary);
		unless ( defined $found ) {
			push @problems, "$dir/$key->{name}: $reason";
			next;
		}

		next if $found eq $key->{fingerprint};
		push @problems,
		    "$dir/$key->{name}: the description declares"
		    . " $key->{fingerprint}, and the key gives $found";
	}

	return @problems;
}

# $self->_index_page($rows):
#	The human page of the directory, as a whole HTML document. The
#	page carries the chrome of the site. It sits one directory
#	below the root, so every link of the chrome takes the step
#	back.
sub _index_page ( $self, $rows )
{
	my $page = App::FuguWeb::Page->new(
		config => $self->{config},
		base   => '../'
	);

	return $page->document( 'Keys', _index_body($rows) );
}

# $self->_policy:
#	The policy file of the Web Key Directory. The file carries no
#	flag, and the draft of the service reads a line that starts
#	with a number sign as a comment. An empty file would pass no
#	check of the site that tells a written file from a missing
#	one.
sub _policy ($self)
{
	return
	      '# The Web Key Directory of '
	    . $self->{config}->keys_org
	    . ". It sets no policy flag.\n";
}

# $self->_security_txt($set):
#	The text of security.txt. The Encryption field points at the
#	current OpenPGP key. A site that publishes no such key, or
#	that names no url, writes no such field.
sub _security_txt ( $self, $ordered )
{
	my $config = $self->{config};

	# The first current OpenPGP key of the publication order. A
	# site with two OpenPGP purposes names the newest current key
	# of them, because the order sorts the serial down inside one
	# status.
	my $encryption;
	my $url = $config->keys_url;
	if ( defined $url ) {
		my ($current) =
		    grep {
			       $_->{type} eq 'openpgp'
			    && $_->{status} eq 'current'
		    } @$ordered;
		$encryption = "$url/$current->{name}" if $current;
	}

	my $text = $self->{keydir}->security_txt(
		contact    => $config->keys_contact,
		expires    => $config->keys_expires,
		encryption => $encryption
	);

	return defined $text ? $text : $self->_fail( $self->{keydir}->error );
}

# $self->_in_dir($name):
#	The path of one name of the key directory, relative to the
#	output directory.
sub _in_dir ( $self, $name )
{
	return $self->{config}->keys_dir . "/$name";
}

# $self->_armored(@keys):
#	Report whether the set holds an OpenPGP key. The KEYS file
#	holds those keys only, so a set with none writes no such file
#	and the inventory names none.
sub _armored ( $self, @keys )
{
	return scalar grep { $_->{type} eq 'openpgp' } @keys;
}

# $self->_published(@keys):
#	Every OpenPGP key that the Web Key Directory serves. A key
#	with no email address has no address to answer for, so the
#	directory holds no file for it.
#
#	An address whose keys are all retired serves nothing. gpg
#	--locate-keys reads the file to encrypt a message, and a
#	retired key is the one key that must not answer that. A
#	retired key beside a current one still serves, because the
#	current key leads the file.
sub _published ( $self, @keys )
{
	my @named =
	    grep { $_->{type} eq 'openpgp' && defined $_->{email} } @keys;

	my %live;
	for my $key (@named) {
		$live{ $key->{wkd} } = 1 if $key->{status} ne 'retired';
	}

	return grep { $live{ $_->{wkd} } } @named;
}

# _signify_problem($bytes):
#	The reason that a file is not a signify public key, or undef
#	when it is one.
#
#	The extension of a key file gives its type, so a name that
#	ends in .pub is a signify key by its name alone. Nothing else
#	reads those bytes: the guards of Fugu::KeyDir hold an OpenPGP
#	key and skip every other type. A file of any content would
#	therefore publish under that name, a private key of any kind
#	included.
#
#	A signify public key holds two lines. The first line starts
#	with 'untrusted comment: ', which signify(1) needs. The second
#	line is the key body: 42 bytes in base64, and the first two
#	bytes spell Ed.
sub _signify_problem ($bytes)
{
	my @line = split /\n/, $bytes, -1;
	pop @line if @line && $line[-1] eq '';

	unless ( @line == 2 ) {
		return
		      'it holds '
		    . scalar(@line)
		    . ' lines, and a signify public key holds 2';
	}

	unless ( $line[0] =~ /\Auntrusted comment: / ) {
		return 'the first line is no untrusted comment line';
	}

	unless ( $line[1] =~ m{\A[A-Za-z0-9+/]{56}\z} ) {
		return 'the key body is not 56 base64 characters';
	}

	my $raw = MIME::Base64::decode_base64( $line[1] );
	unless ( length($raw) == 42 ) {
		return
		      'the key body decodes to '
		    . length($raw)
		    . ' bytes, and a signify key holds 42';
	}

	unless ( substr( $raw, 0, 2 ) eq 'Ed' ) {
		return 'the key body names no signify algorithm';
	}

	return;
}

# _signature_problem($bytes):
#	The reason that a file is not a signify signature, or undef
#	when it is one.
#
#	The build copies the signature as it stands, and it verifies
#	nothing: a site that verified its own manifest would prove
#	nothing. A file of any content would therefore publish under
#	the name that every consumer install reads.
#
#	A signify signature holds two lines. The first line starts
#	with 'untrusted comment: ', which signify(1) needs. The second
#	line is the signature body: 100 base64 characters, which
#	decode to 74 bytes whose first two bytes spell Ed.
sub _signature_problem ($bytes)
{
	my @line = split /\n/, $bytes, -1;
	pop @line if @line && $line[-1] eq '';

	unless ( @line == 2 ) {
		return
		      'it holds '
		    . scalar(@line)
		    . ' lines, and a signify signature holds 2';
	}

	unless ( $line[0] =~ /\Auntrusted comment: / ) {
		return 'the first line is no untrusted comment line';
	}

	# 99 characters and one pad always decode to 74 bytes, so the
	# length needs no second test. A key body needs one, because
	# 56 characters carry no pad and decode to 42.
	unless ( $line[1] =~ m{\A[A-Za-z0-9+/]{99}=\z} ) {
		return 'the signature body is not 100 base64 characters';
	}

	my $raw = MIME::Base64::decode_base64( $line[1] );
	unless ( substr( $raw, 0, 2 ) eq 'Ed' ) {
		return 'the signature body names no signify algorithm';
	}

	return;
}

# _addresses(@keys):
#	The Web Key Directory hash of each key, once for each hash, in
#	the order that the keys arrive. Two keys of one address share
#	one published path.
sub _addresses (@keys)
{
	my %seen;

	return grep { !$seen{$_}++ } map { $_->{wkd} } @keys;
}

# $self->_fail($reason):
#	Record the reason and return undef, so each public method
#	fails the same way.
sub _fail ( $self, $reason )
{
	$self->{error} = $reason;

	return;
}

# _index_body($rows):
#	The body fragment of the human page: one row for each key, in
#	publication order. Every value is escaped, and a value that
#	the description left out becomes an empty cell.
sub _index_body ($rows)
{
	my @head = (
		'Key',    'Purpose',     'Serial', 'Type',
		'Status', 'Fingerprint', 'Since',  'Until'
	);

	my $html = "<h1>Keys</h1>\n<table>\n<thead>\n<tr>";
	$html .= "<th>$_</th>" for @head;
	$html .= "</tr>\n</thead>\n<tbody>\n";

	for my $row (@$rows) {
		my $href = App::FuguWeb::escape_attr( $row->{name} );
		my $stem = App::FuguWeb::escape_html( $row->{stem} );

		$html .= qq{<tr><td><a href="$href">$stem</a></td>};
		$html .= '<td>' . _cell( $row->{$_} ) . '</td>'
		    for qw(purpose serial type status fingerprint since until);
		$html .= "</tr>\n";
	}

	return $html . "</tbody>\n</table>\n";
}

# _cell($value):
#	One table cell. A value that the description left out becomes
#	an empty cell, so a template tests one thing and the row keeps
#	its column count.
sub _cell ($value)
{
	return defined $value ? App::FuguWeb::escape_html($value) : '';
}

# _digest_of($path):
#	The lowercase hex SHA256 digest of the file, or undef when the
#	file does not open. addfile reads in blocks, so the check
#	never holds a whole key set in memory.
sub _digest_of ($path)
{
	open my $fh, '<', $path or return;
	binmode $fh;

	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return lc $sha->hexdigest;
}

1;

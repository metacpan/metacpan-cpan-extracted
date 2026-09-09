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

package App::FuguVM::Mirror;
our $VERSION = '0.2.0';

use Fugu::File;
use Fugu::Log;
use Fugu::Process;
use Fugu::Signify;

# App::FuguVM::Mirror - the OpenBSD mirror of one guest.
#
# The module is the one home of the mirror facts: the host, the URLs
# of a version and an architecture, the download helper, the release
# key, and the verification. Fugu::Signify proves the signed SHA256
# manifest, and this module decides which manifest signs which file.
#
# A file must verify before it enters the cache, because the cache is
# what a later run reads. A verification failure therefore leaves no
# file in the cache.

# The host of the two scopes. No consumer asks for a second release
# host, and a second one would multiply the trees under cache_dir.
# The distfile tree is not a scope of this module: the guest fetches
# a distfile itself, from a mirror host that carries the tree.
use constant { CDN_HOST => 'cdn.openbsd.org', };

# The share directory of the release keys. The commit that adds a key
# is a trust decision, so a human adds each file.
use constant { KEYS_SHARE_DIR => 'share/fuguvm/signify', };

# $class->new(%args):
#	Build the mirror of one version and one architecture.
#
#	%args:
#		cache    => $cache  # Required: an App::FuguVM::Proxy::Cache
#		version  => '7.8'   # Required: the OpenBSD version
#		arch     => 'arm64' # Required: the architecture name
#		keys_dir => $dir    # Optional: the signify_dir directive
#		verify   => 1       # Optional: the default is 1
#
#	The method dies when cache, version or arch is absent. Each
#	one is a programming error.
sub new ( $class, %args )
{
	for my $required (qw(cache version arch)) {
		die "App::FuguVM::Mirror needs $required\n"
		    if !defined $args{$required};
	}

	return bless {
		cache    => $args{cache},
		version  => $args{version},
		arch     => $args{arch},
		keys_dir => $args{keys_dir},
		verify   => $args{verify} // 1,
		manifest => {},
		error    => undef,
	}, $class;
}

# $self->version:
#	Return the OpenBSD version of this mirror. The mirror is the
#	one home of the version, so a consumer asks it and holds no
#	copy.
sub version ($self)
{
	return $self->{version};
}

# $self->url($file):
#	Return the URL of a file of the architecture directory.
sub url ( $self, $file )
{
	return 'https://' . CDN_HOST
	    . "/pub/OpenBSD/$self->{version}/$self->{arch}/$file";
}

# $self->source_url($file):
#	Return the URL of a file of the version directory. The source
#	tarballs and their manifest live there.
sub source_url ( $self, $file )
{
	return 'https://' . CDN_HOST . "/pub/OpenBSD/$self->{version}/$file";
}

# $self->error:
#	Return the reason of the most recent failure, or undef. Every
#	public method clears the reason before it starts.
sub error ($self)
{
	return $self->{error};
}

# $self->key_path:
#	Return the public key file of the version, or undef with the
#	reason in error. The version names the file: 7.8 gives
#	openbsd-78-base.pub. The resolution order is the keys_dir
#	argument, then /etc/signify, then the share tree. An OpenBSD
#	host holds the authentic key from its own installation, which
#	is a better anchor than a copy in a repository.
sub key_path ($self)
{
	$self->{error} = undef;

	( my $short = $self->{version} ) =~ s/\.//g;
	my $file = "openbsd-$short-base.pub";

	my @tried;
	for my $dir ( $self->{keys_dir}, '/etc/signify' ) {
		next if !defined $dir;
		push @tried, $dir;
		my $path = "$dir/$file";
		return $path if -f $path;
	}

	my $shared = Fugu::File->share_path(
		KEYS_SHARE_DIR . "/$file",
		from => __FILE__,
		dist => 'App-FuguVM'
	);
	return $shared if defined $shared;

	push @tried, KEYS_SHARE_DIR;
	$self->{error} = "no public key $file in " . join( ', ', @tried );

	return;
}

# $self->fetch($url):
#	Download the URL to a temporary file with the scripts/ftp
#	helper. Return the File::Temp object, or undef with the reason
#	in error. This method is the one home of the helper call.
sub fetch ( $self, $url )
{
	$self->{error} = undef;

	my $ftp = Fugu::File->share_path(
		'scripts/ftp',
		from => __FILE__,
		dist => 'App-FuguVM'
	);
	if ( !defined $ftp ) {
		$self->{error} = 'cannot find the ftp helper';
		return;
	}

	require File::Temp;
	my $tmp = File::Temp->new;

	# The helper writes its progress as it goes, and a download of
	# a hundred megabytes is a wait that an operator wants to see.
	# sh runs the helper: an installed share tree does not keep the
	# exec bit.
	my $result = Fugu::Process->run(
		cmd         => [ 'sh', $ftp, $tmp->filename, $url ],
		passthrough => 1,
	);
	if ( !$result->{success} ) {
		$self->{error} = "download failed: $url ("
		    . ( $result->{error} // "exit $result->{exit_code}" ) . ')';
		return;
	}

	if ( !-s $tmp->filename ) {
		$self->{error} = "download wrote no bytes: $url";
		return;
	}

	return $tmp;
}

# $self->manifest($scope):
#	Make sure that the SHA256 and the SHA256.sig of the scope are
#	cached, and prove the signature under the release key. Return
#	the cached manifest path, or undef with the reason in error.
#	The scope is 'release' for the architecture directory and
#	'source' for the version directory. The module caches the
#	proven path for the length of the object.
sub manifest ( $self, $scope )
{
	$self->{error} = undef;

	return $self->{manifest}{$scope}
	    if defined $self->{manifest}{$scope};

	if ( !$self->{verify} ) {
		$self->{error} =
		    'verification is off, so no manifest is proven';
		return;
	}

	my $key = $self->key_path;
	return if !defined $key;

	my $manifest = $self->_cached_manifest($scope);
	return if !defined $manifest;
	my $signature = $self->_ensure_unverified( $scope, 'SHA256.sig' );
	return if !defined $signature;

	my $signify = $self->_signify($key);
	if ( !defined $signify->verify( $manifest, $signature ) ) {
		$self->{error} = $self->_signify_error($signify);
		return;
	}

	$self->{manifest}{$scope} = $manifest;

	return $manifest;
}

# $self->manifest_names($scope):
#	Return the file names that the manifest of the scope holds, as
#	a sorted array reference, or undef with the reason in error.
#	With verification on, the names come from the proven manifest.
#	With verification off, the manifest is a routing table only,
#	and the method reads it without a proof.
sub manifest_names ( $self, $scope )
{
	$self->{error} = undef;

	my $digests = $self->_manifest_digests($scope);
	return if !defined $digests;

	return [ sort keys %$digests ];
}

# $self->_manifest_digests($scope):
#	Return the name-to-digest map of the manifest of the scope, or
#	undef with the reason in error. With verification on, the map
#	comes from the proven manifest.
#
#	The parser accepts a duplicate line whose digest is identical:
#	the real SHA256 of an OpenBSD release directory repeats the
#	install image lines, and a repeated identical fact changes
#	nothing. Fugu LIB-SIGNIFY refuses such a manifest whole, so
#	this module checks each digest itself, under the signature
#	that the manifest proof made. A duplicate name with a
#	different digest is a broken manifest, and the parser refuses
#	it, like a line that does not parse.
sub _manifest_digests ( $self, $scope )
{
	my $manifest =
	      $self->{verify}
	    ? $self->manifest($scope)
	    : $self->_cached_manifest($scope);
	return if !defined $manifest;

	my $bytes = Fugu::File->read($manifest);
	if ( !defined $bytes ) {
		$self->{error} = "cannot read $manifest";
		return;
	}

	my %digest;
	for my $line ( split /\n/, $bytes ) {
		my ( $name, $hex ) =
		    $line =~ /^SHA256 \((.+)\) = ([0-9A-Fa-f]{64})$/;
		if ( !defined $name ) {
			$self->{error} =
			    "$manifest: cannot parse manifest line: $line";
			return;
		}
		$hex = lc $hex;
		if ( exists $digest{$name} && $digest{$name} ne $hex ) {
			$self->{error} = "$manifest: duplicate name $name"
			    . ' with two digests';
			return;
		}
		$digest{$name} = $hex;
	}

	if ( !%digest ) {
		$self->{error} = "$manifest: the manifest is empty";
		return;
	}

	return \%digest;
}

# $self->verify_file($scope, $name, $path):
#	Verify one local file against the proven manifest of the
#	scope, under its manifest name. Return 1, or undef with the
#	reason in error. The manifest proof runs the signature check;
#	the digest check runs here, so a manifest with a repeated
#	identical line still verifies.
sub verify_file ( $self, $scope, $name, $path )
{
	$self->{error} = undef;

	if ( !$self->{verify} ) {
		$self->{error} = 'verification is off, so no proof is made';
		return;
	}

	my $digests = $self->_manifest_digests($scope);
	return if !defined $digests;

	my $expected = $digests->{$name};
	if ( !defined $expected ) {
		$self->{error} =
		    "the manifest of the $scope scope does not hold $name";
		return;
	}

	my $computed = _digest($path);
	if ( !defined $computed ) {
		$self->{error} = "cannot digest $path";
		return;
	}

	if ( $computed ne $expected ) {
		$self->{error} = "$name: digest mismatch:"
		    . " expected $expected, computed $computed";
		return;
	}

	return 1;
}

# _digest($path):
#	The lowercase hex SHA256 digest of a file, or undef when the
#	file does not open. addfile reads in blocks, so a file set of
#	hundreds of megabytes never enters memory whole.
sub _digest ($path)
{
	require Digest::SHA;

	open my $fh, '<', $path or return;
	binmode $fh;

	my $sha = Digest::SHA->new(256);
	$sha->addfile($fh);
	close $fh;

	return lc $sha->hexdigest;
}

# $self->ensure($scope, $file):
#	Return the cached path of a file of the scope. On a cache
#	miss, prove the manifest, fetch the file, verify it, and store
#	it. Return undef with the reason in error on any failure. The
#	file verifies before it enters the cache, so a verification
#	failure leaves no file in the cache.
sub ensure ( $self, $scope, $file )
{
	$self->{error} = undef;

	my $url    = $self->_scope_url( $scope, $file );
	my $cached = $self->{cache}->lookup($url);
	return $cached if defined $cached;

	if ( !$self->{verify} ) {
		Fugu::Log->default->warning(
			'Verification is off: %s enters the cache unproven',
			$file );
	}
	else {
		return if !defined $self->manifest($scope);
	}

	my $tmp = $self->fetch($url);
	return if !defined $tmp;

	if ( $self->{verify} ) {
		return
		    if !
		    defined $self->verify_file( $scope, $file, $tmp->filename );
	}

	my $path = $self->{cache}->store_from_file( $url, $tmp->filename );
	if ( !defined $path ) {
		$self->{error} = "cannot store $file in the cache";
		return;
	}

	return $path;
}

# $self->verify_cache:
#	Verify every cached file of the two scopes. Return
#	{ ok, failed, unknown }, each one a list of { scope, name }
#	entries sorted by name, or undef with the reason in error.
#
#	A cached file that the proven manifest of its scope names is
#	ok or failed. A cached file that no proven manifest names is
#	unknown: index.txt, a package, and every file of a scope whose
#	manifest is absent or unproven, are all in that class. The
#	method never skips a cached file. The SHA256 and SHA256.sig
#	pairs stay out of the three lists while their proof holds,
#	because that proof covers them.
#
#	A cached manifest pair that fails its own proof is a failure:
#	the method removes the pair and reports its SHA256 under
#	failed, so a poisoned pair cannot pin every later run. A pair
#	that the method cannot fetch leaves the files of its scope
#	unknown.
#
#	The manifest proof makes one signify(1) run for each scope,
#	and each digest check runs in this module, so a tree of a
#	hundred files costs one signify(1) run for each scope.
sub verify_cache ($self)
{
	$self->{error} = undef;

	my %report = ( ok => [], failed => [], unknown => [] );

	for my $scope (qw(release source)) {
		my @entries =
		    grep { $_->[0] ne 'SHA256' && $_->[0] ne 'SHA256.sig' }
		    @{ $self->_scope_files($scope) };
		my $cached_manifest = $self->{cache}
		    ->lookup( $self->_scope_url( $scope, 'SHA256' ) );
		next if !@entries && !defined $cached_manifest;

		my $manifest = $self->manifest($scope);
		if ( !defined $manifest ) {
			my $reason = $self->{error};

			# A key that does not resolve proves nothing,
			# and nothing failed a proof. Stop.
			return if !defined $self->key_path;
			$self->{error} = $reason;

			# A cached pair that failed its proof must not
			# stay: it would pin every later run.
			if ( defined $cached_manifest ) {
				unlink $cached_manifest;
				my $sig = $self->{cache}->cache_path(
					$self->_scope_url(
						$scope, 'SHA256.sig'
					) );
				unlink $sig if defined $sig && -f $sig;
				push @{ $report{failed} },
				    { scope => $scope, name => 'SHA256' };
			}

			# No proven manifest names these files.
			push @{ $report{unknown} },
			    map { { scope => $scope, name => $_->[0] } }
			    @entries;
			next;
		}

		my $digests = $self->_manifest_digests($scope);
		return if !defined $digests;

		# The manifest proof above ran the one signify(1) call
		# of the scope. Each digest check runs here.
		for my $entry (@entries) {
			my ( $name, $path ) = @$entry;
			my $expected = $digests->{$name};
			if ( !defined $expected ) {
				push @{ $report{unknown} },
				    { scope => $scope, name => $name };
				next;
			}

			my $computed = _digest($path);
			my $state =
			    defined $computed && $computed eq $expected
			    ? 'ok'
			    : 'failed';
			push @{ $report{$state} },
			    { scope => $scope, name => $name };
		}
	}

	@{ $report{$_} } = sort { $a->{name} cmp $b->{name} } @{ $report{$_} }
	    for keys %report;

	# The removal above is a report, not a failure of this method.
	$self->{error} = undef;

	return \%report;
}

# $self->cached_path($scope, $file):
#	Return the cache path of a file of the scope, cached or not.
#	The verify verb of the tool removes a failed file through this
#	answer.
sub cached_path ( $self, $scope, $file )
{
	return $self->{cache}->cache_path( $self->_scope_url( $scope, $file ) );
}

# $self->_scope_url($scope, $file):
#	Return the URL of a file of the scope. An unknown scope is a
#	programming error.
sub _scope_url ( $self, $scope, $file )
{
	return $self->url($file)        if $scope eq 'release';
	return $self->source_url($file) if $scope eq 'source';

	die "unknown mirror scope: $scope\n";
}

# $self->_scope_files($scope):
#	Return every cached file of the scope directory, as
#	[ [ $name, $path ], ... ]. The release scope reads the
#	architecture directory, and the source scope reads the files
#	directly under the version directory.
sub _scope_files ( $self, $scope )
{
	my $dir = $self->cached_path( $scope, '' );
	$dir =~ s{/\z}{};

	my @files;
	return \@files if !-d $dir;

	opendir my $dh, $dir or return \@files;
	my @names = sort grep { -f "$dir/$_" } readdir $dh;
	closedir $dh;

	@files = map { [ $_, "$dir/$_" ] } @names;

	return \@files;
}

# $self->_cached_manifest($scope):
#	Return the cached SHA256 of the scope, and fetch it first when
#	the cache misses. The manifest needs no proof of its own to
#	enter the cache: its signature proves it on every read.
sub _cached_manifest ( $self, $scope )
{
	return $self->_ensure_unverified( $scope, 'SHA256' );
}

# $self->_ensure_unverified($scope, $file):
#	Return the cached path of a manifest file, and fetch it first
#	when the cache misses. Only the SHA256 pair takes this path:
#	the signature check proves both, so a store before the proof
#	is safe.
sub _ensure_unverified ( $self, $scope, $file )
{
	my $url    = $self->_scope_url( $scope, $file );
	my $cached = $self->{cache}->lookup($url);
	return $cached if defined $cached;

	my $tmp = $self->fetch($url);
	return if !defined $tmp;

	my $path = $self->{cache}->store_from_file( $url, $tmp->filename );
	if ( !defined $path ) {
		$self->{error} = "cannot store $file in the cache";
		return;
	}

	return $path;
}

# $self->_signify($key):
#	Build the verifier over the one release key. The release
#	directory of a numbered release carries one signature, under
#	the base key of that release, so a second key would accept a
#	file that the version does not own.
sub _signify ( $self, $key )
{
	return Fugu::Signify->new( keys => [$key] );
}

# $self->_signify_error($signify):
#	Return the reason of a failed signify call. An absent command
#	is an install problem, so that reason also names the packages.
sub _signify_error ( $self, $signify )
{
	my $reason = $signify->error // 'signify failed';
	$reason .=
	      ' (install the package signify-openbsd on Linux,'
	    . ' or signify-osx on Darwin)'
	    if $signify->command_absent;

	return $reason;
}

1;

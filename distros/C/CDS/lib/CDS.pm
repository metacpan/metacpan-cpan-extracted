# This is part of the Condensation Perl Module 0.25 (cli) built on 2022-02-05.
# See https://condensation.io for information about the Condensation Data System.

use strict;
use warnings;
use 5.010000;
use CDS::C;

use Cwd;
use Digest::SHA;
use Encode;
use Fcntl;
use HTTP::Date;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Server::Simple;
use LWP::UserAgent;
use Time::Local;
use utf8;
package CDS;

our $VERSION = '0.25';
our $edition = 'cli';
our $releaseDate = '2022-02-05';

sub now { time * 1000 }

sub SECOND { 1000 }
sub MINUTE { 60 * 1000 }
sub HOUR { 60 * 60 * 1000 }
sub DAY { 24 * 60 * 60 * 1000 }
sub WEEK { 7 * 24 * 60 * 60 * 1000 }
sub MONTH { 30 * 24 * 60 * 60 * 1000 }
sub YEAR { 365 * 24 * 60 * 60 * 1000 }

# File system utility functions.

sub readBytesFromFile {
	my $class = shift;
	my $filename = shift;

	open(my $fh, '<:bytes', $filename) || return;
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub writeBytesToFile {
	my $class = shift;
	my $filename = shift;

	open(my $fh, '>:bytes', $filename) || return;
	print $fh @_;
	close $fh;
	return 1;
}

sub readTextFromFile {
	my $class = shift;
	my $filename = shift;

	open(my $fh, '<:utf8', $filename) || return;
	local $/;
	my $content = <$fh>;
	close $fh;
	return $content;
}

sub writeTextToFile {
	my $class = shift;
	my $filename = shift;

	open(my $fh, '>:utf8', $filename) || return;
	print $fh @_;
	close $fh;
	return 1;
}

sub listFolder {
	my $class = shift;
	my $folder = shift;

	opendir(my $dh, $folder) || return;
	my @files = readdir $dh;
	closedir $dh;
	return @files;
}

sub intermediateFolders {
	my $class = shift;
	my $path = shift;

	my @paths = ($path);
	while (1) {
		$path =~ /^(.+)\/(.*?)$/ || last;
		$path = $1;
		next if ! length $2;
		unshift @paths, $path;
	}
	return @paths;
}

# This is for debugging purposes only.
sub log {
	my $class = shift;

	print STDERR @_, "\n";
}

sub min {
	my $class = shift;

	my $min = shift;
	for my $number (@_) {
		$min = $min < $number ? $min : $number;
	}

	return $min;
}

sub max {
	my $class = shift;

	my $max = shift;
	for my $number (@_) {
		$max = $max > $number ? $max : $number;
	}

	return $max;
}

sub booleanCompare {
	my $class = shift;
	my $a = shift;
	my $b = shift;
	 $a && $b ? 0 : $a ? 1 : $b ? -1 : 0 }

# Utility functions for random sequences

srand(time);
our @hexDigits = ('0'..'9', 'a'..'f');

sub randomHex {
	my $class = shift;
	my $length = shift;

	return substr(unpack('H*', CDS::C::randomBytes(int(($length + 1) / 2))), 0, $length);
}

sub randomBytes {
	my $class = shift;
	my $length = shift;

	return CDS::C::randomBytes($length);
}

sub randomKey {
	my $class = shift;

	return CDS::C::randomBytes(32);
}

sub version { 'Condensation, Perl, '.$CDS::VERSION }

# Conversion of numbers and booleans to and from bytes.
# To convert text, use Encode::encode_utf8($text) and Encode::decode_utf8($bytes).
# To convert hex sequences, use pack('H*', $hex) and unpack('H*', $bytes).

sub bytesFromBoolean {
	my $class = shift;
	my $value = shift;
	 $value ? 'y' : '' }

sub bytesFromInteger {
	my $class = shift;
	my $value = shift;

	return '' if $value >= 0 && $value < 1;
	return pack 'c', $value if $value >= -0x80 && $value < 0x80;
	return pack 's>', $value if $value >= -0x8000 && $value < 0x8000;

	# This works up to 63 bits, plus 1 sign bit
	my $bytes = pack 'q>', $value;

	my $pos = 0;
	my $first = ord(substr($bytes, 0, 1));
	if ($value > 0) {
		# Perl internally uses an unsigned 64-bit integer if the value is positive
		return "\x7f\xff\xff\xff\xff\xff\xff\xff" if $first >= 128;
		while ($first == 0) {
			my $next = ord(substr($bytes, $pos + 1, 1));
			last if $next >= 128;
			$first = $next;
			$pos += 1;
		}
	} elsif ($first == 255) {
		while ($first == 255) {
			my $next = ord(substr($bytes, $pos + 1, 1));
			last if $next < 128;
			$first = $next;
			$pos += 1;
		}
	}

	return substr($bytes, $pos);
}

sub bytesFromUnsigned {
	my $class = shift;
	my $value = shift;

	return '' if $value < 1;
	return pack 'C', $value if $value < 0x100;
	return pack 'S>', $value if $value < 0x10000;

	# This works up to 64 bits
	my $bytes = pack 'Q>', $value;
	my $pos = 0;
	$pos += 1 while substr($bytes, $pos, 1) eq "\0";
	return substr($bytes, $pos);
}

sub bytesFromFloat32 {
	my $class = shift;
	my $value = shift;
	 pack('f', $value) }
sub bytesFromFloat64 {
	my $class = shift;
	my $value = shift;
	 pack('d', $value) }

sub booleanFromBytes {
	my $class = shift;
	my $bytes = shift;

	return length $bytes > 0;
}

sub integerFromBytes {
	my $class = shift;
	my $bytes = shift;

	return 0 if ! length $bytes;
	my $value = unpack('C', substr($bytes, 0, 1));
	$value -= 0x100 if $value & 0x80;
	for my $i (1 .. length($bytes) - 1) {
		$value *= 256;
		$value += unpack('C', substr($bytes, $i, 1));
	}
	return $value;
}

sub unsignedFromBytes {
	my $class = shift;
	my $bytes = shift;

	my $value = 0;
	for my $i (0 .. length($bytes) - 1) {
		$value *= 256;
		$value += unpack('C', substr($bytes, $i, 1));
	}
	return $value;
}

sub floatFromBytes {
	my $class = shift;
	my $bytes = shift;

	return unpack('f', $bytes) if length $bytes == 4;
	return unpack('d', $bytes) if length $bytes == 8;
	return undef;
}

# Initial counter value for AES in CTR mode
sub zeroCTR { "\0" x 16 }

my $emptyBytesHash = CDS::Hash->fromHex('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
sub emptyBytesHash { $emptyBytesHash }

# Checks if a box label is valid.
sub isValidBoxLabel {
	my $class = shift;
	my $label = shift;
	 $label eq 'messages' || $label eq 'private' || $label eq 'public' }

# Groups box additions or removals by account hash and box label.
sub groupedBoxOperations {
	my $class = shift;
	my $operations = shift;

	my %byAccountHash;
	for my $operation (@$operations) {
		my $accountHashBytes = $operation->{accountHash}->bytes;
		$byAccountHash{$accountHashBytes} = {accountHash => $operation->{accountHash}, byBoxLabel => {}} if ! exists $byAccountHash{$accountHashBytes};
		my $byBoxLabel = $byAccountHash{$accountHashBytes}->{byBoxLabel};
		my $boxLabel = $operation->{boxLabel};
		$byBoxLabel->{$boxLabel} = [] if ! exists $byBoxLabel->{$boxLabel};
		push @{$byBoxLabel->{$boxLabel}}, $operation;
	}

	return values %byAccountHash;
}

### Open envelopes ###

sub verifyEnvelopeSignature {
	my $class = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	# Read the signature
	my $signature = $envelope->child('signature')->bytesValue;
	return if length $signature < 1;

	# Verify the signature
	return if ! $publicKey->verifyHash($hash, $signature);
	return 1;
}

# The result of parsing an ACCOUNT token (see Token.pm).
package CDS::AccountToken;

sub new {
	my $class = shift;
	my $cliStore = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	return bless {
		cliStore => $cliStore,
		actorHash => $actorHash,
		};
}

sub cliStore { shift->{cliStore} }
sub actorHash { shift->{actorHash} }
sub url {
	my $o = shift;
	 $o->{cliStore}->url.'/accounts/'.$o->{actorHash}->hex }

package CDS::ActorGroup;

# Members must be sorted in descending revision order, such that the member with the most recent revision is first. Members must not include any revoked actors.
sub new {
	my $class = shift;
	my $members = shift;
	my $entrustedActorsRevision = shift;
	my $entrustedActors = shift;

	# Create the cache for the "contains" method
	my $containCache = {};
	for my $member (@$members) {
		$containCache->{$member->actorOnStore->publicKey->hash->bytes} = 1;
	}

	return bless {
		members => $members,
		entrustedActorsRevision => $entrustedActorsRevision,
		entrustedActors => $entrustedActors,
		containsCache => $containCache,
		};
}

sub members {
	my $o = shift;
	 @{$o->{members}} }
sub entrustedActorsRevision { shift->{entrustedActorsRevision} }
sub entrustedActors {
	my $o = shift;
	 @{$o->{entrustedActors}} }

# Checks whether the actor group contains at least one active member.
sub isActive {
	my $o = shift;

	for my $member (@{$o->{members}}) {
		return 1 if $member->isActive;
	}
	return;
}

# Returns the most recent active member, the most recent idle member, or undef if the group is empty.
sub leader {
	my $o = shift;

	for my $member (@{$o->{members}}) {
		return $member if $member->isActive;
	}
	return $o->{members}->[0];
}

# Returns true if the account belongs to this actor group.
# Note that multiple (different) actor groups may claim that the account belongs to them. In practice, an account usually belongs to one actor group.
sub contains {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	return exists $o->{containsCache}->{$actorHash->bytes};
}

# Returns true if the account is entrusted by this actor group.
sub entrusts {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	for my $actor (@{$o->{entrustedActors}}) {
		return 1 if $actorHash->equals($actor->publicKey->hash);
	}
	return;
}

# Returns all public keys.
sub publicKeys {
	my $o = shift;

	my @publicKeys;
	for my $member (@{$o->{members}}) {
		push @publicKeys, $member->actorOnStore->publicKey;
	}
	for my $actor (@{$o->{entrustedActors}}) {
		push @publicKeys, $actor->actorOnStore->publicKey;
	}
	return @publicKeys;
}

# Returns an ActorGroupBuilder with all members and entrusted keys of this ActorGroup.
sub toBuilder {
	my $o = shift;

	my $builder = CDS::ActorGroupBuilder->new;
	$builder->mergeEntrustedActors($o->{entrustedActorsRevision});
	for my $member (@{$o->{members}}) {
		my $publicKey = $member->actorOnStore->publicKey;
		$builder->addKnownPublicKey($publicKey);
		$builder->addMember($publicKey->hash, $member->storeUrl, $member->revision, $member->isActive ? 'active' : 'idle');
	}
	for my $actor (@{$o->{entrustedActors}}) {
		my $publicKey = $actor->actorOnStore->publicKey;
		$builder->addKnownPublicKey($publicKey);
		$builder->addEntrustedActor($publicKey->hash, $actor->storeUrl);
	}
	return $builder;
}

package CDS::ActorGroup::EntrustedActor;

sub new {
	my $class = shift;
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $storeUrl = shift;

	return bless {
		actorOnStore => $actorOnStore,
		storeUrl => $storeUrl,
		};
}

sub actorOnStore { shift->{actorOnStore} }
sub storeUrl { shift->{storeUrl} }

package CDS::ActorGroup::Member;

sub new {
	my $class = shift;
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $storeUrl = shift;
	my $revision = shift;
	my $isActive = shift;

	return bless {
		actorOnStore => $actorOnStore,
		storeUrl => $storeUrl,
		revision => $revision,
		isActive => $isActive,
		};
}

sub actorOnStore { shift->{actorOnStore} }
sub storeUrl { shift->{storeUrl} }
sub revision { shift->{revision} }
sub isActive { shift->{isActive} }

package CDS::ActorGroupBuilder;

sub new {
	my $class = shift;

	return bless {
		knownPublicKeys => {},			# A hashref of known public keys (e.g. from the existing actor group)
		members => {},					# Members by URL
		entrustedActorsRevision => 0,	# Revision of the list of entrusted actors
		entrustedActors => {},			# Entrusted actors by hash
		};
}

sub members {
	my $o = shift;
	 values %{$o->{members}} }
sub entrustedActorsRevision { shift->{entrustedActorsRevision} }
sub entrustedActors {
	my $o = shift;
	 values %{$o->{entrustedActors}} }
sub knownPublicKeys { shift->{knownPublicKeys} }

sub addKnownPublicKey {
	my $o = shift;
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';

	$o->{publicKeys}->{$publicKey->hash->bytes} = $publicKey;
}

sub addMember {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $storeUrl = shift;
	my $revision = shift // 0;
	my $status = shift // 'active';

	my $url = $storeUrl.'/accounts/'.$hash->hex;
	my $member = $o->{members}->{$url};
	return if $member && $revision <= $member->revision;
	$o->{members}->{$url} = CDS::ActorGroupBuilder::Member->new($hash, $storeUrl, $revision, $status);
	return 1;
}

sub removeMember {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $storeUrl = shift;

	my $url = $storeUrl.'/accounts/'.$hash->hex;
	delete $o->{members}->{$url};
}

sub parseMembers {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $linkedPublicKeys = shift;

	die 'linked public keys?' if ! defined $linkedPublicKeys;
	for my $storeRecord ($record->children) {
		my $accountStoreUrl = $storeRecord->asText;

		for my $statusRecord ($storeRecord->children) {
			my $status = $statusRecord->bytes;

			for my $child ($statusRecord->children) {
				my $hash = $linkedPublicKeys ? $child->hash : CDS::Hash->fromBytes($child->bytes);
				$o->addMember($hash // next, $accountStoreUrl, $child->integerValue, $status);
			}
		}
	}
}

sub mergeEntrustedActors {
	my $o = shift;
	my $revision = shift;

	return if $revision <= $o->{entrustedActorsRevision};
	$o->{entrustedActorsRevision} = $revision;
	$o->{entrustedActors} = {};
	return 1;
}

sub addEntrustedActor {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $storeUrl = shift;

	my $actor = CDS::ActorGroupBuilder::EntrustedActor->new($hash, $storeUrl);
	$o->{entrustedActors}->{$hash->bytes} = $actor;
}

sub removeEntrustedActor {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	delete $o->{entrustedActors}->{$hash->bytes};
}

sub parseEntrustedActors {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $linkedPublicKeys = shift;

	for my $revisionRecord ($record->children) {
		next if ! $o->mergeEntrustedActors($revisionRecord->asInteger);
		$o->parseEntrustedActorList($revisionRecord, $linkedPublicKeys);
	}
}

sub parseEntrustedActorList {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $linkedPublicKeys = shift;

	die 'linked public keys?' if ! defined $linkedPublicKeys;
	for my $storeRecord ($record->children) {
		my $storeUrl = $storeRecord->asText;

		for my $child ($storeRecord->children) {
			my $hash = $linkedPublicKeys ? $child->hash : CDS::Hash->fromBytes($child->bytes);
			$o->addEntrustedActor($hash // next, $storeUrl);
		}
	}
}

sub parse {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $linkedPublicKeys = shift;

	$o->parseMembers($record->child('actor group'), $linkedPublicKeys);
	$o->parseEntrustedActors($record->child('entrusted actors'), $linkedPublicKeys);
}

sub load {
	my $o = shift;
	my $store = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $delegate = shift;

	return CDS::LoadActorGroup->load($o, $store, $keyPair, $delegate);
}

sub discover {
	my $o = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $delegate = shift;

	return CDS::DiscoverActorGroup->discover($o, $keyPair, $delegate);
}

# Serializes the actor group to a record that can be passed to parse.
sub addToRecord {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $linkedPublicKeys = shift;

	die 'linked public keys?' if ! defined $linkedPublicKeys;

	my $actorGroupRecord = $record->add('actor group');
	my $currentStoreUrl = undef;
	my $currentStoreRecord = undef;
	my $currentStatus = undef;
	my $currentStatusRecord = undef;
	for my $member (sort { $a->storeUrl cmp $b->storeUrl || CDS->booleanCompare($b->status, $a->status) } $o->members) {
		next if ! $member->revision;

		if (! defined $currentStoreUrl || $currentStoreUrl ne $member->storeUrl) {
			$currentStoreUrl = $member->storeUrl;
			$currentStoreRecord = $actorGroupRecord->addText($currentStoreUrl);
			$currentStatus = undef;
			$currentStatusRecord = undef;
		}

		if (! defined $currentStatus || $currentStatus ne $member->status) {
			$currentStatus = $member->status;
			$currentStatusRecord = $currentStoreRecord->add($currentStatus);
		}

		my $hashRecord = $linkedPublicKeys ? $currentStatusRecord->addHash($member->hash) : $currentStatusRecord->add($member->hash->bytes);
		$hashRecord->addInteger($member->revision);
	}

	if ($o->{entrustedActorsRevision}) {
		my $listRecord = $o->entrustedActorListToRecord($linkedPublicKeys);
		$record->add('entrusted actors')->addInteger($o->{entrustedActorsRevision})->addRecord($listRecord->children);
	}
}

sub toRecord {
	my $o = shift;
	my $linkedPublicKeys = shift;

	my $record = CDS::Record->new;
	$o->addToRecord($record, $linkedPublicKeys);
	return $record;
}

sub entrustedActorListToRecord {
	my $o = shift;
	my $linkedPublicKeys = shift;

	my $record = CDS::Record->new;
	my $currentStoreUrl = undef;
	my $currentStoreRecord = undef;
	for my $actor ($o->entrustedActors) {
		if (! defined $currentStoreUrl || $currentStoreUrl ne $actor->storeUrl) {
			$currentStoreUrl = $actor->storeUrl;
			$currentStoreRecord = $record->addText($currentStoreUrl);
		}

		$linkedPublicKeys ? $currentStoreRecord->addHash($actor->hash) : $currentStoreRecord->add($actor->hash->bytes);
	}

	return $record;
}

package CDS::ActorGroupBuilder::EntrustedActor;

sub new {
	my $class = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $storeUrl = shift;

	return bless {
		hash => $hash,
		storeUrl => $storeUrl,
		};
}

sub hash { shift->{hash} }
sub storeUrl { shift->{storeUrl} }

package CDS::ActorGroupBuilder::Member;

sub new {
	my $class = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $storeUrl = shift;
	my $revision = shift;
	my $status = shift;

	return bless {
		hash => $hash,
		storeUrl => $storeUrl,
		revision => $revision,
		status => $status,
		};
}

sub hash { shift->{hash} }
sub storeUrl { shift->{storeUrl} }
sub revision { shift->{revision} }
sub status { shift->{status} }

# The result of parsing an ACTORGROUP token (see Token.pm).
package CDS::ActorGroupToken;

sub new {
	my $class = shift;
	my $label = shift;
	my $actorGroup = shift; die 'wrong type '.ref($actorGroup).' for $actorGroup' if defined $actorGroup && ref $actorGroup ne 'CDS::ActorGroup';

	return bless {
		label => $label,
		actorGroup => $actorGroup,
		};
}

sub label { shift->{label} }
sub actorGroup { shift->{actorGroup} }

# A public key and a store.
package CDS::ActorOnStore;

sub new {
	my $class = shift;
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';
	my $store = shift;

	return bless {
		publicKey => $publicKey,
		store => $store
		};
}

sub publicKey { shift->{publicKey} }
sub store { shift->{store} }

sub equals {
	my $this = shift;
	my $that = shift;

	return 1 if ! defined $this && ! defined $that;
	return if ! defined $this || ! defined $that;
	return $this->{store}->id eq $that->{store}->id && $this->{publicKey}->{hash}->equals($that->{publicKey}->{hash});
}

package CDS::ActorWithDocument;

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $storageStore = shift;
	my $messagingStore = shift;
	my $messagingStoreUrl = shift;
	my $publicKeyCache = shift;

	my $o = bless {
		keyPair => $keyPair,
		storageStore => $storageStore,
		messagingStore => $messagingStore,
		messagingStoreUrl => $messagingStoreUrl,
		groupDataHandlers => [],
		}, $class;

	# Private data on the storage store
	$o->{storagePrivateRoot} = CDS::PrivateRoot->new($keyPair, $storageStore, $o);
	$o->{groupDocument} = CDS::RootDocument->new($o->{storagePrivateRoot}, 'group data');
	$o->{localDocument} = CDS::RootDocument->new($o->{storagePrivateRoot}, 'local data');

	# Private data on the messaging store
	$o->{messagingPrivateRoot} = $storageStore->id eq $messagingStore->id ? $o->{storagePrivateRoot} : CDS::PrivateRoot->new($keyPair, $messagingStore, $o);
	$o->{sentList} = CDS::SentList->new($o->{messagingPrivateRoot});
	$o->{sentListReady} = 0;

	# Group data sharing
	$o->{groupDataSharer} = CDS::GroupDataSharer->new($o);
	$o->{groupDataSharer}->addDataHandler($o->{groupDocument}->label, $o->{groupDocument});

	# Selectors
	$o->{groupRoot} = $o->{groupDocument}->root;
	$o->{localRoot} = $o->{localDocument}->root;
	$o->{publicDataSelector} = $o->{groupRoot}->child('public data');
	$o->{actorGroupSelector} = $o->{groupRoot}->child('actor group');
	$o->{actorSelector} = $o->{actorGroupSelector}->child(substr($keyPair->publicKey->hash->bytes, 0, 16));
	$o->{entrustedActorsSelector} = $o->{groupRoot}->child('entrusted actors');

	# Message reader
	my $pool = CDS::MessageBoxReaderPool->new($keyPair, $publicKeyCache, $o);
	$o->{messageBoxReader} = CDS::MessageBoxReader->new($pool, CDS::ActorOnStore->new($keyPair->publicKey, $messagingStore), CDS->HOUR);

	# Active actor group members and entrusted keys
	$o->{cachedGroupDataMembers} = {};
	$o->{cachedEntrustedKeys} = {};
	return $o;
}

sub keyPair { shift->{keyPair} }
sub storageStore { shift->{storageStore} }
sub messagingStore { shift->{messagingStore} }
sub messagingStoreUrl { shift->{messagingStoreUrl} }

sub storagePrivateRoot { shift->{storagePrivateRoot} }
sub groupDocument { shift->{groupDocument} }
sub localDocument { shift->{localDocument} }

sub messagingPrivateRoot { shift->{messagingPrivateRoot} }
sub sentList { shift->{sentList} }
sub sentListReady { shift->{sentListReady} }

sub groupDataSharer { shift->{groupDataSharer} }

sub groupRoot { shift->{groupRoot} }
sub localRoot { shift->{localRoot} }
sub publicDataSelector { shift->{publicDataSelector} }
sub actorGroupSelector { shift->{actorGroupSelector} }
sub actorSelector { shift->{actorSelector} }
sub entrustedActorsSelector { shift->{entrustedActorsSelector} }

### Our own actor ###

sub isMe {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	return $o->{keyPair}->publicKey->hash->equals($actorHash);
}

sub setName {
	my $o = shift;
	my $name = shift;

	$o->{actorSelector}->child('name')->set($name);
}

sub getName {
	my $o = shift;

	return $o->{actorSelector}->child('name')->textValue;
}

sub updateMyRegistration {
	my $o = shift;

	$o->{actorSelector}->addObject($o->{keyPair}->publicKey->hash, $o->{keyPair}->publicKey->object);
	my $record = CDS::Record->new;
	$record->add('hash')->addHash($o->{keyPair}->publicKey->hash);
	$record->add('store')->addText($o->{messagingStoreUrl});
	$o->{actorSelector}->set($record);
}

sub setMyActiveFlag {
	my $o = shift;
	my $flag = shift;

	$o->{actorSelector}->child('active')->setBoolean($flag);
}

sub setMyGroupDataFlag {
	my $o = shift;
	my $flag = shift;

	$o->{actorSelector}->child('group data')->setBoolean($flag);
}

### Actor group

sub isGroupMember {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	return 1 if $actorHash->equals($o->{keyPair}->publicKey->hash);
	my $memberSelector = $o->findMember($actorHash) // return;
	return ! $memberSelector->child('revoked')->isSet;
}

sub findMember {
	my $o = shift;
	my $memberHash = shift; die 'wrong type '.ref($memberHash).' for $memberHash' if defined $memberHash && ref $memberHash ne 'CDS::Hash';

	for my $child ($o->{actorGroupSelector}->children) {
		my $record = $child->record;
		my $hash = $record->child('hash')->hashValue // next;
		next if ! $hash->equals($memberHash);
		return $child;
	}

	return;
}

sub forgetOldIdleActors {
	my $o = shift;
	my $limit = shift;

	for my $child ($o->{actorGroupSelector}->children) {
		next if $child->child('active')->booleanValue;
		next if $child->child('group data')->booleanValue;
		next if $child->revision > $limit;
		$child->forgetBranch;
	}
}

### Group data members

sub getGroupDataMembers {
	my $o = shift;

	# Update the cached list
	for my $child ($o->{actorGroupSelector}->children) {
		my $record = $child->record;
		my $hash = $record->child('hash')->hashValue;
		$hash = undef if $hash->equals($o->{keyPair}->publicKey->hash);
		$hash = undef if $child->child('revoked')->isSet;
		$hash = undef if ! $child->child('group data')->isSet;

		# Remove
		if (! $hash) {
			delete $o->{cachedGroupDataMembers}->{$child->label};
			next;
		}

		# Keep
		my $member = $o->{cachedGroupDataMembers}->{$child->label};
		my $storeUrl = $record->child('store')->textValue;
		next if $member && $member->storeUrl eq $storeUrl && $member->actorOnStore->publicKey->hash->equals($hash);

		# Verify the store
		my $store = $o->onVerifyMemberStore($storeUrl, $child);
		if (! $store) {
			delete $o->{cachedGroupDataMembers}->{$child->label};
			next;
		}

		# Reuse the public key and add
		if ($member && $member->actorOnStore->publicKey->hash->equals($hash)) {
			my $actorOnStore = CDS::ActorOnStore->new($member->actorOnStore->publicKey, $store);
			$o->{cachedEntrustedKeys}->{$child->label} = {storeUrl => $storeUrl, actorOnStore => $actorOnStore};
		}

		# Get the public key and add
		my ($publicKey, $invalidReason, $storeError) = $o->{keyPair}->getPublicKey($hash, $o->{groupDocument}->unsaved);
		return if defined $storeError;
		if (defined $invalidReason) {
			delete $o->{cachedGroupDataMembers}->{$child->label};
			next;
		}

		my $actorOnStore = CDS::ActorOnStore->new($publicKey, $store);
		$o->{cachedGroupDataMembers}->{$child->label} = {storeUrl => $storeUrl, actorOnStore => $actorOnStore};
	}

	# Return the current list
	return [map { $_->{actorOnStore} } values %{$o->{cachedGroupDataMembers}}];
}

### Entrusted actors

sub entrust {
	my $o = shift;
	my $storeUrl = shift;
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';

	# TODO: this is not compatible with the Java implementation (which uses a record with "hash" and "store")
	my $selector = $o->{entrustedActorsSelector};
	my $builder = CDS::ActorGroupBuilder->new;
	$builder->parseEntrustedActorList($selector->record, 1);
	$builder->removeEntrustedActor($publicKey->hash);
	$builder->addEntrustedActor($storeUrl, $publicKey->hash);
	$selector->addObject($publicKey->hash, $publicKey->object);
	$selector->set($builder->entrustedActorListToRecord(1));
	$o->{cachedEntrustedKeys}->{$publicKey->hash->bytes} = $publicKey;
}

sub doNotEntrust {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $selector = $o->{entrustedActorsSelector};
	my $builder = CDS::ActorGroupBuilder->new;
	$builder->parseEntrustedActorList($selector->record, 1);
	$builder->removeEntrustedActor($hash);
	$selector->set($builder->entrustedActorListToRecord(1));
	delete $o->{cachedEntrustedKeys}->{$hash->bytes};
}

sub getEntrustedKeys {
	my $o = shift;

	my $entrustedKeys = [];
	for my $storeRecord ($o->{entrustedActorsSelector}->record->children) {
		for my $child ($storeRecord->children) {
			my $hash = $child->hash // next;
			push @$entrustedKeys, $o->getEntrustedKey($hash) // next;
		}
	}

	# We could remove unused keys from $o->{cachedEntrustedKeys} here, but since this is
	# such a rare event, and doesn't consume a lot of memory, this would be overkill.

	return $entrustedKeys;
}

sub getEntrustedKey {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $entrustedKey = $o->{cachedEntrustedKeys}->{$hash->bytes};
	return $entrustedKey if $entrustedKey;

	my ($publicKey, $invalidReason, $storeError) = $o->{keyPair}->getPublicKey($hash, $o->{groupDocument}->unsaved);
	return if defined $storeError;
	return if defined $invalidReason;
	$o->{cachedEntrustedKeys}->{$hash->bytes} = $publicKey;
	return $publicKey;
}

### Private data

sub procurePrivateData {
	my $o = shift;
	my $interval = shift // CDS->DAY;

	$o->{storagePrivateRoot}->procure($interval) // return;
	$o->{groupDocument}->read // return;
	$o->{localDocument}->read // return;
	return 1;
}

sub savePrivateDataAndShareGroupData {
	my $o = shift;

	$o->{localDocument}->save;
	$o->{groupDocument}->save;
	$o->groupDataSharer->share;
	my $entrustedKeys = $o->getEntrustedKeys // return;
	my ($ok, $missingHash) = $o->{storagePrivateRoot}->save($entrustedKeys);
	return 1 if $ok;
	$o->onMissingObject($missingHash) if $missingHash;
	return;
}

# abstract sub onVerifyMemberStore($storeUrl, $selector)
# abstract sub onPrivateRootReadingInvalidEntry($o, $source, $reason)
# abstract sub onMissingObject($missingHash)

### Sending messages

sub procureSentList {
	my $o = shift;
	my $interval = shift // CDS->DAY;

	$o->{messagingPrivateRoot}->procure($interval) // return;
	$o->{sentList}->read // return;
	$o->{sentListReady} = 1;
	return 1;
}

sub openMessageChannel {
	my $o = shift;
	my $label = shift;
	my $validity = shift;

	return CDS::MessageChannel->new($o, $label, $validity);
}

sub sendMessages {
	my $o = shift;

	return 1 if ! $o->{sentList}->hasChanges;
	$o->{sentList}->save;
	my $entrustedKeys = $o->getEntrustedKeys // return;
	my ($ok, $missingHash) = $o->{messagingPrivateRoot}->save($entrustedKeys);
	return 1 if $ok;
	$o->onMissingObject($missingHash) if $missingHash;
	return;
}

### Receiving messages

# abstract sub onMessageBoxVerifyStore($o, $senderStoreUrl, $hash, $envelope, $senderHash)
# abstract sub onMessage($o, $message)
# abstract sub onInvalidMessage($o, $source, $reason)
# abstract sub onMessageBoxEntry($o, $message)
# abstract sub onMessageBoxInvalidEntry($o, $source, $reason)

### Announcing ###

sub announceOnAllStores {
	my $o = shift;

	$o->announce($o->{storageStore});
	$o->announce($o->{messagingStore}) if $o->{messagingStore}->id ne $o->{storageStore}->id;
}

sub announce {
	my $o = shift;
	my $store = shift;

	die 'probably calling old announce, which should now be announceOnAllStores' if ! defined $store;

	# Prepare the actor group
	my $builder = CDS::ActorGroupBuilder->new;

	my $me = $o->keyPair->publicKey->hash;
	$builder->addMember($me, $o->messagingStoreUrl, CDS->now, 'active');
	for my $child ($o->actorGroupSelector->children) {
		my $record = $child->record;
		my $hash = $record->child('hash')->hashValue // next;
		next if $hash->equals($me);
		my $storeUrl = $record->child('store')->textValue;
		my $revokedSelector = $child->child('revoked');
		my $activeSelector = $child->child('active');
		my $revision = CDS->max($child->revision, $revokedSelector->revision, $activeSelector->revision);
		my $actorStatus = $revokedSelector->booleanValue ? 'revoked' : $activeSelector->booleanValue ? 'active' : 'idle';
		$builder->addMember($hash, $storeUrl, $revision, $actorStatus);
	}

	$builder->parseEntrustedActorList($o->entrustedActorsSelector->record, 1) if $builder->mergeEntrustedActors($o->entrustedActorsSelector->revision);

	# Create the card
	my $card = $builder->toRecord(0);
	$card->add('public key')->addHash($o->{keyPair}->publicKey->hash);

	# Add the public data
	for my $child ($o->publicDataSelector->children) {
		my $childRecord = $child->record;
		$card->addRecord($childRecord->children);
	}

	# Create an unsaved state
	my $unsaved = CDS::Unsaved->new($o->publicDataSelector->document->unsaved);

	# Add the public card and the public key
	my $cardObject = $card->toObject;
	my $cardHash = $cardObject->calculateHash;
	$unsaved->state->addObject($cardHash, $cardObject);
	$unsaved->state->addObject($me, $o->keyPair->publicKey->object);

	# Prepare the public envelope
	my $envelopeObject = $o->keyPair->createPublicEnvelope($cardHash)->toObject;
	my $envelopeHash = $envelopeObject->calculateHash;

	# Upload the objects
	my ($missingObject, $transferStore, $transferError) = $o->keyPair->transfer([$cardHash], $unsaved, $store);
	return if defined $transferError;
	if ($missingObject) {
		$missingObject->{context} = 'announce on '.$store->id;
		$o->onMissingObject($missingObject);
		return;
	}

	# Prepare to modify
	my $modifications = CDS::StoreModifications->new;
	$modifications->add($me, 'public', $envelopeHash, $envelopeObject);

	# List the current cards to remove them
	# Ignore errors, in the worst case, we are going to have multiple entries in the public box
	my ($hashes, $error) = $store->list($me, 'public', 0, $o->keyPair);
	if ($hashes) {
		for my $hash (@$hashes) {
			$modifications->remove($me, 'public', $hash);
		}
	}

	# Modify the public box
	my $modifyError = $store->modify($modifications, $o->keyPair);
	return if defined $modifyError;
	return $envelopeHash, $cardHash;
}

# The result of parsing a BOX token (see Token.pm).
package CDS::BoxToken;

sub new {
	my $class = shift;
	my $accountToken = shift;
	my $boxLabel = shift;

	return bless {
		accountToken => $accountToken,
		boxLabel => $boxLabel
		};
}

sub accountToken { shift->{accountToken} }
sub boxLabel { shift->{boxLabel} }
sub url {
	my $o = shift;
	 $o->{accountToken}->url.'/'.$o->{boxLabel} }

package CDS::CLIActor;

use parent -norequire, 'CDS::ActorWithDocument';

sub openOrCreateDefault {
	my $class = shift;
	my $ui = shift;

	$class->open(CDS::Configuration->getOrCreateDefault($ui));
}

sub open {
	my $class = shift;
	my $configuration = shift;

	# Read the store configuration
	my $ui = $configuration->ui;
	my $storeManager = CDS::CLIStoreManager->new($ui);

	my $storageStoreUrl = $configuration->storageStoreUrl;
	my $storageStore = $storeManager->storeForUrl($storageStoreUrl) // return $ui->error('Your storage store "', $storageStoreUrl, '" cannot be accessed. You can set this store in "', $configuration->file('store'), '".');

	my $messagingStoreUrl = $configuration->messagingStoreUrl;
	my $messagingStore = $storeManager->storeForUrl($messagingStoreUrl) // return $ui->error('Your messaging store "', $messagingStoreUrl, '" cannot be accessed. You can set this store in "', $configuration->file('messaging-store'), '".');

	# Read the key pair
	my $keyPair = $configuration->keyPair // return $ui->error('Your key pair (', $configuration->file('key-pair'), ') is missing.');

	# Create the actor
	my $publicKeyCache = CDS::PublicKeyCache->new(128);
	my $o = $class->SUPER::new($keyPair, $storageStore, $messagingStore, $messagingStoreUrl, $publicKeyCache);
	$o->{ui} = $ui;
	$o->{storeManager} = $storeManager;
	$o->{configuration} = $configuration;
	$o->{sessionRoot} = $o->localRoot->child('sessions')->child(''.getppid);
	$o->{keyPairToken} = CDS::KeyPairToken->new($configuration->file('key-pair'), $keyPair);

	# Message handlers
	$o->{messageHandlers} = {};
	$o->setMessageHandler('sender', \&onIgnoreMessage);
	$o->setMessageHandler('store', \&onIgnoreMessage);
	$o->setMessageHandler('group data', \&onGroupDataMessage);

	# Read the private data
	if (! $o->procurePrivateData) {
		$o->{ui}->space;
		$ui->pRed('Failed to read the local private data.');
		$o->{ui}->space;
		return;
	}

	return $o;
}

sub ui { shift->{ui} }
sub storeManager { shift->{storeManager} }
sub configuration { shift->{configuration} }
sub sessionRoot { shift->{sessionRoot} }
sub keyPairToken { shift->{keyPairToken} }

### Saving

sub saveOrShowError {
	my $o = shift;

	$o->forgetOldSessions;
	my ($ok, $missingHash) = $o->savePrivateDataAndShareGroupData;
	return if ! $ok;
	return $o->onMissingObject($missingHash) if $missingHash;
	$o->sendMessages;
	return 1;
}

sub onMissingObject {
	my $o = shift;
	my $missingObject = shift; die 'wrong type '.ref($missingObject).' for $missingObject' if defined $missingObject && ref $missingObject ne 'CDS::Object';

	$o->{ui}->space;
	$o->{ui}->pRed('The object ', $missingObject->hash->hex, ' was missing while saving data.');
	$o->{ui}->space;
	$o->{ui}->p('This is a fatal error with two possible sources:');
	$o->{ui}->p('- A store may have lost objects, e.g. due to an error with the underlying storage, misconfiguration, or too aggressive garbage collection.');
	$o->{ui}->p('- The application is linking objects without properly storing them. This is an error in the application, that must be fixed by a developer.');
	$o->{ui}->space;
}

sub onGroupDataSharingStoreError {
	my $o = shift;
	my $recipientActorOnStore = shift; die 'wrong type '.ref($recipientActorOnStore).' for $recipientActorOnStore' if defined $recipientActorOnStore && ref $recipientActorOnStore ne 'CDS::ActorOnStore';
	my $storeError = shift;

	$o->{ui}->space;
	$o->{ui}->pRed('Unable to share the group data with ', $recipientActorOnStore->publicKey->hash->hex, '.');
	$o->{ui}->space;
}

### Reading

sub onPrivateRootReadingInvalidEntry {
	my $o = shift;
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';
	my $reason = shift;

	$o->{ui}->space;
	$o->{ui}->pRed('The envelope ', $source->hash->shortHex, ' points to invalid private data (', $reason, ').');
	$o->{ui}->p('This could be due to a storage system failure, a malicious attempt to delete or modify your data, or simply an application error. To investigate what is going on, the following commands may be helpful:');
	$o->{ui}->line('  cds open envelope ', $source->hash->hex, ' from ', $source->actorOnStore->publicKey->hash->hex, ' on ', $source->actorOnStore->store->url);
	$o->{ui}->line('  cds show record ', $source->hash->hex, ' on ', $source->actorOnStore->store->url);
	$o->{ui}->line('  cds list private box of ', $source->actorOnStore->publicKey->hash->hex, ' on ', $source->actorOnStore->store->url);
	$o->{ui}->p('To remove the invalid entry, type:');
	$o->{ui}->line('  cds remove ', $source->hash->hex, ' from private box of ', $source->actorOnStore->publicKey->hash->hex, ' on ', $source->actorOnStore->store->url);
	$o->{ui}->space;
}

sub onVerifyMemberStore {
	my $o = shift;
	my $storeUrl = shift;
	my $actorSelector = shift; die 'wrong type '.ref($actorSelector).' for $actorSelector' if defined $actorSelector && ref $actorSelector ne 'CDS::Selector';
	 $o->storeForUrl($storeUrl) }

### Announcing

sub registerIfNecessary {
	my $o = shift;

	my $now = CDS->now;
	return if $o->{actorSelector}->revision > $now - CDS->DAY;
	$o->updateMyRegistration;
	$o->setMyActiveFlag(1);
	$o->setMyGroupDataFlag(1);
}

sub announceIfNecessary {
	my $o = shift;

	my $state = join('', map { CDS->bytesFromUnsigned($_->revision) } sort { $a->label cmp $b->label } $o->{actorGroupSelector}->children);
	$o->announceOnStoreIfNecessary($o->{storageStore}, $state);
	$o->announceOnStoreIfNecessary($o->{messagingStore}, $state) if $o->{messagingStore}->id ne $o->{storageStore}->id;
}

sub announceOnStoreIfNecessary {
	my $o = shift;
	my $store = shift;
	my $state = shift;

	my $stateSelector = $o->{localRoot}->child('announced')->childWithText($store->id);
	return if $stateSelector->bytesValue eq $state;
	my ($envelopeHash, $cardHash) = $o->announce($store);
	return $o->{ui}->pRed('Updating the card on ', $store->url, ' failed.') if ! $envelopeHash;
	$stateSelector->setBytes($state);
	$o->{ui}->pGreen('The card on ', $store->url, ' has been updated.');
	return 1;
}

### Store resolving

sub storeForUrl {
	my $o = shift;
	my $url = shift;

	$o->{storeManager}->setCacheStoreUrl($o->{sessionRoot}->child('use cache')->textValue);
	return $o->{storeManager}->storeForUrl($url);
}

### Processing messages

sub setMessageHandler {
	my $o = shift;
	my $type = shift;
	my $handler = shift;

	$o->{messageHandlers}->{$type} = $handler;
}

sub readMessages {
	my $o = shift;

	$o->{ui}->title('Messages');
	$o->{countMessages} = 0;
	$o->{messageBoxReader}->read;
	$o->{ui}->line($o->{ui}->gray('none')) if ! $o->{countMessages};
}

sub onMessageBoxVerifyStore {
	my $o = shift;
	my $senderStoreUrl = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $senderHash = shift; die 'wrong type '.ref($senderHash).' for $senderHash' if defined $senderHash && ref $senderHash ne 'CDS::Hash';

	return $o->storeForUrl($senderStoreUrl);
}

sub onMessageBoxEntry {
	my $o = shift;
	my $message = shift;

	$o->{countMessages} += 1;

	for my $section ($message->content->children) {
		my $type = $section->bytes;
		my $handler = $o->{messageHandlers}->{$type} // \&onUnknownMessage;
		&$handler($o, $message, $section);
	}

#	1. message processed
#		-> source can be deleted immediately (e.g. invalid)
#			source.discard()
#		-> source has been merged, and will be deleted when changes have been saved
#			document.addMergedSource(source)
#	2. wait for sender store
#		-> set entry.waitForStore = senderStore
#	3. skip
#		-> set entry.processed = false

	my $source = $message->source;
	$message->source->discard;
}

sub onGroupDataMessage {
	my $o = shift;
	my $message = shift;
	my $section = shift;

	my $ok = $o->{groupDataSharer}->processGroupDataMessage($message, $section);
	$o->{groupDocument}->read;
	return $o->{ui}->line('Group data from ', $message->sender->publicKey->hash->hex) if $ok;
	$o->{ui}->line($o->{ui}->red('Group data from foreign actor ', $message->sender->publicKey->hash->hex, ' (ignored)'));
}

sub onIgnoreMessage {
	my $o = shift;
	my $message = shift;
	my $section = shift;
	 }

sub onUnknownMessage {
	my $o = shift;
	my $message = shift;
	my $section = shift;

	$o->{ui}->line($o->{ui}->orange('Unknown message of type "', $section->asText, '" from ', $message->sender->publicKey->hash->hex));
}

sub onMessageBoxInvalidEntry {
	my $o = shift;
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';
	my $reason = shift;

	$o->{ui}->warning('Discarding invalid message ', $source->hash->hex, ' (', $reason, ').');
	$source->discard;
}

### Remembered values

sub labelSelector {
	my $o = shift;
	my $label = shift;

	my $bytes = Encode::encode_utf8($label);
	return $o->groupRoot->child('labels')->child($bytes);
}

sub remembered {
	my $o = shift;
	my $label = shift;

	return $o->labelSelector($label)->record;
}

sub remember {
	my $o = shift;
	my $label = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	$o->labelSelector($label)->set($record);
}

sub rememberedRecords {
	my $o = shift;

	my $records = {};
	for my $child ($o->{groupRoot}->child('labels')->children) {
		next if ! $child->isSet;
		my $label = Encode::decode_utf8($child->label);
		$records->{$label} = $child->record;
	}

	return $records;
}

sub storeLabel {
	my $o = shift;
	my $storeUrl = shift;

	my $records = $o->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if length $record->child('actor')->bytesValue;
		next if $storeUrl ne $record->child('store')->textValue;
		return $label;
	}

	return;
}

sub actorLabel {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	my $records = $o->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if $actorHash->bytes ne $record->child('actor')->bytesValue;
		return $label;
	}

	return;
}

sub actorLabelByHashStartBytes {
	my $o = shift;
	my $actorHashStartBytes = shift;

	my $length = length $actorHashStartBytes;
	my $records = $o->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if $actorHashStartBytes ne substr($record->child('actor')->bytesValue, 0, $length);
		return $label;
	}

	return;
}

sub accountLabel {
	my $o = shift;
	my $storeUrl = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	my $storeLabel;
	my $actorLabel;

	my $records = $o->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		my $actorBytes = $record->child('actor')->bytesValue;

		my $correctActor = $actorHash->bytes eq $actorBytes;
		$actorLabel = $label if $correctActor;

		if ($storeUrl eq $record->child('store')->textValue) {
			return $label if $correctActor;
			$storeLabel = $label if ! length $actorBytes;
		}
	}

	return (undef, $storeLabel, $actorLabel);
}

sub keyPairLabel {
	my $o = shift;
	my $file = shift;

	my $records = $o->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if $file ne $record->child('key pair')->textValue;
		return $label;
	}

	return;
}

### References that can be used in commands

sub actorReference {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	return $o->actorLabel($actorHash) // $actorHash->hex;
}

sub storeReference {
	my $o = shift;
	my $store = shift;
	 $o->storeUrlReference($store->url); }

sub storeUrlReference {
	my $o = shift;
	my $storeUrl = shift;

	return $o->storeLabel($storeUrl) // $storeUrl;
}

sub accountReference {
	my $o = shift;
	my $accountToken = shift;

	my ($accountLabel, $storeLabel, $actorLabel) = $o->accountLabel($accountToken->{cliStore}->url, $accountToken->{actorHash});
	return $accountLabel if defined $accountLabel;
	return defined $actorLabel ? $actorLabel : $accountToken->{actorHash}->hex, ' on ', defined $storeLabel ? $storeLabel : $accountToken->{cliStore}->url;
}

sub boxReference {
	my $o = shift;
	my $boxToken = shift;

	return $o->boxName($boxToken->{boxLabel}), ' of ', $o->accountReference($boxToken->{accountToken});
}

sub keyPairReference {
	my $o = shift;
	my $keyPairToken = shift;

	return $o->keyPairLabel($keyPairToken->file) // $keyPairToken->file;
}

sub blueActorReference {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	my $label = $o->actorLabel($actorHash);
	return defined $label ? $o->{ui}->blue($label) : $actorHash->hex;
}

sub blueStoreReference {
	my $o = shift;
	my $store = shift;
	 $o->blueStoreUrlReference($store->url); }

sub blueStoreUrlReference {
	my $o = shift;
	my $storeUrl = shift;

	my $label = $o->storeLabel($storeUrl);
	return defined $label ? $o->{ui}->blue($label) : $storeUrl;
}

sub blueAccountReference {
	my $o = shift;
	my $accountToken = shift;

	my ($accountLabel, $storeLabel, $actorLabel) = $o->accountLabel($accountToken->{cliStore}->url, $accountToken->{actorHash});
	return $o->{ui}->blue($accountLabel) if defined $accountLabel;
	return defined $actorLabel ? $o->{ui}->blue($actorLabel) : $accountToken->{actorHash}->hex, ' on ', defined $storeLabel ? $o->{ui}->blue($storeLabel) : $accountToken->{cliStore}->url;
}

sub blueBoxReference {
	my $o = shift;
	my $boxToken = shift;

	return $o->boxName($boxToken->{boxLabel}), ' of ', $o->blueAccountReference($boxToken->{accountToken});
}

sub blueKeyPairReference {
	my $o = shift;
	my $keyPairToken = shift;

	my $label = $o->keyPairLabel($keyPairToken->file);
	return defined $label ? $o->{ui}->blue($label) : $keyPairToken->file;
}

sub boxName {
	my $o = shift;
	my $boxLabel = shift;

	return 'private box' if $boxLabel eq 'private';
	return 'public box' if $boxLabel eq 'public';
	return 'message box' if $boxLabel eq 'messages';
	return $boxLabel;
}

### Session

sub forgetOldSessions {
	my $o = shift;

	for my $child ($o->{sessionRoot}->parent->children) {
		my $pid = $child->label;
		next if -e '/proc/'.$pid;
		$child->forgetBranch;
	}
}

sub selectedKeyPairToken {
	my $o = shift;

	my $file = $o->{sessionRoot}->child('selected key pair')->textValue;
	return if ! length $file;
	my $keyPair = CDS::KeyPair->fromFile($file) // return;
	return CDS::KeyPairToken->new($file, $keyPair);
}

sub selectedStoreUrl {
	my $o = shift;

	my $storeUrl = $o->{sessionRoot}->child('selected store')->textValue;
	return if ! length $storeUrl;
	return $storeUrl;
}

sub selectedStore {
	my $o = shift;

	my $storeUrl = $o->selectedStoreUrl // return;
	return $o->storeForUrl($storeUrl);
}

sub selectedActorHash {
	my $o = shift;

	return CDS::Hash->fromBytes($o->{sessionRoot}->child('selected actor')->bytesValue);
}

sub preferredKeyPairToken {
	my $o = shift;
	 $o->selectedKeyPairToken // $o->keyPairToken }
sub preferredStore {
	my $o = shift;
	 $o->selectedStore // $o->storageStore }
sub preferredStores {
	my $o = shift;
	 $o->selectedStore // ($o->storageStore, $o->messagingStore) }
sub preferredActorHash {
	my $o = shift;
	 $o->selectedActorHash // $o->keyPair->publicKey->hash }

### Common functions

sub uiGetObject {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;
	my $keyPairToken = shift;

	my ($object, $storeError) = $store->get($hash, $keyPairToken->keyPair);
	return if defined $storeError;
	return $o->{ui}->error('The object ', $hash->hex, ' does not exist on "', $store->url, '".') if ! $object;
	return $object;
}

sub uiGetRecord {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;
	my $keyPairToken = shift;

	my $object = $o->uiGetObject($hash, $store, $keyPairToken) // return;
	return CDS::Record->fromObject($object) // return $o->{ui}->error('The object ', $hash->hex, ' is not a record.');
}

sub uiGetPublicKey {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;
	my $keyPairToken = shift;

	my $object = $o->uiGetObject($hash, $store, $keyPairToken) // return;
	return CDS::PublicKey->fromObject($object) // return $o->{ui}->error('The object ', $hash->hex, ' is not a public key.');
}

sub isEnvelope {
	my $o = shift;
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	my $record = CDS::Record->fromObject($object) // return;
	return if ! $record->contains('signed');
	my $signatureRecord = $record->child('signature')->firstChild;
	return if ! $signatureRecord->hash;
	return if ! length $signatureRecord->bytes;
	return 1;
}

package CDS::CLIStoreManager;

sub new {
	my $class = shift;
	my $ui = shift;

	return bless {ui => $ui, failedStores => {}};
}

sub ui { shift->{ui} }

sub rawStoreForUrl {
	my $o = shift;
	my $url = shift;

	return if ! $url;
	return
		CDS::FolderStore->forUrl($url) //
		CDS::HTTPStore->forUrl($url) //
		undef;
}

sub storeForUrl {
	my $o = shift;
	my $url = shift;

	my $store = $o->rawStoreForUrl($url);
	my $progressStore = CDS::UI::ProgressStore->new($store, $url, $o->{ui});
	my $cachedStore = defined $o->{cacheStore} ? CDS::ObjectCache->new($progressStore, $o->{cacheStore}) : $progressStore;
	return CDS::ErrorHandlingStore->new($cachedStore, $url, $o);
}

sub onStoreSuccess {
	my $o = shift;
	my $store = shift;
	my $function = shift;

	delete $o->{failedStores}->{$store->store->id};
}

sub onStoreError {
	my $o = shift;
	my $store = shift;
	my $function = shift;
	my $error = shift;

	$o->{failedStores}->{$store->store->id} = 1;
	$o->{ui}->error('The store "', $store->{url}, '" reports: ', $error);
}

sub hasStoreError {
	my $o = shift;
	my $store = shift;
	my $function = shift;

	return if ! $o->{failedStores}->{$store->store->id};
	$o->{ui}->error('Ignoring store "', $store->{url}, '", because it previously reported errors.');
	return 1;
}

sub setCacheStoreUrl {
	my $o = shift;
	my $storeUrl = shift;

	return if ($storeUrl // '') eq ($o->{cacheStoreUrl} // '');
	$o->{cacheStoreUrl} = $storeUrl;
	$o->{cacheStore} = $o->rawStoreForUrl($storeUrl);
}

package CDS::CheckSignatureStore;

sub new {
	my $o = shift;
	my $store = shift;
	my $objects = shift;

	return bless {
		store => $store,
		id => "Check signature store\n".$store->id,
		objects => $objects // {},
		};
}

sub id { shift->{id} }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $entry = $o->{objects}->{$hash->bytes} // return $o->{store}->get($hash);
	return $entry->{object};
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return exists $o->{objects}->{$hash->bytes};
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{objects}->{$hash->bytes} = {hash => $hash, object => $object};
	return;
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'This store only handles objects.';
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'This store only handles objects.';
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'This store only handles objects.';
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $modifications->executeIndividually($o, $keyPair);
}

# BEGIN AUTOGENERATED
package CDS::Commands::ActorGroup;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node010 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&show});
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&joinMember});
	my $node015 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&setMember});
	my $node016 = CDS::Parser::Node->new(0);
	$cds->addArrow($node001, 1, 0, 'show');
	$cds->addArrow($node003, 1, 0, 'join');
	$cds->addArrow($node004, 1, 0, 'set');
	$help->addArrow($node000, 1, 0, 'actor');
	$node000->addArrow($node009, 1, 0, 'group');
	$node001->addArrow($node002, 1, 0, 'actor');
	$node002->addArrow($node010, 1, 0, 'group');
	$node003->addArrow($node005, 1, 0, 'member');
	$node004->addArrow($node007, 1, 0, 'member');
	$node005->addDefault($node006);
	$node005->addArrow($node011, 1, 0, 'ACTOR', \&collectActor);
	$node006->addArrow($node006, 1, 0, 'ACCOUNT', \&collectAccount);
	$node006->addArrow($node014, 1, 1, 'ACCOUNT', \&collectAccount);
	$node007->addDefault($node008);
	$node008->addArrow($node008, 1, 0, 'ACTOR', \&collectActor1);
	$node008->addArrow($node013, 1, 0, 'ACTOR', \&collectActor1);
	$node011->addArrow($node012, 1, 0, 'on');
	$node012->addArrow($node014, 1, 0, 'STORE', \&collectStore);
	$node013->addArrow($node015, 1, 0, 'active', \&collectActive);
	$node013->addArrow($node015, 1, 0, 'backup', \&collectBackup);
	$node013->addArrow($node015, 1, 0, 'idle', \&collectIdle);
	$node013->addArrow($node015, 1, 0, 'revoked', \&collectRevoked);
	$node014->addArrow($node016, 1, 0, 'and');
	$node016->addDefault($node005);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, $value;
}

sub collectActive {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'active';
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectActor1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{actorHashes}}, $value;
}

sub collectBackup {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'backup';
}

sub collectIdle {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'idle';
}

sub collectRevoked {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'revoked';
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, CDS::AccountToken->new($value, $o->{actorHash});
	delete $o->{actorHash};
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME actor-group
# HTML TITLE Actor group
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show actor group');
	$ui->p('Shows all members of our actor group and the entrusted keys.');
	$ui->space;
	$ui->command('cds join ACCOUNT*');
	$ui->command('cds join ACTOR on STORE');
	$ui->p('Adds a member to our actor group. To complete the association, the new member must join us, too.');
	$ui->space;
	$ui->command('cds set member ACTOR* active');
	$ui->command('cds set member ACTOR* backup');
	$ui->command('cds set member ACTOR* idle');
	$ui->command('cds set member ACTOR* revoked');
	$ui->p('Changes the status of a member to one of the following:');
	$ui->p($ui->bold('Active members'), ' share the group data among themselves, and are advertised to receive messages.');
	$ui->p($ui->bold('Backup members'), ' share the group data (like active members), but are publicly advertised as not processing messages (like idle members). This is suitable for backup actors.');
	$ui->p($ui->bold('Idle members'), ' are part of the group, but advertised as not processing messages. They generally do not have the latest group data, and may have no group data at all. Idle members may reactivate themselves, or get reactivated by any active member of the group.');
	$ui->p($ui->bold('Revoked members'), ' have explicitly been removed from the group, e.g. because their private key (or device) got lost. Revoked members can be reactivated by any active member of the group.');
	$ui->p('Note that changing the status does not start or stop the corresponding actor, but just change how it is regarded by others. The status of each member should reflect its actual behavior.');
	$ui->space;
	$ui->p('After modifying the actor group members, you should "cds announce" yourself to publish the changes.');
	$ui->space;
}

sub show {
	my $o = shift;
	my $cmd = shift;

	my $hasMembers = 0;
	for my $actorSelector ($o->{actor}->actorGroupSelector->children) {
		my $record = $actorSelector->record;
		my $hash = $record->child('hash')->hashValue // next;
		next if substr($hash->bytes, 0, length $actorSelector->label) ne $actorSelector->label;
		my $storeUrl = $record->child('store')->textValue;
		my $revisionText = $o->{ui}->niceDateTimeLocal($actorSelector->revision);
		$o->{ui}->line($o->{ui}->gray($revisionText), '  ', $o->coloredType7($actorSelector), '  ', $hash->hex, ' on ', $storeUrl);
		$hasMembers = 1;
	}

	return if $hasMembers;
	$o->{ui}->line($o->{ui}->blue('(just you)'));
}

sub type {
	my $o = shift;
	my $actorSelector = shift; die 'wrong type '.ref($actorSelector).' for $actorSelector' if defined $actorSelector && ref $actorSelector ne 'CDS::Selector';

	my $groupData = $actorSelector->child('group data')->isSet;
	my $active = $actorSelector->child('active')->isSet;
	my $revoked = $actorSelector->child('revoked')->isSet;
	return
		$revoked ? 'revoked' :
		$active && $groupData ? 'active' :
		$groupData ? 'backup' :
		$active ? 'weird' :
			'idle';
}

sub coloredType7 {
	my $o = shift;
	my $actorSelector = shift; die 'wrong type '.ref($actorSelector).' for $actorSelector' if defined $actorSelector && ref $actorSelector ne 'CDS::Selector';

	my $groupData = $actorSelector->child('group data')->isSet;
	my $active = $actorSelector->child('active')->isSet;
	my $revoked = $actorSelector->child('revoked')->isSet;
	return
		$revoked ? $o->{ui}->red('revoked') :
		$active && $groupData ? $o->{ui}->green('active ') :
		$groupData ? $o->{ui}->blue('backup ') :
		$active ? $o->{ui}->orange('weird  ') :
			$o->{ui}->gray('idle   ');
}

sub joinMember {
	my $o = shift;
	my $cmd = shift;

	$o->{accountTokens} = [];
	$cmd->collect($o);

	my $selector = $o->{actor}->actorGroupSelector;
	for my $accountToken (@{$o->{accountTokens}}) {
		my $actorHash = $accountToken->actorHash;

		# Get the public key
		my ($publicKey, $invalidReason, $storeError) = $o->{actor}->keyPair->getPublicKey($actorHash, $accountToken->cliStore);
		if (defined $storeError) {
			$o->{ui}->pRed('Unable to get the public key of ', $actorHash->hex, ' from ', $accountToken->cliStore->url, ': ', $storeError);
			next;
		}

		if (defined $invalidReason) {
			$o->{ui}->pRed('Unable to get the public key of ', $actorHash->hex, ' from ', $accountToken->cliStore->url, ': ', $invalidReason);
			next;
		}

		# Add or update this member
		my $label = substr($actorHash->bytes, 0, 16);
		my $actorSelector = $selector->child($label);
		my $wasMember = $actorSelector->isSet;

		my $record = CDS::Record->new;
		$record->add('hash')->addHash($actorHash);
		$record->add('store')->addText($accountToken->cliStore->url);
		$actorSelector->set($record);
		$actorSelector->addObject($publicKey->hash, $publicKey->object);

		$o->{ui}->pGreen('Updated ', $o->type($actorSelector), ' member ', $actorHash->hex, '.') if $wasMember;
		$o->{ui}->pGreen('Added ', $actorHash->hex, ' as ', $o->type($actorSelector), ' member of the actor group.') if ! $wasMember;
	}

	# Save
	$o->{actor}->saveOrShowError;
}

sub setFlag {
	my $o = shift;
	my $actorSelector = shift; die 'wrong type '.ref($actorSelector).' for $actorSelector' if defined $actorSelector && ref $actorSelector ne 'CDS::Selector';
	my $label = shift;
	my $value = shift;

	my $child = $actorSelector->child($label);
	if ($value) {
		$child->setBoolean(1);
	} else {
		$child->clear;
	}
}

sub setMember {
	my $o = shift;
	my $cmd = shift;

	$o->{actorHashes} = [];
	$cmd->collect($o);

	my $selector = $o->{actor}->actorGroupSelector;
	for my $actorHash (@{$o->{actorHashes}}) {
		my $label = substr($actorHash->bytes, 0, 16);
		my $actorSelector = $selector->child($label);

		my $record = $actorSelector->record;
		my $hash = $record->child('hash')->hashValue;
		if (! $hash) {
			$o->{ui}->pRed($actorHash->hex, ' is not a member of our actor group.');
			next;
		}

		$o->setFlag($actorSelector, 'group data', $o->{status} eq 'active' || $o->{status} eq 'backup');
		$o->setFlag($actorSelector, 'active', $o->{status} eq 'active');
		$o->setFlag($actorSelector, 'revoked', $o->{status} eq 'revoked');
		$o->{ui}->pGreen($actorHash->hex, ' is now ', $o->type($actorSelector), '.');
	}

	# Save
	$o->{actor}->saveOrShowError;
}

# BEGIN AUTOGENERATED
package CDS::Commands::Announce;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node001 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&announceMe});
	my $node002 = CDS::Parser::Node->new(1);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(1);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(0);
	my $node017 = CDS::Parser::Node->new(0, {constructor => \&new, function => \&announceKeyPair});
	$cds->addArrow($node001, 1, 0, 'announce');
	$cds->addArrow($node002, 1, 0, 'announce');
	$help->addArrow($node000, 1, 0, 'announce');
	$node002->addArrow($node003, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node003->addArrow($node004, 1, 0, 'on');
	$node004->addArrow($node005, 1, 0, 'STORE', \&collectStore);
	$node005->addArrow($node006, 1, 0, 'without');
	$node005->addArrow($node007, 1, 0, 'with');
	$node005->addDefault($node017);
	$node006->addArrow($node006, 1, 0, 'ACTOR', \&collectActor);
	$node006->addArrow($node017, 1, 0, 'ACTOR', \&collectActor);
	$node007->addArrow($node008, 1, 0, 'active', \&collectActive);
	$node007->addArrow($node008, 1, 0, 'entrusted', \&collectEntrusted);
	$node007->addArrow($node008, 1, 0, 'idle', \&collectIdle);
	$node007->addArrow($node008, 1, 0, 'revoked', \&collectRevoked);
	$node008->addDefault($node009);
	$node008->addDefault($node010);
	$node009->addArrow($node009, 1, 0, 'ACCOUNT', \&collectAccount);
	$node009->addArrow($node013, 1, 1, 'ACCOUNT', \&collectAccount);
	$node010->addArrow($node010, 1, 0, 'ACTOR', \&collectActor1);
	$node010->addArrow($node011, 1, 0, 'ACTOR', \&collectActor1);
	$node011->addArrow($node012, 1, 0, 'on');
	$node012->addArrow($node013, 1, 0, 'STORE', \&collectStore1);
	$node013->addArrow($node014, 1, 0, 'but');
	$node013->addArrow($node016, 1, 0, 'and');
	$node013->addDefault($node017);
	$node014->addArrow($node015, 1, 0, 'without');
	$node015->addArrow($node015, 1, 0, 'ACTOR', \&collectActor);
	$node015->addArrow($node017, 1, 0, 'ACTOR', \&collectActor);
	$node016->addDefault($node007);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{with}}, {status => $o->{status}, accountToken => $value};
}

sub collectActive {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'active';
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{without}->{$value->bytes} = $value;
}

sub collectActor1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{actorHashes}}, $value;
}

sub collectEntrusted {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'entrusted';
}

sub collectIdle {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'idle';
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
}

sub collectRevoked {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{status} = 'revoked';
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectStore1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	for my $actorHash (@{$o->{actorHashes}}) {
	my $accountToken = CDS::AccountToken->new($value, $actorHash);
	push @{$o->{with}}, {status => $o->{status}, accountToken => $accountToken};
	}

	$o->{actorHashes} = [];
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME announce
# HTML TITLE Announce
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds announce');
	$ui->p('Announces yourself on your accounts.');
	$ui->space;
	$ui->command('cds announce KEYPAIR on STORE');
	$ui->command('… with (active|idle|revoked|entrusted) ACCOUNT*');
	$ui->command('… with (active|idle|revoked|entrusted) ACTOR* on STORE');
	$ui->command('… without ACTOR*');
	$ui->command('… with … and … and … but without …');
	$ui->p('Updates the public card of the indicated key pair on the indicated store. The indicated accounts are added or removed from the actor group on the card.');
	$ui->p('If no card exists, a minimalistic card is created.');
	$ui->p('Use this with care, as the generated card may not be compliant with the card produced by the actor.');
	$ui->space;
}

sub announceMe {
	my $o = shift;
	my $cmd = shift;

	$o->announceOnStore($o->{actor}->storageStore);
	$o->announceOnStore($o->{actor}->messagingStore) if $o->{actor}->messagingStore->id ne $o->{actor}->storageStore->id;
	$o->{ui}->space;
}

sub announceOnStore {
	my $o = shift;
	my $store = shift;

	$o->{ui}->space;
	$o->{ui}->title($store->url);
	my ($envelopeHash, $cardHash, $invalidReason, $storeError) = $o->{actor}->announce($store);
	return if defined $storeError;
	return $o->{ui}->pRed($invalidReason) if defined $invalidReason;
	$o->{ui}->pGreen('Announced');
}

sub announceKeyPair {
	my $o = shift;
	my $cmd = shift;

	$o->{actors} = [];
	$o->{with} = [];
	$o->{without} = {};
	$o->{now} = CDS->now;
	$cmd->collect($o);

	# List
	$o->{keyPair} = $o->{keyPairToken}->keyPair;
	my ($hashes, $listError) = $o->{store}->list($o->{keyPair}->publicKey->hash, 'public', 0, $o->{keyPair});
	return if defined $listError;

	# Check if there are more than one cards
	if (scalar @$hashes > 1) {
		$o->{ui}->space;
		$o->{ui}->p('This account contains more than one public card:');
		$o->{ui}->pushIndent;
		for my $hash (@$hashes) {
			$o->{ui}->line($o->{ui}->gold('cds show card ', $hash->hex, ' on ', $o->{storeUrl}));
		}
		$o->{ui}->popIndent;
		$o->{ui}->p('Remove all but the most recent card. Cards can be removed as follows:');
		my $keyPairReference = $o->{actor}->blueKeyPairReference($o->{keyPairToken});
		$o->{ui}->line($o->{ui}->gold('cds remove ', 'HASH', ' on ', $o->{storeUrl}, ' using ', $keyPairReference));
		$o->{ui}->space;
		return;
	}

	# Read the card
	my $cardRecord = scalar @$hashes ? $o->readCard($hashes->[0]) : CDS::Record->new;
	return if ! $cardRecord;

	# Parse
	my $builder = CDS::ActorGroupBuilder->new;
	$builder->parse($cardRecord, 0);

	# Apply the changes
	for my $change (@{$o->{with}}) {
		if ($change->{status} eq 'entrusted') {
			$builder->addEntrustedActor($change->{accountToken}->cliStore->url, $change->{accountToken}->actorHash);
			$builder->{entrustedActorsRevision} = $o->{now};
		} else {
			$builder->addMember($change->{accountToken}->cliStore->url, $change->{accountToken}->actorHash, $o->{now}, $change->{status});
		}
	}

	for my $hash (values %{$o->{without}}) {
		$builder->removeEntrustedActor($hash)
	}

	for my $member ($builder->members) {
		next if ! $o->{without}->{$member->hash->bytes};
		$builder->removeMember($member->storeUrl, $member->hash);
	}

	# Write the new card
	my $newCard = $builder->toRecord(0);
	$newCard->add('public key')->addHash($o->{keyPair}->publicKey->hash);

	for my $child ($cardRecord->children) {
		if ($child->bytes eq 'actor group') {
		} elsif ($child->bytes eq 'entrusted actors') {
		} elsif ($child->bytes eq 'public key') {
		} else {
			$newCard->addRecord($child);
		}
	}

	$o->announce($newCard, $hashes);
}

sub readCard {
	my $o = shift;
	my $envelopeHash = shift; die 'wrong type '.ref($envelopeHash).' for $envelopeHash' if defined $envelopeHash && ref $envelopeHash ne 'CDS::Hash';

	# Open the envelope
	my ($object, $storeError) = $o->{store}->get($envelopeHash, $o->{keyPair});
	return if defined $storeError;
	return $o->{ui}->error('Envelope object ', $envelopeHash->hex, ' not found.') if ! $object;

	my $envelope = CDS::Record->fromObject($object) // return $o->{ui}->error($envelopeHash->hex, ' is not a record.');
	my $cardHash = $envelope->child('content')->hashValue // return $o->{ui}->error($envelopeHash->hex, ' is not a valid envelope, because it has no content hash.');
	return $o->{ui}->error($envelopeHash->hex, ' has an invalid signature.') if ! CDS->verifyEnvelopeSignature($envelope, $o->{keyPair}->publicKey, $cardHash);

	# Read the card
	my ($cardObject, $storeError1) = $o->{store}->get($cardHash, $o->{keyPair});
	return if defined $storeError1;
	return $o->{ui}->error('Card object ', $cardHash->hex, ' not found.') if ! $cardObject;

	return CDS::Record->fromObject($cardObject) // return $o->{ui}->error($cardHash->hex, ' is not a record.');
}

sub applyChanges {
	my $o = shift;
	my $actorGroup = shift; die 'wrong type '.ref($actorGroup).' for $actorGroup' if defined $actorGroup && ref $actorGroup ne 'CDS::ActorGroup';
	my $status = shift;
	my $accounts = shift;

	for my $account (@$accounts) {
		$actorGroup->{$account->url} = {storeUrl => $account->cliStore->url, actorHash => $account->actorHash, revision => $o->{now}, status => $status};
	}
}

sub announce {
	my $o = shift;
	my $card = shift;
	my $sourceHashes = shift;

	my $inMemoryStore = CDS::InMemoryStore->create;

	# Serialize the card
	my $cardObject = $card->toObject;
	my $cardHash = $cardObject->calculateHash;
	$inMemoryStore->put($cardHash, $cardObject);
	$inMemoryStore->put($o->{keyPair}->publicKey->hash, $o->{keyPair}->publicKey->object);

	# Prepare the public envelope
	my $envelopeObject = $o->{keyPair}->createPublicEnvelope($cardHash)->toObject;
	my $envelopeHash = $envelopeObject->calculateHash;
	$inMemoryStore->put($envelopeHash, $envelopeObject);

	# Transfer
	my ($missingHash, $failedStore, $storeError) = $o->{keyPair}->transfer([$envelopeHash], $inMemoryStore, $o->{store});
	return if $storeError;
	return $o->{ui}->pRed('Object ', $missingHash, ' is missing.') if $missingHash;

	# Modify
	my $modifications = CDS::StoreModifications->new;
	$modifications->add($o->{keyPair}->publicKey->hash, 'public', $envelopeHash);
	for my $hash (@$sourceHashes) {
		$modifications->remove($o->{keyPair}->publicKey->hash, 'public', $hash);
	}

	my $modifyError = $o->{store}->modify($modifications, $o->{keyPair});
	return if $modifyError;

	$o->{ui}->pGreen('Announced on ', $o->{store}->url, '.');
}

# BEGIN AUTOGENERATED
package CDS::Commands::Book;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&book});
	$cds->addArrow($node000, 1, 0, 'book');
	$cds->addArrow($node001, 1, 0, 'book');
	$cds->addArrow($node002, 1, 0, 'book');
	$help->addArrow($node003, 1, 0, 'book');
	$node000->addArrow($node000, 1, 0, 'HASH', \&collectHash);
	$node000->addArrow($node004, 1, 0, 'HASH', \&collectHash);
	$node001->addArrow($node001, 1, 0, 'OBJECT', \&collectObject);
	$node001->addArrow($node006, 1, 0, 'OBJECT', \&collectObject);
	$node002->addArrow($node002, 1, 0, 'HASH', \&collectHash);
	$node002->addArrow($node006, 1, 0, 'HASH', \&collectHash);
	$node004->addArrow($node005, 1, 0, 'on');
	$node005->addArrow($node005, 1, 0, 'STORE', \&collectStore);
	$node005->addArrow($node006, 1, 0, 'STORE', \&collectStore);
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{hashes}}, $value;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{objectTokens}}, $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{stores}}, $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME store-book
# HTML TITLE Book
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds book OBJECT*');
	$ui->command('cds book HASH* on STORE*');
	$ui->p('Books all indicated objects and reports whether booking as successful.');
	$ui->space;
	$ui->command('cds book HASH*');
	$ui->p('As above, but uses the selected store.');
	$ui->space;
}

sub book {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPair} = $o->{actor}->preferredKeyPairToken->keyPair;
	$o->{hashes} = [];
	$o->{stores} = [];
	$o->{objectTokens} = [];
	$cmd->collect($o);

	# Use the selected store
	push @{$o->{stores}}, $o->{actor}->preferredStore if ! scalar @{$o->{stores}};

	# Book all hashes on all stores
	my %triedStores;
	for my $store (@{$o->{stores}}) {
		next if $triedStores{$store->url};
		$triedStores{$store->url} = 1;
		for my $hash (@{$o->{hashes}}) {
			$o->process($store, $hash);
		}
	}

	# Book the direct object references
	for my $objectToken (@{$o->{objectTokens}}) {
		$o->process($objectToken->cliStore, $objectToken->hash);
	}

	# Warn the user if no key pair is selected
	return if ! $o->{hasErrors};
	return if $o->{keyPair};
	$o->{ui}->space;
	$o->{ui}->warning('Since no key pair is selected, the bookings were requested without signature. Stores are more likely to accept signed bookings. To add a signature, select a key pair using "cds use …", or create your key pair using "cds create my key pair".');
}

sub process {
	my $o = shift;
	my $store = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	# Upload the object
	my $success = $store->book($hash, $o->{keyPair});
	if ($success) {
		$o->{ui}->line($o->{ui}->green('OK          '), $hash->hex, ' on ', $store->url);
	} else {
		$o->{ui}->line($o->{ui}->red('not found   '), $hash->hex, ' on ', $store->url);
		$o->{hasErrors} = 1;
	}
}

# BEGIN AUTOGENERATED
package CDS::Commands::CheckKeyPair;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node011 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&checkKeyPair});
	$cds->addArrow($node004, 1, 0, 'check');
	$cds->addArrow($node005, 1, 0, 'fix');
	$help->addArrow($node000, 1, 0, 'check');
	$help->addArrow($node001, 1, 0, 'fix');
	$node000->addArrow($node002, 1, 0, 'key');
	$node001->addArrow($node003, 1, 0, 'key');
	$node002->addArrow($node010, 1, 0, 'pair');
	$node003->addArrow($node010, 1, 0, 'pair');
	$node004->addArrow($node006, 1, 0, 'key');
	$node005->addArrow($node007, 1, 0, 'key');
	$node006->addArrow($node008, 1, 0, 'pair');
	$node007->addArrow($node009, 1, 0, 'pair');
	$node008->addArrow($node011, 1, 0, 'FILE', \&collectFile);
	$node009->addArrow($node011, 1, 0, 'FILE', \&collectFile1);
}

sub collectFile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{file} = $value;
}

sub collectFile1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{file} = $value;
	$o->{fix} = 1;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME check-key-pair
# HTML TITLE Check key pair
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds check key pair FILE');
	$ui->p('Checks if the key pair FILE is complete, i.e. that a valid private key and a matching public key exists.');
	$ui->space;
}

sub checkKeyPair {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	# Check if we have a complete private key
	my $bytes = CDS->readBytesFromFile($o->{file}) // return $o->{ui}->error('The file "', $o->{file}, '" cannot be read.');
	my $record = CDS::Record->fromObject(CDS::Object->fromBytes($bytes));

	my $rsaKey = $record->child('rsa key');
	my $e = $rsaKey->child('e')->bytesValue;
	return $o->{ui}->error('The exponent "e" of the private key is missing.') if ! length $e;
	my $p = $rsaKey->child('p')->bytesValue;
	return $o->{ui}->error('The prime "p" of the private key is missing.') if ! length $p;
	my $q = $rsaKey->child('q')->bytesValue;
	return $o->{ui}->error('The prime "q" of the private key is missing.') if ! length $q;
	$o->{ui}->pGreen('The private key is complete.');

	# Derive the public key
	my $privateKey = CDS::C::privateKeyNew($e, $p, $q);
	my $publicKey = CDS::C::publicKeyFromPrivateKey($privateKey);
	my $n = CDS::C::publicKeyN($publicKey);

	# Check if we have a matching public key
	my $publicKeyObjectBytes = $record->child('public key object')->bytesValue;
	return $o->{ui}->error('The public key is missing.') if ! length $publicKeyObjectBytes;
	$o->{publicKeyObject} = CDS::Object->fromBytes($publicKeyObjectBytes) // return $o->{ui}->error('The public key is is not a valid Condensation object.');
	$o->{publicKeyHash} = $o->{publicKeyObject}->calculateHash;
	my $publicKeyRecord = CDS::Record->fromObject($o->{publicKeyObject});
	return $o->{ui}->error('The public key is not a valid record.') if ! $publicKeyRecord;
	my $publicN = $publicKeyRecord->child('n')->bytesValue;
	return $o->{ui}->error('The modulus "n" of the public key is missing.') if ! length $publicN;
	my $publicE = $publicKeyRecord->child('e')->bytesValue // $o->{ui}->error('The public key is incomplete.');
	return $o->{ui}->error('The exponent "e" of the public key is missing.') if ! length $publicE;
	return $o->{ui}->error('The exponent "e" of the public key does not match the exponent "e" of the private key.') if $publicE ne $e;
	return $o->{ui}->error('The modulus "n" of the public key does not correspond to the primes "p" and "q" of the private key.') if $publicN ne $n;
	$o->{ui}->pGreen('The public key ', $o->{publicKeyHash}->hex, ' is complete.');

	# At this point, the configuration looks good, and we can load the key pair
	CDS::KeyPair->fromRecord($record) // $o->{ui}->error('Your key pair looks complete, but could not be loaded.');
}

# BEGIN AUTOGENERATED
package CDS::Commands::CollectGarbage;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node004 = CDS::Parser::Node->new(0, {constructor => \&new, function => \&collectGarbage});
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0, {constructor => \&new, function => \&reportGarbage});
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&collectGarbage});
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&reportGarbage});
	$cds->addArrow($node001, 1, 0, 'report');
	$cds->addArrow($node002, 1, 0, 'collect');
	$help->addArrow($node000, 1, 0, 'collect');
	$node000->addArrow($node003, 1, 0, 'garbage');
	$node001->addArrow($node006, 1, 0, 'garbage');
	$node002->addArrow($node004, 1, 0, 'garbage');
	$node004->addArrow($node005, 1, 0, 'of');
	$node004->addDefault($node008);
	$node005->addArrow($node008, 1, 0, 'STORE', \&collectStore);
	$node006->addArrow($node007, 1, 0, 'of');
	$node006->addDefault($node009);
	$node007->addArrow($node009, 1, 0, 'STORE', \&collectStore);
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME collect-garbage
# HTML TITLE Garbage collection
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds collect garbage [of STORE]');
	$ui->p('Runs garbage collection. STORE must be a folder store. Objects not in use, and older than 1 day are removed from the store.');
	$ui->p('If no store is provided, garbage collection is run on the selected store, or the actor\'s storage store.');
	$ui->space;
	$ui->p('The store must not be written to while garbage collection is running. Objects booked during garbage collection may get deleted, and leave the store in a corrupt state. Reading from the store is fine.');
	$ui->space;
	$ui->command('cds report garbage [of STORE]');
	$ui->p('As above, but reports obsolete objects rather than deleting them. A protocol (shell script) is written to ".garbage" in the store folder.');
	$ui->space;
}

sub collectGarbage {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->run(CDS::Commands::CollectGarbage::Delete->new($o->{ui}));
}

sub wrapUpDeletion {
	my $o = shift;
	 }

sub reportGarbage {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->run(CDS::Commands::CollectGarbage::Report->new($o->{ui}));
	$o->{ui}->space;
}

# Creates a folder with the selected permissions.
sub run {
	my $o = shift;
	my $handler = shift;

	# Prepare
	my $store = $o->{store} // $o->{actor}->selectedStore // $o->{actor}->storageStore;
	my $folderStore = CDS::FolderStore->forUrl($store->url) // return $o->{ui}->error('"', $store->url, '" is not a folder store.');
	$handler->initialize($folderStore) // return;

	$o->{storeFolder} = $folderStore->folder;
	$o->{accountsFolder} = $folderStore->folder.'/accounts';
	$o->{objectsFolder} = $folderStore->folder.'/objects';
	my $dateLimit = time - 86400;
	my $envelopeExpirationLimit = time * 1000;

	# Read the tree index
	$o->readIndex;

	# Process all accounts
	$o->{ui}->space;
	$o->{ui}->title($o->{ui}->left(64, 'Accounts'), '   ', $o->{ui}->right(10, 'messages'), ' ', $o->{ui}->right(10, 'private'), ' ', $o->{ui}->right(10, 'public'), '   ', 'last modification');
	$o->startProgress('accounts');
	$o->{usedHashes} = {};
	$o->{missingObjects} = {};
	$o->{brokenOrigins} = {};
	my $countAccounts = 0;
	my $countKeptEnvelopes = 0;
	my $countDeletedEnvelopes = 0;
	for my $accountHash (sort { $$a cmp $$b } $folderStore->accounts) {
		# This would be the private key, but we don't use it right now
		$o->{usedHashes}->{$accountHash->hex} = 1;

		my $newestDate = 0;
		my %sizeByBox;
		my $accountFolder = $o->{accountsFolder}.'/'.$accountHash->hex;
		foreach my $boxLabel (CDS->listFolder($accountFolder)) {
			next if $boxLabel =~ /^\./;
			my $boxFolder = $accountFolder.'/'.$boxLabel;
			my $date = &lastModified($boxFolder);
			$newestDate = $date if $newestDate < $date;
			my $size = 0;
			foreach my $filename (CDS->listFolder($boxFolder)) {
				next if $filename =~ /^\./;
				my $hash = pack('H*', $filename);
				my $file = $boxFolder.'/'.$filename;

				my $timestamp = $o->envelopeExpiration($hash, $boxFolder);
				if ($timestamp > 0 && $timestamp < $envelopeExpirationLimit) {
					$countDeletedEnvelopes += 1;
					$handler->deleteEnvelope($file) // return;
					next;
				}

				$countKeptEnvelopes += 1;
				my $date = &lastModified($file);
				$newestDate = $date if $newestDate < $date;
				$size += $o->traverse($hash, $boxFolder);
			}
			$sizeByBox{$boxLabel} = $size;
		}

		$o->{ui}->line($accountHash->hex, '   ',
			$o->{ui}->right(10, $o->{ui}->niceFileSize($sizeByBox{'messages'} || 0)), ' ',
			$o->{ui}->right(10, $o->{ui}->niceFileSize($sizeByBox{'private'} || 0)), ' ',
			$o->{ui}->right(10, $o->{ui}->niceFileSize($sizeByBox{'public'} || 0)), '   ',
			$newestDate == 0 ? 'never' : $o->{ui}->niceDateTime($newestDate * 1000));

		$countAccounts += 1;
	}

	$o->{ui}->line($countAccounts, ' accounts traversed');
	$o->{ui}->space;

	# Mark all objects that are younger than 1 day (so that objects being uploaded right now but not linked yet remain)
	$o->{ui}->title('Objects');
	$o->startProgress('objects');

	my %objects;
	my @topFolders = sort grep {$_ !~ /^\./} CDS->listFolder($o->{objectsFolder});
	foreach my $topFolder (@topFolders) {
		my @files = sort grep {$_ !~ /^\./} CDS->listFolder($o->{objectsFolder}.'/'.$topFolder);
		foreach my $filename (@files) {
			$o->incrementProgress;
			my $hash = pack 'H*', $topFolder.$filename;
			my @s = stat $o->{objectsFolder}.'/'.$topFolder.'/'.$filename;
			$objects{$hash} = $s[7];
			next if $s[9] < $dateLimit;
			$o->traverse($hash, 'recent object');
		}
	}

	$o->{ui}->line(scalar keys %objects, ' objects traversed');
	$o->{ui}->space;

	# Delete all unmarked objects, and add the marked objects to the new tree index
	my $index = CDS::Record->new;
	my $countKeptObjects = 0;
	my $sizeKeptObjects = 0;
	my $countDeletedObjects = 0;
	my $sizeDeletedObjects = 0;

	$handler->startDeletion;
	$o->startProgress('delete-objects');
	for my $hash (keys %objects) {
		my $size = $objects{$hash};
		if (exists $o->{usedHashes}->{$hash}) {
			$countKeptObjects += 1;
			$sizeKeptObjects += $size;
			my $entry = $o->{index}->{$hash};
			$index->addRecord($entry) if $entry;
		} else {
			$o->incrementProgress;
			$countDeletedObjects += 1;
			$sizeDeletedObjects += $size;
			my $hashHex = unpack 'H*', $hash;
			my $file = $o->{objectsFolder}.'/'.substr($hashHex, 0, 2).'/'.substr($hashHex, 2);
			$handler->deleteObject($file) // return;
		}
	}

	# Write the new tree index
	CDS->writeBytesToFile($o->{storeFolder}.'/.index-new', $index->toObject->bytes);
	rename $o->{storeFolder}.'/.index-new', $o->{storeFolder}.'/.index';

	# Show what has been done
	$o->{ui}->space;
	$o->{ui}->line($countDeletedEnvelopes, ' ', $handler->{deletedEnvelopesText});
	$o->{ui}->line($countKeptEnvelopes, ' ', $handler->{keptEnvelopesText});
	my $line1 = $countDeletedObjects.' '.$handler->{deletedObjectsText};
	my $line2 = $countKeptObjects.' '.$handler->{keptObjectsText};
	my $maxLength = CDS->max(length $line1, length $line2);
	$o->{ui}->line($o->{ui}->left($maxLength, $line1), '  ', $o->{ui}->gray($o->{ui}->niceFileSize($sizeDeletedObjects)));
	$o->{ui}->line($o->{ui}->left($maxLength, $line2), '  ', $o->{ui}->gray($o->{ui}->niceFileSize($sizeKeptObjects)));
	$o->{ui}->space;
	$handler->wrapUp;

	my $missing = scalar keys %{$o->{missingObjects}};
	if ($missing) {
		$o->{ui}->warning($missing, ' objects are referenced from other objects, but missing:');

		my $count = 0;
		for my $hashBytes (sort keys %{$o->{missingObjects}}) {
			$o->{ui}->warning('  ', unpack('H*', $hashBytes));

			$count += 1;
			if ($missing > 10 && $count > 5) {
				$o->{ui}->warning('  …');
				last;
			}
		}

		$o->{ui}->space;
		$o->{ui}->warning('The missing objects are from the following origins:');
		for my $origin (sort keys %{$o->{brokenOrigins}}) {
			$o->{ui}->line('  ', $o->{ui}->orange($origin));
		}

		$o->{ui}->space;
	}
}

sub traverse {
	my $o = shift;
	my $hashBytes = shift;
	my $origin = shift;

	return $o->{usedHashes}->{$hashBytes} if exists $o->{usedHashes}->{$hashBytes};

	# Get index information about the object
	my $record = $o->index($hashBytes, $origin) // return 0;
	my $size = $record->nthChild(0)->asInteger;

	# Process children
	my $pos = 0;
	my $hashes = $record->nthChild(1)->bytes;
	while ($pos < length $hashes) {
		$size += $o->traverse(substr($hashes, $pos, 32), $origin);
		$pos += 32;
	}

	# Keep the size for future use
	$o->{usedHashes}->{$hashBytes} = $size;
	return $size;
}

sub readIndex {
	my $o = shift;

	$o->{index} = {};
	my $file = $o->{storeFolder}.'/.index';
	my $record = CDS::Record->fromObject(CDS::Object->fromBytes(CDS->readBytesFromFile($file))) // return;
	for my $child ($record->children) {
		$o->{index}->{$child->bytes} = $child;
	}
}

sub index {
	my $o = shift;
	my $hashBytes = shift;
	my $origin = shift;

	$o->incrementProgress;

	# Report a known result
	if ($o->{missingObjects}->{$hashBytes}) {
		$o->{brokenOrigins}->{$origin} = 1;
		return;
	}

	return $o->{index}->{$hashBytes} if exists $o->{index}->{$hashBytes};

	# Object file
	my $hashHex = unpack 'H*', $hashBytes;
	my $file = $o->{objectsFolder}.'/'.substr($hashHex, 0, 2).'/'.substr($hashHex, 2);

	# Size and existence
	my @s = stat $file;
	if (! scalar @s) {
		$o->{missingObjects}->{$hashBytes} = 1;
		$o->{brokenOrigins}->{$origin} = 1;
		return;
	}
	my $size = $s[7];
	return $o->{ui}->error('Unexpected: object ', $hashHex, ' has ', $size, ' bytes') if $size < 4;

	# Read header
	open O, '<', $file;
	read O, my $buffer, 4;
	my $links = unpack 'L>', $buffer;
	return $o->{ui}->error('Unexpected: object ', $hashHex, ' has ', $links, ' references') if $links > 160000;
	return $o->{ui}->error('Unexpected: object ', $hashHex, ' is too small for ', $links, ' references') if 4 + $links * 32 > $s[7];
	my $hashes = '';
	read O, $hashes, $links * 32 if $links > 0;
	close O;

	return $o->{ui}->error('Incomplete read: ', length $hashes, ' out of ', $links * 32, ' bytes received.') if length $hashes != $links * 32;

	my $record = CDS::Record->new($hashBytes);
	$record->addInteger($size);
	$record->add($hashes);
	return $o->{index}->{$hashBytes} = $record;
}

sub envelopeExpiration {
	my $o = shift;
	my $hashBytes = shift;
	my $origin = shift;

	my $entry = $o->index($hashBytes, $origin) // return 0;
	return $entry->nthChild(2)->asInteger if scalar $entry->children > 2;

	# Object file
	my $hashHex = unpack 'H*', $hashBytes;
	my $file = $o->{objectsFolder}.'/'.substr($hashHex, 0, 2).'/'.substr($hashHex, 2);
	my $record = CDS::Record->fromObject(CDS::Object->fromBytes(CDS->readBytesFromFile($file)));
	my $expires = $record->child('expires')->integerValue;
	$entry->addInteger($expires);
	return $expires;
}

sub startProgress {
	my $o = shift;
	my $title = shift;

	$o->{progress} = 0;
	$o->{progressTitle} = $title;
	$o->{ui}->progress($o->{progress}, ' ', $o->{progressTitle});
}

sub incrementProgress {
	my $o = shift;

	$o->{progress} += 1;
	return if $o->{progress} % 100;
	$o->{ui}->progress($o->{progress}, ' ', $o->{progressTitle});
}

sub lastModified {
	my $file = shift;

	my @s = stat $file;
	return scalar @s ? $s[9] : 0;
}

package CDS::Commands::CollectGarbage::Delete;

sub new {
	my $class = shift;
	my $ui = shift;

	return bless {
		ui => $ui,
		deletedEnvelopesText => 'expired envelopes deleted',
		keptEnvelopesText => 'envelopes kept',
		deletedObjectsText => 'objects deleted',
		keptObjectsText => 'objects kept',
		};
}

sub initialize {
	my $o = shift;
	my $folder = shift;
	 1 }

sub startDeletion {
	my $o = shift;

	$o->{ui}->title('Deleting obsolete objects');
}

sub deleteEnvelope {
	my $o = shift;
	my $file = shift;
	 $o->deleteObject($file) }

sub deleteObject {
	my $o = shift;
	my $file = shift;

	unlink $file // return $o->{ui}->error('Unable to delete "', $file, '". Giving up …');
	return 1;
}

sub wrapUp {
	my $o = shift;
	 }

package CDS::Commands::CollectGarbage::Report;

sub new {
	my $class = shift;
	my $ui = shift;

	return bless {
		ui => $ui,
		countReported => 0,
		deletedEnvelopesText => 'envelopes have expired',
		keptEnvelopesText => 'envelopes are in use',
		deletedObjectsText => 'objects can be deleted',
		keptObjectsText => 'objects are in use',
		};
}

sub initialize {
	my $o = shift;
	my $folderStore = shift;

	$o->{file} = $folderStore->folder.'/.garbage';
	open($o->{fh}, '>', $o->{file}) || return $o->{ui}->error('Failed to open ', $o->{file}, ' for writing.');
	return 1;
}

sub startDeletion {
	my $o = shift;

	$o->{ui}->title('Deleting obsolete objects');
}

sub deleteEnvelope {
	my $o = shift;
	my $file = shift;
	 $o->deleteObject($file) }

sub deleteObject {
	my $o = shift;
	my $file = shift;

	my $fh = $o->{fh};
	print $fh 'rm ', $file, "\n";
	$o->{countReported} += 1;
	print $fh 'echo ', $o->{countReported}, ' files deleted', "\n" if $o->{countReported} % 100 == 0;
	return 1;
}

sub wrapUp {
	my $o = shift;

	close $o->{fh};
	if ($o->{countReported} == 0) {
		unlink $o->{file};
	} else {
		$o->{ui}->space;
		$o->{ui}->p('The report was written to ', $o->{file}, '.');
		$o->{ui}->space;
	}
}

# BEGIN AUTOGENERATED
package CDS::Commands::CreateKeyPair;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node006 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&createKeyPair});
	$cds->addArrow($node002, 1, 0, 'create');
	$help->addArrow($node000, 1, 0, 'create');
	$node000->addArrow($node001, 1, 0, 'key');
	$node001->addArrow($node005, 1, 0, 'pair');
	$node002->addArrow($node003, 1, 0, 'key');
	$node003->addArrow($node004, 1, 0, 'pair');
	$node004->addArrow($node006, 1, 0, 'FILENAME', \&collectFilename);
}

sub collectFilename {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{filename} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME create-key-pair
# HTML TITLE Create key pair
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds create key pair FILENAME');
	$ui->p('Generates a key pair, and writes it to FILENAME.');
	$ui->space;
	$ui->title('Related commands');
	$ui->line('  cds select …');
	$ui->line('  cds use …');
	$ui->line('  cds entrust …');
	$ui->line('  cds drop …');
	$ui->space;
}

sub createKeyPair {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	return $o->{ui}->error('The file "', $o->{filename}, '" exists.') if -e $o->{filename};
	my $keyPair = CDS::KeyPair->generate;
	$keyPair->writeToFile($o->{filename}) // return $o->{ui}->error('Failed to write the key pair file "', $o->{filename}, '".');
	$o->{ui}->pGreen('Key pair "', $o->{filename}, '" created.');
}

# BEGIN AUTOGENERATED
package CDS::Commands::Curl;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node001 = CDS::Parser::Node->new(1);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlGet});
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlPut});
	my $node017 = CDS::Parser::Node->new(0);
	my $node018 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlBook});
	my $node019 = CDS::Parser::Node->new(0);
	my $node020 = CDS::Parser::Node->new(0);
	my $node021 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlList});
	my $node022 = CDS::Parser::Node->new(0);
	my $node023 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlGet});
	my $node024 = CDS::Parser::Node->new(0);
	my $node025 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlPut});
	my $node026 = CDS::Parser::Node->new(0);
	my $node027 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlBook});
	my $node028 = CDS::Parser::Node->new(0);
	my $node029 = CDS::Parser::Node->new(1);
	my $node030 = CDS::Parser::Node->new(0);
	my $node031 = CDS::Parser::Node->new(0);
	my $node032 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlList});
	my $node033 = CDS::Parser::Node->new(0);
	my $node034 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlGet});
	my $node035 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlPut});
	my $node036 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlBook});
	my $node037 = CDS::Parser::Node->new(1);
	my $node038 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlList});
	my $node039 = CDS::Parser::Node->new(0);
	my $node040 = CDS::Parser::Node->new(0);
	my $node041 = CDS::Parser::Node->new(0);
	my $node042 = CDS::Parser::Node->new(0);
	my $node043 = CDS::Parser::Node->new(0);
	my $node044 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlList});
	my $node045 = CDS::Parser::Node->new(1);
	my $node046 = CDS::Parser::Node->new(0);
	my $node047 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlModify});
	my $node048 = CDS::Parser::Node->new(0);
	my $node049 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlModify});
	my $node050 = CDS::Parser::Node->new(0);
	my $node051 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&curlModify});
	$cds->addArrow($node001, 1, 0, 'curl');
	$help->addArrow($node000, 1, 0, 'curl');
	$node001->addArrow($node002, 1, 0, 'get');
	$node001->addArrow($node003, 1, 0, 'put');
	$node001->addArrow($node004, 1, 0, 'book');
	$node001->addArrow($node005, 1, 0, 'get');
	$node001->addArrow($node006, 1, 0, 'book');
	$node001->addArrow($node007, 1, 0, 'list');
	$node001->addArrow($node007, 1, 0, 'watch', \&collectWatch);
	$node001->addDefault($node011);
	$node002->addArrow($node013, 1, 0, 'HASH', \&collectHash);
	$node003->addArrow($node016, 1, 0, 'FILE', \&collectFile);
	$node004->addArrow($node018, 1, 0, 'HASH', \&collectHash);
	$node005->addArrow($node023, 1, 0, 'OBJECT', \&collectObject);
	$node006->addArrow($node027, 1, 0, 'OBJECT', \&collectObject);
	$node007->addArrow($node008, 1, 0, 'message');
	$node007->addArrow($node009, 1, 0, 'private');
	$node007->addArrow($node010, 1, 0, 'public');
	$node007->addArrow($node021, 0, 0, 'messages', \&collectMessages);
	$node007->addArrow($node021, 0, 0, 'private', \&collectPrivate);
	$node007->addArrow($node021, 0, 0, 'public', \&collectPublic);
	$node008->addArrow($node021, 1, 0, 'box', \&collectMessages);
	$node009->addArrow($node021, 1, 0, 'box', \&collectPrivate);
	$node010->addArrow($node021, 1, 0, 'box', \&collectPublic);
	$node011->addArrow($node012, 1, 0, 'remove');
	$node011->addArrow($node020, 1, 0, 'add');
	$node012->addArrow($node012, 1, 0, 'HASH', \&collectHash1);
	$node012->addArrow($node037, 1, 0, 'HASH', \&collectHash1);
	$node013->addArrow($node014, 1, 0, 'from');
	$node013->addArrow($node015, 0, 0, 'on');
	$node013->addDefault($node023);
	$node014->addArrow($node023, 1, 0, 'STORE', \&collectStore);
	$node015->addArrow($node023, 0, 0, 'STORE', \&collectStore);
	$node016->addArrow($node017, 1, 0, 'onto');
	$node016->addDefault($node025);
	$node017->addArrow($node025, 1, 0, 'STORE', \&collectStore);
	$node018->addArrow($node019, 1, 0, 'on');
	$node018->addDefault($node027);
	$node019->addArrow($node027, 1, 0, 'STORE', \&collectStore);
	$node020->addArrow($node029, 1, 0, 'FILE', \&collectFile1);
	$node020->addArrow($node029, 1, 0, 'HASH', \&collectHash2);
	$node021->addArrow($node022, 1, 0, 'of');
	$node022->addArrow($node032, 1, 0, 'ACTOR', \&collectActor);
	$node023->addArrow($node024, 1, 0, 'using');
	$node024->addArrow($node034, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node025->addArrow($node026, 1, 0, 'using');
	$node026->addArrow($node035, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node027->addArrow($node028, 1, 0, 'using');
	$node028->addArrow($node036, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node029->addDefault($node020);
	$node029->addArrow($node030, 1, 0, 'and');
	$node029->addArrow($node040, 1, 0, 'to');
	$node030->addArrow($node031, 1, 0, 'remove');
	$node031->addArrow($node031, 1, 0, 'HASH', \&collectHash1);
	$node031->addArrow($node037, 1, 0, 'HASH', \&collectHash1);
	$node032->addArrow($node033, 1, 0, 'on');
	$node033->addArrow($node038, 1, 0, 'STORE', \&collectStore);
	$node037->addArrow($node040, 1, 0, 'from');
	$node038->addArrow($node039, 1, 0, 'using');
	$node039->addArrow($node044, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node040->addArrow($node041, 1, 0, 'message');
	$node040->addArrow($node042, 1, 0, 'private');
	$node040->addArrow($node043, 1, 0, 'public');
	$node040->addArrow($node045, 0, 0, 'messages', \&collectMessages1);
	$node040->addArrow($node045, 0, 0, 'private', \&collectPrivate1);
	$node040->addArrow($node045, 0, 0, 'public', \&collectPublic1);
	$node041->addArrow($node045, 1, 0, 'box', \&collectMessages1);
	$node042->addArrow($node045, 1, 0, 'box', \&collectPrivate1);
	$node043->addArrow($node045, 1, 0, 'box', \&collectPublic1);
	$node045->addArrow($node046, 1, 0, 'of');
	$node045->addDefault($node047);
	$node046->addArrow($node047, 1, 0, 'ACTOR', \&collectActor1);
	$node047->addArrow($node011, 1, 0, 'and', \&collectAnd);
	$node047->addArrow($node048, 1, 0, 'on');
	$node048->addArrow($node049, 1, 0, 'STORE', \&collectStore);
	$node049->addArrow($node050, 1, 0, 'using');
	$node050->addArrow($node051, 1, 0, 'KEYPAIR', \&collectKeypair);
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectActor1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{currentBatch}->{actorHash} = $value;
}

sub collectAnd {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{batches}}, $o->{currentBatch};
	$o->{currentBatch} = {
	addHashes => [],
	addEnvelopes => [],
	removeHashes => []
	};
}

sub collectFile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{file} = $value;
}

sub collectFile1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{currentBatch}->{addFiles}}, $value;
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
}

sub collectHash1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{currentBatch}->{removeHashes}}, $value;
}

sub collectHash2 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{currentBatch}->{addHashes}}, $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
}

sub collectMessages {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabel} = 'messages';
}

sub collectMessages1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{currentBatch}->{boxLabel} = 'messages';
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value->hash;
	$o->{store} = $value->cliStore;
}

sub collectPrivate {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabel} = 'private';
}

sub collectPrivate1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{currentBatch}->{boxLabel} = 'private';
}

sub collectPublic {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabel} = 'public';
}

sub collectPublic1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{currentBatch}->{boxLabel} = 'public';
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectWatch {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{watchTimeout} = 60000;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME curl
# HTML TITLE Curl
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->p($ui->blue('cds curl'), ' prepares and executes a CURL command line for a HTTP store request. This is helpful for debugging a HTTP store implementation. Outside of low-level debugging, it is more convenient to use the "cds get|put|list|add|remove …" commands, which are richer in functionality, and work on all stores.');
	$ui->space;
	$ui->command('cds curl get OBJECT');
	$ui->command('cds curl get HASH [from|on STORE]');
	$ui->p('Downloads an object with a GET request on an object store.');
	$ui->space;
	$ui->command('cds curl put FILE [onto STORE]');
	$ui->p('Uploads an object with a PUT request on an object store.');
	$ui->space;
	$ui->command('cds curl book OBJECT');
	$ui->command('cds curl book HASH [on STORE]');
	$ui->p('Books an object with a POST request on an object store.');
	$ui->space;
	$ui->command('cds curl list message box of ACTOR [on STORE]');
	$ui->command('cds curl list private box of ACTOR [on STORE]');
	$ui->command('cds curl list public box of ACTOR [on STORE]');
	$ui->p('Lists the indicated box with a GET request on an account store.');
	$ui->space;
	$ui->command('cds curl watch message box of ACTOR [on STORE]');
	$ui->command('cds curl watch private box of ACTOR [on STORE]');
	$ui->command('cds curl watch public box of ACTOR [on STORE]');
	$ui->p('As above, but with a watch timeout of 60 second.');
	$ui->space;
	$ui->command('cds curl add (FILE|HASH)* to (message|private|public) box of ACTOR [and …] [on STORE]');
	$ui->command('cds curl remove HASH* from (message|private|public) box of ACTOR [and …] [on STORE]');
	$ui->p('Modifies the indicated boxes with a POST request on an account store. Multiple modifications to different boxes may be chained using "and". All modifications are submitted using a single request, which is optionally signed (see below).');
	$ui->space;
	$ui->command('… using KEYPAIR');
	$ui->p('Signs the request using KEYPAIR instead of the actor\'s key pair. The store may or may not verify the signature.');
	$ui->p('For debugging purposes, information about the signature is stored as ".cds-curl-bytes-to-sign", ".cds-curl-hash-to-sign", and ".cds-curl-signature" in the current folder. Note that signatures are valid for 1-2 minutes only. After that, servers will reject them to guard against replay attacks.');
	$ui->space;
}

sub curlGet {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken if ! $o->{keyPairToken};
	$o->{store} = $o->{actor}->preferredStore if ! $o->{store};

	my $objectToken = CDS::ObjectToken->new($o->{store}, $o->{hash});
	$o->curlRequest('GET', $objectToken->url, ['--output', $o->{hash}->hex]);
}

sub curlPut {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken if ! $o->{keyPairToken};
	$o->{store} = $o->{actor}->preferredStore if ! $o->{store};

	my $bytes = CDS->readBytesFromFile($o->{file}) // return $o->{ui}->error('Unable to read "', $o->{file}, '".');
	my $hash = CDS::Hash->calculateFor($bytes);
	my $objectToken = CDS::ObjectToken->new($o->{store}, $hash);
	$o->curlRequest('PUT', $objectToken->url, ['--data-binary', '@'.$o->{file}, '-H', 'Content-Type: application/condensation-object']);
}

sub curlBook {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken if ! $o->{keyPairToken};
	$o->{store} = $o->{actor}->preferredStore if ! $o->{store};

	my $objectToken = CDS::ObjectToken->new($o->{store}, $o->{hash});
	$o->curlRequest('POST', $objectToken->url, []);
}

sub curlList {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken if ! $o->{keyPairToken};
	$o->{store} = $o->{actor}->preferredStore if ! $o->{store};
	$o->{actorHash} = $o->{actor}->preferredActorHash if ! $o->{actorHash};

	my $boxToken = CDS::BoxToken->new(CDS::AccountToken->new($o->{store}, $o->{actorHash}), $o->{boxLabel});
	my $args = ['--output', '.cds-curl-list'];
	push @$args, '-H', 'Condensation-Watch: '.$o->{watchTimeout}.' ms' if $o->{watchTimeout};
	$o->curlRequest('GET', $boxToken->url, $args);
}

sub curlModify {
	my $o = shift;
	my $cmd = shift;

	$o->{currentBatch} = {
		addHashes => [],
		addEnvelopes => [],
		removeHashes => [],
		};
	$o->{batches} = [];
	$cmd->collect($o);
	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken if ! $o->{keyPairToken};
	$o->{store} = $o->{actor}->preferredStore if ! $o->{store};

	# Prepare the modifications
	my $modifications = CDS::StoreModifications->new;

	for my $batch (@{$o->{batches}}, $o->{currentBatch}) {
		$batch->{actorHash} = $o->{actor}->preferredActorHash if ! $batch->{actorHash};

		for my $hash (@{$batch->{addHashes}}) {
			$modifications->add($batch->{actorHash}, $batch->{boxLabel}, $hash);
		}

		for my $file (@{$batch->{addFiles}}) {
			my $bytes = CDS->readBytesFromFile($file) // return $o->{ui}->error('Unable to read "', $file, '".');
			my $object = CDS::Object->fromBytes($bytes) // return $o->{ui}->error('"', $file, '" is not a Condensation object.');
			my $hash = $object->calculateHash;
			$o->{ui}->warning('"', $file, '" is not a valid envelope. The server may reject it.') if ! $o->{actor}->isEnvelope($object);
			$modifications->add($batch->{actorHash}, $batch->{boxLabel}, $hash, $object);
		}

		for my $hash (@{$batch->{removeHashes}}) {
			$modifications->remove($batch->{actorHash}, $batch->{boxLabel}, $hash);
		}
	}

	$o->{ui}->warning('You didn\'t specify any changes. The server should accept, but ignore this.') if $modifications->isEmpty;

	# Write a new file
	my $modificationsObject = $modifications->toRecord->toObject;
	my $modificationsHash = $modificationsObject->calculateHash;
	my $file = '.cds-curl-modifications-'.substr($modificationsHash->hex, 0, 8);
	CDS->writeBytesToFile($file, $modificationsObject->header, $modificationsObject->data) // return $o->{ui}->error('Unable to write modifications to "', $file, '".');
	$o->{ui}->line(scalar @{$modifications->additions}, ' addition(s) and ', scalar @{$modifications->removals}, ' removal(s) written to "', $file, '".');

	# Submit
	$o->curlRequest('POST', $o->{store}->url.'/accounts', ['--data-binary', '@'.$file, '-H', 'Content-Type: application/condensation-modifications'], $modificationsObject);
}

sub curlRequest {
	my $o = shift;
	my $method = shift;
	my $url = shift;
	my $curlArgs = shift;
	my $contentObjectToSign = shift;

	# Parse the URL
	$url =~ /^(https?):\/\/([^\/]+)(\/.*|)$/i || return $o->{ui}->error('"', $url, '" does not look like a valid and complete http://… or https://… URL.');
	my $protocol = lc($1);
	my $host = $2;
	my $path = $3;

	# Strip off user and password, if any
	my $credentials;
	if ($host =~ /^(.*)\@([^\@]*)$/) {
		$credentials = $1;
		$host = lc($2);
	} else {
		$host = lc($host);
	}

	# Remove default port
	if ($host =~ /^(.*):(\d+)$/) {
		$host = $1 if $protocol eq 'http' && $2 == 80;
		$host = $1 if $protocol eq 'https' && $2 == 443;
	}

	# Checks the path and warn the user if obvious things are likely to go wrong
	$o->{ui}->warning('Warning: "//" in URL may not work') if $path =~ /\/\//;
	$o->{ui}->warning('Warning: /./ or /../ in URL may not work') if $path =~ /\/\.+\//;
	$o->{ui}->warning('Warning: /. or /.. at the end of the URL may not work') if $path =~ /\/\.+$/;

	# Signature

	# Date
	my $dateString = CDS::ISODate->millisecondString(CDS->now);

	# Text to sign
	my $bytesToSign = $dateString."\0".uc($method)."\0".$host.$path;
	$bytesToSign .= "\0".$contentObjectToSign->header.$contentObjectToSign->data if defined $contentObjectToSign;

	# Signature
	my $keyPair = $o->{keyPairToken}->keyPair;
	my $hashToSign = CDS::Hash->calculateFor($bytesToSign);
	my $signature = $keyPair->signHash($hashToSign);
	push @$curlArgs, '-H', 'Condensation-Date: '.$dateString;
	push @$curlArgs, '-H', 'Condensation-Actor: '.$keyPair->publicKey->hash->hex;
	push @$curlArgs, '-H', 'Condensation-Signature: '.unpack('H*', $signature);

	# Write signature information to files
	CDS->writeBytesToFile('.cds-curl-bytesToSign', $bytesToSign) || $o->{ui}->warning('Unable to write the bytes to sign to ".cds-curl-bytesToSign".');
	CDS->writeBytesToFile('.cds-curl-hashToSign', $hashToSign->bytes) || $o->{ui}->warning('Unable to write the hash to sign to ".cds-curl-hashToSign".');
	CDS->writeBytesToFile('.cds-curl-signature', $signature) || $o->{ui}->warning('Unable to write signature to ".cds-curl-signature".');

	# Method
	unshift @$curlArgs, '-X', $method if $method ne 'GET';
	unshift @$curlArgs, '-#', '--dump-header', '-';

	# Print
	$o->{ui}->line($o->{ui}->gold('curl', join('', map { ($_ ne '-X' && $_ ne '-' && $_ ne '--dump-header' && $_ ne '-#' && substr($_, 0, 1) eq '-' ? " \\\n     " : ' ').&withQuotesIfNecessary($_) } @$curlArgs), scalar @$curlArgs ? " \\\n     " : ' ', &withQuotesIfNecessary($url)));

	# Execute
	system('curl', @$curlArgs, $url);
}

sub withQuotesIfNecessary {
	my $text = shift;

	return $text =~ /[^a-zA-Z0-9\.\/\@:,_-]/ ? '\''.$text.'\'' : $text;
}

# BEGIN AUTOGENERATED
package CDS::Commands::DiscoverActorGroup;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node002 = CDS::Parser::Node->new(1);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showActorGroupCmd});
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&discover});
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&discover});
	$cds->addArrow($node000, 1, 0, 'show');
	$cds->addArrow($node002, 1, 0, 'discover');
	$help->addArrow($node001, 1, 0, 'discover');
	$help->addArrow($node001, 1, 0, 'rediscover');
	$node000->addArrow($node006, 1, 0, 'ACTORGROUP', \&collectActorgroup);
	$node002->addDefault($node003);
	$node002->addDefault($node004);
	$node002->addDefault($node005);
	$node002->addArrow($node009, 1, 0, 'me', \&collectMe);
	$node002->addArrow($node013, 1, 0, 'ACTORGROUP', \&collectActorgroup1);
	$node003->addArrow($node003, 1, 0, 'ACCOUNT', \&collectAccount);
	$node003->addArrow($node009, 1, 1, 'ACCOUNT', \&collectAccount);
	$node004->addArrow($node004, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node004->addArrow($node007, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node005->addArrow($node005, 1, 0, 'ACTOR', \&collectActor);
	$node005->addArrow($node007, 1, 0, 'ACTOR', \&collectActor);
	$node007->addArrow($node008, 1, 0, 'on');
	$node007->addDefault($node009);
	$node008->addArrow($node009, 1, 0, 'STORE', \&collectStore);
	$node009->addArrow($node010, 1, 0, 'and');
	$node010->addArrow($node011, 1, 0, 'remember');
	$node011->addArrow($node012, 1, 0, 'as');
	$node012->addArrow($node013, 1, 0, 'TEXT', \&collectText);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accounts}}, $value;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{actorHashes}}, $value;
}

sub collectActorgroup {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorGroupToken} = $value;
}

sub collectActorgroup1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorGroupToken} = $value;
	$o->{label} = $value->label;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{actorHashes}}, $value->keyPair->publicKey->hash;
}

sub collectMe {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{me} = 1;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectText {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{label} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME discover
# HTML TITLE Discover actor groups
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds discover ACCOUNT');
	$ui->command('cds discover ACTOR [on STORE]');
	$ui->p('Discovers the actor group the given account belongs to. Only active group members are discovered.');
	$ui->space;
	$ui->command('cds discover ACCOUNT*');
	$ui->command('cds discover ACTOR* on STORE');
	$ui->p('Same as above, but starts discovery with multiple accounts. All accounts must belong to the same actor group.');
	$ui->p('Note that this rarely makes sense. The actor group discovery algorithm reliably discovers an actor group from a single account.');
	$ui->space;
	$ui->command('cds discover me');
	$ui->p('Discovers your own actor group.');
	$ui->space;
	$ui->command('… and remember as TEXT');
	$ui->p('The discovered actor group is remembered as TEXT. See "cds help remember" for details.');
	$ui->space;
	$ui->command('cds discover ACTORGROUP');
	$ui->p('Updates a previously remembered actor group.');
	$ui->space;
	$ui->command('cds show ACTORGROUP');
	$ui->p('Shows a previously discovered and remembered actor group.');
	$ui->space;
}

sub discover {
	my $o = shift;
	my $cmd = shift;

	$o->{accounts} = [];
	$o->{actorHashes} = [];
	$cmd->collect($o);

	# Discover
	my $builder = $o->prepareBuilder;
	my ($actorGroup, $cards, $nodes) = $builder->discover($o->{actor}->keyPair, $o);

	# Show the graph
	$o->{ui}->space;
	$o->{ui}->title('Graph');
	for my $node (@$nodes) {
		my $status = $node->status eq 'active' ? $o->{ui}->green('active  ') : $o->{ui}->gray('idle    ');
		$o->{ui}->line($o->{ui}->blue($node->actorHash->hex), ' on ', $node->storeUrl, '  ', $status, $o->{ui}->gray($o->{ui}->niceDateTime($node->revision)));
		$o->{ui}->pushIndent;
		for my $link ($node->links) {
			my $isMostRecentInformation = $link->revision == $link->node->revision;
			my $color = $isMostRecentInformation ? 246 : 250;
			$o->{ui}->line($link->node->actorHash->shortHex, ' on ', $link->node->storeUrl, '  ', $o->{ui}->foreground($color, $o->{ui}->left(8, $link->status), $o->{ui}->niceDateTime($link->revision)));
		}
		$o->{ui}->popIndent;
	}

	# Show all accounts
	$o->showActorGroup($actorGroup);

	# Show all cards
	$o->{ui}->space;
	$o->{ui}->title('Cards');
	for my $card (@$cards) {
		$o->{ui}->line($o->{ui}->gold('cds show record ', $card->cardHash->hex, ' on ', $card->storeUrl));
	}

	# Remember the actor group if desired
	if ($o->{label}) {
		my $selector = $o->{actor}->labelSelector($o->{label});

		my $record = CDS::Record->new;
		my $actorGroupRecord = $record->add('actor group');
		$actorGroupRecord->add('discovered')->addInteger(CDS->now);
		$actorGroupRecord->addRecord($actorGroup->toBuilder->toRecord(1)->children);
		$selector->set($record);

		for my $publicKey ($actorGroup->publicKeys) {
			$selector->addObject($publicKey->hash, $publicKey->object);
		}

		$o->{actor}->saveOrShowError // return;
	}

	$o->{ui}->space;
}

sub prepareBuilder {
	my $o = shift;

	# Actor group
	return $o->{actorGroupToken}->actorGroup->toBuilder if $o->{actorGroupToken};

	# Other than actor group
	my $builder = CDS::ActorGroupBuilder->new;
	$builder->addKnownPublicKey($o->{actor}->keyPair->publicKey);

	# Me
	$builder->addMember($o->{actor}->messagingStoreUrl, $o->{actor}->keyPair->publicKey->hash) if $o->{me};

	# Accounts
	for my $account (@{$o->{accounts}}) {
		$builder->addMember($account->cliStore->url, $account->actorHash);
	}

	# Actors on store
	if (scalar @{$o->{actorHashes}}) {
		my $store = $o->{store} // $o->{actor}->preferredStore;
		for my $actorHash (@{$o->{actorHashes}}) {
			$builder->addMember($actorHash, $store->url);
		}
	}

	return $builder;
}

sub showActorGroupCmd {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->showActorGroup($o->{actorGroupToken}->actorGroup);
	$o->{ui}->space;
}

sub showActorGroup {
	my $o = shift;
	my $actorGroup = shift; die 'wrong type '.ref($actorGroup).' for $actorGroup' if defined $actorGroup && ref $actorGroup ne 'CDS::ActorGroup';

	$o->{ui}->space;
	$o->{ui}->title(length $o->{label} ? 'Actors of '.$o->{label} : 'Actor group');
	for my $member ($actorGroup->members) {
		my $date = $member->revision ? $o->{ui}->niceDateTimeLocal($member->revision) : '                   ';
		my $status = $member->isActive ? $o->{ui}->green('active  ') : $o->{ui}->gray('idle    ');
		my $storeReference = $o->{actor}->blueStoreUrlReference($member->storeUrl);
		$o->{ui}->line($o->{ui}->gray($date), '  ', $status, '  ', $member->actorOnStore->publicKey->hash->hex, ' on ', $storeReference);
	}

	if ($actorGroup->entrustedActorsRevision) {
		$o->{ui}->space;
		$o->{ui}->title(length $o->{label} ? 'Actors entrusted by '.$o->{label} : 'Entrusted actors');
		$o->{ui}->line($o->{ui}->gray($o->{ui}->niceDateTimeLocal($actorGroup->entrustedActorsRevision)));
		for my $actor ($actorGroup->entrustedActors) {
			my $storeReference = $o->{actor}->storeUrlReference($actor->storeUrl);
			$o->{ui}->line($actor->actorOnStore->publicKey->hash->hex, $o->{ui}->gray(' on ', $storeReference));
		}

		$o->{ui}->line($o->{ui}->gray('(none)')) if ! scalar $actorGroup->entrustedActors;
	}
}

sub onDiscoverActorGroupVerifyStore {
	my $o = shift;
	my $storeUrl = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';

	return $o->{actor}->storeForUrl($storeUrl);
}

sub onDiscoverActorGroupInvalidPublicKey {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';
	my $store = shift;
	my $reason = shift;

	$o->{ui}->warning('Public key ', $actorHash->hex, ' on ', $store->url, ' is invalid: ', $reason);
}

sub onDiscoverActorGroupInvalidCard {
	my $o = shift;
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $envelopeHash = shift; die 'wrong type '.ref($envelopeHash).' for $envelopeHash' if defined $envelopeHash && ref $envelopeHash ne 'CDS::Hash';
	my $reason = shift;

	$o->{ui}->warning('Card ', $envelopeHash->hex, ' on ', $actorOnStore->store->url, ' is invalid: ', $reason);
}

sub onDiscoverActorGroupStoreError {
	my $o = shift;
	my $store = shift;
	my $error = shift;

}

# BEGIN AUTOGENERATED
package CDS::Commands::EntrustedActors;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node011 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&show});
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&doNotEntrust});
	my $node015 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&entrust});
	my $node016 = CDS::Parser::Node->new(0);
	$cds->addArrow($node001, 1, 0, 'show');
	$cds->addArrow($node003, 1, 0, 'do');
	$cds->addArrow($node005, 1, 0, 'entrust');
	$help->addArrow($node000, 1, 0, 'entrusted');
	$node000->addArrow($node010, 1, 0, 'actors');
	$node001->addArrow($node002, 1, 0, 'entrusted');
	$node002->addArrow($node011, 1, 0, 'actors');
	$node003->addArrow($node004, 1, 0, 'not');
	$node004->addArrow($node008, 1, 0, 'entrust');
	$node005->addDefault($node006);
	$node005->addDefault($node007);
	$node005->addArrow($node012, 1, 0, 'ACTOR', \&collectActor);
	$node006->addArrow($node006, 1, 0, 'ACCOUNT', \&collectAccount);
	$node006->addArrow($node015, 1, 1, 'ACCOUNT', \&collectAccount);
	$node007->addArrow($node007, 1, 0, 'ACTOR', \&collectActor1);
	$node007->addArrow($node015, 1, 0, 'ACTOR', \&collectActor1);
	$node008->addDefault($node009);
	$node009->addArrow($node009, 1, 0, 'ACTOR', \&collectActor2);
	$node009->addArrow($node014, 1, 0, 'ACTOR', \&collectActor2);
	$node012->addArrow($node013, 1, 0, 'on');
	$node013->addArrow($node015, 1, 0, 'STORE', \&collectStore);
	$node015->addArrow($node016, 1, 0, 'and');
	$node016->addDefault($node005);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, $value;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectActor1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, CDS::AccountToken->new($o->{actor}->preferredStore, $value);
}

sub collectActor2 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{actorHashes}}, $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, CDS::AccountToken->new($value, $o->{actorHash});
	delete $o->{actorHash};
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME entrusted-actors
# HTML TITLE Entrusted actors
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show entrusted actors');
	$ui->p('Shows all entrusted actors.');
	$ui->space;
	$ui->command('cds entrust ACCOUNT*');
	$ui->command('cds entrust ACTOR on STORE');
	$ui->p('Adds the indicated entrusted actors. Entrusted actors can read our private data and messages. The public key of the entrusted actor must be available on the store.');
	$ui->space;
	$ui->command('cds do not entrust ACTOR*');
	$ui->p('Removes the indicated entrusted actors.');
	$ui->space;
	$ui->p('After modifying the entrusted actors, you should "cds announce" yourself to publish the changes.');
	$ui->space;
}

sub show {
	my $o = shift;
	my $cmd = shift;

	my $builder = CDS::ActorGroupBuilder->new;
	$builder->parseEntrustedActorList($o->{actor}->entrustedActorsSelector->record, 1);

	my @actors = $builder->entrustedActors;
	for my $actor (@actors) {
		my $storeReference = $o->{actor}->storeUrlReference($actor->storeUrl);
		$o->{ui}->line($actor->hash->hex, $o->{ui}->gray(' on ', $storeReference));
	}

	return if scalar @actors;
	$o->{ui}->line($o->{ui}->gray('none'));
}

sub entrust {
	my $o = shift;
	my $cmd = shift;

	$o->{accountTokens} = [];
	$cmd->collect($o);

	# Get the list of currently entrusted actors
	my $entrusted = $o->createEntrustedActorsIndex;

	# Add new actors
	for my $accountToken (@{$o->{accountTokens}}) {
		my $actorHash = $accountToken->actorHash;

		# Check if the key is already entrusted
		if ($entrusted->{$accountToken->url}) {
			$o->{ui}->pOrange($accountToken->url, ' is already entrusted.');
			next;
		}

		# Get the public key
		my ($publicKey, $invalidReason, $storeError) = $o->{actor}->keyPair->getPublicKey($actorHash, $accountToken->cliStore);
		if (defined $storeError) {
			$o->{ui}->pRed('Unable to get the public key ', $actorHash->hex, ' from ', $accountToken->cliStore->url, ': ', $storeError);
			next;
		}

		if (defined $invalidReason) {
			$o->{ui}->pRed('Unable to get the public key ', $actorHash->hex, ' from ', $accountToken->cliStore->url, ': ', $invalidReason);
			next;
		}

		# Add it
		$o->{actor}->entrust($accountToken->cliStore->url, $publicKey);
		$o->{ui}->pGreen($entrusted->{$actorHash->hex} ? 'Updated ' : 'Added ', $actorHash->hex, ' as entrusted actor.');
	}

	# Save
	$o->{actor}->saveOrShowError;
}

sub doNotEntrust {
	my $o = shift;
	my $cmd = shift;

	$o->{actorHashes} = [];
	$cmd->collect($o);

	# Get the list of currently entrusted actors
	my $entrusted = $o->createEntrustedActorsIndex;

	# Remove entrusted actors
	for my $actorHash (@{$o->{actorHashes}}) {
		if ($entrusted->{$actorHash->hex}) {
			$o->{actor}->doNotEntrust($actorHash);
			$o->{ui}->pGreen('Removed ', $actorHash->hex, ' from the list of entrusted actors.');
		} else {
			$o->{ui}->pOrange($actorHash->hex, ' is not entrusted.');
		}
	}

	# Save
	$o->{actor}->saveOrShowError;
}

sub createEntrustedActorsIndex {
	my $o = shift;

	my $builder = CDS::ActorGroupBuilder->new;
	$builder->parseEntrustedActorList($o->{actor}->entrustedActorsSelector->record, 1);

	my $index = {};
	for my $actor ($builder->entrustedActors) {
		my $url = $actor->storeUrl.'/accounts/'.$actor->hash->hex;
		$index->{$actor->hash->hex} = 1;
		$index->{$url} = 1;
	}

	return $index;
}

package CDS::Commands::FolderStore;

# BEGIN AUTOGENERATED

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(0);
	my $node017 = CDS::Parser::Node->new(0);
	my $node018 = CDS::Parser::Node->new(0);
	my $node019 = CDS::Parser::Node->new(0);
	my $node020 = CDS::Parser::Node->new(0);
	my $node021 = CDS::Parser::Node->new(0);
	my $node022 = CDS::Parser::Node->new(0);
	my $node023 = CDS::Parser::Node->new(0);
	my $node024 = CDS::Parser::Node->new(0);
	my $node025 = CDS::Parser::Node->new(1);
	my $node026 = CDS::Parser::Node->new(0);
	my $node027 = CDS::Parser::Node->new(0);
	my $node028 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node029 = CDS::Parser::Node->new(1);
	my $node030 = CDS::Parser::Node->new(0);
	my $node031 = CDS::Parser::Node->new(0);
	my $node032 = CDS::Parser::Node->new(0);
	my $node033 = CDS::Parser::Node->new(0);
	my $node034 = CDS::Parser::Node->new(0);
	my $node035 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&checkPermissions});
	my $node036 = CDS::Parser::Node->new(0);
	my $node037 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&fixPermissions});
	my $node038 = CDS::Parser::Node->new(0);
	my $node039 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showPermissions});
	my $node040 = CDS::Parser::Node->new(0);
	my $node041 = CDS::Parser::Node->new(1);
	my $node042 = CDS::Parser::Node->new(0);
	my $node043 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&addAccount});
	my $node044 = CDS::Parser::Node->new(0);
	my $node045 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&removeAccount});
	my $node046 = CDS::Parser::Node->new(0);
	my $node047 = CDS::Parser::Node->new(1);
	my $node048 = CDS::Parser::Node->new(0);
	my $node049 = CDS::Parser::Node->new(0);
	my $node050 = CDS::Parser::Node->new(0);
	my $node051 = CDS::Parser::Node->new(0);
	my $node052 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&checkPermissions});
	my $node053 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&fixPermissions});
	my $node054 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showPermissions});
	my $node055 = CDS::Parser::Node->new(1);
	my $node056 = CDS::Parser::Node->new(0);
	my $node057 = CDS::Parser::Node->new(0);
	my $node058 = CDS::Parser::Node->new(0);
	my $node059 = CDS::Parser::Node->new(0);
	my $node060 = CDS::Parser::Node->new(0);
	my $node061 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&addAccount});
	my $node062 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&removeAccount});
	my $node063 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&setPermissions});
	my $node064 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&createStore});
	$cds->addArrow($node001, 1, 0, 'create');
	$cds->addArrow($node003, 1, 0, 'check');
	$cds->addArrow($node004, 1, 0, 'fix');
	$cds->addArrow($node005, 1, 0, 'show');
	$cds->addArrow($node007, 1, 0, 'set');
	$cds->addArrow($node009, 1, 0, 'add');
	$cds->addArrow($node010, 1, 0, 'add');
	$cds->addArrow($node011, 1, 0, 'add');
	$cds->addArrow($node012, 1, 0, 'add');
	$cds->addArrow($node013, 1, 0, 'add');
	$cds->addArrow($node023, 1, 0, 'remove');
	$help->addArrow($node000, 1, 0, 'create');
	$node000->addArrow($node028, 1, 0, 'store');
	$node001->addArrow($node002, 1, 0, 'store');
	$node002->addArrow($node029, 1, 0, 'FOLDERNAME', \&collectFoldername);
	$node003->addArrow($node035, 1, 0, 'permissions');
	$node004->addArrow($node037, 1, 0, 'permissions');
	$node005->addArrow($node006, 1, 0, 'permission');
	$node006->addArrow($node039, 1, 0, 'scheme');
	$node007->addArrow($node008, 1, 0, 'permission');
	$node008->addArrow($node041, 1, 0, 'scheme');
	$node009->addArrow($node014, 1, 0, 'account');
	$node010->addArrow($node015, 1, 0, 'account');
	$node011->addArrow($node016, 1, 0, 'account');
	$node012->addArrow($node017, 1, 0, 'account');
	$node013->addArrow($node018, 1, 0, 'account');
	$node014->addArrow($node019, 1, 0, 'for');
	$node015->addArrow($node020, 1, 0, 'for');
	$node016->addArrow($node021, 1, 0, 'for');
	$node017->addArrow($node043, 1, 1, 'ACCOUNT', \&collectAccount);
	$node018->addArrow($node022, 1, 0, 'for');
	$node019->addArrow($node043, 1, 0, 'OBJECTFILE', \&collectObjectfile);
	$node020->addArrow($node043, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node021->addArrow($node025, 1, 0, 'ACTOR', \&collectActor);
	$node022->addArrow($node043, 1, 0, 'OBJECT', \&collectObject);
	$node023->addArrow($node024, 1, 0, 'account');
	$node024->addArrow($node045, 1, 0, 'HASH', \&collectHash);
	$node025->addArrow($node026, 1, 0, 'on');
	$node025->addArrow($node027, 0, 0, 'from');
	$node026->addArrow($node043, 1, 0, 'STORE', \&collectStore);
	$node027->addArrow($node043, 0, 0, 'STORE', \&collectStore);
	$node029->addArrow($node030, 1, 0, 'for');
	$node029->addArrow($node031, 1, 0, 'for');
	$node029->addArrow($node032, 1, 0, 'for');
	$node029->addDefault($node047);
	$node030->addArrow($node033, 1, 0, 'user');
	$node031->addArrow($node034, 1, 0, 'group');
	$node032->addArrow($node047, 1, 0, 'everybody', \&collectEverybody);
	$node033->addArrow($node047, 1, 0, 'USER', \&collectUser);
	$node034->addArrow($node047, 1, 0, 'GROUP', \&collectGroup);
	$node035->addArrow($node036, 1, 0, 'of');
	$node036->addArrow($node052, 1, 0, 'STORE', \&collectStore1);
	$node037->addArrow($node038, 1, 0, 'of');
	$node038->addArrow($node053, 1, 0, 'STORE', \&collectStore1);
	$node039->addArrow($node040, 1, 0, 'of');
	$node040->addArrow($node054, 1, 0, 'STORE', \&collectStore1);
	$node041->addArrow($node042, 1, 0, 'of');
	$node041->addDefault($node055);
	$node042->addArrow($node055, 1, 0, 'STORE', \&collectStore1);
	$node043->addArrow($node044, 1, 0, 'to');
	$node044->addArrow($node061, 1, 0, 'STORE', \&collectStore1);
	$node045->addArrow($node046, 1, 0, 'from');
	$node046->addArrow($node062, 1, 0, 'STORE', \&collectStore1);
	$node047->addArrow($node048, 1, 0, 'and');
	$node047->addDefault($node064);
	$node048->addArrow($node049, 1, 0, 'remember');
	$node049->addArrow($node050, 1, 0, 'it');
	$node050->addArrow($node051, 1, 0, 'as');
	$node051->addArrow($node064, 1, 0, 'TEXT', \&collectText);
	$node055->addArrow($node056, 1, 0, 'to');
	$node055->addArrow($node057, 1, 0, 'to');
	$node055->addArrow($node058, 1, 0, 'to');
	$node056->addArrow($node059, 1, 0, 'user');
	$node057->addArrow($node060, 1, 0, 'group');
	$node058->addArrow($node063, 1, 0, 'everybody', \&collectEverybody);
	$node059->addArrow($node063, 1, 0, 'USER', \&collectUser);
	$node060->addArrow($node063, 1, 0, 'GROUP', \&collectGroup);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{accountToken} = $value;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectEverybody {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{permissions} = CDS::FolderStore::PosixPermissions::World->new;
}

sub collectFoldername {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{foldername} = $value;
}

sub collectGroup {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{permissions} = CDS::FolderStore::PosixPermissions::Group->new($o->{group});
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{accountToken} = CDS::AccountToken->new($value->cliStore, $value->hash);
}

sub collectObjectfile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{file} = $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{accountToken} = CDS::AccountToken->new($value, $o->{actorHash});
}

sub collectStore1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectText {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{label} = $value;
}

sub collectUser {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{permissions} = CDS::FolderStore::PosixPermissions::User->new($value);
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME folder-store
# HTML TITLE Folder store management
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds create store FOLDERNAME');
	$ui->p('Creates a new store in FOLDERNAME, and adds it to the list of known stores. If the folder does not exist, it is created. If it does exist, it must be empty.');
	$ui->space;
	$ui->p('By default, the filesystem permissions of the store are set such that only the current user can post objects and modify boxes. Other users on the system can post to the message box, list boxes, and read objects.');
	$ui->space;
	$ui->command('… for user USER');
	$ui->p('Makes the store accessible to the user USER.');
	$ui->space;
	$ui->command('… for group GROUP');
	$ui->p('Makes the store accessible to the group GROUP.');
	$ui->space;
	$ui->command('… for everybody');
	$ui->p('Makes the store accessible to everybody.');
	$ui->space;
	$ui->p('Note that the permissions only affect direct filesystem access. If your store is exposed by a server (e.g. a web server), it may be accessible to others.');
	$ui->space;
	$ui->command('… and remember it as TEXT');
	$ui->p('Remembers the store under the label TEXT. See "cds help remember" for details.');
	$ui->space;
	$ui->command('cds check permissions [of STORE]');
	$ui->p('Checks the permissions (owner, mode) of all accounts, boxes, box entries, and objects of the store, and reports any error. The permission scheme (user, group, or everybody) is derived from the "accounts" and "objects" folders.');
	$ui->p('If the store is omitted, the selected store is used.');
	$ui->space;
	$ui->command('cds fix permissions [of STORE]');
	$ui->p('Same as above, but tries to fix the permissions (chown, chmod) instead of just reporting them.');
	$ui->space;
	$ui->command('cds show permission scheme [of STORE]');
	$ui->p('Reports the permission scheme of the store.');
	$ui->space;
	$ui->command('cds set permission scheme [of STORE] to (user USER|group GROUP|everybody)');
	$ui->p('Sets the permission scheme of the stores, and changes all permissions accordingly.');
	$ui->space;
	$ui->command('cds add account ACCOUNT [to STORE]');
	$ui->command('cds add account for FILE [to STORE]');
	$ui->command('cds add account for KEYPAIR [to STORE]');
	$ui->command('cds add account for OBJECT [to STORE]');
	$ui->command('cds add account for ACTOR on STORE [to STORE]');
	$ui->p('Uploads the public key (FILE, KEYPAIR, OBJECT, ACCOUNT, or ACTOR on STORE) onto the store, and adds the corresponding account. This grants the user the right to access this account.');
	$ui->space;
	$ui->command('cds remove account HASH [from STORE]');
	$ui->p('Removes the indicated account from the store. This immediately destroys the user\'s data.');
	$ui->space;
}

sub createStore {
	my $o = shift;
	my $cmd = shift;

	$o->{permissions} = CDS::FolderStore::PosixPermissions::User->new;
	$cmd->collect($o);

	# Give up if the folder is non-empty (but we accept hidden files)
	for my $file (CDS->listFolder($o->{foldername})) {
		next if $file =~ /^\./;
		$o->{ui}->pRed('The folder ', $o->{foldername}, ' is not empty. Giving up …');
		return;
	}

	# Create the object store
	$o->create($o->{foldername}.'/objects') // return;
	$o->{ui}->pGreen('Object store created for ', $o->{permissions}->target, '.');

	# Create the account store
	$o->create($o->{foldername}.'/accounts') // return;
	$o->{ui}->pGreen('Account store created for ', $o->{permissions}->target, '.');

	# Return if the user does not want us to add the store
	return if ! defined $o->{label};

	# Remember the store
	my $record = CDS::Record->new;
	$record->addText('store')->addText('file://'.$o->{foldername});
	$o->{actor}->remember($o->{label}, $record);
	$o->{actor}->saveOrShowError;
}

# Creates a folder with the selected permissions.
sub create {
	my $o = shift;
	my $folder = shift;

	# Create the folders to here if necessary
	for my $intermediateFolder (CDS->intermediateFolders($folder)) {
		mkdir $intermediateFolder, 0755;
	}

	# mkdir (if it does not exist yet) and chmod (if it does exist already)
	mkdir $folder, $o->{permissions}->baseFolderMode;
	chmod $o->{permissions}->baseFolderMode, $folder;
	chown $o->{permissions}->uid // -1, $o->{permissions}->gid // -1, $folder;

	# Check if the result is correct
	my @s = stat $folder;
	return $o->{ui}->error('Unable to create ', $o->{foldername}, '.') if ! scalar @s;
	my $mode = $s[2];
	return $o->{ui}->error($folder, ' exists, but is not a folder') if ! Fcntl::S_ISDIR($mode);
	return $o->{ui}->error('Unable to set the owning user ', $o->{permissions}->user, ' for ', $folder, '.') if defined $o->{permissions}->uid && $s[4] != $o->{permissions}->uid;
	return $o->{ui}->error('Unable to set the owning group ', $o->{permissions}->group, ' for ', $folder, '.') if defined $o->{permissions}->gid && $s[5] != $o->{permissions}->gid;
	return $o->{ui}->error('Unable to set the mode on ', $folder, '.') if ($mode & 0777) != $o->{permissions}->baseFolderMode;
	return 1;
}

sub existingFolderStoreOrShowError {
	my $o = shift;

	my $store = $o->{store} // $o->{actor}->preferredStore;

	my $folderStore = CDS::FolderStore->forUrl($store->url);
	if (! $folderStore) {
		$o->{ui}->error('"', $store->url, '" is not a folder store.');
		$o->{ui}->space;
		$o->{ui}->p('Account management and file system permission checks only apply to stores on the local file system. Such stores are referred to by file://… URLs, or file system paths.');
		$o->{ui}->p('To fix the permissions on a remote store, log onto that server and fix the permissions there. Note that permissions are not part of the Condensation protocol, but a property of some underlying storage systems, such as file systems.');
		$o->{ui}->space;
		return;
	}

	if (! $folderStore->exists) {
		$o->{ui}->error('"', $folderStore->folder, '" does not exist.');
		$o->{ui}->space;
		$o->{ui}->p('The folder either does not exist, or is not a folder store. You can create this store using:');
		$o->{ui}->line($o->{ui}->gold('  cds create store ', $folderStore->folder));
		$o->{ui}->space;
		return;
	}

	return $folderStore;
}

sub showPermissions {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	my $folderStore = $o->existingFolderStoreOrShowError // return;
	$o->showStore($folderStore);
	$o->{ui}->space;
}

sub showStore {
	my $o = shift;
	my $folderStore = shift;

	$o->{ui}->space;
	$o->{ui}->title('Store');
	$o->{ui}->line($folderStore->folder);
	$o->{ui}->line('Accessible to ', $folderStore->permissions->target, '.');
}

sub setPermissions {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	my $folderStore = $o->existingFolderStoreOrShowError // return;
	$o->showStore($folderStore);

	$folderStore->setPermissions($o->{permissions});
	$o->{ui}->line('Changing permissions …');
	my $logger = CDS::Commands::FolderStore::SetLogger->new($o, $folderStore->folder);
	$folderStore->checkPermissions($logger) || $o->traversalFailed($folderStore);
	$logger->summary;

	$o->{ui}->space;
}

sub checkPermissions {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	my $folderStore = $o->existingFolderStoreOrShowError // return;
	$o->showStore($folderStore);

	$o->{ui}->line('Checking permissions …');
	my $logger = CDS::Commands::FolderStore::CheckLogger->new($o, $folderStore->folder);
	$folderStore->checkPermissions($logger) || $o->traversalFailed($folderStore);
	$logger->summary;

	$o->{ui}->space;
}

sub fixPermissions {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	my $folderStore = $o->existingFolderStoreOrShowError // return;
	$o->showStore($folderStore);

	$o->{ui}->line('Fixing permissions …');
	my $logger = CDS::Commands::FolderStore::FixLogger->new($o, $folderStore->folder);
	$folderStore->checkPermissions($logger) || $o->traversalFailed($folderStore);
	$logger->summary;

	$o->{ui}->space;
}

sub traversalFailed {
	my $o = shift;
	my $folderStore = shift;

	$o->{ui}->space;
	$o->{ui}->p('Traversal failed because a file or folder could not be accessed. You may have to fix the permissions manually, or run this command with other privileges.');
	$o->{ui}->p('If you have root privileges, you can take over this store using:');
	my $userName = getpwuid($<);
	my $groupName = getgrgid($();
	$o->{ui}->line($o->{ui}->gold('  sudo chown -R ', $userName, ':', $groupName, ' ', $folderStore->folder));
	$o->{ui}->p('and then set the desired permission scheme:');
	$o->{ui}->line($o->{ui}->gold('  cds set permissions of ', $folderStore->folder, ' to …'));
	$o->{ui}->space;
	exit(1);
}

sub addAccount {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	# Prepare
	my $folderStore = $o->existingFolderStoreOrShowError // return;
	my $publicKey = $o->publicKey // return;

	# Upload the public key onto the store
	my $error = $folderStore->put($publicKey->hash, $publicKey->object);
	return $o->{ui}->error('Unable to upload the public key: ', $error) if $error;

	# Create the account folder
	my $folder = $folderStore->folder.'/accounts/'.$publicKey->hash->hex;
	my $permissions = $folderStore->permissions;
	$permissions->mkdir($folder, $permissions->accountFolderMode);
	return $o->{ui}->error('Unable to create folder "', $folder, '".') if ! -d $folder;
	$o->{ui}->pGreen('Account ', $publicKey->hash->hex, ' added.');
	return 1;
}

sub publicKey {
	my $o = shift;

	return $o->{keyPairToken}->keyPair->publicKey if $o->{keyPairToken};

	if ($o->{file}) {
		my $bytes = CDS->readBytesFromFile($o->{file}) // return $o->{ui}->error('Cannot read "', $o->{file}, '".');
		my $object = CDS::Object->fromBytes($bytes) // return $o->{ui}->error('"', $o->{file}, '" is not a public key.');
		return CDS::PublicKey->fromObject($object) // return $o->{ui}->error('"', $o->{file}, '" is not a public key.');
	}

	return $o->{actor}->uiGetPublicKey($o->{accountToken}->actorHash, $o->{accountToken}->cliStore, $o->{actor}->preferredKeyPairToken);
}

sub removeAccount {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	# Prepare the folder
	my $folderStore = $o->existingFolderStoreOrShowError // return;
	my $folder = $folderStore->folder.'/accounts/'.$o->{hash}->hex;
	my $deletedFolder = $folderStore->folder.'/accounts/deleted-'.$o->{hash}->hex;

	# Rename, so that it is not visible any more
	$o->recursivelyDelete($deletedFolder) if -e $deletedFolder;
	return $o->{ui}->line('The account ', $o->{hash}->hex, ' does not exist.') if ! -e $folder;
	rename($folder, $deletedFolder) || return $o->{ui}->error('Unable to rename the folder "', $folder, '".');

	# Try to delete it entirely
	$o->recursivelyDelete($deletedFolder);
	$o->{ui}->pGreen('Account ', $o->{hash}->hex, ' removed.');
	return 1;
}

sub recursivelyDelete {
	my $o = shift;
	my $folder = shift;

	for my $filename (CDS->listFolder($folder)) {
		next if $filename =~ /^\./;
		my $file = $folder.'/'.$filename;
		if (-f $file) {
			unlink $file || $o->{ui}->pOrange('Unable to remove the file "', $file, '".');
		} elsif (-d $file) {
			$o->recursivelyDelete($file);
		}
	}

	rmdir($folder) || $o->{ui}->pOrange('Unable to remove the folder "', $folder, '".');
}

package CDS::Commands::FolderStore::CheckLogger;

use parent -norequire, 'CDS::Commands::FolderStore::Logger';

sub finalizeWrong {
	my $o = shift;

	$o->{ui}->pRed(@_);
	return 0;
}

sub summary {
	my $o = shift;

	$o->{ui}->p(($o->{correct} + $o->{wrong}).' files and folders traversed.');
	if ($o->{wrong} > 0) {
		$o->{ui}->p($o->{wrong}, ' files and folders have wrong permissions. To fix them, run');
		$o->{ui}->line($o->{ui}->gold('  cds fix permissions of ', $o->{store}->url));
	} else {
		$o->{ui}->pGreen('All permissions are OK.');
	}
}

package CDS::Commands::FolderStore::FixLogger;

use parent -norequire, 'CDS::Commands::FolderStore::Logger';

sub finalizeWrong {
	my $o = shift;

	$o->{ui}->line(@_);
	return 1;
}

sub summary {
	my $o = shift;

	$o->{ui}->p(($o->{correct} + $o->{wrong}).' files and folders traversed.');
	$o->{ui}->p('The permissions of ', $o->{wrong}, ' files and folders have been fixed.') if $o->{wrong} > 0;
	$o->{ui}->pGreen('All permissions are OK.');
}

package CDS::Commands::FolderStore::Logger;

sub new {
	my $class = shift;
	my $parent = shift;
	my $baseFolder = shift;

	return bless {
		ui => $parent->{ui},
		store => $parent->{store},
		baseFolder => $baseFolder,
		correct => 0,
		wrong => 0,
		}, $class;
}

sub correct {
	my $o = shift;

	$o->{correct} += 1;
}

sub wrong {
	my $o = shift;
	my $item = shift;
	my $uid = shift;
	my $gid = shift;
	my $mode = shift;
	my $expectedUid = shift;
	my $expectedGid = shift;
	my $expectedMode = shift;

	my $len = length $o->{baseFolder};
	$o->{wrong} += 1;
	$item = '…'.substr($item, $len) if length $item > $len && substr($item, 0, $len) eq $o->{baseFolder};
	my @changes;
	push @changes, 'user '.&username($uid).' -> '.&username($expectedUid) if defined $expectedUid && $uid != $expectedUid;
	push @changes, 'group '.&groupname($gid).' -> '.&groupname($expectedGid) if defined $expectedGid && $gid != $expectedGid;
	push @changes, 'mode '.sprintf('%04o -> %04o', $mode, $expectedMode) if $mode != $expectedMode;
	return $o->finalizeWrong(join(', ', @changes), "\t", $item);
}

sub username {
	my $uid = shift;

	return getpwuid($uid) // $uid;
}

sub groupname {
	my $gid = shift;

	return getgrgid($gid) // $gid;
}

sub accessError {
	my $o = shift;
	my $item = shift;

	$o->{ui}->error('Error accessing ', $item, '.');
	return 0;
}

sub setError {
	my $o = shift;
	my $item = shift;

	$o->{ui}->error('Error setting permissions of ', $item, '.');
	return 0;
}

package CDS::Commands::FolderStore::SetLogger;

use parent -norequire, 'CDS::Commands::FolderStore::Logger';

sub finalizeWrong {
	my $o = shift;

	return 1;
}

sub summary {
	my $o = shift;

	$o->{ui}->p(($o->{correct} + $o->{wrong}).' files and folders traversed.');
	$o->{ui}->p('The permissions of ', $o->{wrong}, ' files and folders have been adjusted.') if $o->{wrong} > 0;
	$o->{ui}->pGreen('All permissions are OK.');
}

# BEGIN AUTOGENERATED
package CDS::Commands::Get;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(1);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(1);
	my $node017 = CDS::Parser::Node->new(0);
	my $node018 = CDS::Parser::Node->new(0);
	my $node019 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&get});
	my $node020 = CDS::Parser::Node->new(1);
	my $node021 = CDS::Parser::Node->new(0);
	my $node022 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&get});
	$cds->addArrow($node000, 1, 0, 'get');
	$cds->addArrow($node001, 1, 0, 'save');
	$cds->addArrow($node002, 1, 0, 'get');
	$cds->addArrow($node003, 1, 0, 'get');
	$cds->addArrow($node009, 1, 0, 'save', \&collectSave);
	$help->addArrow($node005, 1, 0, 'get');
	$help->addArrow($node005, 1, 0, 'save');
	$node000->addArrow($node010, 1, 0, 'HASH', \&collectHash);
	$node001->addArrow($node004, 1, 0, 'data');
	$node002->addArrow($node006, 1, 0, 'HASH', \&collectHash1);
	$node003->addArrow($node010, 1, 0, 'OBJECT', \&collectObject);
	$node004->addArrow($node009, 1, 0, 'of', \&collectOf);
	$node006->addArrow($node007, 1, 0, 'on');
	$node006->addArrow($node008, 0, 0, 'from');
	$node007->addArrow($node010, 1, 0, 'STORE', \&collectStore);
	$node008->addArrow($node010, 0, 0, 'STORE', \&collectStore);
	$node009->addArrow($node013, 1, 0, 'HASH', \&collectHash1);
	$node009->addArrow($node016, 1, 0, 'HASH', \&collectHash);
	$node009->addArrow($node016, 1, 0, 'OBJECT', \&collectObject1);
	$node010->addArrow($node011, 1, 0, 'decrypted');
	$node010->addDefault($node019);
	$node011->addArrow($node012, 1, 0, 'with');
	$node012->addArrow($node019, 1, 0, 'AESKEY', \&collectAeskey);
	$node013->addArrow($node014, 1, 0, 'on');
	$node013->addArrow($node015, 0, 0, 'from');
	$node014->addArrow($node016, 1, 0, 'STORE', \&collectStore);
	$node015->addArrow($node016, 0, 0, 'STORE', \&collectStore);
	$node016->addArrow($node017, 1, 0, 'decrypted');
	$node016->addDefault($node020);
	$node017->addArrow($node018, 1, 0, 'with');
	$node018->addArrow($node020, 1, 0, 'AESKEY', \&collectAeskey);
	$node020->addArrow($node021, 1, 0, 'as');
	$node021->addArrow($node022, 1, 0, 'FILENAME', \&collectFilename);
}

sub collectAeskey {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{aesKey} = $value;
}

sub collectFilename {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{filename} = $value;
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
	$o->{store} = $o->{actor}->preferredStore;
}

sub collectHash1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value->hash;
	$o->{store} = $value->cliStore;
}

sub collectObject1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value->hash;
	push @{$o->{stores}}, $value->store;
}

sub collectOf {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{saveData} = 1;
}

sub collectSave {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{saveObject} = 1;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME store-get
# HTML TITLE Get
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds get OBJECT');
	$ui->command('cds get HASH on STORE');
	$ui->p('Downloads an object and writes it to STDOUT. If the object is not found, the program quits with exit code 1.');
	$ui->space;
	$ui->command('cds get HASH');
	$ui->p('As above, but uses the selected store.');
	$ui->space;
	$ui->command('… decrypted with AESKEY');
	$ui->p('Decrypts the object after retrieval.');
	$ui->space;
	$ui->command('cds save … as FILENAME');
	$ui->p('Saves the object to FILENAME instead of writing it to STDOUT.');
	$ui->space;
	$ui->command('cds save data of … as FILENAME');
	$ui->p('Saves the object\'s data to FILENAME.');
	$ui->space;
	$ui->title('Related commands');
	$ui->line('cds open envelope OBJECT');
	$ui->line('cds show record OBJECT [decrypted with AESKEY]');
	$ui->line('cds show hashes of OBJECT');
	$ui->space;
}

sub get {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	# Retrieve the object
	my $object = $o->{actor}->uiGetObject($o->{hash}, $o->{store}, $o->{actor}->preferredKeyPairToken) // return;

	# Decrypt
	$object = $object->crypt($o->{aesKey}) if defined $o->{aesKey};

	# Output
	if ($o->{saveData}) {
		CDS->writeBytesToFile($o->{filename}, $object->data) // return $o->{ui}->error('Failed to write data to "', $o->{filename}, '".');
		$o->{ui}->pGreen(length $object->data, ' bytes written to ', $o->{filename}, '.');
	} elsif ($o->{saveObject}) {
		CDS->writeBytesToFile($o->{filename}, $object->bytes) // return $o->{ui}->error('Failed to write object to "', $o->{filename}, '".');
		$o->{ui}->pGreen(length $object->bytes, ' bytes written to ', $o->{filename}, '.');
	} else {
		$o->{ui}->raw($object->bytes);
	}
}

# BEGIN AUTOGENERATED
package CDS::Commands::Help;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node001 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&version});
	$cds->addArrow($node000, 0, 0, '--h');
	$cds->addArrow($node000, 0, 0, '--help');
	$cds->addArrow($node000, 0, 0, '-?');
	$cds->addArrow($node000, 0, 0, '-h');
	$cds->addArrow($node000, 0, 0, '-help');
	$cds->addArrow($node000, 0, 0, '/?');
	$cds->addArrow($node000, 0, 0, '/h');
	$cds->addArrow($node000, 0, 0, '/help');
	$cds->addArrow($node001, 0, 0, '--version');
	$cds->addArrow($node001, 0, 0, '-version');
	$cds->addArrow($node001, 1, 0, 'version');
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML IGNORE
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->title('Condensation CLI');
	$ui->line('Version ', $CDS::VERSION, ', ', $CDS::releaseDate, ', implementing the Condensation 1 protocol');
	$ui->space;
	$ui->p('Condensation is a distributed data system with conflict-free forward merging and end-to-end security. More information is available on ', $ui->a('https://condensation.io'), '.');
	$ui->space;
	$ui->p('The command line interface (CLI) understands english-like queries like these:');
	$ui->pushIndent;
	$ui->line($ui->blue('cds show key pair'));
	$ui->line($ui->blue('cds create key pair thomas'));
	$ui->line($ui->blue('cds get 45db86549d6d2af3a45be834f2cb0e08cdbbd7699624e7bfd947a3505e6b03e5 \\'));
	$ui->line($ui->blue('   and decrypt with 8b8b091bbe577d5e8d38eae9cd327aa8123fe402a41ea9dd16d86f42fb70cf7e'));
	$ui->popIndent;
	$ui->space;
	$ui->p('If you don\'t know how to continue a command, simply put a ? to see all valid options:');
	$ui->pushIndent;
	$ui->line($ui->blue('cds ?'));
	$ui->line($ui->blue('cds show ?'));
	$ui->popIndent;
	$ui->space;
	$ui->p('To see a list of help topics, type');
	$ui->pushIndent;
	$ui->line($ui->blue('cds help ?'));
	$ui->popIndent;
	$ui->space;
}

sub version {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->line('Condensation CLI ', $CDS::VERSION, ', ', $CDS::releaseDate);
	$ui->line('implementing the Condensation 1 protocol');
}

# BEGIN AUTOGENERATED
package CDS::Commands::List;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node001 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&list});
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&listBoxes});
	my $node015 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&list});
	$cds->addArrow($node001, 1, 0, 'list');
	$cds->addArrow($node001, 1, 0, 'watch', \&collectWatch);
	$help->addArrow($node000, 1, 0, 'list');
	$node001->addDefault($node002);
	$node001->addArrow($node003, 1, 0, 'message');
	$node001->addArrow($node004, 1, 0, 'private');
	$node001->addArrow($node005, 1, 0, 'public');
	$node001->addArrow($node006, 0, 0, 'messages', \&collectMessages);
	$node001->addArrow($node006, 0, 0, 'private', \&collectPrivate);
	$node001->addArrow($node006, 0, 0, 'public', \&collectPublic);
	$node001->addArrow($node007, 1, 0, 'my', \&collectMy);
	$node001->addDefault($node011);
	$node002->addArrow($node002, 1, 0, 'BOX', \&collectBox);
	$node002->addArrow($node014, 1, 0, 'BOX', \&collectBox);
	$node003->addArrow($node006, 1, 0, 'box', \&collectMessages);
	$node004->addArrow($node006, 1, 0, 'box', \&collectPrivate);
	$node005->addArrow($node006, 1, 0, 'box', \&collectPublic);
	$node006->addArrow($node011, 1, 0, 'of');
	$node006->addDefault($node012);
	$node007->addArrow($node008, 1, 0, 'message');
	$node007->addArrow($node009, 1, 0, 'private');
	$node007->addArrow($node010, 1, 0, 'public');
	$node007->addArrow($node015, 1, 0, 'boxes');
	$node007->addArrow($node015, 0, 0, 'messages', \&collectMessages);
	$node007->addArrow($node015, 0, 0, 'private', \&collectPrivate);
	$node007->addArrow($node015, 0, 0, 'public', \&collectPublic);
	$node008->addArrow($node015, 1, 0, 'box', \&collectMessages);
	$node009->addArrow($node015, 1, 0, 'box', \&collectPrivate);
	$node010->addArrow($node015, 1, 0, 'box', \&collectPublic);
	$node011->addArrow($node012, 1, 0, 'ACTOR', \&collectActor);
	$node011->addArrow($node012, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node011->addArrow($node015, 1, 1, 'ACCOUNT', \&collectAccount);
	$node011->addArrow($node015, 1, 0, 'ACTORGROUP', \&collectActorgroup);
	$node012->addArrow($node013, 1, 0, 'on');
	$node012->addDefault($node015);
	$node013->addArrow($node015, 1, 0, 'STORE', \&collectStore);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value->actorHash;
	$o->{store} = $value->cliStore;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectActorgroup {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorGroup} = $value;
}

sub collectBox {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{boxTokens}}, $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value->keyPair->publicKey->hash;
	$o->{keyPairToken} = $value;
}

sub collectMessages {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabels} = ['messages'];
}

sub collectMy {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{my} = 1;
}

sub collectPrivate {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabels} = ['private'];
}

sub collectPublic {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabels} = ['public'];
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectWatch {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{watchTimeout} = 60000;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME store-list
# HTML TITLE List
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds list BOX');
	$ui->p('Lists the indicated box. The object references are shown as "cds open envelope …" command, which can be executed to display the corresponding envelope. Change the command to "cds get …" to download the raw object, or "cds show record …" to show it as record.');
	$ui->space;
	$ui->command('cds list');
	$ui->p('Lists all boxes of the selected key pair.');
	$ui->space;
	$ui->command('cds list BOXLABEL');
	$ui->p('Lists only the indicated box of the selected key pair. BOXLABEL may be:');
	$ui->line('  message box');
	$ui->line('  public box');
	$ui->line('  private box');
	$ui->space;
	$ui->command('cds list my boxes');
	$ui->command('cds list my BOXLABEL');
	$ui->p('Lists your own boxes.');
	$ui->space;
	$ui->command('cds list [BOXLABEL of] ACTORGROUP|ACCOUNT');
	$ui->p('Lists boxes of an actor group, or account.');
	$ui->space;
	$ui->command('cds list [BOXLABEL of] KEYPAIR|ACTOR [on STORE]');
	$ui->p('Lists boxes of an actor on the specified or selected store.');
	$ui->space;
}

sub listBoxes {
	my $o = shift;
	my $cmd = shift;

	$o->{boxTokens} = [];
	$o->{boxLabels} = ['messages', 'private', 'public'];
	$cmd->collect($o);

	# Use the selected key pair to sign requests
	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken if ! $o->{keyPairToken};

	for my $boxToken (@{$o->{boxTokens}}) {
		$o->listBox($boxToken);
	}

	$o->{ui}->space;
}

sub list {
	my $o = shift;
	my $cmd = shift;

	$o->{boxLabels} = ['messages', 'private', 'public'];
	$cmd->collect($o);

	# Actor hashes
	my @actorHashes;
	my @stores;
	if ($o->{my}) {
		$o->{keyPairToken} = $o->{actor}->keyPairToken;
		push @actorHashes, $o->{keyPairToken}->keyPair->publicKey->hash;
		push @stores, $o->{actor}->storageStore, $o->{actor}->messagingStore;
	} elsif ($o->{actorHash}) {
		push @actorHashes, $o->{actorHash};
	} elsif ($o->{actorGroup}) {
		# TODO
	} else {
		push @actorHashes, $o->{actor}->preferredActorHash;
	}

	# Stores
	push @stores, $o->{store} if $o->{store};
	push @stores, $o->{actor}->preferredStore if ! scalar @stores;

	# Use the selected key pair to sign requests
	my $preferredKeyPairToken = $o->{actor}->preferredKeyPairToken;
	$o->{keyPairToken} = $preferredKeyPairToken if ! $o->{keyPairToken};
	$o->{keyPairContext} = $preferredKeyPairToken->keyPair->equals($o->{keyPairToken}->keyPair) ? '' : $o->{ui}->gray(' using ', $o->{actor}->keyPairReference($o->{keyPairToken}));

	# List boxes
	for my $store (@stores) {
		for my $actorHash (@actorHashes) {
			for my $boxLabel (@{$o->{boxLabels}}) {
				$o->listBox(CDS::BoxToken->new(CDS::AccountToken->new($store, $actorHash), $boxLabel));
			}
		}
	}

	$o->{ui}->space;
}

sub listBox {
	my $o = shift;
	my $boxToken = shift;

	$o->{ui}->space;
	$o->{ui}->title($o->{actor}->blueBoxReference($boxToken));

	# Query the store
	my $store = $boxToken->accountToken->cliStore;
	my ($hashes, $storeError) = $store->list($boxToken->accountToken->actorHash, $boxToken->boxLabel, $o->{watchTimeout} // 0, $o->{keyPairToken}->keyPair);
	return if defined $storeError;

	# Print the result
	my $count = scalar @$hashes;
	return if ! $count;

	my $context = $boxToken->boxLabel eq 'messages' ? $o->{ui}->gray(' on ', $o->{actor}->storeReference($store)) : $o->{ui}->gray(' from ', $o->{actor}->accountReference($boxToken->accountToken));
	my $keyPairContext = $boxToken->boxLabel eq 'public' ? '' : $o->{keyPairContext} // '';
	foreach my $hash (sort { $a->bytes cmp $b->bytes } @$hashes) {
		$o->{ui}->line($o->{ui}->gold('cds open envelope ', $hash->hex), $context, $keyPairContext);
	}
	$o->{ui}->line($count.' entries') if $count > 5;
}

# BEGIN AUTOGENERATED
package CDS::Commands::Modify;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node008 = CDS::Parser::Node->new(1);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&modify});
	$cds->addDefault($node000);
	$help->addArrow($node007, 1, 0, 'add');
	$help->addArrow($node007, 1, 0, 'purge');
	$help->addArrow($node007, 1, 0, 'remove');
	$node000->addArrow($node001, 1, 0, 'add');
	$node000->addArrow($node002, 1, 0, 'remove');
	$node000->addArrow($node003, 1, 0, 'add');
	$node000->addArrow($node008, 1, 0, 'purge', \&collectPurge);
	$node001->addArrow($node001, 1, 0, 'HASH', \&collectHash);
	$node001->addArrow($node004, 1, 0, 'HASH', \&collectHash);
	$node002->addArrow($node002, 1, 0, 'HASH', \&collectHash1);
	$node002->addArrow($node005, 1, 0, 'HASH', \&collectHash1);
	$node003->addArrow($node003, 1, 0, 'FILE', \&collectFile);
	$node003->addArrow($node006, 1, 0, 'FILE', \&collectFile);
	$node004->addArrow($node008, 1, 0, 'to');
	$node005->addArrow($node008, 1, 0, 'from');
	$node006->addArrow($node008, 1, 0, 'to');
	$node008->addArrow($node000, 1, 0, 'and');
	$node008->addArrow($node009, 1, 0, 'message');
	$node008->addArrow($node010, 1, 0, 'private');
	$node008->addArrow($node011, 1, 0, 'public');
	$node008->addArrow($node012, 0, 0, 'messages', \&collectMessages);
	$node008->addArrow($node012, 0, 0, 'private', \&collectPrivate);
	$node008->addArrow($node012, 0, 0, 'public', \&collectPublic);
	$node008->addArrow($node016, 1, 0, 'BOX', \&collectBox);
	$node009->addArrow($node012, 1, 0, 'box', \&collectMessages);
	$node010->addArrow($node012, 1, 0, 'box', \&collectPrivate);
	$node011->addArrow($node012, 1, 0, 'box', \&collectPublic);
	$node012->addArrow($node013, 1, 0, 'of');
	$node013->addArrow($node014, 1, 0, 'ACTOR', \&collectActor);
	$node013->addArrow($node014, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node013->addArrow($node016, 1, 1, 'ACCOUNT', \&collectAccount);
	$node014->addArrow($node015, 1, 0, 'on');
	$node014->addDefault($node016);
	$node015->addArrow($node016, 1, 0, 'STORE', \&collectStore);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxToken} = CDS::BoxToken->new($value, $o->{boxLabel});
	delete $o->{boxLabel};
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectBox {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxToken} = $value;
}

sub collectFile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{fileAdditions}}, $value;
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{additions}}, $value;
}

sub collectHash1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{removals}}, $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value->publicKey->hash;
	$o->{keyPairToken} = $value;
}

sub collectMessages {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabel} = 'messages';
}

sub collectPrivate {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabel} = 'private';
}

sub collectPublic {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxLabel} = 'public';
}

sub collectPurge {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{purge} = 1;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{boxToken} = CDS::BoxToken->new(CDS::AccountToken->new($value, $o->{actorHash}), $o->{boxLabel});
	delete $o->{boxLabel};
	delete $o->{actorHash};
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME store-modify
# HTML TITLE Modify
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds add HASH* to BOX');
	$ui->p('Adds HASH to BOX.');
	$ui->space;
	$ui->command('cds add FILE* to BOX');
	$ui->p('Adds the envelope FILE to BOX.');
	$ui->space;
	$ui->command('cds remove HASH* from BOX');
	$ui->p('Removes HASH from BOX.');
	$ui->p('Note that the store may just mark the hash for removal, and defer its actual removal, or even cancel it. Such removals will still be reported as success.');
	$ui->space;
	$ui->command('cds purge BOX');
	$ui->p('Empties BOX, i.e., removes all its hashes.');
	$ui->space;
	$ui->command('… BOXLABEL of ACCOUNT');
	$ui->p('Modifies a box of an actor group, or account.');
	$ui->space;
	$ui->command('… BOXLABEL of KEYPAIR on STORE');
	$ui->command('… BOXLABEL of ACTOR on STORE');
	$ui->p('Modifies a box of a key pair or an actor on a specific store.');
	$ui->space;
}

sub modify {
	my $o = shift;
	my $cmd = shift;

	$o->{additions} = [];
	$o->{removals} = [];
	$cmd->collect($o);

	# Add a box using the selected store
	if ($o->{actorHash} && $o->{boxLabel}) {
		$o->{boxToken} = CDS::BoxToken->new(CDS::AccountToken->new($o->{actor}->preferredStore, $o->{actorHash}), $o->{boxLabel});
		delete $o->{actorHash};
		delete $o->{boxLabel};
	}

	my $store = $o->{boxToken}->accountToken->cliStore;

	# Prepare additions
	my $modifications = CDS::StoreModifications->new;
	for my $hash (@{$o->{additions}}) {
		$modifications->add($o->{boxToken}->accountToken->actorHash, $o->{boxToken}->boxLabel, $hash);
	}

	for my $file (@{$o->{fileAdditions}}) {
		my $bytes = CDS->readBytesFromFile($file) // return $o->{ui}->error('Unable to read "', $file, '".');
		my $object = CDS::Object->fromBytes($bytes) // return $o->{ui}->error('"', $file, '" is not a Condensation object.');
		my $hash = $object->calculateHash;
		$o->{ui}->warning('"', $file, '" is not a valid envelope. The server may reject it.') if ! $o->{actor}->isEnvelope($object);
		$modifications->add($o->{boxToken}->accountToken->actorHash, $o->{boxToken}->boxLabel, $hash, $object);
	}

	# Prepare removals
	my $boxRemovals = [];
	for my $hash (@{$o->{removals}}) {
		$modifications->remove($o->{boxToken}->accountToken->actorHash, $o->{boxToken}->boxLabel, $hash);
	}

	# If purging is requested, list the box
	if ($o->{purge}) {
		my ($hashes, $error) = $store->list($o->{boxToken}->accountToken->actorHash, $o->{boxToken}->boxLabel, 0);
		return if defined $error;
		$o->{ui}->warning('The box is empty.') if ! scalar @$hashes;

		for my $hash (@$hashes) {
			$modifications->remove($o->{boxToken}->accountToken->actorHash, $o->{boxToken}->boxLabel, $hash);
		}
	}

	# Cancel if there is nothing to do
	return if $modifications->isEmpty;

	# Modify the box
	my $keyPairToken = $o->{keyPairToken} // $o->{actor}->preferredKeyPairToken;
	my $error = $store->modify($modifications, $keyPairToken->keyPair);
	$o->{ui}->pGreen('Box modified.') if ! defined $error;

	# Print undo information
	if ($o->{purge} && scalar @$boxRemovals) {
		$o->{ui}->space;
		$o->{ui}->line($o->{ui}->gray('To undo purging, type:'));
		$o->{ui}->line($o->{ui}->gray('  cds add ', join(" \\\n         ", map { $_->{hash}->hex } @$boxRemovals), " \\\n         to ", $o->{actor}->boxReference($o->{boxToken})));
		$o->{ui}->space;
	}
}

# BEGIN AUTOGENERATED
package CDS::Commands::OpenEnvelope;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node003 = CDS::Parser::Node->new(1);
	my $node004 = CDS::Parser::Node->new(1);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(1);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(1);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&openEnvelope});
	$cds->addArrow($node001, 1, 0, 'open');
	$help->addArrow($node000, 1, 0, 'open');
	$node000->addArrow($node002, 1, 0, 'envelope');
	$node001->addArrow($node003, 1, 0, 'envelope');
	$node003->addArrow($node004, 1, 0, 'HASH', \&collectHash);
	$node003->addArrow($node007, 1, 0, 'OBJECT', \&collectObject);
	$node004->addArrow($node005, 1, 0, 'from');
	$node004->addArrow($node006, 1, 0, 'from');
	$node004->addDefault($node009);
	$node005->addArrow($node009, 1, 0, 'ACTOR', \&collectActor);
	$node006->addArrow($node011, 1, 1, 'ACCOUNT', \&collectAccount);
	$node007->addArrow($node008, 1, 0, 'from');
	$node007->addDefault($node011);
	$node008->addArrow($node011, 1, 0, 'ACTOR', \&collectActor);
	$node009->addArrow($node010, 1, 0, 'on');
	$node009->addDefault($node011);
	$node010->addArrow($node011, 1, 0, 'STORE', \&collectStore);
	$node011->addArrow($node012, 1, 0, 'using');
	$node011->addDefault($node013);
	$node012->addArrow($node013, 1, 0, 'KEYPAIR', \&collectKeypair);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{senderHash} = $value->actorHash;
	$o->{store} = $value->cliStore;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{senderHash} = $value;
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
	$o->{store} = $o->{actor}->preferredStore;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value->hash;
	$o->{store} = $value->cliStore;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME open-envelope
# HTML TITLE Open envelope
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds open envelope OBJECT');
	$ui->command('cds open envelope HASH on STORE');
	$ui->p('Downloads an envelope, verifies its signatures, and tries to decrypt the AES key using the selected key pair and your own key pair.');
	$ui->p('In addition to displaying the envelope details, this command also displays the necessary "cds show record …" command to retrieve the content.');
	$ui->space;
	$ui->command('cds open envelope HASH');
	$ui->p('As above, but uses the selected store.');
	$ui->space;
	$ui->command('… from ACTOR');
	$ui->p('Assumes that the envelope was signed by ACTOR, and downloads the corresponding public key. The sender store is assumed to be the envelope\'s store. This is useful to verify public and private envelopes.');
	$ui->space;
	$ui->command('… using KEYPAIR');
	$ui->p('Tries to decrypt the AES key using this key pair, instead of the selected key pair.');
	$ui->space;
}

sub openEnvelope {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken;
	$cmd->collect($o);

	# Get the envelope
	my $envelope = $o->{actor}->uiGetRecord($o->{hash}, $o->{store}, $o->{keyPairToken}) // return;

	# Continue by envelope type
	my $contentRecord = $envelope->child('content');
	if ($contentRecord->hashValue) {
		if ($envelope->contains('encrypted for')) {
			$o->processPrivateEnvelope($envelope);
		} else {
			$o->processPublicEnvelope($envelope);
		}
	} elsif (length $contentRecord->bytesValue) {
		if ($envelope->contains('head') && $envelope->contains('mac')) {
			$o->processStreamEnvelope($envelope);
		} else {
			$o->processMessageEnvelope($envelope);
		}
	} else {
		$o->processOther($envelope);
	}
}

sub processOther {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	$o->{ui}->space;
	$o->{ui}->pOrange('This is not an envelope. Envelopes always have a "content" section. The raw record is shown below.');
	$o->{ui}->space;
	$o->{ui}->title('Record');
	$o->{ui}->recordChildren($envelope, $o->{actor}->storeReference($o->{store}));
	$o->{ui}->space;
}

sub processPublicEnvelope {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	$o->{ui}->space;
	$o->{ui}->title('Public envelope');
	$o->{ui}->line($o->{ui}->gold('cds show record ', $o->{hash}->hex, ' on ', $o->{actor}->storeReference($o->{store})));

	my $contentHash = $envelope->child('content')->hashValue;
	$o->showPublicPrivateSignature($envelope, $contentHash);

	$o->{ui}->space;
	$o->{ui}->title('Content');
	$o->{ui}->line($o->{ui}->gold('cds show record ', $contentHash->hex, ' on ', $o->{actor}->storeReference($o->{store})));

	$o->{ui}->space;
}

sub processPrivateEnvelope {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	$o->{ui}->space;
	$o->{ui}->title('Private envelope');
	$o->{ui}->line($o->{ui}->gold('cds show record ', $o->{hash}->hex, ' on ', $o->{actor}->storeReference($o->{store})));

	my $aesKey = $o->decryptAesKey($envelope);
	my $contentHash = $envelope->child('content')->hashValue;
	$o->showPublicPrivateSignature($envelope, $contentHash);
	$o->showEncryptedFor($envelope);

	$o->{ui}->space;
	if ($aesKey) {
		$o->{ui}->title('Content');
		$o->{ui}->line($o->{ui}->gold('cds show record ', $contentHash->hex, ' on ', $o->{actor}->storeReference($o->{store}), ' decrypted with ', unpack('H*', $aesKey)));
	} else {
		$o->{ui}->title('Encrypted content');
		$o->{ui}->line($o->{ui}->gold('cds get ', $contentHash->hex, ' on ', $o->{actor}->storeReference($o->{store})));
	}

	$o->{ui}->space;
}

sub showPublicPrivateSignature {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $contentHash = shift; die 'wrong type '.ref($contentHash).' for $contentHash' if defined $contentHash && ref $contentHash ne 'CDS::Hash';

	$o->{ui}->space;
	$o->{ui}->title('Signed by');
	if ($o->{senderHash}) {
		my $accountToken = CDS::AccountToken->new($o->{store}, $o->{senderHash});
		$o->{ui}->line($o->{actor}->blueAccountReference($accountToken));
		$o->showSignature($envelope, $o->{senderHash}, $o->{store}, $contentHash);
	} else {
		$o->{ui}->p('The signer is not known. To verify the signature of a public or private envelope, you need to indicate the account on which it was found:');
		$o->{ui}->line($o->{ui}->gold('  cds show envelope ', $o->{hash}->hex, ' from ', $o->{ui}->underlined('ACTOR'), ' on ', $o->{actor}->storeReference($o->{store})));
	}
}

sub processMessageEnvelope {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	$o->{ui}->space;
	$o->{ui}->title('Message envelope');
	$o->{ui}->line($o->{ui}->gold('cds show record ', $o->{hash}->hex, ' on ', $o->{actor}->storeReference($o->{store})));

	# Decrypt
	my $encryptedContentBytes = $envelope->child('content')->bytesValue;
	my $aesKey = $o->decryptAesKey($envelope);
	if (! $aesKey) {
		$o->{ui}->space;
		$o->{ui}->title('Encrypted content');
		$o->{ui}->line(length $encryptedContentBytes, ' bytes');
		return $o->processMessageEnvelope2($envelope);
	}

	my $contentObject = CDS::Object->fromBytes(CDS::C::aesCrypt($encryptedContentBytes, $aesKey, CDS->zeroCTR));
	if (! $contentObject) {
		$o->{ui}->pRed('The embedded content object is invalid, or the AES key (', unpack('H*', $aesKey), ') is wrong.');
		return $o->processMessageEnvelope2($envelope);
	}

	#my $signedHash = $contentObject->calculateHash;	# before 2020-05-05
	my $signedHash = CDS::Hash->calculateFor($encryptedContentBytes);
	my $content = CDS::Record->fromObject($contentObject);
	if (! $content) {
		$o->{ui}->pRed('The embedded content object does not contain a record, or the AES key (', unpack('H*', $aesKey), ') is wrong.');
		return $o->processMessageEnvelope2($envelope);
	}

	# Sender hash
	my $senderHash = $content->child('sender')->hashValue;
	$o->{ui}->pRed('The content object is missing the sender.') if ! $senderHash;

	# Sender store
	my $senderStoreRecord = $content->child('store');
	my $senderStoreBytes = $senderStoreRecord->bytesValue;
	my $mentionsSenderStore = length $senderStoreBytes;
	$o->{ui}->pRed('The content object is missing the sender\'s store.') if ! $mentionsSenderStore;
	my $senderStore = scalar $mentionsSenderStore ? $o->{actor}->storeForUrl($senderStoreRecord->textValue) : undef;

	# Sender
	$o->{ui}->space;
	$o->{ui}->title('Signed by');
	if ($senderHash && $senderStore) {
		my $senderToken = CDS::AccountToken->new($senderStore, $senderHash);
		$o->{ui}->line($o->{actor}->blueAccountReference($senderToken));
		$o->showSignature($envelope, $senderHash, $senderStore, $signedHash);
	} elsif ($senderHash) {
		my $actorLabel = $o->{actor}->actorLabel($senderHash) // $senderHash->hex;
		if ($mentionsSenderStore) {
			$o->{ui}->line($actorLabel, ' on ', $o->{ui}->red($o->{ui}->niceBytes($senderStoreBytes, 64)));
		} else {
			$o->{ui}->line($actorLabel);
		}
		$o->{ui}->pOrange('The signature cannot be verified, because the signer\'s store is not known.');
	} elsif ($senderStore) {
		$o->{ui}->line($o->{ui}->red('?'), ' on ', $o->{actor}->storeReference($senderStore));
		$o->{ui}->pOrange('The signature cannot be verified, because the signer is not known.');
	} elsif ($mentionsSenderStore) {
		$o->{ui}->line($o->{ui}->red('?'), ' on ', $o->{ui}->red($o->{ui}->niceBytes($senderStoreBytes, 64)));
		$o->{ui}->pOrange('The signature cannot be verified, because the signer is not known.');
	} else {
		$o->{ui}->pOrange('The signature cannot be verified, because the signer is not known.');
	}

	# Content
	$o->{ui}->space;
	$o->{ui}->title('Content');
	$o->{ui}->recordChildren($content, $senderStore ? $o->{actor}->storeReference($senderStore) : undef);

	return $o->processMessageEnvelope2($envelope);
}

sub processMessageEnvelope2 {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	# Encrypted for
	$o->showEncryptedFor($envelope);

	# Updated by
	$o->{ui}->space;
	$o->{ui}->title('May be removed or updated by');

	for my $child ($envelope->child('updated by')->children) {
		$o->showActorHash24($child->bytes);
	}

	# Expires
	$o->{ui}->space;
	$o->{ui}->title('Expires');
	my $expires = $envelope->child('expires')->integerValue;
	$o->{ui}->line($expires ? $o->{ui}->niceDateTime($expires) : $o->{ui}->gray('never'));
	$o->{ui}->space;
}

sub processStreamHead {
	my $o = shift;
	my $head = shift;

	$o->{ui}->space;
	$o->{ui}->title('Stream head');
	return $o->{ui}->pRed('The envelope does not mention a stream head.') if ! $head;
	$o->{ui}->line($o->{ui}->gold('cds open envelope ', $head->hex, ' on ', $o->{actor}->storeReference($o->{store})));

	# Get the envelope
	my $envelope = $o->{actor}->uiGetRecord($head, $o->{store}, $o->{keyPairToken}) // return;

	# Decrypt the content
	my $encryptedContentBytes = $envelope->child('content')->bytesValue;
	my $aesKey = $o->decryptAesKey($envelope) // return;
	my $contentObject = CDS::Object->fromBytes(CDS::C::aesCrypt($encryptedContentBytes, $aesKey, CDS->zeroCTR)) // return {aesKey => $aesKey};
	my $signedHash = CDS::Hash->calculateFor($encryptedContentBytes);
	my $content = CDS::Record->fromObject($contentObject) // return {aesKey => $aesKey};

	# Sender
	my $senderHash = $content->child('sender')->hashValue;
	my $senderStoreRecord = $content->child('store');
	my $senderStore = $o->{actor}->storeForUrl($senderStoreRecord->textValue);
	return {aesKey => $aesKey, senderHash => $senderHash, senderStore => $senderStore} if ! $senderHash || ! $senderStore;

	$o->{ui}->pushIndent;
	$o->{ui}->space;
	$o->{ui}->title('Signed by');
	my $senderToken = CDS::AccountToken->new($senderStore, $senderHash);
	$o->{ui}->line($o->{actor}->blueAccountReference($senderToken));
	$o->showSignature($envelope, $senderHash, $senderStore, $signedHash);

	# Recipients
	$o->{ui}->space;
	$o->{ui}->title('Encrypted for');
	for my $child ($envelope->child('encrypted for')->children) {
		$o->showActorHash24($child->bytes);
	}

	$o->{ui}->popIndent;
	return {aesKey => $aesKey, senderHash => $senderHash, senderStore => $senderStore, isValid => 1};
}

sub processStreamEnvelope {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	$o->{ui}->space;
	$o->{ui}->title('Stream envelope');
	$o->{ui}->line($o->{ui}->gold('cds show record ', $o->{hash}->hex, ' on ', $o->{actor}->storeReference($o->{store})));

	# Get the head
	my $streamHead = $o->processStreamHead($envelope->child('head')->hashValue);
	$o->{ui}->pRed('The stream head cannot be opened. Open the stream head envelope for details.') if ! $streamHead || ! $streamHead->{isValid};

	# Get the content
	my $encryptedBytes = $envelope->child('content')->bytesValue;

	# Get the CTR
	$o->{ui}->space;
	$o->{ui}->title('CTR');
	my $ctr = $envelope->child('ctr')->bytesValue;
	if (length $ctr == 16) {
		$o->{ui}->line(unpack('H*', $ctr));
	} else {
		$o->{ui}->pRed('The CTR value is invalid.');
	}

	return $o->{ui}->space if ! $streamHead;
	return $o->{ui}->space if ! $streamHead->{aesKey};

	# Get and verify the MAC
	$o->{ui}->space;
	$o->{ui}->title('Message authentication (MAC)');
	my $mac = $envelope->child('mac')->bytesValue;
	my $signedHash = CDS::Hash->calculateFor($encryptedBytes);
	my $expectedMac = CDS::C::aesCrypt($signedHash->bytes, $streamHead->{aesKey}, $ctr);
	if ($mac eq $expectedMac) {
		$o->{ui}->pGreen('The MAC valid.');
	} else {
		$o->{ui}->pRed('The MAC is invalid.');
	}

	# Decrypt the content
	$o->{ui}->space;
	$o->{ui}->title('Content');
	my $contentObject = CDS::Object->fromBytes(CDS::C::aesCrypt($encryptedBytes, $streamHead->{aesKey}, CDS::C::counterPlusInt($ctr, 2)));
	if (! $contentObject) {
		$o->{ui}->pRed('The embedded content object is invalid, or the provided AES key (', unpack('H*', $streamHead->{aesKey}), ') is wrong.') ;
		$o->{ui}->space;
		return;
	}

	my $content = CDS::Record->fromObject($contentObject);
	return $o->{ui}->pRed('The content is not a record.') if ! $content;
	$o->{ui}->recordChildren($content, $streamHead->{senderStore} ? $o->{actor}->storeReference($streamHead->{senderStore}) : undef);
	$o->{ui}->space;

	# The envelope is valid
	#my $source = CDS::Source->new($o->{pool}->{keyPair}, $o->{actorOnStore}, 'messages', $entry->{hash});
	#return CDS::ReceivedMessage->new($o, $entry, $source, $envelope, $streamHead->senderStoreUrl, $streamHead->sender, $content, $streamHead);

}

sub showActorHash24 {
	my $o = shift;
	my $actorHashBytes = shift;

	my $actorHashHex = unpack('H*', $actorHashBytes);
	return $o->{ui}->line($o->{ui}->red($actorHashHex, ' (', length $actorHashBytes, ' instead of 24 bytes)')) if length $actorHashBytes != 24;

	my $actorName = $o->{actor}->actorLabelByHashStartBytes($actorHashBytes);
	$actorHashHex .= '·' x 16;

	my $keyPairHashBytes = $o->{keyPairToken}->keyPair->publicKey->hash->bytes;
	my $isMe = substr($keyPairHashBytes, 0, 24) eq $actorHashBytes;
	$o->{ui}->line($isMe ? $o->{ui}->violet($actorHashHex) : $actorHashHex, (defined $actorName ? $o->{ui}->blue('  '.$actorName) : ''));
	return $isMe;
}

sub showSignature {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $senderHash = shift; die 'wrong type '.ref($senderHash).' for $senderHash' if defined $senderHash && ref $senderHash ne 'CDS::Hash';
	my $senderStore = shift;
	my $signedHash = shift; die 'wrong type '.ref($signedHash).' for $signedHash' if defined $signedHash && ref $signedHash ne 'CDS::Hash';

	# Get the public key
	my $publicKey = $o->getPublicKey($senderHash, $senderStore);
	return $o->{ui}->line($o->{ui}->orange('The signature cannot be verified, because the signer\'s public key is not available.')) if ! $publicKey;

	# Verify the signature
	if (CDS->verifyEnvelopeSignature($envelope, $publicKey, $signedHash)) {
		$o->{ui}->pGreen('The signature is valid.');
	} else {
		$o->{ui}->pRed('The signature is not valid.');
	}
}

sub getPublicKey {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;

	return $o->{keyPairToken}->keyPair->publicKey if $hash->equals($o->{keyPairToken}->keyPair->publicKey->hash);
	return $o->{actor}->uiGetPublicKey($hash, $store, $o->{keyPairToken});
}

sub showEncryptedFor {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	$o->{ui}->space;
	$o->{ui}->title('Encrypted for');

	my $canDecrypt = 0;
	for my $child ($envelope->child('encrypted for')->children) {
		$canDecrypt = 1 if $o->showActorHash24($child->bytes);
	}

	return if $canDecrypt;
	$o->{ui}->space;
	my $keyPairHash = $o->{keyPairToken}->keyPair->publicKey->hash;
	$o->{ui}->pOrange('This envelope is not encrypted for you (', $keyPairHash->shortHex, '). If you possess one of the keypairs mentioned above, add "… using KEYPAIR" to open this envelope.');
}

sub decryptAesKey {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	my $keyPair = $o->{keyPairToken}->keyPair;
	my $hashBytes24 = substr($keyPair->publicKey->hash->bytes, 0, 24);
	my $child = $envelope->child('encrypted for')->child($hashBytes24);

	my $encryptedAesKey = $child->bytesValue;
	return if ! length $encryptedAesKey;

	my $aesKey = $keyPair->decrypt($encryptedAesKey);
	return $aesKey if defined $aesKey && length $aesKey == 32;

	$o->{ui}->pRed('The AES key failed to decrypt. It either wasn\'t encrypted properly, or the encryption was performed with the wrong public key.');
	return;
}

# BEGIN AUTOGENERATED
package CDS::Commands::Put;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(1);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(0);
	my $node017 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&put});
	$cds->addArrow($node000, 1, 0, 'put');
	$cds->addArrow($node001, 1, 0, 'put');
	$cds->addArrow($node002, 1, 0, 'put');
	$help->addArrow($node007, 1, 0, 'put');
	$node000->addArrow($node012, 1, 0, 'OBJECTFILE', \&collectObjectfile);
	$node001->addArrow($node003, 1, 0, 'object');
	$node002->addArrow($node004, 1, 0, 'public');
	$node003->addArrow($node008, 1, 0, 'with');
	$node004->addArrow($node005, 1, 0, 'key');
	$node005->addArrow($node006, 1, 0, 'of');
	$node006->addArrow($node012, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node008->addDefault($node009);
	$node008->addDefault($node011);
	$node009->addArrow($node009, 1, 0, 'HASH', \&collectHash);
	$node009->addArrow($node010, 1, 0, 'HASH', \&collectHash);
	$node010->addArrow($node011, 1, 0, 'and');
	$node011->addArrow($node012, 1, 0, 'FILE', \&collectFile);
	$node012->addArrow($node013, 1, 0, 'encrypted');
	$node012->addDefault($node015);
	$node013->addArrow($node014, 1, 0, 'with');
	$node014->addArrow($node015, 1, 0, 'AESKEY', \&collectAeskey);
	$node015->addArrow($node016, 1, 0, 'onto');
	$node015->addDefault($node017);
	$node016->addArrow($node016, 1, 0, 'STORE', \&collectStore);
	$node016->addArrow($node017, 1, 0, 'STORE', \&collectStore);
}

sub collectAeskey {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{aesKey} = $value;
}

sub collectFile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{dataFile} = $value;
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{hashes}}, $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{object} = $value->keyPair->publicKey->object;
}

sub collectObjectfile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{objectFile} = $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{stores}}, $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME store-put
# HTML TITLE Put
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds put FILE* [onto STORE*]');
	$ui->p('Uploads object files onto object stores. If no stores are provided, the selected store is used. If an upload fails, the program immediately quits with exit code 1.');
	$ui->space;
	$ui->command('cds put FILE encrypted with AESKEY [onto STORE*]');
	$ui->p('Encrypts the object before the upload.');
	$ui->space;
	$ui->command('cds put object with [HASH* and] FILE …');
	$ui->p('Creates an object with the HASHes as hash list and FILE as data.');
	$ui->space;
	$ui->command('cds put public key of KEYPAIR …');
	$ui->p('Uploads the public key of the indicated key pair onto the store.');
	$ui->space;
}

sub put {
	my $o = shift;
	my $cmd = shift;

	$o->{hashes} = [];
	$o->{stores} = [];
	$cmd->collect($o);

	# Stores
	push @{$o->{stores}}, $o->{actor}->preferredStore if ! scalar @{$o->{stores}};

	$o->{get} = [];
	return $o->putObject($o->{object}) if $o->{object};
	return $o->putObjectFile if $o->{objectFile};
	$o->putConstructedFile;
}

sub putObjectFile {
	my $o = shift;

	my $object = $o->{objectFile}->object;

	# Display object information
	$o->{ui}->space;
	$o->{ui}->title('Uploading ', $o->{objectFile}->file, '  ', $o->{ui}->gray($o->{ui}->niceFileSize($object->byteLength)));
	$o->{ui}->line($object->hashesCount == 1 ? '1 hash' : $object->hashesCount.' hashes');
	$o->{ui}->line($o->{ui}->niceFileSize(length $object->data).' data');
	$o->{ui}->space;

	# Upload
	$o->putObject($object);
}

sub putConstructedFile {
	my $o = shift;

	# Create the object
	my $data = CDS->readBytesFromFile($o->{dataFile}) // return $o->{ui}->error('Unable to read "', $o->{dataFile}, '".');
	my $header = pack('L>', scalar @{$o->{hashes}}) . join('', map { $_->bytes } @{$o->{hashes}});
	my $object = CDS::Object->create($header, $data);

	# Display object information
	$o->{ui}->space;
	$o->{ui}->title('Uploading new object  ', $o->{ui}->gray($o->{ui}->niceFileSize(length $object->bytes)));
	$o->{ui}->line($object->hashesCount == 1 ? '1 hash' : $object->hashesCount.' hashes');
	$o->{ui}->line($o->{ui}->niceFileSize(length $object->data).' data from ', $o->{dataFile});
	$o->{ui}->space;

	# Upload
	$o->putObject($object);
}

sub putObject {
	my $o = shift;
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	my $keyPair = $o->{actor}->preferredKeyPairToken->keyPair;

	# Encrypt it if desired
	my $objectBytes;
	if (defined $o->{aesKey}) {
		$object = $object->crypt($o->{aesKey});
		unshift @{$o->{get}}, ' decrypted with ', unpack('H*', $o->{aesKey}), ' ';
	}

	# Calculate the hash
	my $hash = $object->calculateHash;

	# Upload the object
	my $successfulStore;
	for my $store (@{$o->{stores}}) {
		my $error = $store->put($hash, $object, $keyPair);
		next if $error;
		$o->{ui}->pGreen('The object was uploaded onto ', $store->url, '.');
		$successfulStore = $store;
	}

	# Show the corresponding download line
	return if ! $successfulStore;
	$o->{ui}->space;
	$o->{ui}->line('To download the object, type:');
	$o->{ui}->line($o->{ui}->gold('cds get ', $hash->hex), $o->{ui}->gray(' on ', $successfulStore->url, @{$o->{get}}));
	$o->{ui}->space;
}

package CDS::Commands::Remember;

# BEGIN AUTOGENERATED

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0, {constructor => \&new, function => \&showLabels});
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&forget});
	my $node007 = CDS::Parser::Node->new(1);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&remember});
	$cds->addArrow($node000, 1, 0, 'remember');
	$cds->addArrow($node001, 1, 0, 'forget');
	$help->addArrow($node003, 1, 0, 'forget');
	$help->addArrow($node003, 1, 0, 'remember');
	$node000->addArrow($node004, 1, 0, 'ACTOR', \&collectActor);
	$node000->addArrow($node007, 1, 1, 'ACCOUNT', \&collectAccount);
	$node000->addArrow($node007, 1, 0, 'ACTOR', \&collectActor);
	$node000->addArrow($node007, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node000->addArrow($node007, 1, 0, 'STORE', \&collectStore);
	$node001->addDefault($node002);
	$node002->addArrow($node002, 1, 0, 'LABEL', \&collectLabel);
	$node002->addArrow($node006, 1, 0, 'LABEL', \&collectLabel);
	$node004->addArrow($node005, 1, 0, 'on');
	$node005->addArrow($node007, 1, 0, 'STORE', \&collectStore);
	$node007->addArrow($node008, 1, 0, 'as');
	$node008->addArrow($node009, 1, 0, 'TEXT', \&collectText);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value->cliStore;
	$o->{actorHash} = $value->actorHash;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
}

sub collectLabel {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{forget}}, $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectText {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{label} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME remember
# HTML TITLE Remember
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds remember');
	$ui->p('Shows all remembered values.');
	$ui->space;
	$ui->command('cds remember ACCOUNT|ACTOR|STORE|KEYPAIR as TEXT');
	$ui->command('cds remember ACTOR on STORE as TEXT');
	$ui->p('Remembers the indicated actor hash, account, store, or key pair as TEXT. This information is stored in the global state, and therefore persists until the name is deleted (cds forget …) or redefined (cds remember …).');
	$ui->space;
	$ui->p('Key pairs are stored as link (absolute path) to the key pair file, and specific to the device.');
	$ui->space;
	$ui->command('cds forget LABEL');
	$ui->p('Forgets the corresponding item.');
	$ui->space;
}

sub remember {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	my $record = CDS::Record->new;
	$record->add('store')->addText($o->{store}->url) if defined $o->{store};
	$record->add('actor')->add($o->{actorHash}->bytes) if defined $o->{actorHash};
	$record->add('key pair')->addText($o->{keyPairToken}->file) if defined $o->{keyPairToken};
	$o->{actor}->remember($o->{label}, $record);
	$o->{actor}->saveOrShowError;
}

sub forget {
	my $o = shift;
	my $cmd = shift;

	$o->{forget} = [];
	$cmd->collect($o);

	for my $label (@{$o->{forget}}) {
		$o->{actor}->groupRoot->child('labels')->child($label)->clear;
	}

	$o->{actor}->saveOrShowError;
}

sub showLabels {
	my $o = shift;
	my $cmd = shift;

	$o->{ui}->space;
	$o->showRememberedValues;
	$o->{ui}->space;
}

sub showRememberedValues {
	my $o = shift;

	my $hasLabel = 0;
	for my $child (sort { $a->{id} cmp $b->{id} } $o->{actor}->groupRoot->child('labels')->children) {
		my $record = $child->record;
		my $label = $o->{ui}->blue($o->{ui}->left(15, Encode::decode_utf8($child->label)));

		my $actorHash = CDS::Hash->fromBytes($record->child('actor')->bytesValue);
		my $storeUrl = $record->child('store')->textValue;
		my $keyPairFile = $record->child('key pair')->textValue;

		if (length $keyPairFile) {
			$o->{ui}->line($label, ' ', $o->{ui}->gray('key pair'), '    ', $keyPairFile);
			$hasLabel = 1;
		}

		if ($actorHash && length $storeUrl) {
			my $storeReference = $o->{actor}->blueStoreUrlReference($storeUrl);
			$o->{ui}->line($label, ' ', $o->{ui}->gray('account'), '     ', $actorHash->hex, ' on ', $storeReference);
			$hasLabel = 1;
		} elsif ($actorHash) {
			$o->{ui}->line($label, ' ', $o->{ui}->gray('actor'), '       ', $actorHash->hex);
			$hasLabel = 1;
		} elsif (length $storeUrl) {
			$o->{ui}->line($label, ' ', $o->{ui}->gray('store'), '       ', $storeUrl);
			$hasLabel = 1;
		}

		$o->showActorGroupLabel($label, $record->child('actor group'));
	}

	return if $hasLabel;
	$o->{ui}->line($o->{ui}->gray('none'));
}

sub showActorGroupLabel {
	my $o = shift;
	my $label = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	return if ! $record->contains('actor group');

	my $builder = CDS::ActorGroupBuilder->new;
	$builder->parse($record, 1);

	my $countActive = 0;
	my $countIdle = 0;
	my $newestActive = undef;

	for my $member ($builder->members) {
		my $isActive = $member->status eq 'active';
		$countActive += 1 if $isActive;
		$countIdle += 1 if $member->status eq 'idle';

		next if ! $isActive;
		next if $newestActive && $member->revision <= $newestActive->revision;
		$newestActive = $member;
	}

	my @line;
	push @line, $label, ' ', $o->{ui}->gray('actor group'), ' ';
	push @line, $newestActive->hash->hex, ' on ', $o->{actor}->blueStoreUrlReference($newestActive->storeUrl) if $newestActive;
	push @line, $o->{ui}->gray('(no active actor)') if ! $newestActive;
	push @line, $o->{ui}->green('  ', $countActive, ' active');
	my $discovered = $record->child('discovered')->integerValue;
	push @line, $o->{ui}->gray('  ', $o->{ui}->niceDateTimeLocal($discovered)) if $discovered;
	$o->{ui}->line(@line);
}

# BEGIN AUTOGENERATED
package CDS::Commands::Select;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node017 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showSelectionCmd});
	my $node018 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&unselectKeyPair});
	my $node019 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&unselectStore});
	my $node020 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&unselectActor});
	my $node021 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&unselectAll});
	my $node022 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&select});
	$cds->addArrow($node000, 1, 0, 'select');
	$cds->addArrow($node001, 1, 0, 'select');
	$cds->addArrow($node002, 1, 0, 'select');
	$cds->addArrow($node003, 1, 0, 'select');
	$cds->addArrow($node004, 1, 0, 'select');
	$cds->addArrow($node005, 1, 0, 'select');
	$cds->addArrow($node006, 1, 0, 'select');
	$cds->addArrow($node009, 1, 0, 'unselect');
	$cds->addArrow($node010, 1, 0, 'unselect');
	$cds->addArrow($node011, 1, 0, 'unselect');
	$cds->addArrow($node012, 1, 0, 'unselect');
	$cds->addArrow($node017, 1, 0, 'select');
	$help->addArrow($node016, 1, 0, 'select');
	$node000->addArrow($node022, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node001->addArrow($node022, 1, 0, 'STORE', \&collectStore);
	$node002->addArrow($node014, 1, 0, 'ACTOR', \&collectActor);
	$node003->addArrow($node007, 1, 0, 'storage');
	$node004->addArrow($node008, 1, 0, 'messaging');
	$node005->addArrow($node022, 1, 0, 'ACTOR', \&collectActor);
	$node006->addArrow($node022, 1, 1, 'ACCOUNT', \&collectAccount);
	$node007->addArrow($node022, 1, 0, 'store', \&collectStore1);
	$node008->addArrow($node022, 1, 0, 'store', \&collectStore2);
	$node009->addArrow($node013, 1, 0, 'key');
	$node010->addArrow($node019, 1, 0, 'store');
	$node011->addArrow($node020, 1, 0, 'actor');
	$node012->addArrow($node021, 1, 0, 'all');
	$node013->addArrow($node018, 1, 0, 'pair');
	$node014->addArrow($node015, 1, 0, 'on');
	$node015->addArrow($node022, 1, 0, 'STORE', \&collectStore);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value->cliStore;
	$o->{actorHash} = $value->actorHash;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
	$o->{actorHash} = $value->keyPair->publicKey->hash;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectStore1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $o->{actor}->storageStore;
}

sub collectStore2 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $o->{actor}->messagingStore;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME select
# HTML TITLE Select
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds select');
	$ui->p('Shows the current selection.');
	$ui->space;
	$ui->command('cds select KEYPAIR');
	$ui->p('Selects KEYPAIR on this terminal. Some commands will use this key pair by default.');
	$ui->space;
	$ui->command('cds unselect key pair');
	$ui->p('Removes the key pair selection.');
	$ui->space;
	$ui->command('cds select STORE');
	$ui->p('Selects STORE on this terminal. Some commands will use this store by default.');
	$ui->space;
	$ui->command('cds unselect store');
	$ui->p('Removes the store selection.');
	$ui->space;
	$ui->command('cds select ACTOR');
	$ui->p('Selects ACTOR on this terminal. Some commands will use this store by default.');
	$ui->space;
	$ui->command('cds unselect actor');
	$ui->p('Removes the actor selection.');
	$ui->space;
	$ui->command('cds unselect');
	$ui->p('Removes any selection.');
	$ui->space;
}

sub select {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	if ($o->{keyPairToken}) {
		$o->{actor}->sessionRoot->child('selected key pair')->setText($o->{keyPairToken}->file);
		$o->{ui}->pGreen('Key pair ', $o->{keyPairToken}->file, ' selected.');
	}

	if ($o->{store}) {
		$o->{actor}->sessionRoot->child('selected store')->setText($o->{store}->url);
		$o->{ui}->pGreen('Store ', $o->{store}->url, ' selected.');
	}

	if ($o->{actorHash}) {
		$o->{actor}->sessionRoot->child('selected actor')->setBytes($o->{actorHash}->bytes);
		$o->{ui}->pGreen('Actor ', $o->{actorHash}->hex, ' selected.');
	}

	$o->{actor}->saveOrShowError;
}

sub unselectKeyPair {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->sessionRoot->child('selected key pair')->clear;
	$o->{ui}->pGreen('Key pair selection cleared.');
	$o->{actor}->saveOrShowError;
}

sub unselectStore {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->sessionRoot->child('selected store')->clear;
	$o->{ui}->pGreen('Store selection cleared.');
	$o->{actor}->saveOrShowError;
}

sub unselectActor {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->sessionRoot->child('selected actor')->clear;
	$o->{ui}->pGreen('Actor selection cleared.');
	$o->{actor}->saveOrShowError;
}

sub unselectAll {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->sessionRoot->child('selected key pair')->clear;
	$o->{actor}->sessionRoot->child('selected store')->clear;
	$o->{actor}->sessionRoot->child('selected actor')->clear;
	$o->{actor}->saveOrShowError // return;
	$o->showSelection;
}

sub showSelectionCmd {
	my $o = shift;
	my $cmd = shift;

	$o->{ui}->space;
	$o->showSelection;
	$o->{ui}->space;
}

sub showSelection {
	my $o = shift;

	my $keyPairFile = $o->{actor}->sessionRoot->child('selected key pair')->textValue;
	my $storeUrl = $o->{actor}->sessionRoot->child('selected store')->textValue;
	my $actorBytes = $o->{actor}->sessionRoot->child('selected actor')->bytesValue;

	$o->{ui}->line($o->{ui}->darkBold('Selected key pair  '), length $keyPairFile ? $keyPairFile : $o->{ui}->gray('none'));
	$o->{ui}->line($o->{ui}->darkBold('Selected store     '), length $storeUrl ? $storeUrl : $o->{ui}->gray('none'));
	$o->{ui}->line($o->{ui}->darkBold('Selected actor     '), length $actorBytes == 32 ? unpack('H*', $actorBytes) : $o->{ui}->gray('none'));
}

# BEGIN AUTOGENERATED
package CDS::Commands::ShowCard;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node005 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showMyCard});
	my $node006 = CDS::Parser::Node->new(1);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showCard});
	$cds->addArrow($node001, 1, 0, 'show');
	$cds->addArrow($node002, 1, 0, 'show');
	$help->addArrow($node000, 1, 0, 'show');
	$node000->addArrow($node004, 1, 0, 'card');
	$node001->addArrow($node006, 1, 0, 'card');
	$node002->addArrow($node003, 1, 0, 'my');
	$node003->addArrow($node005, 1, 0, 'card');
	$node006->addArrow($node007, 1, 0, 'of');
	$node006->addArrow($node008, 1, 0, 'of');
	$node006->addArrow($node009, 1, 0, 'of');
	$node006->addArrow($node010, 1, 0, 'of');
	$node006->addDefault($node011);
	$node007->addArrow($node007, 1, 0, 'ACCOUNT', \&collectAccount);
	$node007->addArrow($node013, 1, 1, 'ACCOUNT', \&collectAccount);
	$node008->addArrow($node013, 1, 0, 'ACTORGROUP', \&collectActorgroup);
	$node009->addArrow($node011, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node010->addArrow($node011, 1, 0, 'ACTOR', \&collectActor);
	$node011->addArrow($node012, 1, 0, 'on');
	$node011->addDefault($node013);
	$node012->addArrow($node012, 1, 0, 'STORE', \&collectStore);
	$node012->addArrow($node013, 1, 0, 'STORE', \&collectStore);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, $value;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectActorgroup {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	for my $member ($value->actorGroup->members) {
	my $actorOnStore = $member->actorOnStore;
	$o->addKnownPublicKey($actorOnStore->publicKey);
	push @{$o->{accountTokens}}, CDS::AccountToken->new($actorOnStore->store, $actorOnStore->publicKey->hash);
	}
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
	$o->{actorHash} = $value->keyPair->publicKey->hash;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{stores}}, $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME show-card
# HTML TITLE Show an actor's public card
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show card of ACCOUNT');
	$ui->command('cds show card of ACTOR [on STORE]');
	$ui->command('cds show card of KEYPAIR [on STORE]');
	$ui->p('Shows the card(s) of an actor.');
	$ui->space;
	$ui->command('cds show card of ACTORGROUP');
	$ui->p('Shows all cards of an actor group.');
	$ui->space;
	$ui->command('cds show card');
	$ui->p('Shows the card of the selected actor on the selected store.');
	$ui->space;
	$ui->command('cds show my card');
	$ui->p('Shows your own card.');
	$ui->space;
	$ui->p('An actor usually has one card. If no cards are shown, the corresponding actor does not exist, is not using that store, or has not properly announced itself. Two cards may exist while the actor is updating its card. Such a state is temporary, but may exist for hours or days if the actor has intermittent network access. Three or more cards may point to an error in the way the actor updates his card, an error in the synchronization code (if the account is synchronized). Two or more cards may also occur naturally when stores are merged.');
	$ui->space;
	$ui->p('A peer consists of one or more actors, which all publish their own card. The cards are usually different, but should contain consistent information.');
	$ui->space;
	$ui->p('You can publish your own card (i.e. the card of your main key pair) using');
	$ui->p('  cds announce');
	$ui->space;
}

sub showCard {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken;
	$o->{stores} = [];
	$o->{accountTokens} = [];
	$o->{knownPublicKeys} = {};
	$cmd->collect($o);

	# Use actorHash/store
	if (! scalar @{$o->{accountTokens}}) {
		$o->{actorHash} = $o->{actor}->preferredActorHash if ! $o->{actorHash};
		push @{$o->{stores}}, $o->{actor}->preferredStores if ! scalar @{$o->{stores}};
		for my $store (@{$o->{stores}}) {
			push @{$o->{accountTokens}}, CDS::AccountToken->new($store, $o->{actorHash});
		}
	}

	# Show the cards
	$o->addKnownPublicKey($o->{keyPairToken}->keyPair->publicKey);
	$o->addKnownPublicKey($o->{actor}->keyPair->publicKey);
	for my $accountToken (@{$o->{accountTokens}}) {
		$o->processAccount($accountToken);
	}

	$o->{ui}->space;
}

sub showMyCard {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken;
	$o->processAccount(CDS::AccountToken->new($o->{actor}->messagingStore, $o->{actor}->keyPair->publicKey->hash));
	$o->processAccount(CDS::AccountToken->new($o->{actor}->storageStore, $o->{actor}->keyPair->publicKey->hash)) if $o->{actor}->storageStore->url ne $o->{actor}->messagingStore->url;
	$o->{ui}->space;
}

sub processAccount {
	my $o = shift;
	my $accountToken = shift;

	$o->{ui}->space;

	# Query the store
	my $store = $accountToken->cliStore;
	my ($hashes, $storeError) = $store->list($accountToken->actorHash, 'public', 0);
	if (defined $storeError) {
		$o->{ui}->title('public box of ', $o->{actor}->blueAccountReference($accountToken));
		return;
	}

	# Print the result
	my $count = scalar @$hashes;
	$o->{ui}->title('public box of ', $o->{actor}->blueAccountReference($accountToken), '  ', $o->{ui}->blue($count == 0 ? 'no cards' : $count == 1 ? '1 card' : $count.' cards'));
	return if ! $count;

	foreach my $hash (sort { $a->bytes cmp $b->bytes } @$hashes) {
		$o->processEntry($accountToken, $hash);
	}
}

sub processEntry {
	my $o = shift;
	my $accountToken = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $keyPair = $o->{keyPairToken}->keyPair;
	my $store = $accountToken->cliStore;
	my $storeReference = $o->{actor}->storeReference($store);

	# Open the envelope
	$o->{ui}->line($o->{ui}->gold('cds open envelope ', $hash->hex), $o->{ui}->gray(' from ', $accountToken->actorHash->hex, ' on ', $storeReference));

	my $envelope = $o->{actor}->uiGetRecord($hash, $accountToken->cliStore, $o->{keyPairToken}) // return;
	my $publicKey = $o->getPublicKey($accountToken) // $o->{ui}->pRed('The owner\'s public key is missing. Skipping signature verification.');
	my $cardHash = $envelope->child('content')->hashValue // $o->{ui}->pRed('Missing content hash.');
	return $o->{ui}->pRed('Invalid signature.') if $publicKey && $cardHash && ! CDS->verifyEnvelopeSignature($envelope, $publicKey, $cardHash);

	# Read and show the card
	return if ! $cardHash;
	$o->{ui}->line($o->{ui}->gold('cds show record ', $cardHash->hex), $o->{ui}->gray(' on ', $storeReference));
	my $card = $o->{actor}->uiGetRecord($cardHash, $accountToken->cliStore, $o->{keyPairToken}) // return;

	$o->{ui}->pushIndent;
	$o->{ui}->recordChildren($card, $storeReference);
	$o->{ui}->popIndent;
	return;
}

sub getPublicKey {
	my $o = shift;
	my $accountToken = shift;

	my $hash = $accountToken->actorHash;
	my $knownPublicKey = $o->{knownPublicKeys}->{$hash->bytes};
	return $knownPublicKey if $knownPublicKey;
	my $publicKey = $o->{actor}->uiGetPublicKey($hash, $accountToken->cliStore, $o->{keyPairToken}) // return;
	$o->addKnownPublicKey($publicKey);
	return $publicKey;
}

sub addKnownPublicKey {
	my $o = shift;
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';

	$o->{knownPublicKeys}->{$publicKey->hash->bytes} = $publicKey;
}

# BEGIN AUTOGENERATED
package CDS::Commands::ShowKeyPair;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showKeyPair});
	my $node010 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showMyKeyPair});
	my $node011 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showSelectedKeyPair});
	$cds->addArrow($node002, 1, 0, 'show');
	$cds->addArrow($node003, 1, 0, 'show');
	$cds->addArrow($node004, 1, 0, 'show');
	$help->addArrow($node000, 1, 0, 'show');
	$node000->addArrow($node001, 1, 0, 'key');
	$node001->addArrow($node008, 1, 0, 'pair');
	$node002->addArrow($node009, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node003->addArrow($node005, 1, 0, 'my');
	$node004->addArrow($node006, 1, 0, 'key');
	$node005->addArrow($node007, 1, 0, 'key');
	$node006->addArrow($node011, 1, 0, 'pair');
	$node007->addArrow($node010, 1, 0, 'pair');
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME show-key-pair
# HTML TITLE Show key pair
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show KEYPAIR');
	$ui->command('cds show my key pair');
	$ui->command('cds show key pair');
	$ui->p('Shows information about KEYPAIR, your key pair, or the currently selected key pair (see "cds use …").');
	$ui->space;
}

sub showKeyPair {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->showAll($o->{keyPairToken});
}

sub showMyKeyPair {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->showAll($o->{actor}->keyPairToken);
}

sub showSelectedKeyPair {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->showAll($o->{actor}->preferredKeyPairToken);
}

sub show {
	my $o = shift;
	my $keyPairToken = shift;

	$o->{ui}->line($o->{ui}->darkBold('File  '), $keyPairToken->file) if defined $keyPairToken->file;
	$o->{ui}->line($o->{ui}->darkBold('Hash  '), $keyPairToken->keyPair->publicKey->hash->hex);
}

sub showAll {
	my $o = shift;
	my $keyPairToken = shift;

	$o->{ui}->space;
	$o->{ui}->title('Key pair');
	$o->show($keyPairToken);
	$o->showPublicKeyObject($keyPairToken);
	$o->showPublicKey($keyPairToken);
	$o->showPrivateKey($keyPairToken);
	$o->{ui}->space;
}

sub showPublicKeyObject {
	my $o = shift;
	my $keyPairToken = shift;

	my $object = $keyPairToken->keyPair->publicKey->object;
	$o->{ui}->space;
	$o->{ui}->title('Public key object');
	$o->byteData('      ', $object->bytes);
}

sub showPublicKey {
	my $o = shift;
	my $keyPairToken = shift;

	my $rsaPublicKey = $keyPairToken->keyPair->publicKey->{rsaPublicKey};
	$o->{ui}->space;
	$o->{ui}->title('Public key');
	$o->byteData('e     ', CDS::C::publicKeyE($rsaPublicKey));
	$o->byteData('n     ', CDS::C::publicKeyN($rsaPublicKey));
}

sub showPrivateKey {
	my $o = shift;
	my $keyPairToken = shift;

	my $rsaPrivateKey = $keyPairToken->keyPair->{rsaPrivateKey};
	$o->{ui}->space;
	$o->{ui}->title('Private key');
	$o->byteData('e     ', CDS::C::privateKeyE($rsaPrivateKey));
	$o->byteData('p     ', CDS::C::privateKeyP($rsaPrivateKey));
	$o->byteData('q     ', CDS::C::privateKeyQ($rsaPrivateKey));
}

sub byteData {
	my $o = shift;
	my $label = shift;
	my $bytes = shift;

	my $hex = unpack('H*', $bytes);
	$o->{ui}->line($o->{ui}->darkBold($label), substr($hex, 0, 64));

	my $start = 64;
	my $spaces = ' ' x length $label;
	while ($start < length $hex) {
		$o->{ui}->line($spaces, substr($hex, $start, 64));
		$start += 64;
	}
}

# BEGIN AUTOGENERATED
package CDS::Commands::ShowMessages;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showMessagesOfSelected});
	my $node010 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showMyMessages});
	my $node011 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showOurMessages});
	my $node012 = CDS::Parser::Node->new(1);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showMessages});
	$cds->addArrow($node001, 1, 0, 'show');
	$cds->addArrow($node002, 1, 0, 'show');
	$cds->addArrow($node003, 1, 0, 'show');
	$cds->addArrow($node004, 1, 0, 'show');
	$help->addArrow($node000, 1, 0, 'show');
	$node000->addArrow($node008, 1, 0, 'messages');
	$node001->addArrow($node005, 1, 0, 'messages');
	$node002->addArrow($node006, 1, 0, 'my');
	$node003->addArrow($node009, 1, 0, 'messages');
	$node004->addArrow($node007, 1, 0, 'our');
	$node005->addArrow($node012, 1, 0, 'of');
	$node006->addArrow($node010, 1, 0, 'messages');
	$node007->addArrow($node011, 1, 0, 'messages');
	$node012->addArrow($node013, 1, 0, 'ACTOR', \&collectActor);
	$node012->addArrow($node013, 1, 0, 'KEYPAIR', \&collectKeypair);
	$node012->addArrow($node015, 1, 1, 'ACCOUNT', \&collectAccount);
	$node012->addArrow($node015, 1, 0, 'ACTOR', \&collectActor1);
	$node012->addArrow($node015, 1, 0, 'ACTORGROUP', \&collectActorgroup);
	$node012->addArrow($node015, 1, 0, 'KEYPAIR', \&collectKeypair1);
	$node013->addArrow($node014, 1, 0, 'on');
	$node014->addArrow($node015, 1, 0, 'STORE', \&collectStore);
}

sub collectAccount {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, $value;
}

sub collectActor {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{actorHash} = $value;
}

sub collectActor1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, CDS::AccountToken->new($o->{actor}->preferredStore, $value);
}

sub collectActorgroup {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	for my $member ($value->actorGroup->members) {
	push @{$o->{accountTokens}}, CDS::AccountToken->new($member->actorOnStore->store, $member->actorOnStore->publicKey->hash);
	}
}

sub collectKeypair {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
	$o->{actorHash} = $value->keyPair->publicKey->hash;
}

sub collectKeypair1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{keyPairToken} = $value;
	push @{$o->{accountTokens}}, CDS::AccountToken->new($o->{actor}->preferredStore, $value->publicKey->hash);
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{accountTokens}}, CDS::AccountToken->new($value, $o->{actorHash});
	delete $o->{actorHash};
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME show-messages
# HTML TITLE Show messages
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show messages of ACCOUNT');
	$ui->command('cds show messages of ACTOR|KEYPAIR [on STORE]');
	$ui->p('Shows all (unprocessed) messages of an actor ordered by their envelope hash. If store is omitted, the selected store is used.');
	$ui->space;
	$ui->command('cds show messages of ACTORGROUP');
	$ui->p('Shows all messages of all actors of that group.');
	$ui->space;
	$ui->command('cds show messages');
	$ui->p('Shows the messages of the selected key pair on the selected store.');
	$ui->space;
	$ui->command('cds show my messages');
	$ui->p('Shows your messages.');
	$ui->space;
	$ui->command('cds show our messages');
	$ui->p('Shows all messages of your actor group.');
	$ui->space;
	$ui->p('Unprocessed messages are stored in the message box of an actor. Each entry points to an envelope, which in turn points to a record object. The envelope is signed by the sender, but does not hold any date. If the application relies on dates, it must include this date in the message.');
	$ui->space;
	$ui->p('While the envelope hash is stored on the actor\'s store, the envelope and the message are stored on the sender\'s store, and are downloaded from there. Depending on the reachability and responsiveness of that store, messages may not always be accessible.');
	$ui->space;
	$ui->p('Senders typically keep sent messages for about 10 days on their store. After that, the envelope hash may still be in the message box, but the actual message may have vanished.');
	$ui->space;
}

sub showMessagesOfSelected {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken;
	$o->processAccounts(CDS::AccountToken->new($o->{actor}->preferredStore, $o->{actor}->preferredActorHash));
}

sub showMyMessages {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->keyPairToken;
	my $actorHash = $o->{actor}->keyPair->publicKey->hash;
	my $store = $o->{actor}->messagingStore;
	$o->processAccounts(CDS::AccountToken->new($store, $actorHash));
}

sub showOurMessages {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->keyPairToken;

	my @accountTokens;
	for my $child ($o->{actor}->actorGroupSelector->children) {
		next if $child->child('revoked')->isSet;
		next if ! $child->child('active')->isSet;

		my $record = $child->record;
		my $actorHash = $record->child('hash')->hashValue // next;
		my $storeUrl = $record->child('store')->textValue;
		my $store = $o->{actor}->storeForUrl($storeUrl) // next;
		push @accountTokens, CDS::AccountToken->new($store, $actorHash);
	}

	$o->processAccounts(@accountTokens);
}

sub showMessages {
	my $o = shift;
	my $cmd = shift;

	$o->{accountTokens} = [];
	$cmd->collect($o);

	# Unless a key pair was provided, use the selected key pair
	$o->{keyPairToken} = $o->{actor}->keyPairToken if ! $o->{keyPairToken};

	$o->processAccounts(@{$o->{accountTokens}});
}

sub processAccounts {
	my $o = shift;

	# Initialize the statistics
	$o->{countValid} = 0;
	$o->{countInvalid} = 0;

	# Show the messages of all selected accounts
	for my $accountToken (@_) {
		CDS::Commands::ShowMessages::ProcessAccount->new($o, $accountToken);
	}

	# Show the statistics
	$o->{ui}->space;
	$o->{ui}->title('Total');
	$o->{ui}->line(scalar @_, ' account', scalar @_ == 1 ? '' : 's');
	$o->{ui}->line($o->{countValid}, ' message', $o->{countValid} == 1 ? '' : 's');
	$o->{ui}->line($o->{countInvalid}, ' invalid message', $o->{countInvalid} == 1 ? '' : 's') if $o->{countInvalid};
	$o->{ui}->space;
}

package CDS::Commands::ShowMessages::ProcessAccount;

sub new {
	my $class = shift;
	my $cmd = shift;
	my $accountToken = shift;

	my $o = bless {
		cmd => $cmd,
		accountToken => $accountToken,
		countValid => 0,
		countInvalid => 0,
		};

	$cmd->{ui}->space;
	$cmd->{ui}->title('Messages of ', $cmd->{actor}->blueAccountReference($accountToken));

	# Get the public key
	my $publicKey = $o->getPublicKey // return;

	# Read all messages
	my $publicKeyCache = CDS::PublicKeyCache->new(128);
	my $pool = CDS::MessageBoxReaderPool->new($cmd->{keyPairToken}->keyPair, $publicKeyCache, $o);
	my $reader = CDS::MessageBoxReader->new($pool, CDS::ActorOnStore->new($publicKey, $accountToken->cliStore));
	$reader->read;

	$cmd->{ui}->line($cmd->{ui}->gray('No messages.')) if $o->{countValid} + $o->{countInvalid} == 0;
}

sub getPublicKey {
	my $o = shift;

	# Use the keypair's public key if possible
	return $o->{cmd}->{keyPairToken}->keyPair->publicKey if $o->{accountToken}->actorHash->equals($o->{cmd}->{keyPairToken}->keyPair->publicKey->hash);

	# Retrieve the public key
	return $o->{cmd}->{actor}->uiGetPublicKey($o->{accountToken}->actorHash, $o->{accountToken}->cliStore, $o->{cmd}->{keyPairToken});
}

sub onMessageBoxVerifyStore {
	my $o = shift;
	my $senderStoreUrl = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $senderHash = shift; die 'wrong type '.ref($senderHash).' for $senderHash' if defined $senderHash && ref $senderHash ne 'CDS::Hash';

	return $o->{cmd}->{actor}->storeForUrl($senderStoreUrl);
}

sub onMessageBoxEntry {
	my $o = shift;
	my $message = shift;

	$o->{countValid} += 1;
	$o->{cmd}->{countValid} += 1;

	my $ui = $o->{cmd}->{ui};
	my $sender = CDS::AccountToken->new($message->sender->store, $message->sender->publicKey->hash);

	$ui->space;
	$ui->title($message->source->hash->hex);
	$ui->line('from ', $o->{cmd}->{actor}->blueAccountReference($sender));
	$ui->line('for ', $o->{cmd}->{actor}->blueAccountReference($o->{accountToken}));
	$ui->space;
	$ui->recordChildren($message->content);
}

sub onMessageBoxInvalidEntry {
	my $o = shift;
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';
	my $reason = shift;

	$o->{countInvalid} += 1;
	$o->{cmd}->{countInvalid} += 1;

	my $ui = $o->{cmd}->{ui};
	my $hashHex = $source->hash->hex;
	my $storeReference = $o->{cmd}->{actor}->storeReference($o->{accountToken}->cliStore);

	$ui->space;
	$ui->title($hashHex);
	$ui->pOrange($reason);
	$ui->space;
	$ui->p('You may use the following commands to check out the envelope:');
	$ui->line($ui->gold('  cds open envelope ', $hashHex, ' on ', $storeReference));
	$ui->line($ui->gold('  cds show record ', $hashHex, ' on ', $storeReference));
	$ui->line($ui->gold('  cds show hashes and data of ', $hashHex, ' on ', $storeReference));
}

# BEGIN AUTOGENERATED
package CDS::Commands::ShowObject;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node005 = CDS::Parser::Node->new(1);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(1);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&show});
	$cds->addArrow($node000, 1, 0, 'show');
	$cds->addArrow($node001, 1, 0, 'show');
	$cds->addArrow($node003, 1, 0, 'show');
	$help->addArrow($node002, 1, 0, 'show');
	$node000->addArrow($node006, 1, 0, 'object', \&collectObject);
	$node001->addArrow($node006, 1, 0, 'record', \&collectRecord);
	$node002->addArrow($node004, 1, 0, 'bytes');
	$node002->addArrow($node004, 1, 0, 'data');
	$node002->addArrow($node004, 1, 0, 'hash');
	$node002->addArrow($node004, 1, 0, 'hashes');
	$node002->addArrow($node004, 1, 0, 'object');
	$node002->addArrow($node004, 1, 0, 'record');
	$node002->addArrow($node004, 1, 0, 'size');
	$node003->addArrow($node005, 1, 0, 'bytes', \&collectBytes);
	$node003->addArrow($node005, 1, 0, 'data', \&collectData);
	$node003->addArrow($node005, 1, 0, 'hash', \&collectHash);
	$node003->addArrow($node005, 1, 0, 'hashes', \&collectHashes);
	$node003->addArrow($node005, 1, 0, 'record', \&collectRecord);
	$node003->addArrow($node005, 1, 0, 'size', \&collectSize);
	$node005->addArrow($node003, 1, 0, 'and');
	$node005->addArrow($node006, 1, 0, 'of');
	$node006->addArrow($node007, 1, 0, 'HASH', \&collectHash1);
	$node006->addArrow($node010, 1, 1, 'FILE', \&collectFile);
	$node006->addArrow($node010, 1, 0, 'HASH', \&collectHash2);
	$node006->addArrow($node010, 1, 0, 'OBJECT', \&collectObject1);
	$node007->addArrow($node008, 1, 0, 'on');
	$node007->addArrow($node009, 0, 0, 'from');
	$node008->addArrow($node010, 1, 0, 'STORE', \&collectStore);
	$node009->addArrow($node010, 0, 0, 'STORE', \&collectStore);
	$node010->addArrow($node011, 1, 0, 'decrypted');
	$node010->addDefault($node013);
	$node011->addArrow($node012, 1, 0, 'with');
	$node012->addArrow($node013, 1, 0, 'AESKEY', \&collectAeskey);
}

sub collectAeskey {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{aesKey} = $value;
}

sub collectBytes {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showBytes} = 1;
}

sub collectData {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showData} = 1;
}

sub collectFile {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{file} = $value;
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showHash} = 1;
}

sub collectHash1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
}

sub collectHash2 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value;
	$o->{store} = $o->{actor}->preferredStore;
}

sub collectHashes {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showHashes} = 1;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showHashes} = 1;
	$o->{showData} = 1;
}

sub collectObject1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{hash} = $value->hash;
	$o->{store} = $value->cliStore;
}

sub collectRecord {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showRecord} = 1;
}

sub collectSize {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{showSize} = 1;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME show-object
# HTML TITLE Show objects
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show record OBJECT');
	$ui->command('cds show record HASH on STORE');
	$ui->p('Downloads an object, and shows the containing record. The stores are tried in the order they are indicated, until one succeeds. If the object is not found, or not a valid Condensation object, the program quits with exit code 1.');
	$ui->space;
	$ui->line('The following object properties can be displayed:');
	$ui->line('  cds show hash of …');
	$ui->line('  cds show size of …');
	$ui->line('  cds show bytes of …');
	$ui->line('  cds show hashes of …');
	$ui->line('  cds show data of …');
	$ui->line('  cds show record …');
	$ui->space;
	$ui->p('Multiple properties may be combined with "and", e.g.:');
	$ui->line('  cds show size and hashes and record of …');
	$ui->space;
	$ui->command('cds show record HASH');
	$ui->p('As above, but uses the selected store.');
	$ui->space;
	$ui->command('cds show record FILE');
	$ui->p('As above, but loads the object from FILE rather than from an object store.');
	$ui->space;
	$ui->command('… decrypted with AESKEY');
	$ui->p('Decrypts the object after retrieval.');
	$ui->space;
	$ui->command('cds show object …');
	$ui->p('A shortcut for "cds show hashes and data of …".');
	$ui->space;
	$ui->title('Related commands');
	$ui->line('cds get OBJECT [decrypted with AESKEY]');
	$ui->line('cds save [data of] OBJECT [decrypted with AESKEY] as FILE');
	$ui->line('cds open envelope OBJECT [on STORE] [using KEYPAIR]');
	$ui->line('cds show document OBJECT [on STORE]');
	$ui->space;
}

sub show {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	# Get and decrypt the object
	$o->{object} = defined $o->{file} ? $o->loadObjectFromFile : $o->loadObjectFromStore;
	return if ! $o->{object};
	$o->{object} = $o->{object}->crypt($o->{aesKey}) if defined $o->{aesKey};

	# Show the desired information
	$o->showHash if $o->{showHash};
	$o->showSize if $o->{showSize};
	$o->showBytes if $o->{showBytes};
	$o->showHashes if $o->{showHashes};
	$o->showData if $o->{showData};
	$o->showRecord if $o->{showRecord};
	$o->{ui}->space;
}

sub loadObjectFromFile {
	my $o = shift;

	my $bytes = CDS->readBytesFromFile($o->{file}) // return $o->{ui}->error('Unable to read "', $o->{file}, '".');
	return CDS::Object->fromBytes($bytes) // return $o->{ui}->error('"', $o->{file}, '" does not contain a valid Condensation object.');
}

sub loadObjectFromStore {
	my $o = shift;

	return $o->{actor}->uiGetObject($o->{hash}, $o->{store}, $o->{actor}->preferredKeyPairToken);
}

sub loadCommand {
	my $o = shift;

	my $decryption = defined $o->{aesKey} ? ' decrypted with '.unpack('H*', $o->{aesKey}) : '';
	return $o->{file}.$decryption if defined $o->{file};
	return $o->{hash}->hex.' on '.$o->{actor}->storeReference($o->{store}).$decryption;
}

sub showHash {
	my $o = shift;

	$o->{ui}->space;
	$o->{ui}->title('Object hash');
	$o->{ui}->line($o->{object}->calculateHash->hex);
}

sub showSize {
	my $o = shift;

	$o->{ui}->space;
	$o->{ui}->title('Object size');
	$o->{ui}->line($o->{ui}->niceFileSize(length $o->{object}->bytes), ' total (', length $o->{object}->bytes, ' bytes)');
	$o->{ui}->line($o->{object}->hashesCount, ' hashes (', length $o->{object}->header, ' bytes)');
	$o->{ui}->line($o->{ui}->niceFileSize(length $o->{object}->data), ' data (', length $o->{object}->data, ' bytes)');
}

sub showBytes {
	my $o = shift;

	$o->{ui}->space;
	my $bytes = $o->{object}->bytes;
	$o->{ui}->title('Object bytes (', $o->{ui}->niceFileSize(length $bytes), ')');
	return if ! length $bytes;

	my $hexDump = $o->{ui}->hexDump($bytes);
	my $dataStart = $hexDump->styleHashList(0);
	my $end = $dataStart ? $hexDump->styleRecord($dataStart) : 0;
	$hexDump->changeStyle({at => $end, style => $hexDump->reset});
	$hexDump->display;
}

sub showHashes {
	my $o = shift;

	$o->{ui}->space;
	my $hashesCount = $o->{object}->hashesCount;
	$o->{ui}->title($hashesCount == 1 ? '1 hash' : $hashesCount.' hashes');
	my $count = 0;
	for my $hash ($o->{object}->hashes) {
		$o->{ui}->line($o->{ui}->violet(unpack('H4', pack('S>', $count))), '  ', $hash->hex);
		$count += 1;
	}
}

sub showData {
	my $o = shift;

	$o->{ui}->space;
	my $data = $o->{object}->data;
	$o->{ui}->title('Data (', $o->{ui}->niceFileSize(length $data), ')');
	return if ! length $data;

	my $hexDump = $o->{ui}->hexDump($data);
	my $end = $hexDump->styleRecord(0);
	$hexDump->changeStyle({at => $end, style => $hexDump->reset});
	$hexDump->display;
}

sub showRecord {
	my $o = shift;

	# Title
	$o->{ui}->space;
	$o->{ui}->title('Data interpreted as record');

	# Empty object (empty record)
	return $o->{ui}->line($o->{ui}->gray('(empty record)')) if ! length $o->{object}->data;

	# Record
	my $record = CDS::Record->new;
	my $reader = CDS::RecordReader->new($o->{object});
	$reader->readChildren($record);
	if ($reader->hasError) {
		$o->{ui}->pRed('This is not a record.');
		$o->{ui}->space;
		$o->{ui}->p('You may use one of the following commands to check out the content:');
		$o->{ui}->line($o->{ui}->gold('  cds show object ', $o->loadCommand));
		$o->{ui}->line($o->{ui}->gold('  cds show data of ', $o->loadCommand));
		$o->{ui}->line($o->{ui}->gold('  cds save data of ', $o->loadCommand, ' as FILENAME'));
		return;
	}

	$o->{ui}->recordChildren($record, $o->{store} ? $o->{actor}->blueStoreReference($o->{store}) : '');

	# Trailer
	my $trailer = $reader->trailer;
	if (length $trailer) {
		$o->{ui}->space;
		$o->{ui}->pRed('This is probably not a record, because ', length $trailer, ' bytes remain behind the record. Use "cds show data of …" to investigate the raw object content. If this object is encrypted, provide the decryption key using "… and decrypted with KEY".');
		$o->{ui}->space;
	}
}

# BEGIN AUTOGENERATED
package CDS::Commands::ShowPrivateData;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node013 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showGroupData});
	my $node014 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showLocalData});
	my $node015 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showSentList});
	my $node016 = CDS::Parser::Node->new(0);
	my $node017 = CDS::Parser::Node->new(0);
	my $node018 = CDS::Parser::Node->new(0);
	my $node019 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showSentList});
	$cds->addArrow($node006, 1, 0, 'show');
	$cds->addArrow($node007, 1, 0, 'show');
	$cds->addArrow($node008, 1, 0, 'show');
	$help->addArrow($node000, 1, 0, 'show');
	$help->addArrow($node001, 1, 0, 'show');
	$help->addArrow($node002, 1, 0, 'show');
	$node000->addArrow($node003, 1, 0, 'group');
	$node001->addArrow($node004, 1, 0, 'local');
	$node002->addArrow($node005, 1, 0, 'sent');
	$node003->addArrow($node012, 1, 0, 'data');
	$node004->addArrow($node012, 1, 0, 'data');
	$node005->addArrow($node012, 1, 0, 'list');
	$node006->addArrow($node009, 1, 0, 'group');
	$node007->addArrow($node010, 1, 0, 'local');
	$node008->addArrow($node011, 1, 0, 'sent');
	$node009->addArrow($node013, 1, 0, 'data');
	$node010->addArrow($node014, 1, 0, 'data');
	$node011->addArrow($node015, 1, 0, 'list');
	$node015->addArrow($node016, 1, 0, 'ordered');
	$node016->addArrow($node017, 1, 0, 'by');
	$node017->addArrow($node018, 1, 0, 'envelope');
	$node017->addArrow($node019, 1, 0, 'date', \&collectDate);
	$node017->addArrow($node019, 1, 0, 'id', \&collectId);
	$node018->addArrow($node019, 1, 0, 'hash', \&collectHash);
}

sub collectDate {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{orderedBy} = 'date';
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{orderedBy} = 'envelope hash';
}

sub collectId {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{orderedBy} = 'id';
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME show-private-data
# HTML TITLE Show the private data
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show group data');
	$ui->p('Shows the group document. This document is shared among all group members.');
	$ui->space;
	$ui->command('cds show local data');
	$ui->p('Shows the local document. This document is stored locally, and private to this actor.');
	$ui->space;
	$ui->command('cds show sent list');
	$ui->p('Shows the list of sent messages with their expiry date, envelope hash, and content hash.');
	$ui->space;
	$ui->command('… ordered by id');
	$ui->command('… ordered by date');
	$ui->command('… ordered by envelope hash');
	$ui->p('Sorts the list accordingly. By default, the list is sorted by id.');
	$ui->space;
}

sub showGroupData {
	my $o = shift;
	my $cmd = shift;

	$o->{ui}->space;
	$o->{ui}->selector($o->{actor}->groupRoot, 'Group data');
	$o->{ui}->space;
}

sub showLocalData {
	my $o = shift;
	my $cmd = shift;

	$o->{ui}->space;
	$o->{ui}->selector($o->{actor}->localRoot, 'Local data');
	$o->{ui}->space;
}

sub showSentList {
	my $o = shift;
	my $cmd = shift;

	$o->{orderedBy} = 'id';
	$cmd->collect($o);

	$o->{ui}->space;
	$o->{ui}->title('Sent list');

	$o->{actor}->procureSentList // return;
	my $sentList = $o->{actor}->sentList;
	my @items = sort { $a->id cmp $b->id } values %{$sentList->{items}};
	@items = sort { $a->envelopeHashBytes cmp $b->envelopeHashBytes } @items if $o->{orderedBy} eq 'envelope hash';
	@items = sort { $a->validUntil <=> $b->validUntil } @items if $o->{orderedBy} eq 'date';
	my $noHash = '-' x 64;
	for my $item (@items) {
		my $id = $item->id;
		my $envelopeHash = $item->envelopeHash;
		my $message = $item->message;
		my $label = $o->{ui}->niceBytes($id, 32);
		$o->{ui}->line($o->{ui}->gray($o->{ui}->niceDateTimeLocal($item->validUntil)), ' ', $envelopeHash ? $envelopeHash->hex : $noHash, ' ', $o->{ui}->blue($label));
		$o->{ui}->recordChildren($message);
	}

	$o->{ui}->space;
}

# BEGIN AUTOGENERATED
package CDS::Commands::ShowTree;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&showTree});
	$cds->addArrow($node001, 1, 0, 'show');
	$cds->addArrow($node002, 0, 0, 'show');
	$help->addArrow($node000, 1, 0, 'show');
	$node000->addArrow($node003, 1, 0, 'tree');
	$node001->addArrow($node004, 1, 0, 'tree');
	$node002->addArrow($node004, 0, 0, 'trees');
	$node004->addDefault($node005);
	$node004->addDefault($node006);
	$node004->addDefault($node007);
	$node005->addArrow($node005, 1, 0, 'HASH', \&collectHash);
	$node005->addArrow($node010, 1, 0, 'HASH', \&collectHash);
	$node006->addArrow($node006, 1, 0, 'HASH', \&collectHash);
	$node006->addArrow($node008, 1, 0, 'HASH', \&collectHash);
	$node007->addArrow($node007, 1, 0, 'OBJECT', \&collectObject);
	$node007->addArrow($node010, 1, 0, 'OBJECT', \&collectObject);
	$node008->addArrow($node009, 1, 0, 'on');
	$node009->addArrow($node010, 1, 0, 'STORE', \&collectStore);
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{hashes}}, $value;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{objectTokens}}, $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME show-tree
# HTML TITLE Show trees
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds show tree OBJECT*');
	$ui->command('cds show tree HASH* on STORE');
	$ui->p('Downloads a tree, and shows the tree hierarchy. If an object has been traversed before, it is listed as "reported above".');
	$ui->space;
	$ui->command('cds show tree HASH*');
	$ui->p('As above, but uses the selected store.');
	$ui->space;
}

sub showTree {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken;
	$o->{objectTokens} = [];
	$o->{hashes} = [];
	$cmd->collect($o);

	# Process all trees
	for my $objectToken (@{$o->{objectTokens}}) {
		$o->{ui}->space;
		$o->process($objectToken->hash, $objectToken->cliStore);
	}

	if (scalar @{$o->{hashes}}) {
		my $store = $o->{store} // $o->{actor}->preferredStore;
		for my $hash (@{$o->{hashes}}) {
			$o->{ui}->space;
			$o->process($hash, $store);
		}
	}

	# Report the total size
	my $totalSize = 0;
	my $totalDataSize = 0;
	map { $totalSize += $_->{size} ; $totalDataSize += $_->{dataSize} } values %{$o->{objects}};
	$o->{ui}->space;
	$o->{ui}->p(scalar keys %{$o->{objects}}, ' unique objects ', $o->{ui}->bold($o->{ui}->niceFileSize($totalSize)), $o->{ui}->gray(' (', $o->{ui}->niceFileSize($totalSize - $totalDataSize), ' header and ', $o->{ui}->niceFileSize($totalDataSize), ' data)'));
	$o->{ui}->pRed(scalar keys %{$o->{missingObjects}}, ' or more objects are missing') if scalar keys %{$o->{missingObjects}};
	$o->{ui}->space;
}

sub process {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;

	my $hashHex = $hash->hex;

	# Check if we retrieved this object before
	if (exists $o->{objects}->{$hashHex}) {
		$o->{ui}->line($hash->hex, ' reported above') ;
		return 1;
	}

	# Retrieve the object
	my ($object, $storeError) = $store->get($hash, $o->{keyPairToken}->keyPair);
	return if defined $storeError;

	if (! $object) {
		$o->{missingObjects}->{$hashHex} = 1;
		return $o->{ui}->line($hashHex, ' ', $o->{ui}->red('is missing'));
	}

	# Display
	my $size = $object->byteLength;
	$o->{objects}->{$hashHex} = {size => $size, dataSize => length $object->data};
	$o->{ui}->line($hashHex, ' ', $o->{ui}->bold($o->{ui}->niceFileSize($size)), ' ', $o->{ui}->gray($object->hashesCount, ' hashes'));

	# Process all children
	$o->{ui}->pushIndent;
	foreach my $hash ($object->hashes) {
		$o->process($hash, $store) // return;
	}
	$o->{ui}->popIndent;
	return 1;
}

# BEGIN AUTOGENERATED
package CDS::Commands::StartHTTPServer;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(1);
	my $node010 = CDS::Parser::Node->new(0);
	my $node011 = CDS::Parser::Node->new(1);
	my $node012 = CDS::Parser::Node->new(0);
	my $node013 = CDS::Parser::Node->new(0);
	my $node014 = CDS::Parser::Node->new(0);
	my $node015 = CDS::Parser::Node->new(0);
	my $node016 = CDS::Parser::Node->new(1);
	my $node017 = CDS::Parser::Node->new(0);
	my $node018 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&startHttpServer});
	$cds->addArrow($node001, 1, 0, 'start');
	$help->addArrow($node000, 1, 0, 'http');
	$node000->addArrow($node005, 1, 0, 'server');
	$node001->addArrow($node002, 1, 0, 'http');
	$node002->addArrow($node003, 1, 0, 'server');
	$node003->addArrow($node004, 1, 0, 'for');
	$node004->addArrow($node006, 1, 0, 'STORE', \&collectStore);
	$node006->addArrow($node007, 1, 0, 'on');
	$node007->addArrow($node008, 1, 0, 'port');
	$node008->addArrow($node009, 1, 0, 'PORT', \&collectPort);
	$node009->addArrow($node010, 1, 0, 'at');
	$node009->addDefault($node011);
	$node010->addArrow($node011, 1, 0, 'TEXT', \&collectText);
	$node011->addArrow($node012, 1, 0, 'with');
	$node011->addDefault($node016);
	$node012->addArrow($node013, 1, 0, 'static');
	$node013->addArrow($node014, 1, 0, 'files');
	$node014->addArrow($node015, 1, 0, 'from');
	$node015->addArrow($node016, 1, 0, 'FOLDER', \&collectFolder);
	$node016->addArrow($node017, 1, 0, 'for');
	$node016->addDefault($node018);
	$node017->addArrow($node018, 1, 0, 'everybody', \&collectEverybody);
}

sub collectEverybody {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{corsAllowEverybody} = 1;
}

sub collectFolder {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{staticFolder} = $value;
}

sub collectPort {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{port} = $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub collectText {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{root} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME start-http-server
# HTML TITLE HTTP store server
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds start http server for STORE on port PORT');
	$ui->p('Starts a simple HTTP server listening on port PORT. The server handles requests within /objects and /accounts, and uses STORE as backend. Requests on the root URL (/) deliver a short message.');
	$ui->p('You may need superuser (root) privileges to use the default HTTP port 80.');
	$ui->p('This server is very useful for small to medium-size projects, but not particularly efficient for large-scale applications. It makes no effort to use DMA or similar features to speed up delivery, and handles only one request at a time (single-threaded). However, when using a front-end web server with load-balancing capabilities, multiple HTTP servers for the same store may be started to handle multiple requests in parallel.');
	$ui->space;
	$ui->command('… at TEXT');
	$ui->p('As above, but makes the store accessible at /TEXT/objects and /TEXT/accounts.');
	$ui->space;
	$ui->command('… with static files from FOLDER');
	$ui->p('Delivers static files from FOLDER for URLs outside of /objects and /accounts. This is useful for self-contained web apps.');
	$ui->space;
	$ui->command('… for everybody');
	$ui->p('Sets CORS headers to allow everybody to access the store from within a web browser.');
	$ui->space;
	$ui->p('For more options, write a Perl script instantiating and configuring a CDS::HTTPServer.');
	$ui->space;
}

sub startHttpServer {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	my $httpServer = CDS::HTTPServer->new($o->{port});
	$httpServer->setLogger(CDS::Commands::StartHTTPServer::Logger->new($o->{ui}));
	$httpServer->setCorsAllowEverybody($o->{corsAllowEverybody});
	$httpServer->addHandler(CDS::HTTPServer::StoreHandler->new($o->{root} // '/', $o->{store}));
	$httpServer->addHandler(CDS::HTTPServer::IdentificationHandler->new($o->{root} // '/')) if ! defined $o->{staticFolder};
	$httpServer->addHandler(CDS::HTTPServer::StaticFilesHandler->new('/', $o->{staticFolder}, 'index.html')) if defined $o->{staticFolder};
	eval { $httpServer->run; };
	if ($@) {
		my $error = $@;
		$error = $1 if $error =~ /^(.*?)( at |\n)/;
		$o->{ui}->space;
		$o->{ui}->p('Failed to run server on port '.$o->{port}.': '.$error);
		$o->{ui}->space;
	}
}

package CDS::Commands::StartHTTPServer::Logger;

sub new {
	my $class = shift;
	my $ui = shift;

	return bless {ui => $ui};
}

sub onServerStarts {
	my $o = shift;
	my $port = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->line($o->{ui}->gray($ui->niceDateTimeLocal), '  ', $ui->green('Server ready at http://localhost:', $port));
}

sub onRequestStarts {
	my $o = shift;
	my $request = shift;
	 }

sub onRequestError {
	my $o = shift;
	my $request = shift;

	my $ui = $o->{ui};
	$ui->line($o->{ui}->gray($ui->niceDateTimeLocal), '  ', $ui->blue($ui->left(15, $request->peerAddress)), '  ', $request->method, ' ', $request->path, '  ', $ui->red(@_));
}

sub onRequestDone {
	my $o = shift;
	my $request = shift;
	my $responseCode = shift;

	my $ui = $o->{ui};
	$ui->line($o->{ui}->gray($ui->niceDateTimeLocal), '  ', $ui->blue($ui->left(15, $request->peerAddress)), '  ', $request->method, ' ', $request->path, '  ', $ui->bold($responseCode));
}

# BEGIN AUTOGENERATED
package CDS::Commands::Transfer;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(0);
	my $node007 = CDS::Parser::Node->new(0);
	my $node008 = CDS::Parser::Node->new(0);
	my $node009 = CDS::Parser::Node->new(0);
	my $node010 = CDS::Parser::Node->new(1);
	my $node011 = CDS::Parser::Node->new(0);
	my $node012 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&transfer});
	$cds->addArrow($node000, 1, 0, 'thoroughly');
	$cds->addArrow($node001, 0, 0, 'leniently');
	$cds->addDefault($node003);
	$cds->addArrow($node003, 1, 0, 'leniently', \&collectLeniently);
	$cds->addArrow($node003, 1, 0, 'thoroughly', \&collectThoroughly);
	$help->addArrow($node002, 1, 0, 'transfer');
	$node000->addArrow($node003, 1, 0, 'leniently', \&collectLeniently1);
	$node001->addArrow($node003, 0, 0, 'thoroughly', \&collectLeniently1);
	$node003->addArrow($node004, 1, 0, 'transfer');
	$node004->addDefault($node005);
	$node004->addDefault($node006);
	$node004->addDefault($node007);
	$node005->addArrow($node005, 1, 0, 'HASH', \&collectHash);
	$node005->addArrow($node010, 1, 0, 'HASH', \&collectHash);
	$node006->addArrow($node006, 1, 0, 'OBJECT', \&collectObject);
	$node006->addArrow($node010, 1, 0, 'OBJECT', \&collectObject);
	$node007->addArrow($node007, 1, 0, 'HASH', \&collectHash);
	$node007->addArrow($node008, 1, 0, 'HASH', \&collectHash);
	$node008->addArrow($node009, 1, 0, 'from');
	$node009->addArrow($node010, 1, 0, 'STORE', \&collectStore);
	$node010->addArrow($node011, 1, 0, 'to');
	$node011->addArrow($node011, 1, 0, 'STORE', \&collectStore1);
	$node011->addArrow($node012, 1, 0, 'STORE', \&collectStore1);
}

sub collectHash {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{hashes}}, $value;
}

sub collectLeniently {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{leniently} = 1;
}

sub collectLeniently1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{leniently} = 1;
	$o->{thoroughly} = 1;
}

sub collectObject {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{objectTokens}}, $value;
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{fromStore} = $value;
}

sub collectStore1 {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	push @{$o->{toStores}}, $value;
}

sub collectThoroughly {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{thoroughly} = 1;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME transfer
# HTML TITLE Transfer
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds transfer OBJECT* to STORE*');
	$ui->command('cds transfer HASH* from STORE to STORE*');
	$ui->p('Copies a tree from one store to another.');
	$ui->space;
	$ui->command('cds transfer HASH* to STORE*');
	$ui->p('As above, but uses the selected store as source store.');
	$ui->space;
	$ui->command('cds ', $ui->underlined('leniently'), ' transfer …');
	$ui->p('Warns about missing objects, but ignores them and proceeds with the rest.');
	$ui->space;
	$ui->command('cds ', $ui->underlined('thoroughly'), ' transfer …');
	$ui->p('Check subtrees of objects existing at the destination. This may be used to fix missing objects on the destination store.');
	$ui->space;
}

sub transfer {
	my $o = shift;
	my $cmd = shift;

	$o->{keyPairToken} = $o->{actor}->preferredKeyPairToken;
	$o->{objectTokens} = [];
	$o->{hashes} = [];
	$o->{toStores} = [];
	$cmd->collect($o);

	# Use the selected store
	$o->{fromStore} = $o->{actor}->preferredStore if scalar @{$o->{hashes}} && ! $o->{fromStore};

	# Prepare the destination stores
	my $toStores = [];
	for my $toStore (@{$o->{toStores}}) {
		push @$toStores, {store => $toStore, storeError => undef, needed => [1]};
	}

	# Print the stores
	$o->{ui}->space;
	my $n = scalar @$toStores;
	for my $i (0 .. $n - 1) {
		my $toStore = $toStores->[$i];
		$o->{ui}->line($o->{ui}->gray(' │' x $i, ' ┌', '──' x ($n - $i), ' ', $toStore->{store}->url));
	}

	# Process all trees
	$o->{objects} = {};
	$o->{missingObjects} = {};
	for my $objectToken (@{$o->{objectTokens}}) {
		$o->{ui}->line($o->{ui}->gray(' │' x $n));
		$o->process($objectToken->hash, $objectToken->cliStore, $toStores, 1);
	}
	for my $hash (@{$o->{hashes}}) {
		$o->{ui}->line($o->{ui}->gray(' │' x $n));
		$o->process($hash, $o->{fromStore}, $toStores, 1);
	}

	# Print the stores again, with their errors
	$o->{ui}->line($o->{ui}->gray(' │' x $n));
	for my $i (reverse 0 .. $n - 1) {
		my $toStore = $toStores->[$i];
		$o->{ui}->line($o->{ui}->gray(' │' x $i, ' └', '──' x ($n - $i), ' ', $toStore->{store}->url), ' ', defined $toStore->{storeError} ? $o->{ui}->red($toStore->{storeError}) : '');
	}

	# Report the total size
	my $totalSize = 0;
	my $totalDataSize = 0;
	map { $totalSize += $_->{size} ; $totalDataSize += $_->{dataSize} } values %{$o->{objects}};
	$o->{ui}->space;
	$o->{ui}->p(scalar keys %{$o->{objects}}, ' unique objects ', $o->{ui}->bold($o->{ui}->niceFileSize($totalSize)), ' ', $o->{ui}->gray($o->{ui}->niceFileSize($totalDataSize), ' data'));
	$o->{ui}->pOrange(scalar keys %{$o->{missingObjects}}, ' or more objects are missing') if scalar keys %{$o->{missingObjects}};
	$o->{ui}->space;
}

sub process {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $fromStore = shift;
	my $toStores = shift;
	my $depth = shift;

	my $hashHex = $hash->hex;
	my $keyPair = $o->{keyPairToken}->keyPair;

	# Check if we retrieved this object before
	if (exists $o->{objects}->{$hashHex}) {
		$o->report($hash->hex, $toStores, $depth, $o->{ui}->green('copied before'));
		return 1;
	}

	# Try to book the object on all active stores
	my $countNeeded = 0;
	my $hasActiveStore = 0;
	for my $toStore (@$toStores) {
		next if defined $toStore->{storeError};
		$hasActiveStore = 1;
		next if ! $o->{thoroughly} && ! $toStore->{needed}->[$depth - 1];

		my ($found, $bookError) = $toStore->{store}->book($hash);
		if (defined $bookError) {
			$toStore->{storeError} = $bookError;
			next;
		}

		next if $found;
		$toStore->{needed}->[$depth] = 1;
		$countNeeded += 1;
	}

	# Return if all stores reported an error
	return if ! $hasActiveStore;

	# Ignore existing subtrees at the destination unless "thoroughly" is set
	if (! $o->{thoroughly} && ! $countNeeded) {
		$o->report($hashHex, $toStores, $depth, $o->{ui}->gray('skipping subtree'));
		return 1;
	}

	# Retrieve the object
	my ($object, $getError) = $fromStore->get($hash, $keyPair);
	return if defined $getError;

	if (! defined $object) {
		$o->{missingObjects}->{$hashHex} = 1;
		$o->report($hashHex, $toStores, $depth, $o->{ui}->orange('is missing'));
		return if ! $o->{leniently};
	}

	# Display
	my $size = $object->byteLength;
	$o->{objects}->{$hashHex} = {needed => $countNeeded, size => $size, dataSize => length $object->data};
	$o->report($hashHex, $toStores, $depth, $o->{ui}->bold($o->{ui}->niceFileSize($size)), ' ', $o->{ui}->gray($object->hashesCount, ' hashes'));

	# Process all children
	foreach my $hash ($object->hashes) {
		$o->process($hash, $fromStore, $toStores, $depth + 1) // return;
	}

	# Write the object to all active stores
	for my $toStore (@$toStores) {
		next if defined $toStore->{storeError};
		next if ! $toStore->{needed}->[$depth];
		my $putError = $toStore->{store}->put($hash, $object, $keyPair);
		$toStore->{storeError} = $putError if $putError;
	}

	return 1;
}

sub report {
	my $o = shift;
	my $hashHex = shift;
	my $toStores = shift;
	my $depth = shift;

	my @text;
	for my $toStore (@$toStores) {
		if ($toStore->{storeError}) {
			push @text, $o->{ui}->red(' ⨯');
		} elsif ($toStore->{needed}->[$depth]) {
			push @text, $o->{ui}->green(' +');
		} else {
			push @text, $o->{ui}->green(' ‒');
		}
	}

	push @text, ' ', '  ' x ($depth - 1), $hashHex;
	push @text, ' ', @_;
	$o->{ui}->line(@text);
}

# BEGIN AUTOGENERATED
package CDS::Commands::UseCache;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node004 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&useCache});
	my $node005 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&dropCache});
	my $node006 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&cache});
	$cds->addArrow($node000, 1, 0, 'use');
	$cds->addArrow($node002, 1, 0, 'drop');
	$cds->addArrow($node006, 1, 0, 'cache');
	$help->addArrow($node003, 1, 0, 'cache');
	$node000->addArrow($node001, 1, 0, 'cache');
	$node001->addArrow($node004, 1, 0, 'STORE', \&collectStore);
	$node002->addArrow($node005, 1, 0, 'cache');
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME use-cache
# HTML TITLE Using a cache store
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds use cache STORE');
	$ui->p('Uses STORE to cache objects, and speed up subsequent requests of the same object. This is particularly useful when working with (slow) remote stores. The cache store should be a fast store, such as a local folder store or an in-memory store.');
	$ui->p('Cached objects are not linked to any account, and may disappear with the next garbage collection. Most stores however keep objects for a least a few hours after their last use.');
	$ui->space;
	$ui->command('cds drop cache');
	$ui->p('Stops using the cache.');
	$ui->space;
	$ui->command('cds cache');
	$ui->p('Shows which cache store is used (if any).');
	$ui->space;
}

sub useCache {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	$o->{actor}->sessionRoot->child('use cache')->setText($o->{store}->url);
	$o->{actor}->saveOrShowError // return;
	$o->{ui}->pGreen('Using store "', $o->{store}->url, '" to cache objects.');
}

sub dropCache {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->sessionRoot->child('use cache')->clear;
	$o->{actor}->saveOrShowError // return;
	$o->{ui}->pGreen('Not using any cache any more.');
}

sub cache {
	my $o = shift;
	my $cmd = shift;

	my $storeUrl = $o->{actor}->sessionRoot->child('use cache')->textValue;
	return $o->{ui}->line('Not using any cache.') if ! length $storeUrl;
	return $o->{ui}->line('Using store "', $storeUrl, '" to cache objects.');
}

# BEGIN AUTOGENERATED
package CDS::Commands::UseStore;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node005 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&useStoreForMessaging});
	$cds->addArrow($node001, 1, 0, 'use');
	$help->addArrow($node000, 1, 0, 'messaging');
	$node000->addArrow($node004, 1, 0, 'store');
	$node001->addArrow($node002, 1, 0, 'STORE', \&collectStore);
	$node002->addArrow($node003, 1, 0, 'for');
	$node003->addArrow($node005, 1, 0, 'messaging');
}

sub collectStore {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{store} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME use-store
# HTML TITLE Set the messaging store
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds use STORE for messaging');
	$ui->p('Uses STORE to send and receive messages.');
	$ui->space;
}

sub useStoreForMessaging {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);

	$o->{actor}->{configuration}->setMessagingStoreUrl($o->{store}->url);
	$o->{ui}->pGreen('The messaging store is now ', $o->{store}->url);
}

# BEGIN AUTOGENERATED
package CDS::Commands::Welcome;

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(0);
	my $node004 = CDS::Parser::Node->new(0);
	my $node005 = CDS::Parser::Node->new(0);
	my $node006 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node007 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&suppress});
	my $node008 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&enable});
	my $node009 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&show});
	$cds->addArrow($node000, 1, 0, 'suppress');
	$cds->addArrow($node002, 1, 0, 'enable');
	$cds->addArrow($node004, 1, 0, 'show');
	$help->addArrow($node006, 1, 0, 'welcome');
	$node000->addArrow($node001, 1, 0, 'welcome');
	$node001->addArrow($node007, 1, 0, 'message');
	$node002->addArrow($node003, 1, 0, 'welcome');
	$node003->addArrow($node008, 1, 0, 'message');
	$node004->addArrow($node005, 1, 0, 'welcome');
	$node005->addArrow($node009, 1, 0, 'message');
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME welcome
# HTML TITLE Welcome message
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds suppress welcome message');
	$ui->p('Suppresses the welcome message when typing "cds".');
	$ui->space;
	$ui->command('cds enable welcome message');
	$ui->p('Enables the welcome message when typing "cds".');
	$ui->space;
	$ui->command('cds show welcome message');
	$ui->p('Shows the welcome message.');
	$ui->space;
}

sub suppress {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->localRoot->child('suppress welcome message')->setBoolean(1);
	$o->{actor}->saveOrShowError // return;

	$o->{ui}->space;
	$o->{ui}->p('The welcome message will not be shown any more.');
	$o->{ui}->space;
	$o->{ui}->line('You can manually display the message by typing:');
	$o->{ui}->line($o->{ui}->blue('  cds show welcome message'));
	$o->{ui}->line('or re-enable it using:');
	$o->{ui}->line($o->{ui}->blue('  cds enable welcome message'));
	$o->{ui}->space;
}

sub enable {
	my $o = shift;
	my $cmd = shift;

	$o->{actor}->localRoot->child('suppress welcome message')->clear;
	$o->{actor}->saveOrShowError // return;

	$o->{ui}->space;
	$o->{ui}->p('The welcome message will be shown when you type "cds".');
	$o->{ui}->space;
}

sub isEnabled {
	my $o = shift;
	 ! $o->{actor}->localRoot->child('suppress welcome message')->isSet }

sub show {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->title('Hi there!');
	$ui->p('This is the command line interface (CLI) of Condensation ', $CDS::VERSION, ', ', $CDS::releaseDate, '. Condensation is a distributed data system with conflict-free forward merging and end-to-end security. More information is available on https://condensation.io.');
	$ui->space;
	$ui->p('Commands resemble short english sentences. For example, the following "sentence" will show the record of an object:');
	$ui->line($ui->blue('  cds show record e5cbfc282e1f3e6fd0f3e5fffd41964c645f44d7fae8ef5cb350c2dfd2196c9f \\'));
	$ui->line($ui->blue('            from http://examples.condensation.io'));
	$ui->p('Type a "?" to explore possible commands, e.g.');
	$ui->line($ui->blue('  cds show ?'));
	$ui->p('or use TAB or TAB-TAB for command completion.');
	$ui->space;
	$ui->p('To get help, type');
	$ui->line($ui->blue('  cds help'));
	$ui->space;
	$ui->p('To suppress this welcome message, type');
	$ui->line($ui->blue('  cds suppress welcome message'));
	$ui->space;
}

package CDS::Commands::WhatIs;

# BEGIN AUTOGENERATED

sub register {
	my $class = shift;
	my $cds = shift;
	my $help = shift;

	my $node000 = CDS::Parser::Node->new(0);
	my $node001 = CDS::Parser::Node->new(0);
	my $node002 = CDS::Parser::Node->new(0);
	my $node003 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&help});
	my $node004 = CDS::Parser::Node->new(1, {constructor => \&new, function => \&whatIs});
	$cds->addArrow($node001, 1, 0, 'what');
	$help->addArrow($node000, 1, 0, 'what');
	$node000->addArrow($node003, 1, 0, 'is');
	$node001->addArrow($node002, 1, 0, 'is');
	$node002->addArrow($node004, 1, 0, 'TEXT', \&collectText);
}

sub collectText {
	my $o = shift;
	my $label = shift;
	my $value = shift;

	$o->{text} = $value;
}

sub new {
	my $class = shift;
	my $actor = shift;
	 bless {actor => $actor, ui => $actor->ui} }

# END AUTOGENERATED

# HTML FOLDER NAME what-is
# HTML TITLE What is
sub help {
	my $o = shift;
	my $cmd = shift;

	my $ui = $o->{ui};
	$ui->space;
	$ui->command('cds what is TEXT');
	$ui->p('Tells what TEXT could be under the current configuration.');
	$ui->space;
}

sub whatIs {
	my $o = shift;
	my $cmd = shift;

	$cmd->collect($o);
	$o->{butNot} = [];

	$o->{ui}->space;
	$o->{ui}->title($o->{ui}->blue($o->{text}), ' may be …');

	$o->test('ACCOUNT', 'an ACCOUNT', sub { shift->url });
	$o->test('AESKEY', 'an AESKEY', sub { unpack('H*', shift) });
	$o->test('BOX', 'a BOX', sub { shift->url });
	$o->test('BOXLABEL', 'a BOXLABEL', sub { shift });
	$o->test('FILE', 'a FILE', \&fileResult);
	$o->test('FILENAME', 'a FILENAME', \&fileResult);
	$o->test('FOLDER', 'a FOLDER', \&fileResult);
	$o->test('GROUP', 'a GROUP on this system', sub { shift });
	$o->test('HASH', 'a HASH or ACTOR hash', sub { shift->hex });
	$o->test('KEYPAIR', 'a KEYPAIR', \&keyPairResult);
	$o->test('LABEL', 'a remembered LABEL', sub { shift });
	$o->test('OBJECT', 'an OBJECT', sub { shift->url });
	$o->test('OBJECTFILE', 'an OBJECTFILE', \&objectFileResult);
	$o->test('STORE', 'a STORE', sub { shift->url });
	$o->test('USER', 'a USER on this system', sub { shift });

	for my $butNot (@{$o->{butNot}}) {
		$o->{ui}->space;
		$o->{ui}->line('… but not ', $butNot->{text}, ', because:');
		for my $warning (@{$butNot->{warnings}}) {
			$o->{ui}->warning($warning);
		}
	}

	$o->{ui}->space;
}

sub test {
	my $o = shift;
	my $expect = shift;
	my $text = shift;
	my $resultHandler = shift;

	my $token = CDS::Parser::Token->new($o->{actor}, $o->{text});
	my $result = $token->produce($expect);
	if (defined $result) {
		my $whichOne = &$resultHandler($result);
		$o->{ui}->line('… ', $text, '  ', $o->{ui}->gray($whichOne));
	} elsif (scalar @{$token->{warnings}}) {
		push @{$o->{butNot}}, {text => $text, warnings => $token->{warnings}};
	}
}

sub keyPairResult {
	my $keyPairToken = shift;

	return $keyPairToken->file.' ('.$keyPairToken->keyPair->publicKey->hash->hex.')';
}

sub objectFileResult {
	my $objectFileToken = shift;

	return $objectFileToken->file if $objectFileToken->object->byteLength > 1024 * 1024;
	return $objectFileToken->file.' ('.$objectFileToken->object->calculateHash->hex.')';
}

sub fileResult {
	my $file = shift;

	my @s = stat $file;
	my $label =
		! scalar @s ? ' (non-existing)' :
		Fcntl::S_ISDIR($s[2]) ? ' (folder)' :
		Fcntl::S_ISREG($s[2]) ? ' (file, '.$s[7].' bytes)' :
		Fcntl::S_ISLNK($s[2]) ? ' (symbolic link)' :
		Fcntl::S_ISBLK($s[2]) ? ' (block device)' :
		Fcntl::S_ISCHR($s[2]) ? ' (char device)' :
		Fcntl::S_ISSOCK($s[2]) ? ' (socket)' :
		Fcntl::S_ISFIFO($s[2]) ? ' (pipe)' : ' (unknown type)';

	return $file.$label;
}

package CDS::Configuration;

our $xdgConfigurationFolder = ($ENV{XDG_CONFIG_HOME} || $ENV{HOME}.'/.config').'/condensation';
our $xdgDataFolder = ($ENV{XDG_DATA_HOME} || $ENV{HOME}.'/.local/share').'/condensation';

sub getOrCreateDefault {
	my $class = shift;
	my $ui = shift;

	my $configuration = $class->new($ui, $xdgConfigurationFolder, $xdgDataFolder);
	$configuration->createIfNecessary();
	return $configuration;
}

sub new {
	my $class = shift;
	my $ui = shift;
	my $folder = shift;
	my $defaultStoreFolder = shift;

	return bless {ui => $ui, folder => $folder, defaultStoreFolder => $defaultStoreFolder};
}

sub ui { shift->{ui} }
sub folder { shift->{folder} }

sub createIfNecessary {
	my $o = shift;

	my $keyPairFile = $o->{folder}.'/key-pair';
	return 1 if -f $keyPairFile;

	$o->{ui}->progress('Creating configuration folders …');
	$o->createFolder($o->{folder}) // return $o->{ui}->error('Failed to create the folder "', $o->{folder}, '".');
	$o->createFolder($o->{defaultStoreFolder}) // return $o->{ui}->error('Failed to create the folder "', $o->{defaultStoreFolder}, '".');
	CDS::FolderStore->new($o->{defaultStoreFolder})->createIfNecessary;

	$o->{ui}->progress('Generating key pair …');
	my $keyPair = CDS::KeyPair->generate;
	$keyPair->writeToFile($keyPairFile) // return $o->{ui}->error('Failed to write the configuration file "', $keyPairFile, '". Make sure that this location is writable.');
	$o->{ui}->removeProgress;
	return 1;
}

sub createFolder {
	my $o = shift;
	my $folder = shift;

	for my $path (CDS->intermediateFolders($folder)) {
		mkdir $path;
	}

	return -d $folder;
}

sub file {
	my $o = shift;
	my $filename = shift;

	return $o->{folder}.'/'.$filename;
}

sub messagingStoreUrl {
	my $o = shift;

	return $o->readFirstLine('messaging-store') // 'file://'.$o->{defaultStoreFolder};
}

sub storageStoreUrl {
	my $o = shift;

	return $o->readFirstLine('store') // 'file://'.$o->{defaultStoreFolder};
}

sub setMessagingStoreUrl {
	my $o = shift;
	my $storeUrl = shift;

	CDS->writeTextToFile($o->file('messaging-store'), $storeUrl);
}

sub setStorageStoreUrl {
	my $o = shift;
	my $storeUrl = shift;

	CDS->writeTextToFile($o->file('store'), $storeUrl);
}

sub keyPair {
	my $o = shift;

	return CDS::KeyPair->fromFile($o->file('key-pair'));
}

sub setKeyPair {
	my $o = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$keyPair->writeToFile($o->file('key-pair'));
}

sub readFirstLine {
	my $o = shift;
	my $file = shift;

	my $content = CDS->readTextFromFile($o->file($file)) // return;
	$content = $1 if $content =~ /^(.*)\n/;
	$content = $1 if $content =~ /^\s*(.*?)\s*$/;
	return $content;
}

package CDS::DetachedDocument;

use parent -norequire, 'CDS::Document';

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $class->SUPER::new($keyPair, CDS::InMemoryStore->create);
}

sub savingDone {
	my $o = shift;
	my $revision = shift;
	my $newPart = shift;
	my $obsoleteParts = shift;

	# We don't do anything
	$o->{unsaved}->savingDone;
}

package CDS::DiscoverActorGroup;

sub discover {
	my $class = shift;
	my $builder = shift; die 'wrong type '.ref($builder).' for $builder' if defined $builder && ref $builder ne 'CDS::ActorGroupBuilder';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $delegate = shift;

	my $o = bless {
		knownPublicKeys => $builder->knownPublicKeys,	# A hashref of known public keys (e.g. from the existing actor group)
		keyPair => $keyPair,
		delegate => $delegate,							# The delegate
		nodesByUrl => {},								# Nodes on which this actor group is active, by URL
		coverage => {},									# Hashes that belong to this actor group
		};

	# Add all active members
	for my $member ($builder->members) {
		next if $member->status ne 'active';
		my $node = $o->node($member->hash, $member->storeUrl);
		if ($node->{revision} < $member->revision) {
			$node->{revision} = $member->revision;
			$node->{status} = 'active';
		}

		$o->{coverage}->{$member->hash->bytes} = 1;
	}

	# Determine the revision at start
	my $revisionAtStart = 0;
	for my $node (values %{$o->{nodesByUrl}}) {
		$revisionAtStart = $node->{revision} if $revisionAtStart < $node->{revision};
	}

	# Reload the cards of all known accounts
	for my $node (values %{$o->{nodesByUrl}}) {
		$node->discover;
	}

	# From here, try extending to other accounts
	while ($o->extend) {}

	# Compile the list of actors and cards
	my @members;
	my @cards;
	for my $node (values %{$o->{nodesByUrl}}) {
		next if ! $node->{reachable};
		next if ! $node->{attachedToUs};
		next if ! $node->{actorOnStore};
		next if ! $node->isActiveOrIdle;
		#-- member ++ $node->{actorHash}->hex ++ $node->{cardsRead} ++ $node->{cards} // 'undef' ++ $node->{actorOnStore} // 'undef'
		push @members, CDS::ActorGroup::Member->new($node->{actorOnStore}, $node->{storeUrl}, $node->{revision}, $node->isActive);
		push @cards, @{$node->{cards}};
	}

	# Get the newest list of entrusted actors
	my $parser = CDS::ActorGroupBuilder->new;
	for my $card (@cards) {
		$parser->parseEntrustedActors($card->card->child('entrusted actors'), 0);
	}

	# Get the entrusted actors
	my $entrustedActors = [];
	for my $actor ($parser->entrustedActors) {
		my $store = $o->{delegate}->onDiscoverActorGroupVerifyStore($actor->storeUrl);
		next if ! $store;

		my $knownPublicKey = $o->{knownPublicKeys}->{$actor->hash->bytes};
		if ($knownPublicKey) {
			push @$entrustedActors, CDS::ActorGroup::EntrustedActor->new(CDS::ActorOnStore->new($knownPublicKey, $store), $actor->storeUrl);
			next;
		}

		my ($publicKey, $invalidReason, $storeError) = $keyPair->getPublicKey($actor->hash, $store);

		if (defined $invalidReason) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidPublicKey($actor->hash, $store, $invalidReason);
			next;
		}

		if (defined $storeError) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupStoreError($store, $storeError);
			next;
		}

		push @$entrustedActors, CDS::ActorGroup::EntrustedActor->new(CDS::ActorOnStore->new($publicKey, $store), $actor->storeUrl);
	}

	my $members = [sort { $b->{revision} <=> $a->{revision} || $b->{status} cmp $a->{status} } @members];
	return CDS::ActorGroup->new($members, $parser->entrustedActorsRevision, $entrustedActors), [@cards], [grep { $_->{attachedToUs} } values %{$o->{nodesByUrl}}];
}

sub node {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';
	my $storeUrl = shift;
		# private
	my $url = $storeUrl.'/accounts/'.$actorHash->hex;
	my $node = $o->{nodesByUrl}->{$url};
	return $node if $node;
	return $o->{nodesByUrl}->{$url} = CDS::DiscoverActorGroup::Node->new($o, $actorHash, $storeUrl);
}

sub covers {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->{coverage}->{$hash->bytes} }

sub extend {
	my $o = shift;

	# Start with the newest node
	my $mainNode;
	my $mainRevision = -1;
	for my $node (values %{$o->{nodesByUrl}}) {
		next if ! $node->{attachedToUs};
		next if $node->{revision} <= $mainRevision;
		$mainNode = $node;
		$mainRevision = $node->{revision};
	}

	return 0 if ! $mainNode;

	# Reset the reachable flag
	for my $node (values %{$o->{nodesByUrl}}) {
		$node->{reachable} = 0;
	}
	$mainNode->{reachable} = 1;

	# Traverse the graph along active links to find accounts to discover.
	my @toDiscover;
	my @toCheck = ($mainNode);
	while (1) {
		my $currentNode = shift(@toCheck) // last;
		for my $link (@{$currentNode->{links}}) {
			my $node = $link->{node};
			next if $node->{reachable};
			my $prospectiveStatus = $link->{revision} > $node->{revision} ? $link->{status} : $node->{status};
			next if $prospectiveStatus ne 'active';
			$node->{reachable} = 1;
			push @toCheck, $node if $node->{attachedToUs};
			push @toDiscover, $node if ! $node->{attachedToUs};
		}
	}

	# Discover these accounts
	my $hasChanges = 0;
	for my $node (sort { $b->{revision} <=> $a->{revision} } @toDiscover) {
		$node->discover;
		next if ! $node->{attachedToUs};
		$hasChanges = 1;
	}

	return $hasChanges;
}

package CDS::DiscoverActorGroup::Card;

sub new {
	my $class = shift;
	my $storeUrl = shift;
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $envelopeHash = shift; die 'wrong type '.ref($envelopeHash).' for $envelopeHash' if defined $envelopeHash && ref $envelopeHash ne 'CDS::Hash';
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $cardHash = shift; die 'wrong type '.ref($cardHash).' for $cardHash' if defined $cardHash && ref $cardHash ne 'CDS::Hash';
	my $card = shift;

	return bless {
		storeUrl => $storeUrl,
		actorOnStore => $actorOnStore,
		envelopeHash => $envelopeHash,
		envelope => $envelope,
		cardHash => $cardHash,
		card => $card,
		};
}

sub storeUrl { shift->{storeUrl} }
sub actorOnStore { shift->{actorOnStore} }
sub envelopeHash { shift->{envelopeHash} }
sub envelope { shift->{envelope} }
sub cardHash { shift->{cardHash} }
sub card { shift->{card} }

package CDS::DiscoverActorGroup::Link;

sub new {
	my $class = shift;
	my $node = shift;
	my $revision = shift;
	my $status = shift;

	bless {
		node => $node,
		revision => $revision,
		status => $status,
		};
}

sub node { shift->{node} }
sub revision { shift->{revision} }
sub status { shift->{status} }

package CDS::DiscoverActorGroup::Node;

sub new {
	my $class = shift;
	my $discoverer = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';
	my $storeUrl = shift;

	return bless {
		discoverer => $discoverer,
		actorHash => $actorHash,
		storeUrl => $storeUrl,
		revision => -1,
		status => 'idle',
		reachable => 0,				# whether this node is reachable from the main node
		store => undef,
		actorOnStore => undef,
		links => [],				# all links found in the cards
		attachedToUs => 0,			# whether the account belongs to us
		cardsRead => 0,
		cards => [],
		};
}

sub cards {
	my $o = shift;
	 @{$o->{cards}} }
sub isActive {
	my $o = shift;
	 $o->{status} eq 'active' }
sub isActiveOrIdle {
	my $o = shift;
	 $o->{status} eq 'active' || $o->{status} eq 'idle' }

sub actorHash { shift->{actorHash} }
sub storeUrl { shift->{storeUrl} }
sub revision { shift->{revision} }
sub status { shift->{status} }
sub attachedToUs { shift->{attachedToUs} }
sub links {
	my $o = shift;
	 @{$o->{links}} }

sub discover {
	my $o = shift;

	#-- discover ++ $o->{actorHash}->hex
	$o->readCards;
	$o->attach;
}

sub readCards {
	my $o = shift;

	return if $o->{cardsRead};
	$o->{cardsRead} = 1;
	#-- read cards of ++ $o->{actorHash}->hex

	# Get the store
	my $store = $o->{discoverer}->{delegate}->onDiscoverActorGroupVerifyStore($o->{storeUrl}, $o->{actorHash}) // return;

	# Get the public key if necessary
	if (! $o->{actorOnStore}) {
		my $publicKey = $o->{discoverer}->{knownPublicKeys}->{$o->{actorHash}->bytes};
		if (! $publicKey) {
			my ($downloadedPublicKey, $invalidReason, $storeError) = $o->{discoverer}->{keyPair}->getPublicKey($o->{actorHash}, $store);
			return $o->{discoverer}->{delegate}->onDiscoverActorGroupStoreError($store, $storeError) if defined $storeError;
			return $o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidPublicKey($o->{actorHash}, $store, $invalidReason) if defined $invalidReason;
			$publicKey = $downloadedPublicKey;
		}

		$o->{actorOnStore} = CDS::ActorOnStore->new($publicKey, $store);
	}

	# List the public box
	my ($hashes, $storeError) = $store->list($o->{actorHash}, 'public', 0, $o->{discoverer}->{keyPair});
	return $o->{discoverer}->{delegate}->onDiscoverActorGroupStoreError($store, $storeError) if defined $storeError;

	for my $envelopeHash (@$hashes) {
		# Open the envelope
		my ($object, $storeError) = $store->get($envelopeHash, $o->{discoverer}->{keyPair});
		return $o->{discoverer}->{delegate}->onDiscoverActorGroupStoreError($store, $storeError) if defined $storeError;
		if (! $object) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidCard($o->{actorOnStore}, $envelopeHash, 'Envelope object not found.');
			next;
		}

		my $envelope = CDS::Record->fromObject($object);
		if (! $envelope) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidCard($o->{actorOnStore}, $envelopeHash, 'Envelope is not a record.');
			next;
		}

		my $cardHash = $envelope->child('content')->hashValue;
		if (! $cardHash) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidCard($o->{actorOnStore}, $envelopeHash, 'Missing content hash.');
			next;
		}

		if (! CDS->verifyEnvelopeSignature($envelope, $o->{actorOnStore}->publicKey, $cardHash)) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidCard($o->{actorOnStore}, $envelopeHash, 'Invalid signature.');
			next;
		}

		# Read the card
		my ($cardObject, $storeError1) = $store->get($cardHash, $o->{discoverer}->{keyPair});
		return $o->{discoverer}->{delegate}->onDiscoverActorGroupStoreError($store, $storeError) if defined $storeError1;
		if (! $cardObject) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidCard($o->{actorOnStore}, $envelopeHash, 'Card object not found.');
			next;
		}

		my $card = CDS::Record->fromObject($cardObject);
		if (! $card) {
			$o->{discoverer}->{delegate}->onDiscoverActorGroupInvalidCard($o->{actorOnStore}, $envelopeHash, 'Card is not a record.');
			next;
		}

		# Add the card to the list of cards
		push @{$o->{cards}}, CDS::DiscoverActorGroup::Card->new($o->{storeUrl}, $o->{actorOnStore}, $envelopeHash, $envelope, $cardHash, $card);

		# Parse the account list
		my $builder = CDS::ActorGroupBuilder->new;
		$builder->parseMembers($card->child('actor group'), 0);
		for my $member ($builder->members) {
			my $node = $o->{discoverer}->node($member->hash, $member->storeUrl);
			#-- new link ++ $o->{actorHash}->hex ++ $status ++ $hash->hex
			push @{$o->{links}}, CDS::DiscoverActorGroup::Link->new($node, $member->revision, $member->status);
		}
	}
}

sub attach {
	my $o = shift;

	return if $o->{attachedToUs};
	return if ! $o->hasLinkToUs;

	# Attach this node
	$o->{attachedToUs} = 1;

	# Merge all links
	for my $link (@{$o->{links}}) {
		$link->{node}->merge($link->{revision}, $link->{status});
	}

	# Add the hash to the coverage
	$o->{discoverer}->{coverage}->{$o->{actorHash}->bytes} = 1;
}

sub merge {
	my $o = shift;
	my $revision = shift;
	my $status = shift;

	return if $o->{revision} >= $revision;
	$o->{revision} = $revision;
	$o->{status} = $status;
}

sub hasLinkToUs {
	my $o = shift;

	return 1 if $o->{discoverer}->covers($o->{actorHash});
	for my $link (@{$o->{links}}) {
		return 1 if $o->{discoverer}->covers($link->{node}->{actorHash});
	}
	return;
}

package CDS::Document;

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $store = shift;

	my $o = bless {
		keyPair => $keyPair,
		unsaved => CDS::Unsaved->new($store),
		itemsBySelector => {},
		parts => {},
		hasPartsToMerge => 0,
		}, $class;

	$o->{root} = CDS::Selector->root($o);
	$o->{changes} = CDS::Document::Part->new;
	return $o;
}

sub keyPair { shift->{keyPair} }
sub unsaved { shift->{unsaved} }
sub parts {
	my $o = shift;
	 values %{$o->{parts}} }
sub hasPartsToMerge { shift->{hasPartsToMerge} }

### Items

sub root { shift->{root} }
sub rootItem {
	my $o = shift;
	 $o->getOrCreate($o->{root}) }

sub get {
	my $o = shift;
	my $selector = shift; die 'wrong type '.ref($selector).' for $selector' if defined $selector && ref $selector ne 'CDS::Selector';
	 $o->{itemsBySelector}->{$selector->{id}} }

sub getOrCreate {
	my $o = shift;
	my $selector = shift; die 'wrong type '.ref($selector).' for $selector' if defined $selector && ref $selector ne 'CDS::Selector';

	my $item = $o->{itemsBySelector}->{$selector->{id}};
	$o->{itemsBySelector}->{$selector->{id}} = $item = CDS::Document::Item->new($selector) if ! $item;
	return $item;
}

sub prune {
	my $o = shift;
	 $o->rootItem->pruneTree; }

### Merging

sub merge {
	my $o = shift;

	for my $hashAndKey (@_) {
		next if ! $hashAndKey;
		next if $o->{parts}->{$hashAndKey->hash->bytes};
		my $part = CDS::Document::Part->new;
		$part->{hashAndKey} = $hashAndKey;
		$o->{parts}->{$hashAndKey->hash->bytes} = $part;
		$o->{hasPartsToMerge} = 1;
	}
}

sub read {
	my $o = shift;

	return 1 if ! $o->{hasPartsToMerge};

	# Load the parts
	for my $part (values %{$o->{parts}}) {
		next if $part->{isMerged};
		next if $part->{loadedRecord};

		my ($record, $object, $invalidReason, $storeError) = $o->{keyPair}->getAndDecryptRecord($part->{hashAndKey}, $o->{unsaved});
		return if defined $storeError;

		delete $o->{parts}->{$part->{hashAndKey}->hash->bytes} if defined $invalidReason;
		$part->{loadedRecord} = $record;
	}

	# Merge the loaded parts
	for my $part (values %{$o->{parts}}) {
		next if $part->{isMerged};
		next if ! $part->{loadedRecord};
		my $oldFormat = $part->{loadedRecord}->child('client')->textValue =~ /0.19/ ? 1 : 0;
		$o->mergeNode($part, $o->{root}, $part->{loadedRecord}->child('root'), $oldFormat);
		delete $part->{loadedRecord};
		$part->{isMerged} = 1;
	}

	$o->{hasPartsToMerge} = 0;
	return 1;
}

sub mergeNode {
	my $o = shift;
	my $part = shift;
	my $selector = shift; die 'wrong type '.ref($selector).' for $selector' if defined $selector && ref $selector ne 'CDS::Selector';
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $oldFormat = shift;

	# Prepare
	my @children = $record->children;
	return if ! scalar @children;
	my $item = $o->getOrCreate($selector);

	# Merge value
	my $valueRecord = shift @children;
	$valueRecord = $valueRecord->firstChild if $oldFormat;
	$item->mergeValue($part, $valueRecord->asInteger, $valueRecord);

	# Merge children
	for my $child (@children) { $o->mergeNode($part, $selector->child($child->bytes), $child, $oldFormat); }
}

# *** Saving
# Call $document->save at any time to save the current state (if necessary).

# This is called by the items whenever some data changes.
sub dataChanged {
	my $o = shift;
	 }

sub save {
	my $o = shift;

	$o->{unsaved}->startSaving;
	my $revision = CDS->now;
	my $newPart = undef;

	#-- saving ++ $o->{changes}->{count}
	if ($o->{changes}->{count}) {
		# Take the changes
		$newPart = $o->{changes};
		$o->{changes} = CDS::Document::Part->new;

		# Select all parts smaller than 2 * changes
		$newPart->{selected} = 1;
		my $count = $newPart->{count};
		while (1) {
			my $addedPart = 0;
			for my $part (values %{$o->{parts}}) {
				#-- candidate ++ $part->{count} ++ $count
				next if ! $part->{isMerged} || $part->{selected} || $part->{count} >= $count * 2;
				$count += $part->{count};
				$part->{selected} = 1;
				$addedPart = 1;
			}

			last if ! $addedPart;
		}

		# Include the selected items
		for my $item (values %{$o->{itemsBySelector}}) {
			next if ! $item->{part}->{selected};
			$item->setPart($newPart);
			$item->createSaveRecord;
		}

		my $record = CDS::Record->new;
		$record->add('created')->addInteger($revision);
		$record->add('client')->add(CDS->version);
		$record->addRecord($o->rootItem->createSaveRecord);

		# Detach the save records
		for my $item (values %{$o->{itemsBySelector}}) {
			$item->detachSaveRecord;
		}

		# Serialize and encrypt the record
		my $key = CDS->randomKey;
		my $newObject = $record->toObject->crypt($key);
		$newPart->{hashAndKey} = CDS::HashAndKey->new($newObject->calculateHash, $key);
		$newPart->{isMerged} = 1;
		$newPart->{selected} = 0;
		$o->{parts}->{$newPart->{hashAndKey}->hash->bytes} = $newPart;
		#-- added ++ $o->{parts} ++ scalar keys %{$o->{parts}} ++ $newPart->{count}
		$o->{unsaved}->{savingState}->addObject($newPart->{hashAndKey}->hash, $newObject);
	}

	# Remove obsolete parts
	my $obsoleteParts = [];
	for my $part (values %{$o->{parts}}) {
		next if ! $part->{isMerged};
		next if $part->{count};
		push @$obsoleteParts, $part;
		delete $o->{parts}->{$part->{hashAndKey}->hash->bytes};
	}

	# Commit
	#-- saving done ++ $revision ++ $newPart ++ $obsoleteParts
	return $o->savingDone($revision, $newPart, $obsoleteParts);
}

package CDS::Document::Item;

sub new {
	my $class = shift;
	my $selector = shift; die 'wrong type '.ref($selector).' for $selector' if defined $selector && ref $selector ne 'CDS::Selector';

	my $parentSelector = $selector->parent;
	my $parent = $parentSelector ? $selector->document->getOrCreate($parentSelector) : undef;

	my $o = bless {
		document => $selector->document,
		selector => $selector,
		parent => $parent,
		children => [],
		part => undef,
		revision => 0,
		record => CDS::Record->new
		};

	push @{$parent->{children}}, $o if $parent;
	return $o;
}

sub pruneTree {
	my $o = shift;

	# Try to remove children
	for my $child (@{$o->{children}}) { $child->pruneTree; }

	# Don't remove the root item
	return if ! $o->{parent};

	# Don't remove if the item has children, or a value
	return if scalar @{$o->{children}};
	return if $o->{revision} > 0;

	# Remove this from the tree
	$o->{parent}->{children} = [grep { $_ != $o } @{$o->{parent}->{children}}];

	# Remove this from the document hash
	delete $o->{document}->{itemsBySelector}->{$o->{selector}->{id}};
}

# Low-level part change.
sub setPart {
	my $o = shift;
	my $part = shift;

	$o->{part}->{count} -= 1 if $o->{part};
	$o->{part} = $part;
	$o->{part}->{count} += 1 if $o->{part};
}

# Merge a value

sub mergeValue {
	my $o = shift;
	my $part = shift;
	my $revision = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	return if $revision <= 0;
	return if $revision < $o->{revision};
	return if $revision == $o->{revision} && $part->{size} < $o->{part}->{size};
	$o->setPart($part);
	$o->{revision} = $revision;
	$o->{record} = $record;
	$o->{document}->dataChanged;
	return 1;
}

sub forget {
	my $o = shift;

	return if $o->{revision} <= 0;
	$o->{revision} = 0;
	$o->{record} = CDS::Record->new;
	$o->setPart;
}

# Saving

sub createSaveRecord {
	my $o = shift;

	return $o->{saveRecord} if $o->{saveRecord};
	$o->{saveRecord} = $o->{parent} ? $o->{parent}->createSaveRecord->add($o->{selector}->{label}) : CDS::Record->new('root');
	if ($o->{part}->{selected}) {
		CDS->log('Item saving zero revision of ', $o->{selector}->label) if $o->{revision} <= 0;
		$o->{saveRecord}->addInteger($o->{revision})->addRecord($o->{record}->children);
	} else {
		$o->{saveRecord}->add('');
	}
	return $o->{saveRecord};
}

sub detachSaveRecord {
	my $o = shift;

	return if ! $o->{saveRecord};
	delete $o->{saveRecord};
	$o->{parent}->detachSaveRecord if $o->{parent};
}

package CDS::Document::Part;

sub new {
	my $class = shift;

	return bless {
		isMerged => 0,
		hashAndKey => undef,
		size => 0,
		count => 0,
		selected => 0,
		};
}

# In this implementation, we only keep track of the number of values of the list, but
# not of the corresponding items. This saves memory (~100 MiB for 1M items), but takes
# more time (0.5 s for 1M items) when saving. Since command line programs usually write
# the document only once, this is acceptable. Reading the tree anyway takes about 10
# times more time.

package CDS::ErrorHandlingStore;

use parent -norequire, 'CDS::Store';

sub new {
	my $class = shift;
	my $store = shift;
	my $url = shift;
	my $errorHandler = shift;

	return bless {
		store => $store,
		url => $url,
		errorHandler => $errorHandler,
		}
}

sub store { shift->{store} }
sub url { shift->{url} }
sub errorHandler { shift->{errorHandler} }

sub id {
	my $o = shift;
	 'Error handling'."\n  ".$o->{store}->id }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return undef, 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'GET');

	my ($object, $error) = $o->{store}->get($hash, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'GET', $error);
		return undef, $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'GET');
	return $object, $error;
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return undef, 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'BOOK');

	my ($booked, $error) = $o->{store}->book($hash, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'BOOK', $error);
		return undef, $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'BOOK');
	return $booked;
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'PUT');

	my $error = $o->{store}->put($hash, $object, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'PUT', $error);
		return $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'PUT');
	return;
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return undef, 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'LIST');

	my ($hashes, $error) = $o->{store}->list($accountHash, $boxLabel, $timeout, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'LIST', $error);
		return undef, $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'LIST');
	return $hashes;
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'ADD');

	my $error = $o->{store}->add($accountHash, $boxLabel, $hash, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'ADD', $error);
		return $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'ADD');
	return;
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'REMOVE');

	my $error = $o->{store}->remove($accountHash, $boxLabel, $hash, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'REMOVE', $error);
		return $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'REMOVE');
	return;
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return 'Store disabled.' if $o->{errorHandler}->hasStoreError($o, 'MODIFY');

	my $error = $o->{store}->modify($modifications, $keyPair);
	if (defined $error) {
		$o->{errorHandler}->onStoreError($o, 'MODIFY', $error);
		return $error;
	}

	$o->{errorHandler}->onStoreSuccess($o, 'MODIFY');
	return;
}

# A Condensation store on a local folder.
package CDS::FolderStore;

use parent -norequire, 'CDS::Store';

sub forUrl {
	my $class = shift;
	my $url = shift;

	return if substr($url, 0, 8) ne 'file:///';
	return $class->new(substr($url, 7));
}

sub new {
	my $class = shift;
	my $folder = shift;

	return bless {
		folder => $folder,
		permissions => CDS::FolderStore::PosixPermissions->forFolder($folder.'/accounts'),
		};
}

sub id {
	my $o = shift;
	 'file://'.$o->{folder} }
sub folder { shift->{folder} }

sub permissions { shift->{permissions} }
sub setPermissions {
	my $o = shift;
	my $permissions = shift;
	 $o->{permissions} = $permissions; }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $hashHex = $hash->hex;
	my $file = $o->{folder}.'/objects/'.substr($hashHex, 0, 2).'/'.substr($hashHex, 2);
	return CDS::Object->fromBytes(CDS->readBytesFromFile($file));
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	# Book the object if it exists
	my $hashHex = $hash->hex;
	my $folder = $o->{folder}.'/objects/'.substr($hashHex, 0, 2);
	my $file = $folder.'/'.substr($hashHex, 2);
	return 1 if -e $file && utime(undef, undef, $file);
	return;
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	# Book the object if it exists
	my $hashHex = $hash->hex;
	my $folder = $o->{folder}.'/objects/'.substr($hashHex, 0, 2);
	my $file = $folder.'/'.substr($hashHex, 2);
	return if -e $file && utime(undef, undef, $file);

	# Write the file, set the permissions, and move it to the right place
	my $permissions = $o->{permissions};
	$permissions->mkdir($folder, $permissions->objectFolderMode);
	my $temporaryFile = $permissions->writeTemporaryFile($folder, $permissions->objectFileMode, $object->bytes) // return 'Failed to write object';
	rename($temporaryFile, $file) || return 'Failed to rename object.';
	return;
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return undef, 'Invalid box label.' if ! CDS->isValidBoxLabel($boxLabel);

	# Prepare
	my $boxFolder = $o->{folder}.'/accounts/'.$accountHash->hex.'/'.$boxLabel;

	# List
	return $o->listFolder($boxFolder) if ! $timeout;

	# Watch
	my $hashes;
	my $watcher = CDS::FolderStore::Watcher->new($boxFolder);
	my $watchUntil = CDS->now + $timeout;
	while (1) {
		# List
		$hashes = $o->listFolder($boxFolder);
		last if scalar @$hashes;

		# Wait
		$watcher->wait($watchUntil - CDS->now, $watchUntil) // last;
	}

	$watcher->done;
	return $hashes;
}

sub listFolder {
	my $o = shift;
	my $boxFolder = shift;
		# private
	my $hashes = [];
	for my $file (CDS->listFolder($boxFolder)) {
		push @$hashes, CDS::Hash->fromHex($file) // next;
	}

	return $hashes;
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $permissions = $o->{permissions};

	next if ! CDS->isValidBoxLabel($boxLabel);
	my $accountFolder = $o->{folder}.'/accounts/'.$accountHash->hex;
	$permissions->mkdir($accountFolder, $permissions->accountFolderMode);
	my $boxFolder = $accountFolder.'/'.$boxLabel;
	$permissions->mkdir($boxFolder, $permissions->boxFolderMode($boxLabel));
	my $boxFileMode = $permissions->boxFileMode($boxLabel);

	my $temporaryFile = $permissions->writeTemporaryFile($boxFolder, $boxFileMode, '') // return 'Failed to write file.';
	rename($temporaryFile, $boxFolder.'/'.$hash->hex) || return 'Failed to rename file.';
	return;
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	next if ! CDS->isValidBoxLabel($boxLabel);
	my $accountFolder = $o->{folder}.'/accounts/'.$accountHash->hex;
	my $boxFolder = $accountFolder.'/'.$boxLabel;
	next if ! -d $boxFolder;
	unlink $boxFolder.'/'.$hash->hex;
	return;
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $modifications->executeIndividually($o, $keyPair);
}

# Store administration functions

sub exists {
	my $o = shift;

	return -d $o->{folder}.'/accounts' && -d $o->{folder}.'/objects';
}

# Creates the store if it does not exist. The store folder itself must exist.
sub createIfNecessary {
	my $o = shift;

	my $accountsFolder = $o->{folder}.'/accounts';
	my $objectsFolder = $o->{folder}.'/objects';
	$o->{permissions}->mkdir($accountsFolder, $o->{permissions}->baseFolderMode);
	$o->{permissions}->mkdir($objectsFolder, $o->{permissions}->baseFolderMode);
	return -d $accountsFolder && -d $objectsFolder;
}

# Lists accounts. This is a non-standard extension.
sub accounts {
	my $o = shift;

	return	grep { defined $_ }
			map { CDS::Hash->fromHex($_) }
			CDS->listFolder($o->{folder}.'/accounts');
}

# Adds an account. This is a non-standard extension.
sub addAccount {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';

	my $accountFolder = $o->{folder}.'/accounts/'.$accountHash->hex;
	$o->{permissions}->mkdir($accountFolder, $o->{permissions}->accountFolderMode);
	return -d $accountFolder;
}

# Removes an account. This is a non-standard extension.
sub removeAccount {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';

	my $accountFolder = $o->{folder}.'/accounts/'.$accountHash->hex;
	my $trashFolder = $o->{folder}.'/accounts/.deleted-'.CDS->randomHex(16);
	rename $accountFolder, $trashFolder;
	system('rm', '-rf', $trashFolder);
	return ! -d $accountFolder;
}

# Checks (and optionally fixes) the POSIX permissions of all files and folders. This is a non-standard extension.
sub checkPermissions {
	my $o = shift;
	my $logger = shift;

	my $permissions = $o->{permissions};

	# Check the accounts folder
	my $accountsFolder = $o->{folder}.'/accounts';
	$permissions->checkPermissions($accountsFolder, $permissions->baseFolderMode, $logger) || return;

	# Check the account folders
	for my $account (sort { $a cmp $b } CDS->listFolder($accountsFolder)) {
		next if $account !~ /^[0-9a-f]{64}$/;
		my $accountFolder = $accountsFolder.'/'.$account;
		$permissions->checkPermissions($accountFolder, $permissions->accountFolderMode, $logger) || return;

		# Check the box folders
		for my $boxLabel (sort { $a cmp $b } CDS->listFolder($accountFolder)) {
			next if $boxLabel =~ /^\./;
			my $boxFolder = $accountFolder.'/'.$boxLabel;
			$permissions->checkPermissions($boxFolder, $permissions->boxFolderMode($boxLabel), $logger) || return;

			# Check each file
			my $filePermissions = $permissions->boxFileMode($boxLabel);
			for my $file (sort { $a cmp $b } CDS->listFolder($boxFolder)) {
				next if $file !~ /^[0-9a-f]{64}/;
				$permissions->checkPermissions($boxFolder.'/'.$file, $filePermissions, $logger) || return;
			}
		}
	}

	# Check the objects folder
	my $objectsFolder = $o->{folder}.'/objects';
	my $fileMode = $permissions->objectFileMode;
	my $folderMode = $permissions->objectFolderMode;
	$permissions->checkPermissions($objectsFolder, $folderMode, $logger) || return;

	# Check the 256 sub folders
	for my $sub (sort { $a cmp $b } CDS->listFolder($objectsFolder)) {
		next if $sub !~ /^[0-9a-f][0-9a-f]$/;
		my $subFolder = $objectsFolder.'/'.$sub;
		$permissions->checkPermissions($subFolder, $folderMode, $logger) || return;

		for my $file (sort { $a cmp $b } CDS->listFolder($subFolder)) {
			next if $file !~ /^[0-9a-f]{62}/;
			$permissions->checkPermissions($subFolder.'/'.$file, $fileMode, $logger) || return;
		}
	}

	return 1;
}

# Handles POSIX permissions (user, group, and mode).
package CDS::FolderStore::PosixPermissions;

# Returns the permissions set corresponding to the mode, uid, and gid of the base folder.
# If the permissions are ambiguous, the more restrictive set is chosen.
sub forFolder {
	my $class = shift;
	my $folder = shift;

	my @s = stat $folder;
	my $mode = $s[2] // 0;

	return
		($mode & 077) == 077 ? CDS::FolderStore::PosixPermissions::World->new :
		($mode & 070) == 070 ? CDS::FolderStore::PosixPermissions::Group->new($s[5]) :
			CDS::FolderStore::PosixPermissions::User->new($s[4]);
}

sub uid { shift->{uid} }
sub gid { shift->{gid} }

sub user {
	my $o = shift;

	my $uid = $o->{uid} // return;
	return getpwuid($uid) // $uid;
}

sub group {
	my $o = shift;

	my $gid = $o->{gid} // return;
	return getgrgid($gid) // $gid;
}

sub writeTemporaryFile {
	my $o = shift;
	my $folder = shift;
	my $mode = shift;

	# Write the file
	my $temporaryFile = $folder.'/.'.CDS->randomHex(16);
	open(my $fh, '>:bytes', $temporaryFile) || return;
	print $fh @_;
	close $fh;

	# Set the permissions
	chmod $mode, $temporaryFile;
	my $uid = $o->uid;
	my $gid = $o->gid;
	chown $uid // -1, $gid // -1, $temporaryFile if defined $uid && $uid != $< || defined $gid && $gid != $(;
	return $temporaryFile;
}

sub mkdir {
	my $o = shift;
	my $folder = shift;
	my $mode = shift;

	return if -d $folder;

	# Create the folder (note: mode is altered by umask)
	my $success = mkdir $folder, $mode;

	# Set the permissions
	chmod $mode, $folder;
	my $uid = $o->uid;
	my $gid = $o->gid;
	chown $uid // -1, $gid // -1, $folder if defined $uid && $uid != $< || defined $gid && $gid != $(;
	return $success;
}

# Check the permissions of a file or folder, and fix them if desired.
# A logger object is called for the different cases (access error, correct permissions, wrong permissions, error fixing permissions).
sub checkPermissions {
	my $o = shift;
	my $item = shift;
	my $expectedMode = shift;
	my $logger = shift;

	my $expectedUid = $o->uid;
	my $expectedGid = $o->gid;

	# Stat the item
	my @s = stat $item;
	return $logger->accessError($item) if ! scalar @s;
	my $mode = $s[2] & 07777;
	my $uid = $s[4];
	my $gid = $s[5];

	# Check
	my $wrongUid = defined $expectedUid && $uid != $expectedUid;
	my $wrongGid = defined $expectedGid && $gid != $expectedGid;
	my $wrongMode = $mode != $expectedMode;
	if ($wrongUid || $wrongGid || $wrongMode) {
		# Something is wrong
		$logger->wrong($item, $uid, $gid, $mode, $expectedUid, $expectedGid, $expectedMode) || return 1;

		# Fix uid and gid
		if ($wrongUid || $wrongGid) {
			my $count = chown $expectedUid // -1, $expectedGid // -1, $item;
			return $logger->setError($item) if $count < 1;
		}

		# Fix mode
		if ($wrongMode) {
			my $count = chmod $expectedMode, $item;
			return $logger->setError($item) if $count < 1;
		}
	} else {
		# Everything is OK
		$logger->correct($item, $mode, $uid, $gid);
	}

	return 1;
}

# The store belongs to a group. Every user belonging to the group is treated equivalent, and users are supposed to trust each other to some extent.
# The resulting store will have files belonging to multiple users, but the same group.
package CDS::FolderStore::PosixPermissions::Group;

use parent -norequire, 'CDS::FolderStore::PosixPermissions';

sub new {
	my $class = shift;
	my $gid = shift;

	return bless {gid => $gid // $(};
}

sub target {
	my $o = shift;
	 'members of the group '.$o->group }
sub baseFolderMode { 0771 }
sub objectFolderMode { 0771 }
sub objectFileMode { 0664 }
sub accountFolderMode { 0771 }
sub boxFolderMode {
	my $o = shift;
	my $boxLabel = shift;
	 $boxLabel eq 'public' ? 0775 : 0770 }
sub boxFileMode {
	my $o = shift;
	my $boxLabel = shift;
	 $boxLabel eq 'public' ? 0664 : 0660 }

# The store belongs to a single user. Other users shall only be able to read objects and the public box, and post to the message box.
package CDS::FolderStore::PosixPermissions::User;

use parent -norequire, 'CDS::FolderStore::PosixPermissions';

sub new {
	my $class = shift;
	my $uid = shift;

	return bless {uid => $uid // $<};
}

sub target {
	my $o = shift;
	 'user '.$o->user }
sub baseFolderMode { 0711 }
sub objectFolderMode { 0711 }
sub objectFileMode { 0644 }
sub accountFolderMode { 0711 }
sub boxFolderMode {
	my $o = shift;
	my $boxLabel = shift;
	 $boxLabel eq 'public' ? 0755 : 0700 }
sub boxFileMode {
	my $o = shift;
	my $boxLabel = shift;
	 $boxLabel eq 'public' ? 0644 : 0600 }

# The store is open to everybody. This does not usually make sense, but is offered here for completeness.
# This is the simplest permission scheme.
package CDS::FolderStore::PosixPermissions::World;

use parent -norequire, 'CDS::FolderStore::PosixPermissions';

sub new {
	my $class = shift;

	return bless {};
}

sub target { 'everybody' }
sub baseFolderMode { 0777 }
sub objectFolderMode { 0777 }
sub objectFileMode { 0666 }
sub accountFolderMode { 0777 }
sub boxFolderMode { 0777 }
sub boxFileMode { 0666 }

package CDS::FolderStore::Watcher;

sub new {
	my $class = shift;
	my $folder = shift;

	return bless {folder => $folder};
}

sub wait {
	my $o = shift;
	my $remaining = shift;
	my $until = shift;

	return if $remaining <= 0;
	sleep 1;
	return 1;
}

sub done {
	my $o = shift;
	 }

package CDS::GroupDataSharer;

sub new {
	my $class = shift;
	my $actor = shift;

	my $o = bless {
		actor => $actor,
		label => 'shared group data',
		dataHandlers => {},
		messageChannel => CDS::MessageChannel->new($actor, 'group data', CDS->MONTH),
		revision => 0,
		version => '',
		}, $class;

	$actor->storagePrivateRoot->addDataHandler($o->{label}, $o);
	return $o;
}

### Group data handlers

sub addDataHandler {
	my $o = shift;
	my $label = shift;
	my $dataHandler = shift;

	$o->{dataHandlers}->{$label} = $dataHandler;
}

sub removeDataHandler {
	my $o = shift;
	my $label = shift;
	my $dataHandler = shift;

	my $registered = $o->{dataHandlers}->{$label};
	return if $registered != $dataHandler;
	delete $o->{dataHandlers}->{$label};
}

### MergeableData interface

sub addDataTo {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	return if ! $o->{revision};
	$record->addInteger($o->{revision})->add($o->{version});
}

sub mergeData {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	for my $child ($record->children) {
		my $revision = $child->asInteger;
		next if $revision <= $o->{revision};

		$o->{revision} = $revision;
		$o->{version} = $child->bytesValue;
	}
}

sub mergeExternalData {
	my $o = shift;
	my $store = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';

	$o->mergeData($record);
	return if ! $source;
	$source->keep;
	$o->{actor}->storagePrivateRoot->unsaved->state->addMergedSource($source);
}

### Sending messages

sub createMessage {
	my $o = shift;

	my $message = CDS::Record->new;
	my $data = $message->add('group data');
	for my $label (keys %{$o->{dataHandlers}}) {
		my $dataHandler = $o->{dataHandlers}->{$label};
		$dataHandler->addDataTo($data->add($label));
	}
	return $message;
}

sub share {
	my $o = shift;

	# Get the group data members
	my $members = $o->{actor}->getGroupDataMembers // return;
	return 1 if ! scalar @$members;

	# Create the group data message, and check if it changed
	my $message = $o->createMessage;
	my $versionHash = $message->toObject->calculateHash;
	return if $versionHash->bytes eq $o->{version};

	$o->{revision} = CDS->now;
	$o->{version} = $versionHash->bytes;
	$o->{actor}->storagePrivateRoot->dataChanged;

	# Procure the sent list
	$o->{actor}->procureSentList // return;

	# Get the entrusted keys
	my $entrustedKeys = $o->{actor}->getEntrustedKeys // return;

	# Transfer the data
	$o->{messageChannel}->addTransfer([$message->dependentHashes], $o->{actor}->storagePrivateRoot->unsaved, 'group data message');

	# Send the message
	$o->{messageChannel}->setRecipients($members, $entrustedKeys);
	my ($submission, $missingObject) = $o->{messageChannel}->submit($message, $o);
	$o->{actor}->onMissingObject($missingObject) if $missingObject;
	return if ! $submission;
	return 1;
}

sub onMessageChannelSubmissionCancelled {
	my $o = shift;
	 }

sub onMessageChannelSubmissionRecipientDone {
	my $o = shift;
	my $recipientActorOnStore = shift; die 'wrong type '.ref($recipientActorOnStore).' for $recipientActorOnStore' if defined $recipientActorOnStore && ref $recipientActorOnStore ne 'CDS::ActorOnStore';
	 }

sub onMessageChannelSubmissionRecipientFailed {
	my $o = shift;
	my $recipientActorOnStore = shift; die 'wrong type '.ref($recipientActorOnStore).' for $recipientActorOnStore' if defined $recipientActorOnStore && ref $recipientActorOnStore ne 'CDS::ActorOnStore';
	 }

sub onMessageChannelSubmissionDone {
	my $o = shift;
	my $succeeded = shift;
	my $failed = shift;
	 }

### Receiving messages

sub processGroupDataMessage {
	my $o = shift;
	my $message = shift;
	my $section = shift;

	if (! $o->{actor}->isGroupMember($message->sender->publicKey->hash)) {
		# TODO:
		# If the sender is not a known group member, we should run actor group discovery on the sender. He may be part of us, but we don't know that yet.
		# At the very least, we should keep this message, and reconsider it if the actor group changes within the next few minutes (e.g. through another message).
		return;
	}

	for my $child ($section->children) {
		my $dataHandler = $o->{dataHandlers}->{$child->bytes} // next;
		$dataHandler->mergeExternalData($message->sender->store, $child, $message->source);
	}

	return 1;
}

package CDS::HTTPServer;

use parent -norequire, 'HTTP::Server::Simple';

sub new {
	my $class = shift;

	my $o = $class->SUPER::new(@_);
	$o->{logger} = CDS::HTTPServer::Logger->new(*STDERR);
	$o->{handlers} = [];
	return $o;
}

sub addHandler {
	my $o = shift;
	my $handler = shift;

	push @{$o->{handlers}}, $handler;
}

sub setLogger {
	my $o = shift;
	my $logger = shift;

	$o->{logger} = $logger;
}

sub logger { shift->{logger} }

sub setCorsAllowEverybody {
	my $o = shift;
	my $value = shift;

	$o->{corsAllowEverybody} = $value;
}

sub corsAllowEverybody { shift->{corsAllowEverybody} }

# *** HTTP::Server::Simple interface

sub print_banner {
	my $o = shift;

	$o->{logger}->onServerStarts($o->port);
}

sub setup {
	my $o = shift;

	$o->{request} = CDS::HTTPServer::Request->new($o, @_);
}

sub headers {
	my $o = shift;
	my $headers = shift;

	$o->{request}->setHeaders($headers);
}

sub handler {
	my $o = shift;

	# Start writing the log line
	$o->{logger}->onRequestStarts($o->{request});

	# Process the request
	my $responseCode = $o->process;
	$o->{logger}->onRequestDone($o->{request}, $responseCode);

	# Wrap up
	$o->{request}->dropData;
	$o->{request} = undef;
	return;
}

sub process {
	my $o = shift;

	# Run the handler
	for my $handler (@{$o->{handlers}}) {
		my $responseCode = $handler->process($o->{request}) || next;
		return $responseCode;
	}

	# Default handler
	return $o->{request}->reply404;
}

sub bad_request {
	my $o = shift;

	my $content = 'Bad Request';
	print 'HTTP/1.1 400 Bad Request', "\r\n";
	print 'Content-Length: ', length $content, "\r\n";
	print 'Content-Type: text/plain; charset=utf-8', "\r\n";
	print "\r\n";
	print $content;
	$o->{request} = undef;
}

package CDS::HTTPServer::IdentificationHandler;

sub new {
	my $class = shift;
	my $root = shift;

	return bless {root => $root};
}

sub process {
	my $o = shift;
	my $request = shift;

	my $path = $request->pathAbove($o->{root}) // return;
	return if $path ne '/';

	# Options
	return $request->replyOptions('HEAD', 'GET') if $request->method eq 'OPTIONS';

	# Get
	return $request->reply200HTML('<!DOCTYPE html><html><head><meta charset="utf-8"><title>Condensation HTTP Store</title></head><body>This is a <a href="https://condensation.io/specifications/store/http/">Condensation HTTP Store</a> server.</body></html>') if $request->method eq 'HEAD' || $request->method eq 'GET';

	return $request->reply405;
}

package CDS::HTTPServer::Logger;

sub new {
	my $class = shift;
	my $fileHandle = shift;

	return bless {
		fileHandle => $fileHandle,
		lineStarted => 0,
		};
}

sub onServerStarts {
	my $o = shift;
	my $port = shift;

	my $fh = $o->{fileHandle};
	my @t = localtime(time);
	printf $fh '%04d-%02d-%02d %02d:%02d:%02d ', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0];
	print $fh 'Server ready at http://localhost:', $port, "\n";
}

sub onRequestStarts {
	my $o = shift;
	my $request = shift;

	my $fh = $o->{fileHandle};
	my @t = localtime(time);
	printf $fh '%04d-%02d-%02d %02d:%02d:%02d ', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0];
	print $fh $request->peerAddress, ' ', $request->method, ' ', $request->path;
	$o->{lineStarted} = 1;
}

sub onRequestError {
	my $o = shift;
	my $request = shift;

	my $fh = $o->{fileHandle};
	print $fh "\n" if $o->{lineStarted};
	print $fh '  ', @_, "\n";
	$o->{lineStarted} = 0;
}

sub onRequestDone {
	my $o = shift;
	my $request = shift;
	my $responseCode = shift;

	my $fh = $o->{fileHandle};
	print $fh '  ===> ' if ! $o->{lineStarted};
	print $fh ' ', $responseCode, "\n";
	$o->{lineStarted} = 0;
}

package CDS::HTTPServer::MessageGatewayHandler;

sub new {
	my $class = shift;
	my $url = shift;
	my $identity = shift;
	my $recipient = shift;

	return bless {url => $url, identity => $identity, recipient => $recipient};
}

sub process {
	my $o = shift;
	my $request = shift;

	$request->path =~ /^\/data$/ || return;
	my $store = $request->server->store;

	# Options
	return $request->replyOptions('HEAD', 'GET', 'PUT', 'POST', 'DELETE') if $request->method eq 'OPTIONS';

	# Prepare a message
	my $record = CDS::Record->new;
	$record->add('time')->addInteger(CDS->now);
	$record->add('ip')->add($request->peerAddress);
	$record->add('method')->add($request->method);
	$record->add('path')->add($request->path);
	$record->add('query string')->add($request->queryString);

	my $headersRecord = $record->add('headers');
	my $headers = $request->headers;
	for my $key (keys %$headers) {
		$headersRecord->add($key)->add($headers->{$key});
	}

	$record->add('data')->add($request->readData) if $request->remainingData;

	# Post it
	my $success = $o->{identity}->sendMessageRecord($record, undef, [$o->{recipient}]);
	return $success ? $request->reply200 : $request->reply500('Unable to send the message.');
}

package CDS::HTTPServer::Request;

sub new {
	my $class = shift;
	my $server = shift;

	my %parameters = @_;
	return bless {
		server => $server,
		method => $parameters{method},
		path => $parameters{path},
		protocol => $parameters{protocol},
		queryString => $parameters{query_string},
		localName => $parameters{localname},
		localPort => $parameters{localport},
		peerName => $parameters{peername},
		peerAddress => $parameters{peeraddr},
		peerPort => $parameters{peerport},
		headers => {},
		remainingData => 0,
		};
}

sub server { shift->{server} }
sub method { shift->{method} }
sub path { shift->{path} }
sub queryString { shift->{queryString} }
sub peerAddress { shift->{peerAddress} }
sub peerPort { shift->{peerPort} }
sub headers { shift->{headers} }
sub remainingData { shift->{remainingData} }

# *** Request configuration

sub setHeaders {
	my $o = shift;
	my $newHeaders = shift;

	# Set the headers
	while (scalar @$newHeaders) {
		my $key = shift @$newHeaders;
		my $value = shift @$newHeaders;
		$o->{headers}->{lc($key)} = $value;
	}

	# Keep track of the data sent along with the request
	$o->{remainingData} = $o->{headers}->{'content-length'} // 0;
}

sub pathAbove {
	my $o = shift;
	my $root = shift;

	$root .= '/' if $root !~ /\/$/;
	return if substr($o->{path}, 0, length $root) ne $root;
	return substr($o->{path}, length($root) - 1);
}

# *** Request data

# Reads the request data
sub readData {
	my $o = shift;

	my @buffers;
	while ($o->{remainingData} > 0) {
		my $read = sysread(STDIN, my $buffer, $o->{remainingData}) || return;
		$o->{remainingData} -= $read;
		push @buffers, $buffer;
	}

	return join('', @buffers);
}

# Read the request data and writes it directly to a file handle
sub copyDataAndCalculateHash {
	my $o = shift;
	my $fh = shift;

	my $sha = Digest::SHA->new(256);
	while ($o->{remainingData} > 0) {
		my $read = sysread(STDIN, my $buffer, $o->{remainingData}) || return;
		$o->{remainingData} -= $read;
		$sha->add($buffer);
		print $fh $buffer;
	}

	return $sha->digest;
}

# Reads and drops the request data
sub dropData {
	my $o = shift;

	while ($o->{remainingData} > 0) {
		$o->{remainingData} -= read(STDIN, my $buffer, $o->{remainingData}) || return;
	}
}

# *** Query string

sub parseQueryString {
	my $o = shift;

	return {} if ! defined $o->{queryString};

	my $values = {};
	for my $pair (split /&/, $o->{queryString}) {
		if ($pair =~ /^(.*?)=(.*)$/) {
			my $key = $1;
			my $value = $2;
			$values->{&uri_decode($key)} = &uri_decode($value);
		} else {
			$values->{&uri_decode($pair)} = 1;
		}
	}

	return $values;
}

sub uri_decode {
	my $encoded = shift;

	$encoded =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
	return $encoded;
}

# *** Condensation signature

sub checkSignature {
	my $o = shift;
	my $store = shift;
	my $contentBytesToSign = shift;

	# Check the date
	my $dateString = $o->{headers}->{'condensation-date'} // $o->{headers}->{'date'} // return;
	my $date = HTTP::Date::str2time($dateString) // return;
	my $now = time;
	return if $date < $now - 120 || $date > $now + 60;

	# Get and check the actor
	my $actorHash = CDS::Hash->fromHex($o->{headers}->{'condensation-actor'}) // return;
	my ($publicKeyObject, $error) = $store->get($actorHash);
	return if defined $error;
	return if ! $publicKeyObject->calculateHash->equals($actorHash);
	my $publicKey = CDS::PublicKey->fromObject($publicKeyObject) // return;

	# Text to sign
	my $bytesToSign = $dateString."\0".uc($o->{method})."\0".$o->{headers}->{'host'}.$o->{path};
	$bytesToSign .= "\0".$contentBytesToSign if defined $contentBytesToSign;
	my $hashToSign = CDS::Hash->calculateFor($bytesToSign);

	# Check the signature
	my $signatureString = $o->{headers}->{'condensation-signature'} // return;
	$signatureString =~ /^\s*([0-9a-z]{512,512})\s*$/ // return;
	my $signature = pack('H*', $1);
	return if ! $publicKey->verifyHash($hashToSign, $signature);

	# Return the verified actor hash
	return $actorHash;
}

# *** Reply functions

sub reply200 {
	my $o = shift;
	my $content = shift // '';

	return length $content ? $o->reply(200, 'OK', &textContentType, $content) : $o->reply(204, 'No Content', {});
}

sub reply200Bytes {
	my $o = shift;
	my $content = shift // '';

	return length $content ? $o->reply(200, 'OK', {'Content-Type' => 'application/octet-stream'}, $content) : $o->reply(204, 'No Content', {});
}

sub reply200HTML {
	my $o = shift;
	my $content = shift // '';

	return length $content ? $o->reply(200, 'OK', {'Content-Type' => 'text/html; charset=utf-8'}, $content) : $o->reply(204, 'No Content', {});
}

sub replyOptions {
	my $o = shift;

	my $headers = {};
	$headers->{'Allow'} = join(', ', @_, 'OPTIONS');
	$headers->{'Access-Control-Allow-Methods'} = join(', ', @_, 'OPTIONS') if $o->{server}->corsAllowEverybody && $o->{headers}->{'origin'};
	return $o->reply(200, 'OK', $headers);
}

sub replyFatalError {
	my $o = shift;

	$o->{server}->{logger}->onRequestError($o, @_);
	return $o->reply500;
}

sub reply303 {
	my $o = shift;
	my $location = shift;
	 $o->reply(303, 'See Other', {'Location' => $location}) }
sub reply400 { shift->reply(400, 'Bad Request', &textContentType, @_) }
sub reply403 { shift->reply(403, 'Forbidden', &textContentType, @_) }
sub reply404 { shift->reply(404, 'Not Found', &textContentType, @_) }
sub reply405 { shift->reply(405, 'Method Not Allowed', &textContentType, @_) }
sub reply500 { shift->reply(500, 'Internal Server Error', &textContentType, @_) }
sub reply503 { shift->reply(503, 'Service Not Available', &textContentType, @_) }

sub reply {
	my $o = shift;
	my $responseCode = shift;
	my $responseLabel = shift;
	my $headers = shift // {};
	my $content = shift // '';

	# Content-related headers
	$headers->{'Content-Length'} = length($content);

	# Origin
	if ($o->{server}->corsAllowEverybody && (my $origin = $o->{headers}->{'origin'})) {
		$headers->{'Access-Control-Allow-Origin'} = $origin;
		$headers->{'Access-Control-Allow-Headers'} = 'Content-Type';
		$headers->{'Access-Control-Max-Age'} = '86400';
	}

	# Write the reply
	print 'HTTP/1.1 ', $responseCode, ' ', $responseLabel, "\r\n";
	for my $key (keys %$headers) {
		print $key, ': ', $headers->{$key}, "\r\n";
	}
	print "\r\n";
	print $content if $o->{method} ne 'HEAD';

	# Return the response code
	return $responseCode;
}

sub textContentType { {'Content-Type' => 'text/plain; charset=utf-8'} }

package CDS::HTTPServer::StaticContentHandler;

sub new {
	my $class = shift;
	my $path = shift;
	my $content = shift;
	my $contentType = shift;

	return bless {
		path => $path,
		content => $content,
		contentType => $contentType,
		};
}

sub process {
	my $o = shift;
	my $request = shift;

	return if $request->path ne $o->{path};

	# Options
	return $request->replyOptions('HEAD', 'GET') if $request->method eq 'OPTIONS';

	# GET
	return $request->reply(200, 'OK', {'Content-Type' => $o->{contentType}}, $o->{content}) if $request->method eq 'GET';

	# Everything else
	return $request->reply405;
}

package CDS::HTTPServer::StaticFilesHandler;

sub new {
	my $class = shift;
	my $root = shift;
	my $folder = shift;
	my $defaultFile = shift // '';

	return bless {
		root => $root,
		folder => $folder,
		defaultFile => $defaultFile,
		mimeTypesByExtension => {
			'css' => 'text/css',
			'gif' => 'image/gif',
			'html' => 'text/html',
			'jpg' => 'image/jpeg',
			'jpeg' => 'image/jpeg',
			'js' => 'application/javascript',
			'mp4' => 'video/mp4',
			'ogg' => 'video/ogg',
			'pdf' => 'application/pdf',
			'png' => 'image/png',
			'svg' => 'image/svg+xml',
			'txt' => 'text/plain',
			'webm' => 'video/webm',
			'zip' => 'application/zip',
			},
		};
}

sub folder { shift->{folder} }
sub defaultFile { shift->{defaultFile} }
sub mimeTypesByExtension { shift->{mimeTypesByExtension} }

sub setContentType {
	my $o = shift;
	my $extension = shift;
	my $contentType = shift;

	$o->{mimeTypesByExtension}->{$extension} = $contentType;
}

sub process {
	my $o = shift;
	my $request = shift;

	# Options
	return $request->replyOptions('HEAD', 'GET') if $request->method eq 'OPTIONS';

	# Get
	return $o->get($request) if $request->method eq 'GET' || $request->method eq 'HEAD';

	# Anything else
	return $request->reply405;
}

sub get {
	my $o = shift;
	my $request = shift;

	my $path = $request->pathAbove($o->{root}) // return;
	return $o->deliverFileForPath($request, $path);
}

sub deliverFileForPath {
	my $o = shift;
	my $request = shift;
	my $path = shift;

	# Hidden files (starting with a dot), as well as "." and ".." never exist
	for my $segment (split /\/+/, $path) {
		return $request->reply404 if $segment =~ /^\./;
	}

	# If a folder is requested, we serve the default file
	my $file = $o->{folder}.$path;
	if (-d $file) {
		return $request->reply404 if ! length $o->{defaultFile};
		return $request->reply303($request->path.'/') if $file !~ /\/$/;
		$file .= $o->{defaultFile};
	}

	return $o->deliverFile($request, $file);
}

sub deliverFile {
	my $o = shift;
	my $request = shift;
	my $file = shift;
	my $contentType = shift // $o->guessContentType($file);

	my $bytes = $o->readFile($file) // return $request->reply404;
	return $request->reply(200, 'OK', {'Content-Type' => $contentType}, $bytes);
}

# Guesses the content type from the extension
sub guessContentType {
	my $o = shift;
	my $file = shift;

	my $extension = $file =~ /\.([A-Za-z0-9]*)$/ ? lc($1) : '';
	return $o->{mimeTypesByExtension}->{$extension} // 'application/octet-stream';
}

# Reads a file
sub readFile {
	my $o = shift;
	my $file = shift;

	open(my $fh, '<:bytes', $file) || return;
	if (! -f $fh) {
		close $fh;
		return;
	}

	local $/ = undef;
	my $bytes = <$fh>;
	close $fh;
	return $bytes;
}

package CDS::HTTPServer::StoreHandler;

sub new {
	my $class = shift;
	my $root = shift;
	my $store = shift;
	my $checkPutHash = shift;
	my $checkSignatures = shift // 1;

	return bless {
		root => $root,
		store => $store,
		checkPutHash => $checkPutHash,
		checkEnvelopeHash => $checkPutHash,
		checkSignatures => $checkSignatures,
		maximumWatchTimeout => 0,
		};
}

sub process {
	my $o = shift;
	my $request = shift;

	my $path = $request->pathAbove($o->{root}) // return;

	# Objects request
	if ($request->path =~ /^\/objects\/([0-9a-f]{64})$/) {
		my $hash = CDS::Hash->fromHex($1);
		return $o->objects($request, $hash);
	}

	# Box request
	if ($request->path =~ /^\/accounts\/([0-9a-f]{64})\/(messages|private|public)$/) {
		my $accountHash = CDS::Hash->fromHex($1);
		my $boxLabel = $2;
		return $o->box($request, $accountHash, $boxLabel);
	}

	# Box entry request
	if ($request->path =~ /^\/accounts\/([0-9a-f]{64})\/(messages|private|public)\/([0-9a-f]{64})$/) {
		my $accountHash = CDS::Hash->fromHex($1);
		my $boxLabel = $2;
		my $hash = CDS::Hash->fromHex($3);
		return $o->boxEntry($request, $accountHash, $boxLabel, $hash);
	}

	# Account request
	if ($request->path =~ /^\/accounts\/([0-9a-f]{64})$/) {
		return $request->replyOptions if $request->method eq 'OPTIONS';
		return $request->reply405;
	}

	# Accounts request
	if ($request->path =~ /^\/accounts$/) {
		return $o->accounts($request);
	}

	# Other requests on /objects or /accounts
	if ($request->path =~ /^\/(accounts|objects)(\/|$)/) {
		return $request->reply404;
	}

	# Nothing for us
	return;
}

sub objects {
	my $o = shift;
	my $request = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	# Options
	if ($request->method eq 'OPTIONS') {
		return $request->replyOptions('HEAD', 'GET', 'PUT', 'POST');
	}

	# Retrieve object
	if ($request->method eq 'HEAD' || $request->method eq 'GET') {
		my ($object, $error) = $o->{store}->get($hash);
		return $request->replyFatalError($error) if defined $error;
		return $request->reply404 if ! $object;
		# We don't check the SHA256 sum here - this should be done by the client
		return $request->reply200Bytes($object->bytes);
	}

	# Put object
	if ($request->method eq 'PUT') {
		my $bytes = $request->readData // return $request->reply400('No data received.');
		my $object = CDS::Object->fromBytes($bytes) // return $request->reply400('Not a Condensation object.');
		return $request->reply400('SHA256 sum does not match hash.') if $o->{checkPutHash} && ! $object->calculateHash->equals($hash);

		if ($o->{checkSignatures}) {
			my $checkSignatureStore = CDS::CheckSignatureStore->new($o->{store});
			$checkSignatureStore->put($hash, $object);
			return $request->reply403 if ! $request->checkSignature($checkSignatureStore);
		}

		my $error = $o->{store}->put($hash, $object);
		return $request->replyFatalError($error) if defined $error;
		return $request->reply200;
	}

	# Book object
	if ($request->method eq 'POST') {
		return $request->reply403 if $o->{checkSignatures} && ! $request->checkSignature($o->{store});
		return $request->reply400('You cannot send data when booking an object.') if $request->remainingData;
		my ($booked, $error) = $o->{store}->book($hash);
		return $request->replyFatalError($error) if defined $error;
		return $booked ? $request->reply200 : $request->reply404;
	}

	return $request->reply405;
}

sub box {
	my $o = shift;
	my $request = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;

	# Options
	if ($request->method eq 'OPTIONS') {
		return $request->replyOptions('HEAD', 'GET', 'PUT', 'POST');
	}

	# List box
	if ($request->method eq 'HEAD' || $request->method eq 'GET') {
		my $watch = $request->headers->{'condensation-watch'} // '';
		my $timeout = $watch =~ /^(\d+)\s*ms$/ ? $1 + 0 : 0;
		$timeout = $o->{maximumWatchTimeout} if $timeout > $o->{maximumWatchTimeout};
		my ($hashes, $error) = $o->{store}->list($accountHash, $boxLabel, $timeout);
		return $request->replyFatalError($error) if defined $error;
		return $request->reply200Bytes(join('', map { $_->bytes } @$hashes));
	}

	return $request->reply405;
}

sub boxEntry {
	my $o = shift;
	my $request = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	# Options
	if ($request->method eq 'OPTIONS') {
		return $request->replyOptions('HEAD', 'PUT', 'DELETE');
	}

	# Add
	if ($request->method eq 'PUT') {
		if ($o->{checkSignatures}) {
			my $actorHash = $request->checkSignature($o->{store});
			return $request->reply403 if ! $actorHash;
			return $request->reply403 if ! $o->verifyAddition($actorHash, $accountHash, $boxLabel, $hash);
		}

		my $error = $o->{store}->add($accountHash, $boxLabel, $hash);
		return $request->replyFatalError($error) if defined $error;
		return $request->reply200;
	}

	# Remove
	if ($request->method eq 'DELETE') {
		if ($o->{checkSignatures}) {
			my $actorHash = $request->checkSignature($o->{store});
			return $request->reply403 if ! $actorHash;
			return $request->reply403 if ! $o->verifyRemoval($actorHash, $accountHash, $boxLabel, $hash);
		}

		my ($booked, $error) = $o->{store}->remove($accountHash, $boxLabel, $hash);
		return $request->replyFatalError($error) if defined $error;
		return $request->reply200;
	}

	return $request->reply405;
}

sub accounts {
	my $o = shift;
	my $request = shift;

	# Options
	if ($request->method eq 'OPTIONS') {
		return $request->replyOptions('POST');
	}

	# Modify boxes
	if ($request->method eq 'POST') {
		my $bytes = $request->readData // return $request->reply400('No data received.');
		my $modifications = CDS::StoreModifications->fromBytes($bytes);
		return $request->reply400('Invalid modifications.') if ! $modifications;

		if ($o->{checkSignatures}) {
			my $actorHash = $request->checkSignature(CDS::CheckSignatureStore->new($o->{store}, $modifications->objects), $bytes);
			return $request->reply403 if ! $actorHash;
			return $request->reply403 if ! $o->verifyModifications($actorHash, $modifications);
		}

		my $error = $o->{store}->modify($modifications);
		return $request->replyFatalError($error) if defined $error;
		return $request->reply200;
	}

	return $request->reply405;
}

sub verifyModifications {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';
	my $modifications = shift;

	for my $operation (@{$modifications->additions}) {
		return if ! $o->verifyAddition($actorHash, $operation->{accountHash}, $operation->{boxLabel}, $operation->{hash});
	}

	for my $operation (@{$modifications->removals}) {
		return if ! $o->verifyRemoval($actorHash, $operation->{accountHash}, $operation->{boxLabel}, $operation->{hash});
	}

	return 1;
}

sub verifyAddition {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	return 1 if $accountHash->equals($actorHash);
	return 1 if $boxLabel eq 'messages';
	return;
}

sub verifyRemoval {
	my $o = shift;
	my $actorHash = shift; die 'wrong type '.ref($actorHash).' for $actorHash' if defined $actorHash && ref $actorHash ne 'CDS::Hash';
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	return 1 if $accountHash->equals($actorHash);

	# Get the envelope
	my ($bytes, $error) = $o->{store}->get($hash);
	return if defined $error;
	return 1 if ! defined $bytes;
	my $record = CDS::Record->fromObject(CDS::Object->fromBytes($bytes)) // return;

	# Allow anyone listed under "updated by"
	my $actorHashBytes24 = substr($actorHash->bytes, 0, 24);
	for my $child ($record->child('updated by')->children) {
		my $hashBytes24 = $child->bytes;
		next if length $hashBytes24 != 24;
		return 1 if $hashBytes24 eq $actorHashBytes24;
	}

	return;
}

# A Condensation store accessed through HTTP or HTTPS.
package CDS::HTTPStore;

use parent -norequire, 'CDS::Store';

sub forUrl {
	my $class = shift;
	my $url = shift;

	$url =~ /^(http|https):\/\// || return;
	return $class->new($url);
}

sub new {
	my $class = shift;
	my $url = shift;

	return bless {url => $url};
}

sub id {
	my $o = shift;
	 $o->{url} }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $response = $o->request('GET', $o->{url}.'/objects/'.$hash->hex, HTTP::Headers->new);
	return if $response->code == 404;
	return undef, 'get ==> HTTP '.$response->status_line if ! $response->is_success;
	return CDS::Object->fromBytes($response->decoded_content(charset => 'none'));
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $headers = HTTP::Headers->new;
	$headers->header('Content-Type' => 'application/condensation-object');
	my $response = $o->request('PUT', $o->{url}.'/objects/'.$hash->hex, $headers, $keyPair, $object->bytes);
	return if $response->is_success;
	return 'put ==> HTTP '.$response->status_line;
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $response = $o->request('POST', $o->{url}.'/objects/'.$hash->hex, HTTP::Headers->new, $keyPair);
	return if $response->code == 404;
	return 1 if $response->is_success;
	return undef, 'book ==> HTTP '.$response->status_line;
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $boxUrl = $o->{url}.'/accounts/'.$accountHash->hex.'/'.$boxLabel;
	my $headers = HTTP::Headers->new;
	$headers->header('Condensation-Watch' => $timeout.' ms') if $timeout > 0;
	my $response = $o->request('GET', $boxUrl, $headers);
	return undef, 'list ==> HTTP '.$response->status_line if ! $response->is_success;
	my $bytes = $response->decoded_content(charset => 'none');

	if (length($bytes) % 32 != 0) {
		print STDERR 'old procotol', "\n";
		my $hashes = [];
		for my $line (split /\n/, $bytes) {
			push @$hashes, CDS::Hash->fromHex($line) // next;
		}
		return $hashes;
	}

	my $countHashes = int(length($bytes) / 32);
	return [map { CDS::Hash->fromBytes(substr($bytes, $_ * 32, 32)) } 0 .. $countHashes - 1];
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $headers = HTTP::Headers->new;
	my $response = $o->request('PUT', $o->{url}.'/accounts/'.$accountHash->hex.'/'.$boxLabel.'/'.$hash->hex, $headers, $keyPair);
	return if $response->is_success;
	return 'add ==> HTTP '.$response->status_line;
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $headers = HTTP::Headers->new;
	my $response = $o->request('DELETE', $o->{url}.'/accounts/'.$accountHash->hex.'/'.$boxLabel.'/'.$hash->hex, $headers, $keyPair);
	return if $response->is_success;
	return 'remove ==> HTTP '.$response->status_line;
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $bytes = $modifications->toRecord->toObject->bytes;
	my $headers = HTTP::Headers->new;
	$headers->header('Content-Type' => 'application/condensation-modifications');
	my $response = $o->request('POST', $o->{url}.'/accounts', $headers, $keyPair, $bytes, 1);
	return if $response->is_success;
	return 'modify ==> HTTP '.$response->status_line;
}

# Executes a HTTP request.
sub request {
	my $class = shift;
	my $method = shift;
	my $url = shift;
	my $headers = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $data = shift;
	my $signData = shift;
		# private
	$headers->date(time);
	$headers->header('User-Agent' => CDS->version);

	if ($keyPair) {
		my $hostAndPath = $url =~ /^https?:\/\/(.*)$/ ? $1 : $url;
		my $date = CDS::ISODate->millisecondString;
		my $bytesToSign = $date."\0".uc($method)."\0".$hostAndPath;
		$bytesToSign .= "\0".$data if $signData;
		my $hashBytesToSign = Digest::SHA::sha256($bytesToSign);
		my $signature = $keyPair->sign($hashBytesToSign);
		$headers->header('Condensation-Date' => $date);
		$headers->header('Condensation-Actor' => $keyPair->publicKey->hash->hex);
		$headers->header('Condensation-Signature' => unpack('H*', $signature));
	}

	return LWP::UserAgent->new->request(HTTP::Request->new($method, $url, $headers, $data));
}

# Models a hash, and offers binary and hexadecimal representation.
package CDS::Hash;

sub fromBytes {
	my $class = shift;
	my $hashBytes = shift // return;

	return if length $hashBytes != 32;
	return bless \$hashBytes;
}

sub fromHex {
	my $class = shift;
	my $hashHex = shift // return;

	$hashHex =~ /^\s*([a-fA-F0-9]{64,64})\s*$/ || return;
	my $hashBytes = pack('H*', $hashHex);
	return bless \$hashBytes;
}

sub calculateFor {
	my $class = shift;
	my $bytes = shift;

	# The Perl built-in SHA256 implementation is a tad faster than our SHA256 implementation.
	#return $class->fromBytes(CDS::C::sha256($bytes));
	return $class->fromBytes(Digest::SHA::sha256($bytes));
}

sub hex {
	my $o = shift;

	return unpack('H*', $$o);
}

sub shortHex {
	my $o = shift;

	return unpack('H*', substr($$o, 0, 8)) . '…';
}

sub bytes {
	my $o = shift;
	 $$o }

sub equals {
	my $this = shift;
	my $that = shift;

	return 1 if ! defined $this && ! defined $that;
	return if ! defined $this || ! defined $that;
	return $$this eq $$that;
}

sub cmp {
	my $this = shift;
	my $that = shift;
	 $$this cmp $$that }

# A hash with an AES key.
package CDS::HashAndKey;

sub new {
	my $class = shift;
	my $hash = shift // return; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $key = shift // return;

	return bless {
		hash => $hash,
		key => $key,
		};
}

sub hash { shift->{hash} }
sub key { shift->{key} }

package CDS::ISODate;

# Parses a date accepting various ISO variants, and calculates the timestamp using Time::Local
sub parse {
	my $class = shift;
	my $dateString = shift // return;

	if ($dateString =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/) {
		return (timegm(0, 0, 0, $3, $2 - 1, $1 - 1900) + 86400 - 30) * 1000;
	} elsif ($dateString =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(T|\s+)(\d\d):(\d\d):(\d\d|\d\d\.\d*)$/) {
		return (timelocal(0, $6, $5, $3, $2 - 1, $1 - 1900) + $7) * 1000;
	} elsif ($dateString =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(T|\s+)(\d\d):(\d\d):(\d\d|\d\d\.\d*)Z$/) {
		return (timegm(0, $6, $5, $3, $2 - 1, $1 - 1900) + $7) * 1000;
	} elsif ($dateString =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(T|\s+)(\d\d):(\d\d):(\d\d|\d\d\.\d*)+(\d\d):(\d\d)$/) {
		return (timegm(0, $6, $5, $3, $2 - 1, $1 - 1900) + $7 - $8 * 3600 - $9 * 60) * 1000;
	} elsif ($dateString =~ /^(\d\d\d\d)-(\d\d)-(\d\d)(T|\s+)(\d\d):(\d\d):(\d\d|\d\d\.\d*)-(\d\d):(\d\d)$/) {
		return (timegm(0, $6, $5, $3, $2 - 1, $1 - 1900) + $7 + $8 * 3600 + $9 * 60) * 1000;
	} elsif ($dateString =~ /^\s*(\d+)\s*$/) {
		return $1;
	} else {
		return;
	}
}

# Returns a properly formatted string with a precision of 1 day (i.e., the "date" only)
sub dayString {
	my $class = shift;
	my $time = shift // 1000 * time;

	my @t = gmtime($time / 1000);
	return sprintf('%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3]);
}

# Returns a properly formatted string with a precision of 1 second (i.e., "time of day" and "date") using UTC
sub secondString {
	my $class = shift;
	my $time = shift // 1000 * time;

	my @t = gmtime($time / 1000);
	return sprintf('%04d-%02d-%02dT%02d:%02d:%02dZ', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

# Returns a properly formatted string with a precision of 1 second (i.e., "time of day" and "date") using UTC
sub millisecondString {
	my $class = shift;
	my $time = shift // 1000 * time;

	my @t = gmtime($time / 1000);
	return sprintf('%04d-%02d-%02dT%02d:%02d:%02d.%03dZ', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0], int($time) % 1000);
}

# Returns a properly formatted string with a precision of 1 second (i.e., "time of day" and "date") using local time
sub localSecondString {
	my $class = shift;
	my $time = shift // 1000 * time;

	my @t = localtime($time / 1000);
	return sprintf('%04d-%02d-%02dT%02d:%02d:%02d', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

package CDS::InMemoryStore;

sub create {
	my $class = shift;

	return CDS::InMemoryStore->new('inMemoryStore:'.unpack('H*', CDS->randomBytes(16)));
}

sub new {
	my $o = shift;
	my $id = shift;

	return bless {
		id => $id,
		objects => {},
		accounts => {},
		};
}

sub id { shift->{id} }

sub accountForWriting {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $account = $o->{accounts}->{$hash->bytes};
	return $account if $account;
	return $o->{accounts}->{$hash->bytes} = {messages => {}, private => {}, public => {}};
}

# *** Store interface

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $entry = $o->{objects}->{$hash->bytes} // return;
	return $entry->{object};
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $entry = $o->{objects}->{$hash->bytes} // return;
	$entry->{booked} = CDS->now;
	return 1;
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{objects}->{$hash->bytes} = {object => $object, booked => CDS->now};
	return;
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $account = $o->{accounts}->{$accountHash->bytes} // return [];
	my $box = $account->{$boxLabel} // return undef, 'Invalid box label.';
	return values %$box;
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $box = $o->accountForWriting($accountHash)->{$boxLabel} // return;
	$box->{$hash->bytes} = $hash;
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $box = $o->accountForWriting($accountHash)->{$boxLabel} // return;
	delete $box->{$hash->bytes};
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $modifications->executeIndividually($o, $keyPair);
}

# Garbage collection

sub collectGarbage {
	my $o = shift;
	my $graceTime = shift;

	# Mark all objects as not used
	for my $entry (values %{$o->{objects}}) {
		$entry->{inUse} = 0;
	}

	# Mark all objects newer than the grace time
	for my $entry (values %{$o->{objects}}) {
		$o->markEntry($entry) if $entry->{booked} > $graceTime;
	}

	# Mark all objects referenced from a box
	for my $account (values %{$o->{accounts}}) {
		for my $hash (values %{$account->{messages}}) { $o->markHash($hash); }
		for my $hash (values %{$account->{private}}) { $o->markHash($hash); }
		for my $hash (values %{$account->{public}}) { $o->markHash($hash); }
	}

	# Remove empty accounts
	while (my ($key, $account) = each %{$o->{accounts}}) {
		next if scalar keys %{$account->{messages}};
		next if scalar keys %{$account->{private}};
		next if scalar keys %{$account->{public}};
		delete $o->{accounts}->{$key};
	}

	# Remove obsolete objects
	while (my ($key, $entry) = each %{$o->{objects}}) {
		next if $entry->{inUse};
		delete $o->{objects}->{$key};
	}
}

sub markHash {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
			# private
	my $child = $o->{objects}->{$hash->bytes} // return;
	$o->mark($child);
}

sub markEntry {
	my $o = shift;
	my $entry = shift;
			# private
	return if $entry->{inUse};
	$entry->{inUse} = 1;

	# Mark all children
	for my $hash ($entry->{object}->hashes) {
		$o->markHash($hash);
	}
}

package CDS::KeyPair;

sub transfer {
	my $o = shift;
	my $hashes = shift;
	my $sourceStore = shift;
	my $destinationStore = shift;

	for my $hash (@$hashes) {
		my ($missing, $store, $storeError) = $o->recursiveTransfer($hash, $sourceStore, $destinationStore, {});
		return $missing if $missing;
		return undef, $store, $storeError if defined $storeError;
	}

	return;
}

sub recursiveTransfer {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $sourceStore = shift;
	my $destinationStore = shift;
	my $done = shift;
		# private
	return if $done->{$hash->bytes};
	$done->{$hash->bytes} = 1;

	# Book
	my ($booked, $bookError) = $destinationStore->book($hash, $o);
	return undef, $destinationStore, $bookError if defined $bookError;
	return if $booked;

	# Get
	my ($object, $getError) = $sourceStore->get($hash, $o);
	return undef, $sourceStore, $getError if defined $getError;
	return CDS::MissingObject->new($hash, $sourceStore) if ! defined $object;

	# Process children
	for my $child ($object->hashes) {
		my ($missing, $store, $error) = $o->recursiveTransfer($child, $sourceStore, $destinationStore, $done);
		return undef, $store, $error if defined $error;
		if (defined $missing) {
			push @{$missing->{path}}, $child;
			return $missing;
		}
	}

	# Put
	my $putError = $destinationStore->put($hash, $object, $o);
	return undef, $destinationStore, $putError if defined $putError;
	return;
}

sub createPublicEnvelope {
	my $o = shift;
	my $contentHash = shift; die 'wrong type '.ref($contentHash).' for $contentHash' if defined $contentHash && ref $contentHash ne 'CDS::Hash';

	my $envelope = CDS::Record->new;
	$envelope->add('content')->addHash($contentHash);
	$envelope->add('signature')->add($o->signHash($contentHash));
	return $envelope;
}

sub createPrivateEnvelope {
	my $o = shift;
	my $contentHashAndKey = shift;
	my $recipientPublicKeys = shift;

	my $envelope = CDS::Record->new;
	$envelope->add('content')->addHash($contentHashAndKey->hash);
	$o->addRecipientsToEnvelope($envelope, $contentHashAndKey->key, $recipientPublicKeys);
	$envelope->add('signature')->add($o->signHash($contentHashAndKey->hash));
	return $envelope;
}

sub createMessageEnvelope {
	my $o = shift;
	my $storeUrl = shift;
	my $messageRecord = shift; die 'wrong type '.ref($messageRecord).' for $messageRecord' if defined $messageRecord && ref $messageRecord ne 'CDS::Record';
	my $recipientPublicKeys = shift;
	my $expires = shift;

	my $contentRecord = CDS::Record->new;
	$contentRecord->add('store')->addText($storeUrl);
	$contentRecord->add('sender')->addHash($o->publicKey->hash);
	$contentRecord->addRecord($messageRecord->children);
	my $contentObject = $contentRecord->toObject;
	my $contentKey = CDS->randomKey;
	my $encryptedContent = CDS::C::aesCrypt($contentObject->bytes, $contentKey, CDS->zeroCTR);
	#my $hashToSign = $contentObject->calculateHash;	# prior to 2020-05-05
	my $hashToSign = CDS::Hash->calculateFor($encryptedContent);

	my $envelope = CDS::Record->new;
	$envelope->add('content')->add($encryptedContent);
	$o->addRecipientsToEnvelope($envelope, $contentKey, $recipientPublicKeys);
	$envelope->add('updated by')->add(substr($o->publicKey->hash->bytes, 0, 24));
	$envelope->add('expires')->addInteger($expires) if defined $expires;
	$envelope->add('signature')->add($o->signHash($hashToSign));
	return $envelope;
}

sub addRecipientsToEnvelope {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $key = shift;
	my $recipientPublicKeys = shift;
		# private
	my $encryptedKeyRecord = $envelope->add('encrypted for');
	my $myHashBytes24 = substr($o->{publicKey}->hash->bytes, 0, 24);
	$encryptedKeyRecord->add($myHashBytes24)->add($o->{publicKey}->encrypt($key));
	for my $publicKey (@$recipientPublicKeys) {
		next if $publicKey->hash->equals($o->{publicKey}->hash);
		my $hashBytes24 = substr($publicKey->hash->bytes, 0, 24);
		$encryptedKeyRecord->add($hashBytes24)->add($publicKey->encrypt($key));
	}
}

sub generate {
	my $class = shift;

	# Generate a new private key
	my $rsaPrivateKey = CDS::C::privateKeyGenerate();

	# Serialize the public key
	my $rsaPublicKey = CDS::C::publicKeyFromPrivateKey($rsaPrivateKey);
	my $record = CDS::Record->new;
	$record->add('e')->add(CDS::C::publicKeyE($rsaPublicKey));
	$record->add('n')->add(CDS::C::publicKeyN($rsaPublicKey));
	my $publicKey = CDS::PublicKey->fromObject($record->toObject);

	# Return a new CDS::KeyPair instance
	return CDS::KeyPair->new($publicKey, $rsaPrivateKey);
}

sub fromFile {
	my $class = shift;
	my $file = shift;

	my $bytes = CDS->readBytesFromFile($file) // return;
	my $record = CDS::Record->fromObject(CDS::Object->fromBytes($bytes));
	return $class->fromRecord($record);
}

sub fromHex {
	my $class = shift;
	my $hex = shift;

	return $class->fromRecord(CDS::Record->fromObject(CDS::Object->fromBytes(pack 'H*', $hex)));
}

sub fromRecord {
	my $class = shift;
	my $record = shift // return; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my $publicKey = CDS::PublicKey->fromObject(CDS::Object->fromBytes($record->child('public key object')->bytesValue)) // return;
	my $rsaKey = $record->child('rsa key');
	my $e = $rsaKey->child('e')->bytesValue;
	my $p = $rsaKey->child('p')->bytesValue;
	my $q = $rsaKey->child('q')->bytesValue;
	return $class->new($publicKey, CDS::C::privateKeyNew($e, $p, $q) // return);
}

sub new {
	my $class = shift;
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';
	my $rsaPrivateKey = shift;

	return bless {
		publicKey => $publicKey,			# The public key
		rsaPrivateKey => $rsaPrivateKey,	# The private key
		};
}

sub publicKey { shift->{publicKey} }
sub rsaPrivateKey { shift->{rsaPrivateKey} }

### Serialization ###

sub toRecord {
	my $o = shift;

	my $record = CDS::Record->new;
	$record->add('public key object')->add($o->{publicKey}->object->bytes);
	my $rsaKeyRecord = $record->add('rsa key');
	$rsaKeyRecord->add('e')->add(CDS::C::privateKeyE($o->{rsaPrivateKey}));
	$rsaKeyRecord->add('p')->add(CDS::C::privateKeyP($o->{rsaPrivateKey}));
	$rsaKeyRecord->add('q')->add(CDS::C::privateKeyQ($o->{rsaPrivateKey}));
	return $record;
}

sub toHex {
	my $o = shift;

	my $object = $o->toRecord->toObject;
	return unpack('H*', $object->header).unpack('H*', $object->data);
}

sub writeToFile {
	my $o = shift;
	my $file = shift;

	my $object = $o->toRecord->toObject;
	return CDS->writeBytesToFile($file, $object->bytes);
}

### Private key interface ###

sub decrypt {
	my $o = shift;
	my $bytes = shift;
		# decrypt(bytes) -> bytes
	return CDS::C::privateKeyDecrypt($o->{rsaPrivateKey}, $bytes);
}

sub sign {
	my $o = shift;
	my $digest = shift;
		# sign(bytes) -> bytes
	return CDS::C::privateKeySign($o->{rsaPrivateKey}, $digest);
}

sub signHash {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
		# signHash(hash) -> bytes
	return CDS::C::privateKeySign($o->{rsaPrivateKey}, $hash->bytes);
}

### Retrieval ###

# Retrieves an object from one of the stores, and decrypts it.
sub getAndDecrypt {
	my $o = shift;
	my $hashAndKey = shift; die 'wrong type '.ref($hashAndKey).' for $hashAndKey' if defined $hashAndKey && ref $hashAndKey ne 'CDS::HashAndKey';
	my $store = shift;

	my ($object, $error) = $store->get($hashAndKey->hash, $o);
	return undef, undef, $error if defined $error;
	return undef, 'Not found.', undef if ! $object;
	return $object->crypt($hashAndKey->key);
}

# Retrieves an object from one of the stores, and parses it as record.
sub getRecord {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;

	my ($object, $error) = $store->get($hash, $o);
	return undef, undef, undef, $error if defined $error;
	return undef, undef, 'Not found.', undef if ! $object;
	my $record = CDS::Record->fromObject($object) // return undef, undef, 'Not a record.', undef;
	return $record, $object;
}

# Retrieves an object from one of the stores, decrypts it, and parses it as record.
sub getAndDecryptRecord {
	my $o = shift;
	my $hashAndKey = shift; die 'wrong type '.ref($hashAndKey).' for $hashAndKey' if defined $hashAndKey && ref $hashAndKey ne 'CDS::HashAndKey';
	my $store = shift;

	my ($object, $error) = $store->get($hashAndKey->hash, $o);
	return undef, undef, undef, $error if defined $error;
	return undef, undef, 'Not found.', undef if ! $object;
	my $decrypted = $object->crypt($hashAndKey->key);
	my $record = CDS::Record->fromObject($decrypted) // return undef, undef, 'Not a record.', undef;
	return $record, $object;
}

# Retrieves an public key object from one of the stores, and parses its public key.
sub getPublicKey {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;

	my ($object, $error) = $store->get($hash, $o);
	return undef, undef, $error if defined $error;
	return undef, 'Not found.', undef if ! $object;
	return CDS::PublicKey->fromObject($object) // return undef, 'Not a public key.', undef;
}

### Equality ###

sub equals {
	my $this = shift;
	my $that = shift;

	return 1 if ! defined $this && ! defined $that;
	return if ! defined $this || ! defined $that;
	return $this->publicKey->hash->equals($that->publicKey->hash);
}

### Open envelopes ###

sub decryptKeyOnEnvelope {
	my $o = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';

	# Read the AES key
	my $hashBytes24 = substr($o->{publicKey}->hash->bytes, 0, 24);
	my $encryptedAesKey = $envelope->child('encrypted for')->child($hashBytes24)->bytesValue;
	$encryptedAesKey = $envelope->child('encrypted for')->child($o->{publicKey}->hash->bytes)->bytesValue if ! length $encryptedAesKey; # todo: remove this
	return if ! length $encryptedAesKey;

	# Decrypt the AES key
	my $aesKeyBytes = $o->decrypt($encryptedAesKey);
	return if ! $aesKeyBytes || length $aesKeyBytes != 32;

	return $aesKeyBytes;
}

# The result of parsing a KEYPAIR token (see Token.pm).
package CDS::KeyPairToken;

sub new {
	my $class = shift;
	my $file = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return bless {
		file => $file,
		keyPair => $keyPair,
		};
}

sub file { shift->{file} }
sub keyPair { shift->{keyPair} }

package CDS::LoadActorGroup;

sub load {
	my $class = shift;
	my $builder = shift; die 'wrong type '.ref($builder).' for $builder' if defined $builder && ref $builder ne 'CDS::ActorGroupBuilder';
	my $store = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $delegate = shift;

	my $o = bless {
		store => $store,
		keyPair => $keyPair,
		knownPublicKeys => $builder->knownPublicKeys,
		};

	my $members = [];
	for my $member ($builder->members) {
		my $isActive = $member->status eq 'active';
		my $isIdle = $member->status eq 'idle';
		next if ! $isActive && ! $isIdle;

		my ($publicKey, $storeError) = $o->getPublicKey($member->hash);
		return undef, $storeError if defined $storeError;
		next if ! $publicKey;

		my $accountStore = $delegate->onLoadActorGroupVerifyStore($member->storeUrl) // next;
		my $actorOnStore = CDS::ActorOnStore->new($publicKey, $accountStore);
		push @$members, CDS::ActorGroup::Member->new($actorOnStore, $member->storeUrl, $member->revision, $isActive);
	}

	my $entrustedActors = [];
	for my $actor ($builder->entrustedActors) {
		my ($publicKey, $storeError) = $o->getPublicKey($actor->hash);
		return undef, $storeError if defined $storeError;
		next if ! $publicKey;

		my $accountStore = $delegate->onLoadActorGroupVerifyStore($actor->storeUrl) // next;
		my $actorOnStore = CDS::ActorOnStore->new($publicKey, $accountStore);
		push @$entrustedActors, CDS::ActorGroup::EntrustedActor->new($actorOnStore, $actor->storeUrl);
	}

	return CDS::ActorGroup->new($members, $builder->entrustedActorsRevision, $entrustedActors);
}

sub getPublicKey {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $knownPublicKey = $o->{knownPublicKeys}->{$hash->bytes};
	return $knownPublicKey if $knownPublicKey;

	my ($publicKey, $invalidReason, $storeError) = $o->{keyPair}->getPublicKey($hash, $o->{store});
	return undef, $storeError if defined $storeError;
	return if defined $invalidReason;

	$o->{knownPublicKeys}->{$hash->bytes} = $publicKey;
	return $publicKey;
};

# A store that prints all accesses to a filehandle (STDERR by default).
package CDS::LogStore;

use parent -norequire, 'CDS::Store';

sub new {
	my $class = shift;
	my $store = shift;
	my $fileHandle = shift // *STDERR;
	my $prefix = shift // '';

	return bless {
		id => "Log Store\n".$store->id,
		store => $store,
		fileHandle => $fileHandle,
		prefix => '',
		};
}

sub id { shift->{id} }
sub store { shift->{store} }
sub fileHandle { shift->{fileHandle} }
sub prefix { shift->{prefix} }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my ($object, $error) = $o->{store}->get($hash, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('get', $hash->shortHex, defined $object ? &formatByteLength($object->byteLength).' bytes' : defined $error ? 'failed: '.$error : 'not found', $elapsed);
	return $object, $error;
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my $error = $o->{store}->put($hash, $object, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('put', $hash->shortHex . ' ' . &formatByteLength($object->byteLength) . ' bytes', defined $error ? 'failed: '.$error : 'OK', $elapsed);
	return $error;
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my ($booked, $error) = $o->{store}->book($hash, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('book', $hash->shortHex, defined $booked ? 'OK' : defined $error ? 'failed: '.$error : 'not found', $elapsed);
	return $booked, $error;
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my ($hashes, $error) = $o->{store}->list($accountHash, $boxLabel, $timeout, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('list', $accountHash->shortHex . ' ' . $boxLabel . ($timeout ? ' ' . $timeout . ' s' : ''), defined $hashes ? scalar(@$hashes).' entries' : 'failed: '.$error, $elapsed);
	return $hashes, $error;
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my $error = $o->{store}->add($accountHash, $boxLabel, $hash, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('add', $accountHash->shortHex . ' ' . $boxLabel . ' ' . $hash->shortHex, defined $error ? 'failed: '.$error : 'OK', $elapsed);
	return $error;
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my $error = $o->{store}->remove($accountHash, $boxLabel, $hash, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('remove', $accountHash->shortHex . ' ' . $boxLabel . ' ' . $hash->shortHex, defined $error ? 'failed: '.$error : 'OK', $elapsed);
	return $error;
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $start = CDS::C::performanceStart();
	my $error = $o->{store}->modify($modifications, $keyPair);
	my $elapsed = CDS::C::performanceElapsed($start);
	$o->log('modify', scalar(keys %{$modifications->objects}) . ' objects ' . scalar @{$modifications->additions} . ' additions ' . scalar @{$modifications->removals} . ' removals', defined $error ? 'failed: '.$error : 'OK', $elapsed);
	return $error;
}

sub log {
	my $o = shift;
	my $cmd = shift;
	my $input = shift;
	my $output = shift;
	my $elapsed = shift;

	my $fh = $o->{fileHandle} // return;
	print $fh $o->{prefix}, &left(8, $cmd), &left(40, $input), ' => ', &left(40, $output), &formatDuration($elapsed), ' us', "\n";
}

sub left {
	my $width = shift;
	my $text = shift;
		# private
	return $text . (' ' x ($width - length $text)) if length $text < $width;
	return $text;
}

sub formatByteLength {
	my $byteLength = shift;
		# private
	my $s = ''.$byteLength;
	$s = ' ' x (9 - length $s) . $s if length $s < 9;
	my $len = length $s;
	return substr($s, 0, $len - 6).' '.substr($s, $len - 6, 3).' '.substr($s, $len - 3, 3);
}

sub formatDuration {
	my $elapsed = shift;
		# private
	my $s = ''.$elapsed;
	$s = ' ' x (9 - length $s) . $s if length $s < 9;
	my $len = length $s;
	return substr($s, 0, $len - 6).' '.substr($s, $len - 6, 3).' '.substr($s, $len - 3, 3);
}

# Reads the message box of an actor.
package CDS::MessageBoxReader;

sub new {
	my $class = shift;
	my $pool = shift;
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $streamTimeout = shift;

	return bless {
		pool => $pool,
		actorOnStore => $actorOnStore,
		streamCache => CDS::StreamCache->new($pool, $actorOnStore, $streamTimeout // CDS->MINUTE),
		entries => {},
		};
}

sub pool { shift->{pool} }
sub actorOnStore { shift->{actorOnStore} }

sub read {
	my $o = shift;
	my $timeout = shift // 0;

	my $store = $o->{actorOnStore}->store;
	my ($hashes, $listError) = $store->list($o->{actorOnStore}->publicKey->hash, 'messages', $timeout, $o->{pool}->{keyPair});
	return if defined $listError;

	for my $hash (@$hashes) {
		my $entry = $o->{entries}->{$hash->bytes};
		$o->{entries}->{$hash->bytes} = $entry = CDS::MessageBoxReader::Entry->new($hash) if ! $entry;
		next if $entry->{processed};

		# Check the sender store, if necessary
		if ($entry->{waitingForStore}) {
			my ($dummy, $checkError) = $entry->{waitingForStore}->get(CDS->emptyBytesHash, $o->{pool}->{keyPair});
			next if defined $checkError;
		}

		# Get the envelope
		my ($object, $getError) = $o->{actorOnStore}->store->get($entry->{hash}, $o->{pool}->{keyPair});
		return if defined $getError;

		# Mark the entry as processed
		$entry->{processed} = 1;

		if (! defined $object) {
			$o->invalid($entry, 'Envelope object not found.');
			next;
		}

		# Parse the record
		my $envelope = CDS::Record->fromObject($object);
		if (! $envelope) {
			$o->invalid($entry, 'Envelope is not a record.');
			next;
		}

		my $message =
			$envelope->contains('head') && $envelope->contains('mac') ?
				$o->readStreamMessage($entry, $envelope) :
				$o->readNormalMessage($entry, $envelope);
		next if ! $message;

		$o->{pool}->{delegate}->onMessageBoxEntry($message);
	}

	$o->{streamCache}->removeObsolete;
	return 1;
}

sub readNormalMessage {
	my $o = shift;
	my $entry = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
		# private
	# Read the embedded content object
	my $encryptedBytes = $envelope->child('content')->bytesValue;
	return $o->invalid($entry, 'Missing content object.') if ! length $encryptedBytes;

	# Decrypt the key
	my $aesKey = $o->{pool}->{keyPair}->decryptKeyOnEnvelope($envelope);
	return $o->invalid($entry, 'Not encrypted for us.') if ! $aesKey;

	# Decrypt the content
	my $contentObject = CDS::Object->fromBytes(CDS::C::aesCrypt($encryptedBytes, $aesKey, CDS->zeroCTR));
	return $o->invalid($entry, 'Invalid content object.') if ! $contentObject;

	my $content = CDS::Record->fromObject($contentObject);
	return $o->invalid($entry, 'Content object is not a record.') if ! $content;

	# Verify the sender hash
	my $senderHash = $content->child('sender')->hashValue;
	return $o->invalid($entry, 'Missing sender hash.') if ! $senderHash;

	# Verify the sender store
	my $storeRecord = $content->child('store');
	return $o->invalid($entry, 'Missing sender store.') if ! scalar $storeRecord->children;

	my $senderStoreUrl = $storeRecord->textValue;
	my $senderStore = $o->{pool}->{delegate}->onMessageBoxVerifyStore($senderStoreUrl, $entry->{hash}, $envelope, $senderHash);
	return $o->invalid($entry, 'Invalid sender store.') if ! $senderStore;

	# Retrieve the sender's public key
	my ($senderPublicKey, $invalidReason, $publicKeyStoreError) = $o->getPublicKey($senderHash, $senderStore);
	return if defined $publicKeyStoreError;
	return $o->invalid($entry, 'Failed to retrieve the sender\'s public key: '.$invalidReason) if defined $invalidReason;

	# Verify the signature
	my $signedHash = CDS::Hash->calculateFor($encryptedBytes);
	if (! CDS->verifyEnvelopeSignature($envelope, $senderPublicKey, $signedHash)) {
		# For backwards compatibility with versions before 2020-05-05
		return $o->invalid($entry, 'Invalid signature.') if ! CDS->verifyEnvelopeSignature($envelope, $senderPublicKey, $contentObject->calculateHash);
	}

	# The envelope is valid
	my $sender = CDS::ActorOnStore->new($senderPublicKey, $senderStore);
	my $source = CDS::Source->new($o->{pool}->{keyPair}, $o->{actorOnStore}, 'messages', $entry->{hash});
	return CDS::ReceivedMessage->new($o, $entry, $source, $envelope, $senderStoreUrl, $sender, $content);
}

sub readStreamMessage {
	my $o = shift;
	my $entry = shift;
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
		# private
	# Get the head
	my $head = $envelope->child('head')->hashValue;
	return $o->invalid($entry, 'Invalid head message hash.') if ! $head;

	# Get the head envelope
	my $streamHead = $o->{streamCache}->readStreamHead($head);
	return if ! $streamHead;
	return $o->invalid($entry, 'Invalid stream head: '.$streamHead->error) if $streamHead->error;

	# Read the embedded content object
	my $encryptedBytes = $envelope->child('content')->bytesValue;
	return $o->invalid($entry, 'Missing content object.') if ! length $encryptedBytes;

	# Get the CTR
	my $ctr = $envelope->child('ctr')->bytesValue;
	return $o->invalid($entry, 'Invalid CTR.') if length $ctr != 16;

	# Get the MAC
	my $mac = $envelope->child('mac')->bytesValue;
	return $o->invalid($entry, 'Invalid MAC.') if ! $mac;

	# Verify the MAC
	my $signedHash = CDS::Hash->calculateFor($encryptedBytes);
	my $expectedMac = CDS::C::aesCrypt($signedHash->bytes, $streamHead->aesKey, $ctr);
	return $o->invalid($entry, 'Invalid MAC.') if $mac ne $expectedMac;

	# Decrypt the content
	my $contentObject = CDS::Object->fromBytes(CDS::C::aesCrypt($encryptedBytes, $streamHead->aesKey, CDS::C::counterPlusInt($ctr, 2)));
	return $o->invalid($entry, 'Invalid content object.') if ! $contentObject;

	my $content = CDS::Record->fromObject($contentObject);
	return $o->invalid($entry, 'Content object is not a record.') if ! $content;

	# The envelope is valid
	my $source = CDS::Source->new($o->{pool}->{keyPair}, $o->{actorOnStore}, 'messages', $entry->{hash});
	return CDS::ReceivedMessage->new($o, $entry, $source, $envelope, $streamHead->senderStoreUrl, $streamHead->sender, $content, $streamHead);
}

sub invalid {
	my $o = shift;
	my $entry = shift;
	my $reason = shift;
		# private
	my $source = CDS::Source->new($o->{pool}->{keyPair}, $o->{actorOnStore}, 'messages', $entry->{hash});
	$o->{pool}->{delegate}->onMessageBoxInvalidEntry($source, $reason);
}

sub getPublicKey {
	my $o = shift;
	my $senderHash = shift; die 'wrong type '.ref($senderHash).' for $senderHash' if defined $senderHash && ref $senderHash ne 'CDS::Hash';
	my $senderStore = shift;
	my $senderStoreUrl = shift;
		# private
	# Use the account key if sender and recipient are the same
	return $o->{actorOnStore}->publicKey if $senderHash->equals($o->{actorOnStore}->publicKey->hash);

	# Reuse a cached public key
	my $cachedPublicKey = $o->{pool}->{publicKeyCache}->get($senderHash);
	return $cachedPublicKey if $cachedPublicKey;

	# Retrieve the sender's public key from the sender's store
	my ($publicKey, $invalidReason, $storeError) = $o->{pool}->{keyPair}->getPublicKey($senderHash, $senderStore);
	return undef, undef, $storeError if defined $storeError;
	return undef, $invalidReason if defined $invalidReason;
	$o->{pool}->{publicKeyCache}->add($publicKey);
	return $publicKey;
}

package CDS::MessageBoxReader::Entry;

sub new {
	my $class = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	return bless {
		hash => $hash,
		processed => 0,
		};
}

package CDS::MessageBoxReaderPool;

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $publicKeyCache = shift;
	my $delegate = shift;

	return bless {
		keyPair => $keyPair,
		publicKeyCache => $publicKeyCache,
		delegate => $delegate,
		};
}

sub keyPair { shift->{keyPair} }
sub publicKeyCache { shift->{publicKeyCache} }

# Delegate
# onMessageBoxVerifyStore($senderStoreUrl, $hash, $envelope, $senderHash)
# onMessageBoxEntry($receivedMessage)
# onMessageBoxStream($receivedMessage)
# onMessageBoxInvalidEntry($source, $reason)

package CDS::MessageChannel;

sub new {
	my $class = shift;
	my $actor = shift;
	my $label = shift;
	my $validity = shift;

	my $o = bless {
		actor => $actor,
		label => $label,
		validity => $validity,
		};

	$o->{unsaved} = CDS::Unsaved->new($actor->sentList->unsaved);
	$o->{transfers} = [];
	$o->{recipients} = [];
	$o->{entrustedKeys} = [];
	$o->{obsoleteHashes} = {};
	$o->{currentSubmissionId} = 0;
	return $o;
}

sub actor { shift->{actor} }
sub label { shift->{label} }
sub validity { shift->{validity} }
sub unsaved { shift->{unsaved} }
sub item {
	my $o = shift;
	 $o->{actor}->sentList->getOrCreate($o->{label}) }
sub recipients {
	my $o = shift;
	 @{$o->{recipients}} }
sub entrustedKeys {
	my $o = shift;
	 @{$o->{entrustedKeys}} }

sub addObject {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	$o->{unsaved}->state->addObject($hash, $object);
}

sub addTransfer {
	my $o = shift;
	my $hashes = shift;
	my $sourceStore = shift;
	my $context = shift;

	return if ! scalar @$hashes;
	push @{$o->{transfers}}, {hashes => $hashes, sourceStore => $sourceStore, context => $context};
}

sub setRecipientActorGroup {
	my $o = shift;
	my $actorGroup = shift; die 'wrong type '.ref($actorGroup).' for $actorGroup' if defined $actorGroup && ref $actorGroup ne 'CDS::ActorGroup';

	$o->{recipients} = [map { $_->actorOnStore } $actorGroup->members];
	$o->{entrustedKeys} = [map { $_->actorOnStore->publicKey } $actorGroup->entrustedActors];
}

sub setRecipients {
	my $o = shift;
	my $recipients = shift;
	my $entrustedKeys = shift;

	$o->{recipients} = $recipients;
	$o->{entrustedKeys} = $entrustedKeys;
}

sub submit {
	my $o = shift;
	my $message = shift;
	my $done = shift;

	# Check if the sent list has been loaded
	return if ! $o->{actor}->sentListReady;

	# Transfer
	my $transfers = $o->{transfers};
	$o->{transfers} = [];
	for my $transfer (@$transfers) {
		my ($missingObject, $store, $error) = $o->{actor}->keyPair->transfer($transfer->{hashes}, $transfer->{sourceStore}, $o->{actor}->messagingPrivateRoot->unsaved);
		return if defined $error;

		if ($missingObject) {
			$missingObject->{context} = $transfer->{context};
			return undef, $missingObject;
		}
	}

	# Send the message
	return CDS::MessageChannel::Submission->new($o, $message, $done);
}

sub clear {
	my $o = shift;

	$o->item->clear(CDS->now + $o->{validity});
}

package CDS::MessageChannel::Submission;

sub new {
	my $class = shift;
	my $channel = shift;
	my $message = shift;
	my $done = shift;

	$channel->{currentSubmissionId} += 1;

	my $o = bless {
		channel => $channel,
		message => $message,
		done => $done,
		submissionId => $channel->{currentSubmissionId},
		recipients => [$channel->recipients],
		entrustedKeys => [$channel->entrustedKeys],
		expires => CDS->now + $channel->validity,
		};

	# Add the current envelope hash to the obsolete hashes
	my $item = $channel->item;
	$channel->{obsoleteHashes}->{$item->envelopeHash->bytes} = $item->envelopeHash if $item->envelopeHash;
	$o->{obsoleteHashesSnapshot} = [values %{$channel->{obsoleteHashes}}];

	# Create an envelope
	my $publicKeys = [];
	push @$publicKeys, $channel->{actor}->keyPair->publicKey;
	push @$publicKeys, map { $_->publicKey } @{$o->{recipients}};
	push @$publicKeys, @{$o->{entrustedKeys}};
	$o->{envelopeObject} = $channel->{actor}->keyPair->createMessageEnvelope($channel->{actor}->messagingStoreUrl, $message, $publicKeys, $o->{expires})->toObject;
	$o->{envelopeHash} = $o->{envelopeObject}->calculateHash;

	# Set the new item and wait until it gets saved
	$channel->{unsaved}->startSaving;
	$channel->{unsaved}->savingState->addDataSavedHandler($o);
	$channel->{actor}->sentList->unsaved->state->merge($channel->{unsaved}->savingState);
	$item->set($o->{expires}, $o->{envelopeHash}, $message);
	$channel->{unsaved}->savingDone;

	return $o;
}

sub channel { shift->{channel} }
sub message { shift->{message} }
sub recipients {
	my $o = shift;
	 @{$o->{recipients}} }
sub entrustedKeys {
	my $o = shift;
	 @{$o->{entrustedKeys}} }
sub expires { shift->{expires} }
sub envelopeObject { shift->{envelopeObject} }
sub envelopeHash { shift->{envelopeHash} }

sub onDataSaved {
	my $o = shift;

	# If we are not the head any more, give up
	return $o->{done}->onMessageChannelSubmissionCancelled if $o->{submissionId} != $o->{channel}->{currentSubmissionId};
	$o->{channel}->{obsoleteHashes}->{$o->{envelopeHash}->bytes} = $o->{envelopeHash};

	# Process all recipients
	my $succeeded = 0;
	my $failed = 0;
	for my $recipient (@{$o->{recipients}}) {
		my $modifications = CDS::StoreModifications->new;

		# Prepare the list of removals
		my $removals = [];
		for my $hash (@{$o->{obsoleteHashesSnapshot}}) {
			$modifications->remove($recipient->publicKey->hash, 'messages', $hash);
		}

		# Add the message entry
		$modifications->add($recipient->publicKey->hash, 'messages', $o->{envelopeHash}, $o->{envelopeObject});
		my $error = $recipient->store->modify($modifications, $o->{channel}->{actor}->keyPair);

		if (defined $error) {
			$failed += 1;
			$o->{done}->onMessageChannelSubmissionRecipientFailed($recipient, $error);
		} else {
			$succeeded += 1;
			$o->{done}->onMessageChannelSubmissionRecipientDone($recipient);
		}
	}

	if ($failed == 0 || scalar keys %{$o->{obsoleteHashes}} > 64) {
		for my $hash (@{$o->{obsoleteHashesSnapshot}}) {
			delete $o->{channel}->{obsoleteHashes}->{$hash->bytes};
		}
	}

	$o->{done}->onMessageChannelSubmissionDone($succeeded, $failed);
}

package CDS::MissingObject;

sub new {
	my $class = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $store = shift;

	return bless {hash => $hash, store => $store, path => [], context => undef};
}

sub hash { shift->{hash} }
sub store { shift->{store} }
sub path {
	my $o = shift;
	 @{$o->{path}} }
sub context { shift->{context} }

package CDS::NewAnnounce;

sub new {
	my $class = shift;
	my $messagingStore = shift;

	my $o = bless {
		messagingStore => $messagingStore,
		unsaved => CDS::Unsaved->new($messagingStore->store),
		transfers => [],
		card => CDS::Record->new,
		};

	my $publicKey = $messagingStore->actor->keyPair->publicKey;
	$o->{card}->add('public key')->addHash($publicKey->hash);
	$o->addObject($publicKey->hash, $publicKey->object);
	return $o;
}

sub messagingStore { shift->{messagingStore} }
sub card { shift->{card} }

sub addObject {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	$o->{unsaved}->state->addObject($hash, $object);
}

sub addTransfer {
	my $o = shift;
	my $hashes = shift;
	my $sourceStore = shift;
	my $context = shift;

	return if ! scalar @$hashes;
	push @{$o->{transfers}}, {hashes => $hashes, sourceStore => $sourceStore, context => $context};
}

sub addActorGroup {
	my $o = shift;
	my $actorGroupBuilder = shift;

	$actorGroupBuilder->addToRecord($o->{card}, 0);
}

sub submit {
	my $o = shift;

	my $keyPair = $o->{messagingStore}->actor->keyPair;

	# Create the public card
	my $cardObject = $o->{card}->toObject;
	my $cardHash = $cardObject->calculateHash;
	$o->addObject($cardHash, $cardObject);

	# Prepare the public envelope
	my $me = $keyPair->publicKey->hash;
	my $envelopeObject = $keyPair->createPublicEnvelope($cardHash)->toObject;
	my $envelopeHash = $envelopeObject->calculateHash;
	$o->addTransfer([$cardHash], $o->{unsaved}, 'Announcing');

	# Transfer all trees
	for my $transfer (@{$o->{transfers}}) {
		my ($missingObject, $store, $error) = $keyPair->transfer($transfer->{hashes}, $transfer->{sourceStore}, $o->{messagingStore}->store);
		return if defined $error;

		if ($missingObject) {
			$missingObject->{context} = $transfer->{context};
			return undef, $missingObject;
		}
	}

	# Prepare a modification
	my $modifications = CDS::StoreModifications->new;
	$modifications->add($me, 'public', $envelopeHash, $envelopeObject);

	# List the current cards to remove them
	# Ignore errors, in the worst case, we are going to have multiple entries in the public box
	my ($hashes, $error) = $o->{messagingStore}->store->list($me, 'public', 0, $keyPair);
	if ($hashes) {
		for my $hash (@$hashes) {
			$modifications->remove($me, 'public', $hash);
		}
	}

	# Modify the public box
	my $modifyError = $o->{messagingStore}->store->modify($modifications, $keyPair);
	return if defined $modifyError;
	return $envelopeHash, $cardHash;
}

package CDS::NewMessagingStore;

sub new {
	my $class = shift;
	my $actor = shift;
	my $store = shift;

	return bless {
		actor => $actor,
		store => $store,
		};
}

sub actor { shift->{actor} }
sub store { shift->{store} }

# A Condensation object.
# A valid object starts with a 4-byte length (big-endian), followed by 32 * length bytes of hashes, followed by 0 or more bytes of data.
package CDS::Object;

sub emptyHeader { "\0\0\0\0" }

sub create {
	my $class = shift;
	my $header = shift;
	my $data = shift;

	return if length $header < 4;
	my $hashesCount = unpack('L>', substr($header, 0, 4));
	return if length $header != 4 + $hashesCount * 32;
	return bless {
		bytes => $header.$data,
		hashesCount => $hashesCount,
		header => $header,
		data => $data
		};
}

sub fromBytes {
	my $class = shift;
	my $bytes = shift // return;

	return if length $bytes < 4;

	my $hashesCount = unpack 'L>', substr($bytes, 0, 4);
	my $dataStart = $hashesCount * 32 + 4;
	return if $dataStart > length $bytes;

	return bless {
		bytes => $bytes,
		hashesCount => $hashesCount,
		header => substr($bytes, 0, $dataStart),
		data => substr($bytes, $dataStart)
		};
}

sub fromFile {
	my $class = shift;
	my $file = shift;

	return $class->fromBytes(CDS->readBytesFromFile($file));
}

sub bytes { shift->{bytes} }
sub header { shift->{header} }
sub data { shift->{data} }
sub hashesCount { shift->{hashesCount} }
sub byteLength {
	my $o = shift;
	 length($o->{header}) + length($o->{data}) }

sub calculateHash {
	my $o = shift;

	return CDS::Hash->calculateFor($o->{bytes});
}

sub hashes {
	my $o = shift;

	return map { CDS::Hash->fromBytes(substr($o->{header}, $_ * 32 + 4, 32)) } 0 .. $o->{hashesCount} - 1;
}

sub hashAtIndex {
	my $o = shift;
	my $index = shift // return;

	return if $index < 0 || $index >= $o->{hashesCount};
	return CDS::Hash->fromBytes(substr($o->{header}, $index * 32 + 4, 32));
}

sub crypt {
	my $o = shift;
	my $key = shift;

	return CDS::Object->create($o->{header}, CDS::C::aesCrypt($o->{data}, $key, CDS->zeroCTR));
}

sub writeToFile {
	my $o = shift;
	my $file = shift;

	return CDS->writeBytesToFile($file, $o->{bytes});
}

# A store using a cache store to deliver frequently accessed objects faster, and a backend store.
package CDS::ObjectCache;

use parent -norequire, 'CDS::Store';

sub new {
	my $class = shift;
	my $backend = shift;
	my $cache = shift;

	return bless {
		id => "Object Cache\n".$backend->id."\n".$cache->id,
		backend => $backend,
		cache => $cache,
		};
}

sub id { shift->{id} }
sub backend { shift->{backend} }
sub cache { shift->{cache} }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $objectFromCache = $o->{cache}->get($hash);
	return $objectFromCache if $objectFromCache;

	my ($object, $error) = $o->{backend}->get($hash, $keyPair);
	return undef, $error if ! defined $object;
	$o->{cache}->put($hash, $object, undef);
	return $object;
}

sub put {
	my $o = shift;

	# The important thing is that the backend succeeds. The cache is a nice-to-have.
	$o->{cache}->put(@_);
	return $o->{backend}->put(@_);
}

sub book {
	my $o = shift;

	# The important thing is that the backend succeeds. The cache is a nice-to-have.
	$o->{cache}->book(@_);
	return $o->{backend}->book(@_);
}

sub list {
	my $o = shift;

	# Just pass this through to the backend.
	return $o->{backend}->list(@_);
}

sub add {
	my $o = shift;

	# Just pass this through to the backend.
	return $o->{backend}->add(@_);
}

sub remove {
	my $o = shift;

	# Just pass this through to the backend.
	return $o->{backend}->remove(@_);
}

sub modify {
	my $o = shift;

	# Just pass this through to the backend.
	return $o->{backend}->modify(@_);
}

# The result of parsing an OBJECTFILE token (see Token.pm).
package CDS::ObjectFileToken;

sub new {
	my $class = shift;
	my $file = shift;
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	return bless {
		file => $file,
		object => $object,
		};
}

sub file { shift->{file} }
sub object { shift->{object} }

# The result of parsing an OBJECT token.
package CDS::ObjectToken;

sub new {
	my $class = shift;
	my $cliStore = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	return bless {
		cliStore => $cliStore,
		hash => $hash,
		};
}

sub cliStore { shift->{cliStore} }
sub hash { shift->{hash} }
sub url {
	my $o = shift;
	 $o->{cliStore}->url.'/objects/'.$o->{hash}->hex }

package CDS::Parser;

sub new {
	my $class = shift;
	my $actor = shift;
	my $command = shift;

	my $start = CDS::Parser::Node->new(0);
	return bless {
		actor => $actor,
		ui => $actor->ui,
		start => $start,
		states => [CDS::Parser::State->new($start)],
		command => $command,
		};
}

sub actor { shift->{actor} }
sub start { shift->{start} }

sub execute {
	my $o = shift;

	my $processed = [$o->{command}];
	for my $arg (@_) {
		return $o->howToContinue($processed) if $arg eq '?';
		return $o->explain if $arg eq '??';
		my $token = CDS::Parser::Token->new($o->{actor}, $arg);
		$o->advance($token);
		return $o->invalid($processed, $token) if ! scalar @{$o->{states}};
		push @$processed, $arg;
	}

	my @results = grep { $_->runHandler } @{$o->{states}};
	return $o->howToContinue($processed) if ! scalar @results;

	my $maxWeight = 0;
	for my $result (@results) {
		$maxWeight = $result->cumulativeWeight if $maxWeight < $result->cumulativeWeight;
	}

	@results = grep { $_->cumulativeWeight == $maxWeight } @results;
	return $o->ambiguous if scalar @results > 1;

	my $result = shift @results;
	my $handler = $result->runHandler;
	my $instance = &{$handler->{constructor}}(undef, $o->{actor});
	&{$handler->{function}}($instance, $result);
}

sub advance {
	my $o = shift;
	my $token = shift;

	$o->{previousStates} = $o->{states};
	$o->{states} = [];
	for my $state (@{$o->{previousStates}}) {
		push @{$o->{states}}, $state->advance($token);
	}
}

sub showCompletions {
	my $o = shift;
	my $cmd = shift;

	# Parse the command line
	my $state = '';
	my $arg = '';
	my @args;
	for my $c (split //, $cmd) {
		if ($state eq '') {
			if ($c eq ' ') {
				push @args, $arg if length $arg;
				$arg = '';
			} elsif ($c eq '\'') {
				push @args, $arg if length $arg;
				$arg = '';
				$state = '\'';
			} elsif ($c eq '"') {
				push @args, $arg if length $arg;
				$arg = '';
				$state = '"';
			} elsif ($c eq '\\') {
				$state = '\\';
			} else {
				$arg .= $c;
			}
		} elsif ($state eq '\\') {
			$arg .= $c;
			$state = '';
		} elsif ($state eq '\'') {
			if ($c eq '\'') {
				push @args, $arg if length $arg;
				$arg = '';
				$state = '';
			} else {
				$arg .= $c;
			}
		} elsif ($state eq '"') {
			if ($c eq '"') {
				push @args, $arg if length $arg;
				$arg = '';
				$state = '';
			} elsif ($c eq '\\') {
				$state = '"\\';
			} else {
				$arg .= $c;
			}
		} elsif ($state eq '\\"') {
			$arg .= $c;
			$state = '"';
		}
	}

	# Use the last token to complete
	my $lastToken = CDS::Parser::Token->new($o->{actor}, $arg);

	# Look for possible states
	shift @args;
	for my $arg (@args) {
		return if $arg eq '?';
		$o->advance(CDS::Parser::Token->new($o->{actor}, $arg));
	}

	# Complete the last token
	my %possibilities;
	for my $state (@{$o->{states}}) {
		for my $possibility ($state->complete($lastToken)) {
			$possibilities{$possibility} = 1;
		}
	}

	# Print all possibilities
	for my $possibility (keys %possibilities) {
		print $possibility, "\n";
	}
}

sub ambiguous {
	my $o = shift;

	$o->{ui}->space;
	$o->{ui}->pRed('Your query is ambiguous. This is an error in the command grammar.');
	$o->explain;
}

sub explain {
	my $o = shift;

	for my $interpretation (sort { $b->cumulativeWeight <=> $a->cumulativeWeight || $b->isExecutable <=> $a->isExecutable } @{$o->{states}}) {
		$o->{ui}->space;
		$o->{ui}->title('Interpretation with weight ', $interpretation->cumulativeWeight, $interpretation->isExecutable ? $o->{ui}->green(' (executable)') : $o->{ui}->orange(' (incomplete)'));
		$o->showTuples($interpretation->path);
	}

	$o->{ui}->space;
}

sub showTuples {
	my $o = shift;

	for my $state (@_) {
		my $label = $state->label;
		my $value = $state->value;

		my $valueRef = ref $value;
		my $valueText =
			$valueRef eq '' ? $value // '' :
			$valueRef eq 'CDS::Hash' ? $value->hex :
			$valueRef eq 'CDS::ErrorHandlingStore' ? $value->url :
			$valueRef eq 'CDS::AccountToken' ? $value->actorHash->hex . ' on ' . $value->cliStore->url :
				$valueRef;
		$o->{ui}->line($o->{ui}->left(12, $label), $state->collectHandler ? $valueText : $o->{ui}->gray($valueText));
	}
}

sub cmd {
	my $o = shift;
	my $processed = shift;

	my $cmd = join(' ', map { $_ =~ s/(\\|'|")/\\$1/g ; $_ } @$processed);
	$cmd = '…'.substr($cmd, length($cmd) - 20, 20) if length $cmd > 30;
	return $cmd;
}

sub howToContinue {
	my $o = shift;
	my $processed = shift;

	my $cmd = $o->cmd($processed);
	#$o->displayWarnings($o->{states});
	$o->{ui}->space;
	for my $possibility (CDS::Parser::Continuations->collect($o->{states})) {
		$o->{ui}->line($o->{ui}->gray($cmd), $possibility);
	}
	$o->{ui}->space;
}

sub invalid {
	my $o = shift;
	my $processed = shift;
	my $invalid = shift;

	my $cmd = $o->cmd($processed);
	$o->displayWarnings($o->{previousStates});
	$o->{ui}->space;

	$o->{ui}->line($o->{ui}->gray($cmd), ' ', $o->{ui}->red($invalid->{text}));
	if (scalar @{$invalid->{warnings}}) {
		for my $warning (@{$invalid->{warnings}}) {
			$o->{ui}->warning($warning);
		}
	}

	$o->{ui}->space;
	$o->{ui}->title('Possible continuations');
	for my $possibility (CDS::Parser::Continuations->collect($o->{previousStates})) {
		$o->{ui}->line($o->{ui}->gray($cmd), $possibility);
	}
	$o->{ui}->space;
}

sub displayWarnings {
	my $o = shift;
	my $states = shift;

	for my $state (@$states) {
		my $current = $state;
		while ($current) {
			for my $warning (@{$current->{warnings}}) {
				$o->{ui}->warning($warning);
			}
			$current = $current->{previous};
		}
	}
}

# An arrow points from one node to another. The arrow is taken in State::advance if the next argument matches to the label.
package CDS::Parser::Arrow;

sub new {
	my $class = shift;
	my $node = shift;
	my $official = shift;
	my $weight = shift;
	my $label = shift;
	my $handler = shift;

	return bless {
		node => $node,				# target node
		official => $official,		# whether to show this arrow with '?'
		weight => $weight,			# weight
		label => $label,			# label
		handler => $handler,		# handler to invoke if we take this arrow
		};
}

package CDS::Parser::Continuations;

sub collect {
	my $class = shift;
	my $states = shift;

	my $o = bless {possibilities => {}};

	my $visitedNodes = {};
	for my $state (@$states) {
		$o->visit($visitedNodes, $state->node, '');
	}

	for my $possibility (keys %{$o->{possibilities}}) {
		delete $o->{possibilities}->{$possibility} if exists $o->{possibilities}->{$possibility.' …'};
	}

	return sort keys %{$o->{possibilities}};
}

sub visit {
	my $o = shift;
	my $visitedNodes = shift;
	my $node = shift;
	my $text = shift;

	$visitedNodes->{$node} = 1;

	my $arrows = [];
	$node->collectArrows($arrows);

	for my $arrow (@$arrows) {
		next if ! $arrow->{official};

		my $text = $text.' '.$arrow->{label};
		$o->{possibilities}->{$text} = 1 if $arrow->{node}->hasHandler;
		if ($arrow->{node}->endProposals || exists $visitedNodes->{$arrow->{node}}) {
			$o->{possibilities}->{$text . ($o->canContinue($arrow->{node}) ? ' …' : '')} = 1;
			next;
		}

		$o->visit($visitedNodes, $arrow->{node}, $text);
	}

	delete $visitedNodes->{$node};
}

sub canContinue {
	my $o = shift;
	my $node = shift;

	my $arrows = [];
	$node->collectArrows($arrows);

	for my $arrow (@$arrows) {
		next if ! $arrow->{official};
		return 1;
	}

	return;
}

# Nodes and arrows define the graph on which the parse state can move.
package CDS::Parser::Node;

sub new {
	my $class = shift;
	my $endProposals = shift;
	my $handler = shift;

	return bless {
		arrows => [],					# outgoing arrows
		defaults => [],					# default nodes, at which the current state could be as well
		endProposals => $endProposals,	# if set, the proposal search algorithm stops at this node
		handler => $handler,			# handler to be executed if parsing ends here
		};
}

sub endProposals { shift->{endProposals} }

# Adds an arrow.
sub addArrow {
	my $o = shift;
	my $to = shift;
	my $official = shift;
	my $weight = shift;
	my $label = shift;
	my $handler = shift;

	push @{$o->{arrows}}, CDS::Parser::Arrow->new($to, $official, $weight, $label, $handler);
}

# Adds a default node.
sub addDefault {
	my $o = shift;
	my $node = shift;

	push @{$o->{defaults}}, $node;
}

sub collectArrows {
	my $o = shift;
	my $arrows = shift;

	push @$arrows, @{$o->{arrows}};
	for my $default (@{$o->{defaults}}) { $default->collectArrows($arrows); }
}

sub hasHandler {
	my $o = shift;

	return 1 if $o->{handler};
	for my $default (@{$o->{defaults}}) { return 1 if $default->hasHandler; }
	return;
}

sub getHandler {
	my $o = shift;

	return $o->{handler} if $o->{handler};
	for my $default (@{$o->{defaults}}) {
		my $handler = $default->getHandler // next;
		return $handler;
	}
	return;
}

# A parser state denotes a possible current state (after having parsed a certain number of arguments).
# A parser keeps track of multiple states. When advancing, a state may disappear (if no possibility exists), or fan out (if multiple possibilities exist).
# A state is immutable.
package CDS::Parser::State;

sub new {
	my $class = shift;
	my $node = shift;
	my $previous = shift;
	my $arrow = shift;
	my $value = shift;
	my $warnings = shift;

	return bless {
		node => $node,			# current node
		previous => $previous,	# previous state
		arrow => $arrow,		# the arrow we took to get here
		value => $value,		# the value we collected with the last arrow
		warnings => $warnings,	# the warnings we collected with the last arrow
		cumulativeWeight => ($previous ? $previous->cumulativeWeight : 0) + ($arrow ? $arrow->{weight} : 0),	# the weight we collected until here
		};
}

sub node { shift->{node} }
sub runHandler {
	my $o = shift;
	 $o->{node}->getHandler }
sub isExecutable {
	my $o = shift;
	 $o->{node}->getHandler ? 1 : 0 }
sub collectHandler {
	my $o = shift;
	 $o->{arrow} ? $o->{arrow}->{handler} : undef }
sub label {
	my $o = shift;
	 $o->{arrow} ? $o->{arrow}->{label} : 'cds' }
sub value { shift->{value} }
sub arrow { shift->{arrow} }
sub cumulativeWeight { shift->{cumulativeWeight} }

sub advance {
	my $o = shift;
	my $token = shift;

	my $arrows = [];
	$o->{node}->collectArrows($arrows);

	# Let the token know what possibilities we have
	for my $arrow (@$arrows) {
		$token->prepare($arrow->{label});
	}

	# Ask the token to interpret the text
	my @states;
	for my $arrow (@$arrows) {
		my $value = $token->as($arrow->{label}) // next;
		push @states, CDS::Parser::State->new($arrow->{node}, $o, $arrow, $value, $token->{warnings});
	}

	return @states;
}

sub complete {
	my $o = shift;
	my $token = shift;

	my $arrows = [];
	$o->{node}->collectArrows($arrows);

	# Let the token know what possibilities we have
	for my $arrow (@$arrows) {
		next if ! $arrow->{official};
		$token->prepare($arrow->{label});
	}

	# Ask the token to interpret the text
	for my $arrow (@$arrows) {
		next if ! $arrow->{official};
		$token->complete($arrow->{label});
	}

	return @{$token->{possibilities}};
}

sub arrows {
	my $o = shift;

	my $arrows = [];
	$o->{node}->collectArrows($arrows);
	return @$arrows;
}

sub path {
	my $o = shift;

	my @path;
	my $state = $o;
	while ($state) {
		unshift @path, $state;
		$state = $state->{previous};
	}
	return @path;
}

sub collect {
	my $o = shift;
	my $data = shift;

	for my $state ($o->path) {
		my $collectHandler = $state->collectHandler // next;
		&$collectHandler($data, $state->label, $state->value);
	}
}

package CDS::Parser::Token;

sub new {
	my $class = shift;
	my $actor = shift;
	my $text = shift;

	return bless {
		actor => $actor,
		text => $text,
		keywords => {},
		cache => {},
		warnings => [],
		possibilities => [],
		};
}

sub prepare {
	my $o = shift;
	my $expect = shift;

	$o->{keywords}->{$expect} = 1 if $expect =~ /^[a-z0-9]*$/;
}

sub as {
	my $o = shift;
	my $expect = shift;
	 exists $o->{cache}->{$expect} ? $o->{cache}->{$expect} : $o->{cache}->{$expect} = $o->produce($expect) }

sub produce {
	my $o = shift;
	my $expect = shift;

	return $o->account if $expect eq 'ACCOUNT';
	return $o->hash if $expect eq 'ACTOR';
	return $o->actorGroup if $expect eq 'ACTORGROUP';
	return $o->aesKey if $expect eq 'AESKEY';
	return $o->box if $expect eq 'BOX';
	return $o->boxLabel if $expect eq 'BOXLABEL';
	return $o->file if $expect eq 'FILE';
	return $o->filename if $expect eq 'FILENAME';
	return $o->folder if $expect eq 'FOLDER';
	return $o->foldername if $expect eq 'FOLDERNAME';
	return $o->group if $expect eq 'GROUP';
	return $o->hash if $expect eq 'HASH';
	return $o->keyPair if $expect eq 'KEYPAIR';
	return $o->label if $expect eq 'LABEL';
	return $o->object if $expect eq 'OBJECT';
	return $o->objectFile if $expect eq 'OBJECTFILE';
	return $o->port if $expect eq 'PORT';
	return $o->store if $expect eq 'STORE';
	return $o->text if $expect eq 'TEXT';
	return $o->user if $expect eq 'USER';
	return $o->{text} eq $expect ? '' : undef;
}

sub complete {
	my $o = shift;
	my $expect = shift;

	return $o->completeAccount if $expect eq 'ACCOUNT';
	return $o->completeHash if $expect eq 'ACTOR';
	return $o->completeActorGroup if $expect eq 'ACTORGROUP';
	return if $expect eq 'AESKEY';
	return $o->completeBox if $expect eq 'BOX';
	return $o->completeBoxLabel if $expect eq 'BOXLABEL';
	return $o->completeFile if $expect eq 'FILE';
	return $o->completeFile if $expect eq 'FILENAME';
	return $o->completeFolder if $expect eq 'FOLDER';
	return $o->completeFolder if $expect eq 'FOLDERNAME';
	return $o->completeGroup if $expect eq 'GROUP';
	return $o->completeHash if $expect eq 'HASH';
	return $o->completeKeyPair if $expect eq 'KEYPAIR';
	return $o->completeLabel if $expect eq 'LABEL';
	return $o->completeObject if $expect eq 'OBJECT';
	return $o->completeObjectFile if $expect eq 'OBJECTFILE';
	return $o->completeStoreUrl if $expect eq 'STORE';
	return $o->completeUser if $expect eq 'USER';
	return if $expect eq 'TEXT';
	$o->addPossibility($expect);
}

sub addPossibility {
	my $o = shift;
	my $possibility = shift;

	push @{$o->{possibilities}}, $possibility.' ' if substr($possibility, 0, length $o->{text}) eq $o->{text};
}

sub addPartialPossibility {
	my $o = shift;
	my $possibility = shift;

	push @{$o->{possibilities}}, $possibility if substr($possibility, 0, length $o->{text}) eq $o->{text};
}

sub isKeyword {
	my $o = shift;
	 exists $o->{keywords}->{$o->{text}} }

sub account {
	my $o = shift;

	# From a remembered account
	my $record = $o->{actor}->remembered($o->{text});
	my $storeUrl = $record->child('store')->textValue;
	my $actorHash = CDS::Hash->fromBytes($record->child('actor')->bytesValue);
	if ($actorHash && length $storeUrl) {
		my $store = $o->{actor}->storeForUrl($storeUrl) // return $o->warning('Invalid store URL "', $storeUrl, '" in remembered account.');
		my $accountToken = CDS::AccountToken->new($store, $actorHash);
		return $o->warning('"', $o->{text}, '" is interpreted as a keyword. If you mean the account, write "', $accountToken->url, '".') if $o->isKeyword;
		return $accountToken;
	}

	# From a URL
	if ($o->{text} =~ /^\s*(.*?)\/accounts\/([0-9a-fA-F]{64,64})\/*\s*$/) {
		my $storeUrl = $1;
		my $actorHash = CDS::Hash->fromHex($2);
		$storeUrl = 'file://'.Cwd::abs_path($storeUrl) if $storeUrl !~ /^[a-zA-Z0-9_\+-]*:/ && -d $storeUrl;
		my $cliStore = $o->{actor}->storeForUrl($storeUrl) // return $o->warning('Invalid store URL "', $storeUrl, '".');
		return CDS::AccountToken->new($cliStore, $actorHash);
	}

	return;
}

sub completeAccount {
	my $o = shift;

	$o->completeUrl;

	my $records = $o->{actor}->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		my $storeUrl = $record->child('store')->textValue;
		next if ! length $storeUrl;
		my $actorHash = CDS::Hash->fromBytes($record->child('actor')->bytesValue) // next;

		$o->addPossibility($label);
		$o->addPossibility($storeUrl.'/accounts/'.$actorHash->hex);
	}

	return;
}

sub aesKey {
	my $o = shift;

	$o->{text} =~ /^[0-9A-Fa-f]{64}$/ || return;
	return pack('H*', $o->{text});
}

sub box {
	my $o = shift;

	# From a URL
	if ($o->{text} =~ /^\s*(.*?)\/accounts\/([0-9a-fA-F]{64,64})\/(messages|private|public)\/*\s*$/) {
		my $storeUrl = $1;
		my $boxLabel = $3;
		my $actorHash = CDS::Hash->fromHex($2);
		$storeUrl = 'file://'.Cwd::abs_path($storeUrl) if $storeUrl !~ /^[a-zA-Z0-9_\+-]*:/ && -d $storeUrl;
		my $cliStore = $o->{actor}->storeForUrl($storeUrl) // return $o->warning('Invalid store URL "', $storeUrl, '".');
		my $accountToken = CDS::AccountToken->new($cliStore, $actorHash);
		return CDS::BoxToken->new($accountToken, $boxLabel);
	}

	return;
}

sub completeBox {
	my $o = shift;

	$o->completeUrl;
	return;
}

sub boxLabel {
	my $o = shift;

	return $o->{text} if $o->{text} eq 'messages';
	return $o->{text} if $o->{text} eq 'private';
	return $o->{text} if $o->{text} eq 'public';
	return;
}

sub completeBoxLabel {
	my $o = shift;

	$o->addPossibility('messages');
	$o->addPossibility('private');
	$o->addPossibility('public');
}

sub file {
	my $o = shift;

	my $file = Cwd::abs_path($o->{text}) // return;
	return if ! -f $file;
	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the file, write "./', $o->{text}, '".') if $o->isKeyword;
	return $file;
}

sub completeFile {
	my $o = shift;

	my $folder = './';
	my $startFilename = $o->{text};
	$startFilename = $ENV{HOME}.'/'.$1 if $startFilename =~ /^~\/(.*)$/;
	if ($startFilename eq '~') {
		$folder = $ENV{HOME}.'/';
		$startFilename = '';
	} elsif ($startFilename =~ /^(.*\/)([^\/]*)$/) {
		$folder = $1;
		$startFilename = $2;
	}

	for my $filename (CDS->listFolder($folder)) {
		next if $filename eq '.';
		next if $filename eq '..';
		next if substr($filename, 0, length $startFilename) ne $startFilename;
		my $file = $folder.$filename;
		$file .= '/' if -d $file;
		$file .= ' ' if -f $file;
		push @{$o->{possibilities}}, $file;
	}
}

sub filename {
	my $o = shift;

	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the file, write "./', $o->{text}, '".') if $o->isKeyword;
	return Cwd::abs_path($o->{text});
}

sub folder {
	my $o = shift;

	my $folder = Cwd::abs_path($o->{text}) // return;
	return if ! -d $folder;
	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the folder, write "./', $o->{text}, '".') if $o->isKeyword;
	return $folder;
}

sub completeFolder {
	my $o = shift;

	my $folder = './';
	my $startFilename = $o->{text};
	if ($o->{text} =~ /^(.*\/)([^\/]*)$/) {
		$folder = $1;
		$startFilename = $2;
	}

	for my $filename (CDS->listFolder($folder)) {
		next if $filename eq '.';
		next if $filename eq '..';
		next if substr($filename, 0, length $startFilename) ne $startFilename;
		my $file = $folder.$filename;
		next if ! -d $file;
		push @{$o->{possibilities}}, $file.'/';
	}
}

sub foldername {
	my $o = shift;

	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the folder, write "./', $o->{text}, '".') if $o->isKeyword;
	return Cwd::abs_path($o->{text});
}

sub group {
	my $o = shift;

	return int($1) if $o->{text} =~ /^\s*(\d{1,5})\s*$/;
	return getgrnam($o->{text});
}

sub completeGroup {
	my $o = shift;

	while (my $name = getgrent) {
		$o->addPossibility($name);
	}
}

sub hash {
	my $o = shift;

	my $hash = CDS::Hash->fromHex($o->{text});
	return $hash if $hash;

	# Check if it's a remembered actor hash
	my $record = $o->{actor}->remembered($o->{text});
	my $actorHash = CDS::Hash->fromBytes($record->child('actor')->bytesValue) // return;
	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the actor, write "', $actorHash->hex, '".') if $o->isKeyword;
	return $actorHash;
}

sub completeHash {
	my $o = shift;

	my $records = $o->{actor}->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		my $hash = CDS::Hash->fromBytes($record->child('actor')->bytesValue) // next;
		$o->addPossibility($label);
		$o->addPossibility($hash->hex);
	}

	for my $child ($o->{actor}->actorGroupSelector->children) {
		my $hash = $child->record->child('hash')->hashValue // next;
		$o->addPossibility($hash->hex);
	}
}

sub keyPair {
	my $o = shift;

	# Remembered key pair
	my $record = $o->{actor}->remembered($o->{text});
	my $file = $record->child('key pair')->textValue;

	# Key pair from file
	if (! length $file) {
		$file = Cwd::abs_path($o->{text}) // return;
		return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the file, write "./', $o->{text}, '".') if $o->isKeyword && -f $file;
	}

	# Load the key pair
	return if ! -f $file;
	my $bytes = CDS->readBytesFromFile($file) // return $o->warning('The key pair file "', $file, '" could not be read.');
	my $keyPair = CDS::KeyPair->fromRecord(CDS::Record->fromObject(CDS::Object->fromBytes($bytes))) // return $o->warning('The file "', $file, '" does not contain a key pair.');
	return CDS::KeyPairToken->new($file, $keyPair);
}

sub completeKeyPair {
	my $o = shift;

	$o->completeFile;

	my $records = $o->{actor}->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if ! length $record->child('key pair')->textValue;
		$o->addPossibility($label);
	}
}

sub label {
	my $o = shift;

	my $records = $o->{actor}->remembered($o->{text});
	return $o->{text} if $records->children;
	return;
}

sub completeLabel {
	my $o = shift;

	my $records = $o->{actor}->rememberedRecords;
	for my $label (keys %$records) {
		next if substr($label, 0, length $o->{text}) ne $o->{text};
		$o->addPossibility($label);
	}
}

sub object {
	my $o = shift;

	# Folder stores use the first two hex digits as folder
	my $url = $o->{text} =~ /^\s*(.*?\/objects\/)([0-9a-fA-F]{2,2})\/([0-9a-fA-F]{62,62})\/*\s*$/ ? $1.$2.$3 : $o->{text};

	# From a URL
	if ($url =~ /^\s*(.*?)\/objects\/([0-9a-fA-F]{64,64})\/*\s*$/) {
		my $storeUrl = $1;
		my $hash = CDS::Hash->fromHex($2);
		$storeUrl = 'file://'.Cwd::abs_path($storeUrl) if $storeUrl !~ /^[a-zA-Z0-9_\+-]*:/ && -d $storeUrl;
		my $cliStore = $o->{actor}->storeForUrl($storeUrl) // return $o->warning('Invalid store URL "', $storeUrl, '".');
		return CDS::ObjectToken->new($cliStore, $hash);
	}

	return;
}

sub completeObject {
	my $o = shift;

	$o->completeUrl;
	return;
}

sub objectFile {
	my $o = shift;

	# Key pair from file
	my $file = Cwd::abs_path($o->{text}) // return;
	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the file, write "./', $o->{text}, '".') if $o->isKeyword && -f $file;

	# Load the object
	return if ! -f $file;
	my $bytes = CDS->readBytesFromFile($file) // return $o->warning('The object file "', $file, '" could not be read.');
	my $object = CDS::Object->fromBytes($bytes) // return $o->warning('The file "', $file, '" does not contain a Condensation object.');
	return CDS::ObjectFileToken->new($file, $object);
}

sub completeObjectFile {
	my $o = shift;

	$o->completeFile;
	return;
}

sub actorGroup {
	my $o = shift;

	# We only accept named actor groups. Accepting a single account as actor group is ambiguous whenever ACCOUNT and ACTORGROUP are accepted. For commands that are requiring an ACTORGROUP, they can also accept an ACCOUNT and then convert it.

	# Check if it's an actor group label
	my $record = $o->{actor}->remembered($o->{text})->child('actor group');
	return if ! scalar $record->children;
	return $o->warning('"', $o->{text}, '" is interpreted as keyword. To refer to the actor group, rename it.') if $o->isKeyword;

	my $builder = CDS::ActorGroupBuilder->new;
	$builder->addKnownPublicKey($o->{actor}->keyPair->publicKey);
	$builder->parse($record, 1);
	my ($actorGroup, $storeError) = $builder->load($o->{actor}->groupDocument->unsaved, $o->{actor}->keyPair, $o);
	return $o->{actor}->storeError($o->{actor}->storageStore, $storeError) if defined $storeError;
	return CDS::ActorGroupToken->new($o->{text}, $actorGroup);
}

sub onLoadActorGroupVerifyStore {
	my $o = shift;
	my $storeUrl = shift;
	 $o->{actor}->storeForUrl($storeUrl); }

sub completeActorGroup {
	my $o = shift;

	my $records = $o->{actor}->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if ! scalar $record->child('actor group')->children;
		$o->addPossibility($label);
	}
	return;
}

sub port {
	my $o = shift;

	my $port = int($o->{text});
	return if $port <= 0 || $port > 65536;
	return $port;
}

sub rememberedStoreUrl {
	my $o = shift;

	my $record = $o->{actor}->remembered($o->{text});
	my $storeUrl = $record->child('store')->textValue;
	return if ! length $storeUrl;

	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the store, write "', $storeUrl, '".') if $o->isKeyword;
	return $storeUrl;
}

sub directStoreUrl {
	my $o = shift;

	return $o->warning('"', $o->{text}, '" is interpreted as keyword. If you mean the folder store, write "./', $o->{text}, '".') if $o->isKeyword;
	return if $o->{text} =~ /[0-9a-f]{32}/;

	return $o->{text} if $o->{text} =~ /^[a-zA-Z0-9_\+-]*:/;
	return 'file://'.Cwd::abs_path($o->{text}) if -d $o->{text} && -d $o->{text}.'/accounts' && -d $o->{text}.'/objects';
	return;
}

sub store {
	my $o = shift;

	my $url = $o->rememberedStoreUrl // $o->directStoreUrl // return;
	return $o->{actor}->storeForUrl($url) // return $o->warning('"', $o->{text}, '" looks like a store, but no implementation is available to handle this protocol.');
}

sub completeFolderStoreUrl {
	my $o = shift;

	my $folder = './';
	my $startFilename = $o->{text};
	if ($o->{text} =~ /^(.*\/)([^\/]*)$/) {
		$folder = $1;
		$startFilename = $2;
	}

	for my $filename (CDS->listFolder($folder)) {
		next if $filename eq '.';
		next if $filename eq '..';
		next if substr($filename, 0, length $startFilename) ne $startFilename;
		my $file = $folder.$filename;
		next if ! -d $file;
		push @{$o->{possibilities}}, $file . (-d $file.'/accounts' && -d $file.'/objects' ? ' ' : '/');
	}
}

sub completeStoreUrl {
	my $o = shift;

	$o->completeFolderStoreUrl;
	$o->completeUrl;

	my $records = $o->{actor}->rememberedRecords;
	for my $label (keys %$records) {
		my $record = $records->{$label};
		next if length $record->child('actor')->bytesValue;
		my $storeUrl = $record->child('store')->textValue;
		next if ! length $storeUrl;
		$o->addPossibility($label);
		$o->addPossibility($storeUrl);
	}
}

sub completeUrl {
	my $o = shift;

	$o->addPartialPossibility('http://');
	$o->addPartialPossibility('https://');
	$o->addPartialPossibility('ftp://');
	$o->addPartialPossibility('sftp://');
	$o->addPartialPossibility('file://');
}

sub text {
	my $o = shift;

	return $o->{text};
}

sub user {
	my $o = shift;

	return int($1) if $o->{text} =~ /^\s*(\d{1,5})\s*$/;
	return getpwnam($o->{text});
}

sub completeUser {
	my $o = shift;

	while (my $name = getpwent) {
		$o->addPossibility($name);
	}
}

sub warning {
	my $o = shift;

	push @{$o->{warnings}}, join('', @_);
	return;
}

# Reads the private box of an actor.
package CDS::PrivateBoxReader;

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $store = shift;
	my $delegate = shift;

	return bless {
		keyPair => $keyPair,
		actorOnStore => CDS::ActorOnStore->new($keyPair->publicKey, $store),
		delegate => $delegate,
		entries => {},
		};
}

sub keyPair { shift->{keyPair} }
sub actorOnStore { shift->{actorOnStore} }
sub delegate { shift->{delegate} }

sub read {
	my $o = shift;

	my $store = $o->{actorOnStore}->store;
	my ($hashes, $listError) = $store->list($o->{actorOnStore}->publicKey->hash, 'private', 0, $o->{keyPair});
	return if defined $listError;

	# Keep track of the processed entries
	my $newEntries = {};
	for my $hash (@$hashes) {
		$newEntries->{$hash->bytes} = $o->{entries}->{$hash->bytes} // {hash => $hash, processed => 0};
	}
	$o->{entries} = $newEntries;

	# Process new entries
	for my $entry (values %$newEntries) {
		next if $entry->{processed};

		# Get the envelope
		my ($object, $getError) = $store->get($entry->{hash}, $o->{keyPair});
		return if defined $getError;

		if (! defined $object) {
			$o->invalid($entry, 'Envelope object not found.');
			next;
		}

		# Parse the record
		my $envelope = CDS::Record->fromObject($object);
		if (! $envelope) {
			$o->invalid($entry, 'Envelope is not a record.');
			next;
		}

		# Read the content hash
		my $contentHash = $envelope->child('content')->hashValue;
		if (! $contentHash) {
			$o->invalid($entry, 'Missing content hash.');
			next;
		}

		# Verify the signature
		if (! CDS->verifyEnvelopeSignature($envelope, $o->{keyPair}->publicKey, $contentHash)) {
			$o->invalid($entry, 'Invalid signature.');
			next;
		}

		# Decrypt the key
		my $aesKey = $o->{keyPair}->decryptKeyOnEnvelope($envelope);
		if (! $aesKey) {
			$o->invalid($entry, 'Not encrypted for us.');
			next;
		}

		# Retrieve the content
		my $contentHashAndKey = CDS::HashAndKey->new($contentHash, $aesKey);
		my ($contentRecord, $contentObject, $contentInvalidReason, $contentStoreError) = $o->{keyPair}->getAndDecryptRecord($contentHashAndKey, $store);
		return if defined $contentStoreError;

		if (defined $contentInvalidReason) {
			$o->invalid($entry, $contentInvalidReason);
			next;
		}

		$entry->{processed} = 1;
		my $source = CDS::Source->new($o->{keyPair}, $o->{actorOnStore}, 'private', $entry->{hash});
		$o->{delegate}->onPrivateBoxEntry($source, $envelope, $contentHashAndKey, $contentRecord);
	}

	return 1;
}

sub invalid {
	my $o = shift;
	my $entry = shift;
	my $reason = shift;

	$entry->{processed} = 1;
	my $source = CDS::Source->new($o->{actorOnStore}, 'private', $entry->{hash});
	$o->{delegate}->onPrivateBoxInvalidEntry($source, $reason);
}

# Delegate
# onPrivateBoxEntry($source, $envelope, $contentHashAndKey, $contentRecord)
# onPrivateBoxInvalidEntry($source, $reason)

package CDS::PrivateRoot;

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $store = shift;
	my $delegate = shift;

	my $o = bless {
		unsaved => CDS::Unsaved->new($store),
		delegate => $delegate,
		dataHandlers => {},
		hasChanges => 0,
		procured => 0,
		mergedEntries => [],
		};

	$o->{privateBoxReader} = CDS::PrivateBoxReader->new($keyPair, $store, $o);
	return $o;
}

sub delegate { shift->{delegate} }
sub privateBoxReader { shift->{privateBoxReader} }
sub unsaved { shift->{unsaved} }
sub hasChanges { shift->{hasChanges} }
sub procured { shift->{procured} }

sub addDataHandler {
	my $o = shift;
	my $label = shift;
	my $dataHandler = shift;

	$o->{dataHandlers}->{$label} = $dataHandler;
}

sub removeDataHandler {
	my $o = shift;
	my $label = shift;
	my $dataHandler = shift;

	my $registered = $o->{dataHandlers}->{$label};
	return if $registered != $dataHandler;
	delete $o->{dataHandlers}->{$label};
}

# *** Procurement

sub procure {
	my $o = shift;
	my $interval = shift;

	my $now = CDS->now;
	return $o->{procured} if $o->{procured} + $interval > $now;
	$o->{privateBoxReader}->read // return;
	$o->{procured} = $now;
	return $now;
}

# *** Merging

sub onPrivateBoxEntry {
	my $o = shift;
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $contentHashAndKey = shift;
	my $content = shift;

	for my $section ($content->children) {
		my $dataHandler = $o->{dataHandlers}->{$section->bytes} // next;
		$dataHandler->mergeData($section);
	}

	push @{$o->{mergedEntries}}, $source->hash;
}

sub onPrivateBoxInvalidEntry {
	my $o = shift;
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';
	my $reason = shift;

	$o->{delegate}->onPrivateRootReadingInvalidEntry($source, $reason);
	$source->discard;
}

# *** Saving

sub dataChanged {
	my $o = shift;

	$o->{hasChanges} = 1;
}

sub save {
	my $o = shift;
	my $entrustedKeys = shift;

	$o->{unsaved}->startSaving;
	return $o->savingSucceeded if ! $o->{hasChanges};
	$o->{hasChanges} = 0;

	# Create the record
	my $record = CDS::Record->new;
	$record->add('created')->addInteger(CDS->now);
	$record->add('client')->add(CDS->version);
	for my $label (keys %{$o->{dataHandlers}}) {
		my $dataHandler = $o->{dataHandlers}->{$label};
		$dataHandler->addDataTo($record->add($label));
	}

	# Submit the object
	my $key = CDS->randomKey;
	my $object = $record->toObject->crypt($key);
	my $hash = $object->calculateHash;
	$o->{unsaved}->savingState->addObject($hash, $object);
	my $hashAndKey = CDS::HashAndKey->new($hash, $key);

	# Create the envelope
	my $keyPair = $o->{privateBoxReader}->keyPair;
	my $publicKeys = [$keyPair->publicKey, @$entrustedKeys];
	my $envelopeObject = $keyPair->createPrivateEnvelope($hashAndKey, $publicKeys)->toObject;
	my $envelopeHash = $envelopeObject->calculateHash;
	$o->{unsaved}->savingState->addObject($envelopeHash, $envelopeObject);

	# Transfer
	my ($missing, $store, $storeError) = $keyPair->transfer([$hash], $o->{unsaved}, $o->{privateBoxReader}->actorOnStore->store);
	return $o->savingFailed($missing) if defined $missing || defined $storeError;

	# Modify the private box
	my $modifications = CDS::StoreModifications->new;
	$modifications->add($keyPair->publicKey->hash, 'private', $envelopeHash, $envelopeObject);
	for my $hash (@{$o->{mergedEntries}}) {
		$modifications->remove($keyPair->publicKey->hash, 'private', $hash);
	}

	my $modifyError = $o->{privateBoxReader}->actorOnStore->store->modify($modifications, $keyPair);
	return $o->savingFailed if defined $modifyError;

	# Set the new merged hashes
	$o->{mergedEntries} = [$envelopeHash];
	return $o->savingSucceeded;
}

sub savingSucceeded {
	my $o = shift;

	# Discard all merged sources
	for my $source ($o->{unsaved}->savingState->mergedSources) {
		$source->discard;
	}

	# Call all data saved handlers
	for my $handler ($o->{unsaved}->savingState->dataSavedHandlers) {
		$handler->onDataSaved;
	}

	$o->{unsaved}->savingDone;
	return 1;
}

sub savingFailed {
	my $o = shift;
	my $missing = shift;
		# private
	$o->{unsaved}->savingFailed;
	$o->{hasChanges} = 1;
	return undef, $missing;
}

# A public key of somebody.
package CDS::PublicKey;

sub fromObject {
	my $class = shift;
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	my $record = CDS::Record->fromObject($object) // return;
	my $rsaPublicKey = CDS::C::publicKeyNew($record->child('e')->bytesValue, $record->child('n')->bytesValue) // return;
	return bless {
		hash => $object->calculateHash,
		rsaPublicKey => $rsaPublicKey,
		object => $object,
		lastAccess => 0,	# used by PublicKeyCache
		};
}

sub object { shift->{object} }
sub bytes {
	my $o = shift;
	 $o->{object}->bytes }

### Public key interface ###

sub hash { shift->{hash} }
sub encrypt {
	my $o = shift;
	my $bytes = shift;
	 CDS::C::publicKeyEncrypt($o->{rsaPublicKey}, $bytes) }
sub verifyHash {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $signature = shift;
	 CDS::C::publicKeyVerify($o->{rsaPublicKey}, $hash->bytes, $signature) }

package CDS::PublicKeyCache;

sub new {
	my $class = shift;
	my $maxSize = shift;

	return bless {
		cache => {},
		maxSize => $maxSize,
		};
}

sub add {
	my $o = shift;
	my $publicKey = shift; die 'wrong type '.ref($publicKey).' for $publicKey' if defined $publicKey && ref $publicKey ne 'CDS::PublicKey';

	$o->{cache}->{$publicKey->hash->bytes} = {publicKey => $publicKey, lastAccess => CDS->now};
	$o->deleteOldest;
	return;
}

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $entry = $o->{cache}->{$hash->bytes} // return;
	$entry->{lastAccess} = CDS->now;
	return $entry->{publicKey};
}

sub deleteOldest {
	my $o = shift;
		# private
	return if scalar values %{$o->{cache}} < $o->{maxSize};

	my @entries = sort { $a->{lastAccess} <=> $b->{lastAccess} } values %{$o->{cache}};
	my $toRemove = int(scalar(@entries) - $o->{maxSize} / 2);
	for my $entry (@entries) {
		$toRemove -= 1;
		last if $toRemove <= 0;
		delete $o->{cache}->{$entry->{publicKey}->hash->bytes};
	}
}

package CDS::PutTree;

sub new {
	my $o = shift;
	my $store = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $commitPool = shift;

	return bless {
		store => $store,
		commitPool => $commitPool,
		keyPair => $keyPair,
		done => {},
		};
}

sub put {
	my $o = shift;
	my $hash = shift // return; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	return if $o->{done}->{$hash->bytes};

	# Get the item
	my $hashAndObject = $o->{commitPool}->object($hash) // return;

	# Upload all children
	for my $hash ($hashAndObject->object->hashes) {
		my $error = $o->put($hash);
		return $error if defined $error;
	}

	# Upload this object
	my $error = $o->{store}->put($hashAndObject->hash, $hashAndObject->object, $o->{keyPair});
	return $error if defined $error;
	$o->{done}->{$hash->bytes} = 1;
	return;
}

package CDS::ReceivedMessage;

sub new {
	my $class = shift;
	my $messageBoxReader = shift;
	my $entry = shift;
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $senderStoreUrl = shift;
	my $sender = shift;
	my $content = shift;
	my $streamHead = shift;

	return bless {
		messageBoxReader => $messageBoxReader,
		entry => $entry,
		source => $source,
		envelope => $envelope,
		senderStoreUrl => $senderStoreUrl,
		sender => $sender,
		content => $content,
		streamHead => $streamHead,
		isDone => 0,
		};
}

sub source { shift->{source} }
sub envelope { shift->{envelope} }
sub senderStoreUrl { shift->{senderStoreUrl} }
sub sender { shift->{sender} }
sub content { shift->{content} }

sub waitForSenderStore {
	my $o = shift;

	$o->{entry}->{waitingForStore} = $o->sender->store;
}

sub skip {
	my $o = shift;

	$o->{entry}->{processed} = 0;
}

# A record is a tree, whereby each nodes holds a byte sequence and an optional hash.
# Child nodes are ordered, although the order does not always matter.
package CDS::Record;

sub fromObject {
	my $class = shift;
	my $object = shift // return; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	my $root = CDS::Record->new;
	$root->addFromObject($object) // return;
	return $root;
}

sub new {
	my $class = shift;
	my $bytes = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	bless {
		bytes => $bytes // '',
		hash => $hash,
		children => [],
		};
}

# *** Adding

# Adds a record
sub add {
	my $o = shift;
	my $bytes = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $record = CDS::Record->new($bytes, $hash);
	push @{$o->{children}}, $record;
	return $record;
}

sub addText {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add(Encode::encode_utf8($value // ''), $hash) }
sub addBoolean {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add(CDS->bytesFromBoolean($value), $hash) }
sub addInteger {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add(CDS->bytesFromInteger($value // 0), $hash) }
sub addUnsigned {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add(CDS->bytesFromUnsigned($value // 0), $hash) }
sub addFloat32 {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add(CDS->bytesFromFloat32($value // 0), $hash) }
sub addFloat64 {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add(CDS->bytesFromFloat64($value // 0), $hash) }
sub addHash {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->add('', $hash) }
sub addHashAndKey {
	my $o = shift;
	my $hashAndKey = shift; die 'wrong type '.ref($hashAndKey).' for $hashAndKey' if defined $hashAndKey && ref $hashAndKey ne 'CDS::HashAndKey';
	 $hashAndKey ? $o->add($hashAndKey->key, $hashAndKey->hash) : $o->add('') }
sub addRecord {
	my $o = shift;
	 push @{$o->{children}}, @_; return; }

sub addFromObject {
	my $o = shift;
	my $object = shift // return; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	return 1 if ! length $object->data;
	return CDS::RecordReader->new($object)->readChildren($o);
}

# *** Set value

sub set {
	my $o = shift;
	my $bytes = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	$o->{bytes} = $bytes;
	$o->{hash} = $hash;
	return;
}

# *** Querying

# Returns true if the record contains a child with the indicated bytes.
sub contains {
	my $o = shift;
	my $bytes = shift;

	for my $child (@{$o->{children}}) {
		return 1 if $child->{bytes} eq $bytes;
	}
	return;
}

# Returns the child record for the given bytes. If no record with these bytes exists, a record with these bytes is returned (but not added).
sub child {
	my $o = shift;
	my $bytes = shift;

	for my $child (@{$o->{children}}) {
		return $child if $child->{bytes} eq $bytes;
	}
	return $o->new($bytes);
}

# Returns the first child, or an empty record.
sub firstChild {
	my $o = shift;
	 $o->{children}->[0] // $o->new }

# Returns the nth child, or an empty record.
sub nthChild {
	my $o = shift;
	my $i = shift;
	 $o->{children}->[$i] // $o->new }

sub containsText {
	my $o = shift;
	my $text = shift;
	 $o->contains(Encode::encode_utf8($text // '')) }
sub childWithText {
	my $o = shift;
	my $text = shift;
	 $o->child(Encode::encode_utf8($text // '')) }

# *** Get value

sub bytes { shift->{bytes} }
sub hash { shift->{hash} }
sub children {
	my $o = shift;
	 @{$o->{children}} }

sub asText {
	my $o = shift;
	 Encode::decode_utf8($o->{bytes}) // '' }
sub asBoolean {
	my $o = shift;
	 CDS->booleanFromBytes($o->{bytes}) }
sub asInteger {
	my $o = shift;
	 CDS->integerFromBytes($o->{bytes}) // 0 }
sub asUnsigned {
	my $o = shift;
	 CDS->unsignedFromBytes($o->{bytes}) // 0 }
sub asFloat {
	my $o = shift;
	 CDS->floatFromBytes($o->{bytes}) // 0 }

sub asHashAndKey {
	my $o = shift;

	return if ! $o->{hash};
	return if length $o->{bytes} != 32;
	return CDS::HashAndKey->new($o->{hash}, $o->{bytes});
}

sub bytesValue {
	my $o = shift;
	 $o->firstChild->bytes }
sub hashValue {
	my $o = shift;
	 $o->firstChild->hash }
sub textValue {
	my $o = shift;
	 $o->firstChild->asText }
sub booleanValue {
	my $o = shift;
	 $o->firstChild->asBoolean }
sub integerValue {
	my $o = shift;
	 $o->firstChild->asInteger }
sub unsignedValue {
	my $o = shift;
	 $o->firstChild->asUnsigned }
sub floatValue {
	my $o = shift;
	 $o->firstChild->asFloat }
sub hashAndKeyValue {
	my $o = shift;
	 $o->firstChild->asHashAndKey }

# *** Dependent hashes

sub dependentHashes {
	my $o = shift;

	my $hashes = {};
	$o->traverseHashes($hashes);
	return values %$hashes;
}

sub traverseHashes {
	my $o = shift;
	my $hashes = shift;
		# private
	$hashes->{$o->{hash}->bytes} = $o->{hash} if $o->{hash};
	for my $child (@{$o->{children}}) {
		$child->traverseHashes($hashes);
	}
}

# *** Size

sub countEntries {
	my $o = shift;

	my $count = 1;
	for my $child (@{$o->{children}}) { $count += $child->countEntries; }
	return $count;
}

sub calculateSize {
	my $o = shift;

	return 4 + $o->calculateSizeContribution;
}

sub calculateSizeContribution {
	my $o = shift;
		# private
	my $byteLength = length $o->{bytes};
	my $size = $byteLength < 30 ? 1 : $byteLength < 286 ? 2 : 9;
	$size += $byteLength;
	$size += 32 + 4 if $o->{hash};
	for my $child (@{$o->{children}}) {
		$size += $child->calculateSizeContribution;
	}
	return $size;
}

# *** Serialization

# Serializes this record into a Condensation object.
sub toObject {
	my $o = shift;

	my $writer = CDS::RecordWriter->new;
	$writer->writeChildren($o);
	return CDS::Object->create($writer->header, $writer->data);
}

package CDS::RecordReader;

sub new {
	my $class = shift;
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	return bless {
		object => $object,
		data => $object->data,
		pos => 0,
		hasError => 0
		};
}

sub hasError { shift->{hasError} }

sub readChildren {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	while (1) {
		# Flags
		my $flags = $o->readUnsigned8 // return;

		# Data
		my $length = $flags & 0x1f;
		my $byteLength = $length == 30 ? 30 + ($o->readUnsigned8 // return) : $length == 31 ? ($o->readUnsigned64 // return) : $length;
		my $bytes = $o->readBytes($byteLength);
		my $hash = $flags & 0x20 ? $o->{object}->hashAtIndex($o->readUnsigned32 // return) : undef;
		return if $o->{hasError};

		# Children
		my $child = $record->add($bytes, $hash);
		return if $flags & 0x40 && ! $o->readChildren($child);
		return 1 if ! ($flags & 0x80);
	}
}

sub use {
	my $o = shift;
	my $length = shift;

	my $start = $o->{pos};
	$o->{pos} += $length;
	return substr($o->{data}, $start, $length) if $o->{pos} <= length $o->{data};
	$o->{hasError} = 1;
	return;
}

sub readUnsigned8 {
	my $o = shift;
	 unpack('C', $o->use(1) // return) }
sub readUnsigned32 {
	my $o = shift;
	 unpack('L>', $o->use(4) // return) }
sub readUnsigned64 {
	my $o = shift;
	 unpack('Q>', $o->use(8) // return) }
sub readBytes {
	my $o = shift;
	my $length = shift;
	 $o->use($length) }
sub trailer {
	my $o = shift;
	 substr($o->{data}, $o->{pos}) }

package CDS::RecordWriter;

sub new {
	my $class = shift;

	return bless {
		hashesCount => 0,
		hashes => '',
		data => ''
		};
}

sub header {
	my $o = shift;
	 pack('L>', $o->{hashesCount}).$o->{hashes} }
sub data { shift->{data} }

sub writeChildren {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my @children = @{$record->{children}};
	return if ! scalar @children;
	my $lastChild = pop @children;
	for my $child (@children) { $o->writeNode($child, 1); }
	$o->writeNode($lastChild, 0);
}

sub writeNode {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $hasMoreSiblings = shift;

	# Flags
	my $byteLength = length $record->{bytes};
	my $flags = $byteLength < 30 ? $byteLength : $byteLength < 286 ? 30 : 31;
	$flags |= 0x20 if defined $record->{hash};
	my $countChildren = scalar @{$record->{children}};
	$flags |= 0x40 if $countChildren;
	$flags |= 0x80 if $hasMoreSiblings;
	$o->writeUnsigned8($flags);

	# Data
	$o->writeUnsigned8($byteLength - 30) if ($flags & 0x1f) == 30;
	$o->writeUnsigned64($byteLength) if ($flags & 0x1f) == 31;
	$o->writeBytes($record->{bytes});
	$o->writeUnsigned32($o->addHash($record->{hash})) if $flags & 0x20;

	# Children
	$o->writeChildren($record);
}

sub writeUnsigned8 {
	my $o = shift;
	my $value = shift;
	 $o->{data} .= pack('C', $value) }
sub writeUnsigned32 {
	my $o = shift;
	my $value = shift;
	 $o->{data} .= pack('L>', $value) }
sub writeUnsigned64 {
	my $o = shift;
	my $value = shift;
	 $o->{data} .= pack('Q>', $value) }

sub writeBytes {
	my $o = shift;
	my $bytes = shift;

	warn $bytes.' is a utf8 string, not a byte string.' if utf8::is_utf8($bytes);
	$o->{data} .= $bytes;
}

sub addHash {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $index = $o->{hashesCount};
	$o->{hashes} .= $hash->bytes;
	$o->{hashesCount} += 1;
	return $index;
}

package CDS::RootDocument;

use parent -norequire, 'CDS::Document';

sub new {
	my $class = shift;
	my $privateRoot = shift;
	my $label = shift;

	my $o = $class->SUPER::new($privateRoot->privateBoxReader->keyPair, $privateRoot->unsaved);
	$o->{privateRoot} = $privateRoot;
	$o->{label} = $label;
	$privateRoot->addDataHandler($label, $o);

	# State
	$o->{dataSharingMessage} = undef;
	return $o;
}

sub privateRoot { shift->{privateRoot} }
sub label { shift->{label} }

sub savingDone {
	my $o = shift;
	my $revision = shift;
	my $newPart = shift;
	my $obsoleteParts = shift;

	$o->{privateRoot}->unsaved->state->merge($o->{unsaved}->savingState);
	$o->{unsaved}->savingDone;
	$o->{privateRoot}->dataChanged if $newPart || scalar @$obsoleteParts;
}

sub addDataTo {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	for my $part (sort { $a->{hashAndKey}->hash->bytes cmp $b->{hashAndKey}->hash->bytes } values %{$o->{parts}}) {
		$record->addHashAndKey($part->{hashAndKey});
	}
}
sub mergeData {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my @hashesAndKeys;
	for my $child ($record->children) {
		push @hashesAndKeys, $child->asHashAndKey // next;
	}

	$o->merge(@hashesAndKeys);
}

sub mergeExternalData {
	my $o = shift;
	my $store = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';

	my @hashes;
	my @hashesAndKeys;
	for my $child ($record->children) {
		my $hashAndKey = $child->asHashAndKey // next;
		next if $o->{parts}->{$hashAndKey->hash->bytes};
		push @hashes, $hashAndKey->hash;
		push @hashesAndKeys, $hashAndKey;
	}

	my ($missing, $transferStore, $storeError) = $o->{keyPair}->transfer([@hashes], $store, $o->{privateRoot}->unsaved);
	return if defined $storeError;
	return if $missing;

	if ($source) {
		$source->keep;
		$o->{privateRoot}->unsaved->state->addMergedSource($source);
	}

	$o->merge(@hashesAndKeys);
	return 1;
}

package CDS::Selector;

sub root {
	my $class = shift;
	my $document = shift;

	return bless {document => $document, id => 'ROOT', label => ''};
}

sub document { shift->{document} }
sub parent { shift->{parent} }
sub label { shift->{label} }

sub child {
	my $o = shift;
	my $label = shift;

	return bless {
		document => $o->{document},
		id => $o->{id}.'/'.unpack('H*', $label),
		parent => $o,
		label => $label,
		};
}

sub childWithText {
	my $o = shift;
	my $label = shift;

	return $o->child(Encode::encode_utf8($label // ''));
}

sub children {
	my $o = shift;

	my $item = $o->{document}->get($o) // return;
	return map { $_->{selector} } @{$item->{children}};
}

# Value

sub revision {
	my $o = shift;

	my $item = $o->{document}->get($o) // return 0;
	return $item->{revision};
}

sub isSet {
	my $o = shift;

	my $item = $o->{document}->get($o) // return;
	return scalar $item->{record}->children > 0;
}

sub record {
	my $o = shift;

	my $item = $o->{document}->get($o) // return CDS::Record->new;
	return $item->{record};
}

sub set {
	my $o = shift;
	my $record = shift // return; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my $now = CDS->now;
	my $item = $o->{document}->getOrCreate($o);
	$item->mergeValue($o->{document}->{changes}, $item->{revision} >= $now ? $item->{revision} + 1 : $now, $record);
}

sub merge {
	my $o = shift;
	my $revision = shift;
	my $record = shift // return; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my $item = $o->{document}->getOrCreate($o);
	return $item->mergeValue($o->{document}->{changes}, $revision, $record);
}

sub clear {
	my $o = shift;
	 $o->set(CDS::Record->new) }

sub clearInThePast {
	my $o = shift;

	$o->merge($o->revision + 1, CDS::Record->new) if $o->isSet;
}

sub forget {
	my $o = shift;

	my $item = $o->{document}->get($o) // return;
	$item->forget;
}

sub forgetBranch {
	my $o = shift;

	for my $child ($o->children) { $child->forgetBranch; }
	$o->forget;
}

# Convenience methods (simple interface)

sub firstValue {
	my $o = shift;

	my $item = $o->{document}->get($o) // return CDS::Record->new;
	return $item->{record}->firstChild;
}

sub bytesValue {
	my $o = shift;
	 $o->firstValue->bytes }
sub hashValue {
	my $o = shift;
	 $o->firstValue->hash }
sub textValue {
	my $o = shift;
	 $o->firstValue->asText }
sub booleanValue {
	my $o = shift;
	 $o->firstValue->asBoolean }
sub integerValue {
	my $o = shift;
	 $o->firstValue->asInteger }
sub unsignedValue {
	my $o = shift;
	 $o->firstValue->asUnsigned }
sub floatValue {
	my $o = shift;
	 $o->firstValue->asFloat }
sub hashAndKeyValue {
	my $o = shift;
	 $o->firstValue->asHashAndKey }

# Sets a new value unless the node has that value already.
sub setBytes {
	my $o = shift;
	my $bytes = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	my $record = CDS::Record->new;
	$record->add($bytes, $hash);
	$o->set($record);
}

sub setHash {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes('', $hash); };
sub setText {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes(Encode::encode_utf8($value), $hash); };
sub setBoolean {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes(CDS->bytesFromBoolean($value), $hash); };
sub setInteger {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes(CDS->bytesFromInteger($value), $hash); };
sub setUnsigned {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes(CDS->bytesFromUnsigned($value), $hash); };
sub setFloat32 {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes(CDS->bytesFromFloat32($value), $hash); };
sub setFloat64 {
	my $o = shift;
	my $value = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	 $o->setBytes(CDS->bytesFromFloat64($value), $hash); };
sub setHashAndKey {
	my $o = shift;
	my $hashAndKey = shift; die 'wrong type '.ref($hashAndKey).' for $hashAndKey' if defined $hashAndKey && ref $hashAndKey ne 'CDS::HashAndKey';
	 $o->setBytes($hashAndKey->key, $hashAndKey->hash); };

# Adding objects and merged sources

sub addObject {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	$o->{document}->{unsaved}->state->addObject($hash, $object);
}

sub addMergedSource {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	$o->{document}->{unsaved}->state->addMergedSource($hash);
}

package CDS::SentItem;

use parent -norequire, 'CDS::UnionList::Item';

sub new {
	my $class = shift;
	my $unionList = shift;
	my $id = shift;

	my $o = $class->SUPER::new($unionList, $id);
	$o->{validUntil} = 0;
	$o->{message} = CDS::Record->new;
	return $o;
}

sub validUntil { shift->{validUntil} }
sub envelopeHash {
	my $o = shift;
	 CDS::Hash->fromBytes($o->{message}->bytes) }
sub envelopeHashBytes {
	my $o = shift;
	 $o->{message}->bytes }
sub message { shift->{message} }

sub addToRecord {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	$record->add($o->{id})->addInteger($o->{validUntil})->addRecord($o->{message});
}

sub set {
	my $o = shift;
	my $validUntil = shift;
	my $envelopeHash = shift; die 'wrong type '.ref($envelopeHash).' for $envelopeHash' if defined $envelopeHash && ref $envelopeHash ne 'CDS::Hash';
	my $messageRecord = shift; die 'wrong type '.ref($messageRecord).' for $messageRecord' if defined $messageRecord && ref $messageRecord ne 'CDS::Record';

	my $message = CDS::Record->new($envelopeHash->bytes);
	$message->addRecord($messageRecord->children);
	$o->merge($o->{unionList}->{changes}, CDS->max($validUntil, $o->{validUntil} + 1), $message);
}

sub clear {
	my $o = shift;
	my $validUntil = shift;

	$o->merge($o->{unionList}->{changes}, CDS->max($validUntil, $o->{validUntil} + 1), CDS::Record->new);
}

sub merge {
	my $o = shift;
	my $part = shift;
	my $validUntil = shift;
	my $message = shift;

	return if $o->{validUntil} > $validUntil;
	return if $o->{validUntil} == $validUntil && $part->{size} < $o->{part}->{size};
	$o->{validUntil} = $validUntil;
	$o->{message} = $message;
	$o->setPart($part);
}

package CDS::SentList;

use parent -norequire, 'CDS::UnionList';

sub new {
	my $class = shift;
	my $privateRoot = shift;

	return $class->SUPER::new($privateRoot, 'sent list');
}

sub createItem {
	my $o = shift;
	my $id = shift;

	return CDS::SentItem->new($o, $id);
}

sub mergeRecord {
	my $o = shift;
	my $part = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my $item = $o->getOrCreate($record->bytes);
	for my $child ($record->children) {
		my $validUntil = $child->asInteger;
		my $message = $child->firstChild;
		$item->merge($part, $validUntil, $message);
	}
}

sub forgetObsoleteItems {
	my $o = shift;

	my $now = CDS->now;
	my $toDelete = [];
	for my $item (values %{$o->{items}}) {
		next if $item->{validUntil} >= $now;
		$o->forgetItem($item);
	}
}

package CDS::Source;

sub new {
	my $class = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	return bless {
		keyPair => $keyPair,
		actorOnStore => $actorOnStore,
		boxLabel => $boxLabel,
		hash => $hash,
		referenceCount => 1,
		};
}

sub keyPair { shift->{keyPair} }
sub actorOnStore { shift->{actorOnStore} }
sub boxLabel { shift->{boxLabel} }
sub hash { shift->{hash} }
sub referenceCount { shift->{referenceCount} }

sub keep {
	my $o = shift;

	if ($o->{referenceCount} < 1) {
		warn 'The source '.$o->{actorOnStore}->publicKey->hash->hex.'/'.$o->{boxLabel}.'/'.$o->{hash}->hex.' has already been discarded, and cannot be kept any more.';
		return;
	}

	$o->{referenceCount} += 1;
}

sub discard {
	my $o = shift;

	if ($o->{referenceCount} < 1) {
		warn 'The source '.$o->{actorOnStore}->publicKey->hash->hex.'/'.$o->{boxLabel}.'/'.$o->{hash}->hex.' has already been discarded, and cannot be discarded again.';
		return;
	}

	$o->{referenceCount} -= 1;
	return if $o->{referenceCount} > 0;

	$o->{actorOnStore}->store->remove($o->{actorOnStore}->publicKey->hash, $o->{boxLabel}, $o->{hash}, $o->{keyPair});
}

# A store mapping objects and accounts to a group of stores.
package CDS::SplitStore;

use parent -norequire, 'CDS::Store';

sub new {
	my $class = shift;
	my $key = shift;

	return bless {
		id => 'Split Store\n'.unpack('H*', CDS::C::aesCrypt(CDS->zeroCTR, $key, CDS->zeroCTR)),
		key => $key,
		accountStores => [],
		objectStores => [],
		};
}

sub id { shift->{id} }

### Store configuration

sub assignAccounts {
	my $o = shift;
	my $fromIndex = shift;
	my $toIndex = shift;
	my $store = shift;

	for my $i ($fromIndex .. $toIndex) {
		$o->{accountStores}->[$i] = $store;
	}
}

sub assignObjects {
	my $o = shift;
	my $fromIndex = shift;
	my $toIndex = shift;
	my $store = shift;

	for my $i ($fromIndex .. $toIndex) {
		$o->{objectStores}->[$i] = $store;
	}
}

sub objectStore {
	my $o = shift;
	my $index = shift;
	 $o->{objectStores}->[$index] }
sub accountStore {
	my $o = shift;
	my $index = shift;
	 $o->{accountStores}->[$index] }

### Hash encryption

our $zeroCounter = "\0" x 16;

sub storeIndex {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	# To avoid attacks on a single store, the hash is encrypted with a key known to the operator only
	my $encryptedBytes = CDS::C::aesCrypt(substr($hash->bytes, 0, 16), $o->{key}, $zeroCounter);

	# Use the first byte as store index
	return ord(substr($encryptedBytes, 0, 1));
}

### Store interface

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $store = $o->objectStore($o->storeIndex($hash)) // return undef, 'No store assigned.';
	return $store->get($hash, $keyPair);
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $store = $o->objectStore($o->storeIndex($hash)) // return undef, 'No store assigned.';
	return $store->put($hash, $object, $keyPair);
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $store = $o->objectStore($o->storeIndex($hash)) // return undef, 'No store assigned.';
	return $store->book($hash, $keyPair);
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $store = $o->accountStore($o->storeIndex($accountHash)) // return undef, 'No store assigned.';
	return $store->list($accountHash, $boxLabel, $timeout, $keyPair);
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $store = $o->accountStore($o->storeIndex($accountHash)) // return 'No store assigned.';
	return $store->add($accountHash, $boxLabel, $hash, $keyPair);
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $store = $o->accountStore($o->storeIndex($accountHash)) // return 'No store assigned.';
	return $store->remove($accountHash, $boxLabel, $hash, $keyPair);
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	# Put objects
	my %objectsByStoreId;
	for my $entry (values %{$modifications->objects}) {
		my $store = $o->objectStore($o->storeIndex($entry->{hash}));
		my $target = $objectsByStoreId{$store->id};
		$objectsByStoreId{$store->id} = $target = {store => $store, modifications => CDS::StoreModifications->new};
		$target->modifications->put($entry->{hash}, $entry->{object});
	}

	for my $item (values %objectsByStoreId) {
		my $error = $item->{store}->modify($item->{modifications}, $keyPair);
		return $error if $error;
	}

	# Add box entries
	my %additionsByStoreId;
	for my $operation (@{$modifications->additions}) {
		my $store = $o->accountStore($o->storeIndex($operation->{accountHash}));
		my $target = $additionsByStoreId{$store->id};
		$additionsByStoreId{$store->id} = $target = {store => $store, modifications => CDS::StoreModifications->new};
		$target->modifications->add($operation->{accountHash}, $operation->{boxLabel}, $operation->{hash});
	}

	for my $item (values %additionsByStoreId) {
		my $error = $item->{store}->modify($item->{modifications}, $keyPair);
		return $error if $error;
	}

	# Remove box entries (but ignore errors)
	my %removalsByStoreId;
	for my $operation (@$modifications->removals) {
		my $store = $o->accountStore($o->storeIndex($operation->{accountHash}));
		my $target = $removalsByStoreId{$store->id};
		$removalsByStoreId{$store->id} = $target = {store => $store, modifications => CDS::StoreModifications->new};
		$target->modifications->add($operation->{accountHash}, $operation->{boxLabel}, $operation->{hash});
	}

	for my $item (values %removalsByStoreId) {
		$item->{store}->modify($item->{modifications}, $keyPair);
	}

	return;
}

# General
# sub id($o)				# () => String
package CDS::Store;

# Object store functions
# sub get($o, $hash, $keyPair)				# Hash, KeyPair? => Object?, String?
# sub put($o, $hash, $object, $keyPair)		# Hash, Object, KeyPair? => String?
# sub book($o, $hash, $keyPair)				# Hash, KeyPair? => 1?, String?

# Account store functions
# sub list($o, $accountHash, $boxLabel, $timeout, $keyPair)		# Hash, String, Duration, KeyPair? => @$Hash, String?
# sub add($o, $accountHash, $boxLabel, $hash, $keyPair)			# Hash, String, Hash, KeyPair? => String?
# sub remove($o, $accountHash, $boxLabel, $hash, $keyPair)		# Hash, String, Hash, KeyPair? => String?
# sub modify($o, $storeModifications, $keyPair)					# StoreModifications, KeyPair? => String?

package CDS::StoreModifications;

sub new {
	my $class = shift;

	return bless {
		objects => {},
		additions => [],
		removals => [],
		};
}

sub objects { shift->{objects} }
sub additions { shift->{additions} }
sub removals { shift->{removals} }

sub isEmpty {
	my $o = shift;

	return if scalar keys %{$o->{objects}};
	return if scalar @{$o->{additions}};
	return if scalar @{$o->{removals}};
	return 1;
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	$o->{objects}->{$hash->bytes} = {hash => $hash, object => $object};
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	$o->put($hash, $object) if $object;
	push @{$o->{additions}}, {accountHash => $accountHash, boxLabel => $boxLabel, hash => $hash};
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';

	push @{$o->{removals}}, {accountHash => $accountHash, boxLabel => $boxLabel, hash => $hash};
}

sub executeIndividually {
	my $o = shift;
	my $store = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	# Process objects
	for my $entry (values %{$o->{objects}}) {
		my $error = $store->put($entry->{hash}, $entry->{object}, $keyPair);
		return $error if $error;
	}

	# Process additions
	for my $entry (@{$o->{additions}}) {
		my $error = $store->add($entry->{accountHash}, $entry->{boxLabel}, $entry->{hash}, $keyPair);
		return $error if $error;
	}

	# Process removals (and ignore errors)
	for my $entry (@{$o->{removals}}) {
		$store->remove($entry->{accountHash}, $entry->{boxLabel}, $entry->{hash}, $keyPair);
	}

	return;
}

# Returns a text representation of box additions and removals.
sub toRecord {
	my $o = shift;

	my $record = CDS::Record->new;

	# Objects
	my $objectsRecord = $record->add('puts');
	for my $entry (values %{$o->{objects}}) {
		$objectsRecord->add($entry->{hash}->bytes)->add($entry->{object}->bytes);
	}

	# Box additions and removals
	&addEntriesToRecord($o->{additions}, $record->add('add'));
	&addEntriesToRecord($o->{removals}, $record->add('remove'));

	return $record;
}

sub addEntriesToRecord {
	my $unsortedEntries = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
		# private
	my @additions = sort { ($a->{accountHash}->bytes cmp $b->{accountHash}->bytes) || ($a->{boxLabel} cmp $b->{boxLabel}) } @$unsortedEntries;
	my $entry = shift @additions;
	while (defined $entry) {
		my $accountHash = $entry->{accountHash};
		my $accountRecord = $record->add($accountHash->bytes);

		while (defined $entry && $entry->{accountHash}->bytes eq $accountHash->bytes) {
			my $boxLabel = $entry->{boxLabel};
			my $boxRecord = $accountRecord->add($boxLabel);

			while (defined $entry && $entry->{boxLabel} eq $boxLabel) {
				$boxRecord->add($entry->{hash}->bytes);
				$entry = shift @additions;
			}
		}
	}
}

sub fromBytes {
	my $class = shift;
	my $bytes = shift;

	my $object = CDS::Object->fromBytes($bytes) // return;
	my $record = CDS::Record->fromObject($object) // return;
	return $class->fromRecord($record);
}

sub fromRecord {
	my $class = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my $modifications = $class->new;

	# Read objects (and "envelopes" entries used before 2022-01)
	for my $objectRecord ($record->child('put')->children, $record->child('envelopes')->children) {
		my $hash = CDS::Hash->fromBytes($objectRecord->bytes) // return;
		my $object = CDS::Object->fromBytes($objectRecord->firstChild->bytes) // return;
		#return if $o->{checkEnvelopeHash} && ! $object->calculateHash->equals($hash);
		$modifications->put($hash, $object);
	}

	# Read additions and removals
	readEntriesFromRecord($modifications->{addition}, $record->child('add')) // return;
	readEntriesFromRecord($modifications->{removal}, $record->child('remove')) // return;

	return $modifications;
}

sub readEntriesFromRecord {
	my $entries = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
		# private
	for my $accountHashRecord ($record->children) {
		my $accountHash = CDS::Hash->fromBytes($accountHashRecord->bytes) // return;
		for my $boxLabelRecord ($accountHashRecord->children) {
			my $boxLabel = $boxLabelRecord->bytes;
			return if ! CDS->isValidBoxLabel($boxLabel);

			for my $hashRecord ($boxLabelRecord->children) {
				my $hash = CDS::Hash->fromBytes($hashRecord->bytes) // return;
				push @$entries, {accountHash => $accountHash, boxLabel => $boxLabel, hash => $hash};
			}
		}
	}

	return 1;
}

package CDS::StreamCache;

sub new {
	my $class = shift;
	my $pool = shift;
	my $actorOnStore = shift; die 'wrong type '.ref($actorOnStore).' for $actorOnStore' if defined $actorOnStore && ref $actorOnStore ne 'CDS::ActorOnStore';
	my $timeout = shift;

	return bless {
		pool => $pool,
		actorOnStore => $actorOnStore,
		timeout => $timeout,
		cache => {},
		};
}

sub messageBoxReader { shift->{messageBoxReader} }

sub removeObsolete {
	my $o = shift;

	my $limit = CDS->now - $o->{timeout};
	for my $key (%{$o->{knownStreamHeads}}) {
		my $streamHead = $o->{knownStreamHeads}->{$key} // next;
		next if $streamHead->lastUsed < $limit;
		delete $o->{knownStreamHeads}->{$key};
	}
}

sub readStreamHead {
	my $o = shift;
	my $head = shift;

	my $streamHead = $o->{knownStreamHeads}->{$head->hex};
	if ($streamHead) {
		$streamHead->stillInUse;
		return $streamHead;
	}

	# Retrieve the head envelope
	my ($object, $getError) = $o->{actorOnStore}->store->get($head, $o->{pool}->{keyPair});
	return if defined $getError;

	# Parse the head envelope
	my $envelope = CDS::Record->fromObject($object);
	return $o->invalid($head, 'Not a record.') if ! $envelope;

	# Read the embedded content object
	my $encryptedBytes = $envelope->child('content')->bytesValue;
	return $o->invalid($head, 'Missing content object.') if ! length $encryptedBytes;

	# Decrypt the key
	my $aesKey = $o->{pool}->{keyPair}->decryptKeyOnEnvelope($envelope);
	return $o->invalid($head, 'Not encrypted for us.') if ! $aesKey;

	# Decrypt the content
	my $contentObject = CDS::Object->fromBytes(CDS::C::aesCrypt($encryptedBytes, $aesKey, CDS->zeroCTR));
	return $o->invalid($head, 'Invalid content object.') if ! $contentObject;

	my $content = CDS::Record->fromObject($contentObject);
	return $o->invalid($head, 'Content object is not a record.') if ! $content;

	# Verify the sender hash
	my $senderHash = $content->child('sender')->hashValue;
	return $o->invalid($head, 'Missing sender hash.') if ! $senderHash;

	# Verify the sender store
	my $storeRecord = $content->child('store');
	return $o->invalid($head, 'Missing sender store.') if ! scalar $storeRecord->children;

	my $senderStoreUrl = $storeRecord->textValue;
	my $senderStore = $o->{pool}->{delegate}->onMessageBoxVerifyStore($senderStoreUrl, $head, $envelope, $senderHash);
	return $o->invalid($head, 'Invalid sender store.') if ! $senderStore;

	# Retrieve the sender's public key
	my ($senderPublicKey, $invalidReason, $publicKeyStoreError) = $o->getPublicKey($senderHash, $senderStore);
	return if defined $publicKeyStoreError;
	return $o->invalid($head, 'Failed to retrieve the sender\'s public key: '.$invalidReason) if defined $invalidReason;

	# Verify the signature
	my $signedHash = CDS::Hash->calculateFor($encryptedBytes);
	return $o->invalid($head, 'Invalid signature.') if ! CDS->verifyEnvelopeSignature($envelope, $senderPublicKey, $signedHash);

	# The envelope is valid
	my $sender = CDS::ActorOnStore->new($senderPublicKey, $senderStore);
	my $newStreamHead = CDS::StreamHead->new($head, $envelope, $senderStoreUrl, $sender, $aesKey, $content);
	$o->{knownStreamHeads}->{$head->hex} = $newStreamHead;
	return $newStreamHead;
}

sub invalid {
	my $o = shift;
	my $head = shift;
	my $reason = shift;
		# private
	my $newStreamHead = CDS::StreamHead->new($head, undef, undef, undef, undef, undef, $reason);
	$o->{knownStreamHeads}->{$head->hex} = $newStreamHead;
	return $newStreamHead;
}

package CDS::StreamHead;

sub new {
	my $class = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $envelope = shift; die 'wrong type '.ref($envelope).' for $envelope' if defined $envelope && ref $envelope ne 'CDS::Record';
	my $senderStoreUrl = shift;
	my $sender = shift;
	my $content = shift;
	my $error = shift;

	return bless {
		hash => $hash,
		envelope => $envelope,
		senderStoreUrl => $senderStoreUrl,
		sender => $sender,
		content => $content,
		error => $error,
		lastUsed => CDS->now,
		};
}

sub hash { shift->{hash} }
sub envelope { shift->{envelope} }
sub senderStoreUrl { shift->{senderStoreUrl} }
sub sender { shift->{sender} }
sub content { shift->{content} }
sub error { shift->{error} }
sub isValid {
	my $o = shift;
	 ! defined $o->{error} }
sub lastUsed { shift->{lastUsed} }

sub stillInUse {
	my $o = shift;

	$o->{lastUsed} = CDS->now;
}

package CDS::SubDocument;

use parent -norequire, 'CDS::Document';

sub new {
	my $class = shift;
	my $parentSelector = shift; die 'wrong type '.ref($parentSelector).' for $parentSelector' if defined $parentSelector && ref $parentSelector ne 'CDS::Selector';

	my $o = $class->SUPER::new($parentSelector->document->keyPair, $parentSelector->document->unsaved);
	$o->{parentSelector} = $parentSelector;
	return $o;
}

sub parentSelector { shift->{parentSelector} }

sub partSelector {
	my $o = shift;
	my $hashAndKey = shift; die 'wrong type '.ref($hashAndKey).' for $hashAndKey' if defined $hashAndKey && ref $hashAndKey ne 'CDS::HashAndKey';

	$o->{parentSelector}->child(substr($hashAndKey->hash->bytes, 0, 16));
}

sub read {
	my $o = shift;

	$o->merge(map { $_->hashAndKeyValue } $o->{parentSelector}->children);
	return $o->SUPER::read;
}

sub savingDone {
	my $o = shift;
	my $revision = shift;
	my $newPart = shift;
	my $obsoleteParts = shift;

	$o->{parentSelector}->document->unsaved->state->merge($o->{unsaved}->savingState);

	# Remove obsolete parts
	for my $part (@$obsoleteParts) {
		$o->partSelector($part->{hashAndKey})->merge($revision, CDS::Record->new);
	}

	# Add the new part
	if ($newPart) {
		my $record = CDS::Record->new;
		$record->addHashAndKey($newPart->{hashAndKey});
		$o->partSelector($newPart->{hashAndKey})->merge($revision, $record);
	}

	$o->{unsaved}->savingDone;
}

# Useful functions to display textual information on the terminal
package CDS::UI;

sub new {
	my $class = shift;
	my $fileHandle = shift // *STDOUT;
	my $pure = shift;

	binmode $fileHandle, ":utf8";
	return bless {
		fileHandle => $fileHandle,
		pure => $pure,
		indentCount => 0,
		indent => '',
		valueIndent => 16,
		hasSpace => 0,
		hasError => 0,
		hasWarning => 0,
		};
}

sub fileHandle { shift->{fileHandle} }

### Indent

sub pushIndent {
	my $o = shift;

	$o->{indentCount} += 1;
	$o->{indent} = '  ' x $o->{indentCount};
	return;
}

sub popIndent {
	my $o = shift;

	$o->{indentCount} -= 1;
	$o->{indent} = '  ' x $o->{indentCount};
	return;
}

sub valueIndent {
	my $o = shift;
	my $width = shift;

	$o->{valueIndent} = $width;
}

### Low-level (non-semantic) output

sub print {
	my $o = shift;

	my $fh = $o->{fileHandle} // return;
	print $fh @_;
}

sub raw {
	my $o = shift;

	$o->removeProgress;
	my $fh = $o->{fileHandle} // return;
	binmode $fh, ":bytes";
	print $fh @_;
	binmode $fh, ":utf8";
	$o->{hasSpace} = 0;
	return;
}

sub space {
	my $o = shift;

	$o->removeProgress;
	return if $o->{hasSpace};
	$o->{hasSpace} = 1;
	$o->print("\n");
	return;
}

# A line of text (without word-wrap).
sub line {
	my $o = shift;

	$o->removeProgress;
	my $span = CDS::UI::Span->new(@_);
	$o->print($o->{indent});
	$span->printTo($o);
	$o->print(chr(0x1b), '[0m', "\n");
	$o->{hasSpace} = 0;
	return;
}

# A line of word-wrapped text.
sub p {
	my $o = shift;

	$o->removeProgress;
	my $span = CDS::UI::Span->new(@_);
	$span->wordWrap({lineLength => 0, maxLength => 100 - length $o->{indent}, indent => $o->{indent}});
	$o->print($o->{indent});
	$span->printTo($o);
	$o->print(chr(0x1b), '[0m', "\n");
	$o->{hasSpace} = 0;
	return;
}

# Line showing the progress.
sub progress {
	my $o = shift;

	return if $o->{pure};
	$| = 1;
	$o->{hasProgress} = 1;
	my $text = '  '.join('', @_);
	$text = substr($text, 0, 79).'…' if length $text > 80;
	$text .= ' ' x (80 - length $text) if length $text < 80;
	$o->print($text, "\r");
}

# Progress line removal.
sub removeProgress {
	my $o = shift;

	return if $o->{pure};
	return if ! $o->{hasProgress};
	$o->print(' ' x 80, "\r");
	$o->{hasProgress} = 0;
	$| = 0;
}

### Low-level (non-semantic) formatting

sub span {
	my $o = shift;
	 CDS::UI::Span->new(@_) }

sub bold {
	my $o = shift;

	my $span = CDS::UI::Span->new(@_);
	$span->{bold} = 1;
	return $span;
}

sub underlined {
	my $o = shift;

	my $span = CDS::UI::Span->new(@_);
	$span->{underlined} = 1;
	return $span;
}

sub foreground {
	my $o = shift;
	my $foreground = shift;

	my $span = CDS::UI::Span->new(@_);
	$span->{foreground} = $foreground;
	return $span;
}

sub background {
	my $o = shift;
	my $background = shift;

	my $span = CDS::UI::Span->new(@_);
	$span->{background} = $background;
	return $span;
}

sub red {
	my $o = shift;
	 $o->foreground(196, @_) }		# for failure
sub green {
	my $o = shift;
	 $o->foreground(40, @_) }		# for success
sub orange {
	my $o = shift;
	 $o->foreground(166, @_) }	# for warnings
sub blue {
	my $o = shift;
	 $o->foreground(33, @_) }		# to highlight something (selection)
sub violet {
	my $o = shift;
	 $o->foreground(93, @_) }	# to highlight something (selection)
sub gold {
	my $o = shift;
	 $o->foreground(238, @_) }		# for commands that can be executed
sub gray {
	my $o = shift;
	 $o->foreground(246, @_) }		# for additional (less important) information

sub darkBold {
	my $o = shift;

	my $span = CDS::UI::Span->new(@_);
	$span->{bold} = 1;
	$span->{foreground} = 240;
	return $span;
}

### Semantic output

sub title {
	my $o = shift;
	 $o->line($o->bold(@_)) }

sub left {
	my $o = shift;
	my $width = shift;
	my $text = shift;

	return substr($text, 0, $width - 1).'…' if length $text > $width;
	return $text . ' ' x ($width - length $text);
}

sub right {
	my $o = shift;
	my $width = shift;
	my $text = shift;

	return substr($text, 0, $width - 1).'…' if length $text > $width;
	return ' ' x ($width - length $text) . $text;
}

sub keyValue {
	my $o = shift;
	my $key = shift;
	my $firstLine = shift;

	my $indent = $o->{valueIndent} - length $o->{indent};
	$key = substr($key, 0, $indent - 2).'…' if defined $firstLine && length $key >= $indent;
	$key .= ' ' x ($indent - length $key);
	$o->line($o->gray($key), $firstLine);
	my $noKey = ' ' x $indent;
	for my $line (@_) { $o->line($noKey, $line); }
	return;
}

sub command {
	my $o = shift;
	 $o->line($o->bold(@_)) }

sub verbose {
	my $o = shift;
	 $o->line($o->foreground(45, @_)) if $o->{verbose} }

sub pGreen {
	my $o = shift;

	$o->p($o->green(@_));
	return;
}

sub pOrange {
	my $o = shift;

	$o->p($o->orange(@_));
	return;
}

sub pRed {
	my $o = shift;

	$o->p($o->red(@_));
	return;
}

### Warnings and errors

sub hasWarning { shift->{hasWarning} }
sub hasError { shift->{hasError} }

sub warning {
	my $o = shift;

	$o->{hasWarning} = 1;
	$o->p($o->orange(@_));
	return;
}

sub error {
	my $o = shift;

	$o->{hasError} = 1;
	my $span = CDS::UI::Span->new(@_);
	$span->{background} = 196;
	$span->{foreground} = 15;
	$span->{bold} = 1;
	$o->line($span);
	return;
}

### Semantic formatting

sub a {
	my $o = shift;
	 $o->underlined(@_) }

### Human readable formats

sub niceBytes {
	my $o = shift;
	my $bytes = shift;
	my $maxLength = shift;

	my $length = length $bytes;
	my $text = defined $maxLength && $length > $maxLength ? substr($bytes, 0, $maxLength - 1).'…' : $bytes;
	$text =~ s/[\x00-\x1f\x7f-\xff]/./g;
	return $text;
}

sub niceFileSize {
	my $o = shift;
	my $fileSize = shift;

	return $fileSize.' bytes' if $fileSize < 1000;
	return sprintf('%0.1f', $fileSize / 1000).' KB' if $fileSize < 10000;
	return sprintf('%0.0f', $fileSize / 1000).' KB' if $fileSize < 1000000;
	return sprintf('%0.1f', $fileSize / 1000000).' MB' if $fileSize < 10000000;
	return sprintf('%0.0f', $fileSize / 1000000).' MB' if $fileSize < 1000000000;
	return sprintf('%0.1f', $fileSize / 1000000000).' GB' if $fileSize < 10000000000;
	return sprintf('%0.0f', $fileSize / 1000000000).' GB';
}

sub niceDateTimeLocal {
	my $o = shift;
	my $time = shift // time() * 1000;

	my @t = localtime($time / 1000);
	return sprintf('%04d-%02d-%02d %02d:%02d:%02d', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

sub niceDateTime {
	my $o = shift;
	my $time = shift // time() * 1000;

	my @t = gmtime($time / 1000);
	return sprintf('%04d-%02d-%02d %02d:%02d:%02d UTC', $t[5] + 1900, $t[4] + 1, $t[3], $t[2], $t[1], $t[0]);
}

sub niceDate {
	my $o = shift;
	my $time = shift // time() * 1000;

	my @t = gmtime($time / 1000);
	return sprintf('%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3]);
}

sub niceTime {
	my $o = shift;
	my $time = shift // time() * 1000;

	my @t = gmtime($time / 1000);
	return sprintf('%02d:%02d:%02d UTC', $t[2], $t[1], $t[0]);
}

### Special output

sub record {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $storeUrl = shift;
	 CDS::UI::Record->display($o, $record, $storeUrl) }

sub recordChildren {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $storeUrl = shift;

	for my $child ($record->children) {
		CDS::UI::Record->display($o, $child, $storeUrl);
	}
}

sub selector {
	my $o = shift;
	my $selector = shift; die 'wrong type '.ref($selector).' for $selector' if defined $selector && ref $selector ne 'CDS::Selector';
	my $rootLabel = shift;

	my $item = $selector->document->get($selector);
	my $revision = $item->{revision} ? $o->green('  ', $o->niceDateTime($item->{revision})) : '';

	if ($selector->{id} eq 'ROOT') {
		$o->line($o->bold($rootLabel // 'Data tree'), $revision);
		$o->recordChildren($selector->record);
		$o->selectorChildren($selector);
	} else {
		my $label = $selector->label;
		my $labelText = length $label > 64 ? substr($label, 0, 64).'…' : $label;
		$labelText =~ s/[\x00-\x1f\x7f-\xff]/·/g;
		$o->line($o->blue($labelText), $revision);

		$o->pushIndent;
		$o->recordChildren($selector->record);
		$o->selectorChildren($selector);
		$o->popIndent;
	}
}

sub selectorChildren {
	my $o = shift;
	my $selector = shift; die 'wrong type '.ref($selector).' for $selector' if defined $selector && ref $selector ne 'CDS::Selector';

	for my $child (sort { $a->{id} cmp $b->{id} } $selector->children) {
		$o->selector($child);
	}
}

sub hexDump {
	my $o = shift;
	my $bytes = shift;
	 CDS::UI::HexDump->new($o, $bytes) }

package CDS::UI::HexDump;

sub new {
	my $class = shift;
	my $ui = shift;
	my $bytes = shift;

	return bless {ui => $ui, bytes => $bytes, styleChanges => [], };
}

sub reset { chr(0x1b).'[0m' }
sub foreground {
	my $o = shift;
	my $color = shift;
	 chr(0x1b).'[0;38;5;'.$color.'m' }

sub changeStyle {
	my $o = shift;

	push @{$o->{styleChanges}}, @_;
}

sub styleHashList {
	my $o = shift;
	my $offset = shift;

	my $hashesCount = unpack('L>', substr($o->{bytes}, $offset, 4));
	my $dataStart = $offset + 4 + $hashesCount  * 32;
	return $offset if $dataStart > length $o->{bytes};

	# Styles
	my $darkGreen = $o->foreground(28);
	my $green0 = $o->foreground(40);
	my $green1 = $o->foreground(34);

	# Color the hash count
	my $pos = $offset;
	$o->changeStyle({at => $pos, style => $darkGreen, breakBefore => 1});
	$pos += 4;

	# Color the hashes
	my $alternate = 0;
	while ($hashesCount) {
		$o->changeStyle({at => $pos, style => $alternate ? $green1 : $green0, breakBefore => 1});
		$pos += 32;
		$alternate = 1 - $alternate;
		$hashesCount -= 1;
	}

	return $dataStart;
}

sub styleRecord {
	my $o = shift;
	my $offset = shift;

	# Styles
	my $blue = $o->foreground(33);
	my $black = $o->reset;
	my $violet = $o->foreground(93);
	my @styleChanges;

	# Prepare
	my $pos = $offset;
	my $hasError = 0;
	my $level = 0;

	my $use = sub { my $length = shift;
		my $start = $pos;
		$pos += $length;
		return substr($o->{bytes}, $start, $length) if $pos <= length $o->{bytes};
		$hasError = 1;
		return;
	};

	my $readUnsigned8 = sub { unpack('C', &$use(1) // return) };
	my $readUnsigned32 = sub { unpack('L>', &$use(4) // return) };
	my $readUnsigned64 = sub { unpack('Q>', &$use(8) // return) };

	# Parse all record nodes
	while ($level >= 0) {
		# Flags
		push @styleChanges, {at => $pos, style => $blue, breakBefore => 1};
		my $flags = &$readUnsigned8 // last;

		# Data
		my $length = $flags & 0x1f;
		my $byteLength = $length == 30 ? 30 + (&$readUnsigned8 // last) : $length == 31 ? (&$readUnsigned64 // last) : $length;

		if ($byteLength) {
			push @styleChanges, {at => $pos, style => $black};
			&$use($byteLength) // last;
		}

		if ($flags & 0x20) {
			push @styleChanges, {at => $pos, style => $violet};
			&$readUnsigned32 // last;
		}

		# Children
		$level += 1 if $flags & 0x40;
		$level -= 1 if ! ($flags & 0x80);
	}

	# Don't apply any styles if there are errors
	$hasError = 1 if $pos != length $o->{bytes};
	return $offset if $hasError;

	$o->changeStyle(@styleChanges);
	return $pos;
}

sub display {
	my $o = shift;

	$o->{ui}->valueIndent(8);

	my $resetStyle = chr(0x1b).'[0m';
	my $length = length($o->{bytes});
	my $lineStart = 0;
	my $currentStyle = '';

	my @styleChanges = sort { $a->{at} <=> $b->{at} } @{$o->{styleChanges}};
	push @styleChanges, {at => $length};
	my $nextChange = shift(@styleChanges);

	$o->{ui}->line($o->{ui}->gray('····   0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f  0123456789abcdef'));
	while ($lineStart < $length) {
		my $hexLine = $currentStyle;
		my $textLine = $currentStyle;

		my $k = 0;
		while ($k < 16) {
			my $index = $lineStart + $k;
			last if $index >= $length;

			my $break = 0;
			while ($index >= $nextChange->{at}) {
				$currentStyle = $nextChange->{style};
				$break = $nextChange->{breakBefore} && $k > 0;
				$hexLine .= $currentStyle;
				$textLine .= $currentStyle;
				$nextChange = shift @styleChanges;
				last if $break;
			}

			last if $break;

			my $byte = substr($o->{bytes}, $lineStart + $k, 1);
			$hexLine .= ' '.unpack('H*', $byte);

			my $code = ord($byte);
			$textLine .= $code >= 32 && $code <= 126 ? $byte : '·';

			$k += 1;
		}

		$hexLine .= '   ' x (16 - $k);
		$textLine .= ' ' x (16 - $k);
		$o->{ui}->line($o->{ui}->gray(unpack('H4', pack('S>', $lineStart))), ' ', $hexLine, $resetStyle, '  ', $textLine, $resetStyle);

		$lineStart += $k;
	}
}

package CDS::UI::ProgressStore;

use parent -norequire, 'CDS::Store';

sub new {
	my $class = shift;
	my $store = shift;
	my $url = shift;
	my $ui = shift;

	return bless {
		store => $store,
		url => $url,
		ui => $ui,
		}
}

sub store { shift->{store} }
sub url { shift->{url} }
sub ui { shift->{ui} }

sub id {
	my $o = shift;
	 'Progress'."\n  ".$o->{store}->id }

### Object store functions

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress('GET ', $hash->shortHex, ' on ', $o->{url});
	return $o->{store}->get($hash, $keyPair);
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress('BOOK ', $hash->shortHex, ' on ', $o->{url});
	return $o->{store}->book($hash, $keyPair);
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress('PUT ', $hash->shortHex, ' (', $o->{ui}->niceFileSize($object->byteLength), ') on ', $o->{url});
	return $o->{store}->put($hash, $object, $keyPair);
}

### Account store functions

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress($timeout == 0 ? 'LIST ' : 'WATCH ', $boxLabel, ' of ', $accountHash->shortHex, ' on ', $o->{url});
	return $o->{store}->list($accountHash, $boxLabel, $timeout, $keyPair);
}

sub add {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress('ADD ', $accountHash->shortHex, ' ', $boxLabel, ' ', $hash->shortHex, ' on ', $o->{url});
	return $o->{store}->add($accountHash, $boxLabel, $hash, $keyPair);
}

sub remove {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress('REMOVE ', $accountHash->shortHex, ' ', $boxLabel, ' ', $hash->shortHex, ' on ', $o->{url});
	return $o->{store}->remove($accountHash, $boxLabel, $hash, $keyPair);
}

sub modify {
	my $o = shift;
	my $modifications = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	$o->{ui}->progress('MODIFY +', scalar @{$modifications->additions}, ' -', scalar @{$modifications->removals}, ' on ', $o->{url});
	return $o->{store}->modify($modifications, $keyPair);
}

# Displays a record, and tries to guess the byte interpretation
package CDS::UI::Record;

sub display {
	my $class = shift;
	my $ui = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $storeUrl = shift;

	my $o = bless {
		ui => $ui,
		onStore => defined $storeUrl ? $ui->gray(' on ', $storeUrl) : '',
		};

	$o->record($record, '');
}

sub record {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $context = shift;

	my $bytes = $record->bytes;
	my $hash = $record->hash;
	my @children = $record->children;

	# Try to interpret the key / value pair with a set of heuristic rules
	my @value =
		! length $bytes && $hash ? ($o->{ui}->gold('cds show record '), $hash->hex, $o->{onStore}) :
		! length $bytes ? $o->{ui}->gray('empty') :
		length $bytes == 32 && $hash ? ($o->{ui}->gold('cds show record '), $hash->hex, $o->{onStore}, $o->{ui}->gold(' decrypted with ', unpack('H*', $bytes))) :
		$context eq 'e' ? $o->hexValue($bytes) :
		$context eq 'n' ? $o->hexValue($bytes) :
		$context eq 'p' ? $o->hexValue($bytes) :
		$context eq 'q' ? $o->hexValue($bytes) :
		$context eq 'encrypted for' ? $o->hexValue($bytes) :
		$context eq 'updated by' ? $o->hexValue($bytes) :
		$context =~ /(^| )id( |$)/ ? $o->hexValue($bytes) :
		$context =~ /(^| )key( |$)/ ? $o->hexValue($bytes) :
		$context =~ /(^| )signature( |$)/ ? $o->hexValue($bytes) :
		$context =~ /(^| )revision( |$)/ ? $o->revisionValue($bytes) :
		$context =~ /(^| )date( |$)/ ? $o->dateValue($bytes) :
		$context =~ /(^| )expires( |$)/ ? $o->dateValue($bytes) :
			$o->guessValue($bytes);

	push @value, ' ', $o->{ui}->blue($hash->hex), $o->{onStore} if $hash && ($bytes && length $bytes != 32);
	$o->{ui}->line(@value);

	# Children
	$o->{ui}->pushIndent;
	for my $child (@children) { $o->record($child, $bytes); }
	$o->{ui}->popIndent;
}

sub hexValue {
	my $o = shift;
	my $bytes = shift;

	my $length = length $bytes;
	return '#'.unpack('H*', substr($bytes, 0, $length)) if $length <= 64;
	return '#'.unpack('H*', substr($bytes, 0, 64)), '…', $o->{ui}->gray(' (', $length, ' bytes)');
}

sub guessValue {
	my $o = shift;
	my $bytes = shift;

	my $length = length $bytes;
	my $text = $length > 64 ? substr($bytes, 0, 64).'…' : $bytes;
	$text =~ s/[\x00-\x1f\x7f-\xff]/·/g;
	my @value = ($text);

	if ($length <= 8) {
		my $integer = CDS->integerFromBytes($bytes);
		push @value, $o->{ui}->gray(' = ', $integer, $o->looksLikeTimestamp($integer) ? ' = '.$o->{ui}->niceDateTime($integer).' = '.$o->{ui}->niceDateTimeLocal($integer) : '');
	}

	push @value, $o->{ui}->gray(' = ', CDS->floatFromBytes($bytes)) if $length == 4 || $length == 8;
	push @value, $o->{ui}->gray(' = ', CDS::Hash->fromBytes($bytes)->hex) if $length == 32;
	push @value, $o->{ui}->gray(' (', length $bytes, ' bytes)') if length $bytes > 64;
	return @value;
}

sub dateValue {
	my $o = shift;
	my $bytes = shift;

	my $integer = CDS->integerFromBytes($bytes);
	return $integer if ! $o->looksLikeTimestamp($integer);
	return $o->{ui}->niceDateTime($integer), '  ', $o->{ui}->gray($o->{ui}->niceDateTimeLocal($integer));
}

sub revisionValue {
	my $o = shift;
	my $bytes = shift;

	my $integer = CDS->integerFromBytes($bytes);
	return $integer if ! $o->looksLikeTimestamp($integer);
	return $o->{ui}->niceDateTime($integer);
}

sub looksLikeTimestamp {
	my $o = shift;
	my $integer = shift;

	return $integer > 100000000000 && $integer < 10000000000000;
}

package CDS::UI::Span;

sub new {
	my $class = shift;

	return bless {
		text => [@_],
		};
}

sub printTo {
	my $o = shift;
	my $ui = shift;
	my $parent = shift;

	if ($parent) {
		$o->{appliedForeground} = $o->{foreground} // $parent->{appliedForeground};
		$o->{appliedBackground} = $o->{background} // $parent->{appliedBackground};
		$o->{appliedBold} = $o->{bold} // $parent->{appliedBold} // 0;
		$o->{appliedUnderlined} = $o->{underlined} // $parent->{appliedUnderlined} // 0;
	} else {
		$o->{appliedForeground} = $o->{foreground};
		$o->{appliedBackground} = $o->{background};
		$o->{appliedBold} = $o->{bold} // 0;
		$o->{appliedUnderlined} = $o->{underlined} // 0;
	}

	my $style = chr(0x1b).'[0';
	$style .= ';1' if $o->{appliedBold};
	$style .= ';4' if $o->{appliedUnderlined};
	$style .= ';38;5;'.$o->{appliedForeground} if defined $o->{appliedForeground};
	$style .= ';48;5;'.$o->{appliedBackground} if defined $o->{appliedBackground};
	$style .= 'm';

	my $needStyle = 1;
	for my $child (@{$o->{text}}) {
		my $ref = ref $child;
		if ($ref eq 'CDS::UI::Span') {
			$child->printTo($ui, $o);
			$needStyle = 1;
			next;
		} elsif (length $ref) {
			warn 'Printing REF';
			$child = $ref;
		} elsif (! defined $child) {
			warn 'Printing UNDEF';
			$child = 'UNDEF';
		}

		if ($needStyle) {
			$ui->print($style);
			$needStyle = 0;
		}

		$ui->print($child);
	}
}

sub wordWrap {
	my $o = shift;
	my $state = shift;

	my $index = -1;
	for my $child (@{$o->{text}}) {
		$index += 1;

		next if ! defined $child;

		my $ref = ref $child;
		if ($ref eq 'CDS::UI::Span') {
			$child->wordWrap($state);
			next;
		} elsif (length $ref) {
			warn 'Printing REF';
			$child = $ref;
		} elsif (! defined $child) {
			warn 'Printing UNDEF';
			$child = 'UNDEF';
		}

		my $position = -1;
		for my $char (split //, $child) {
			$position += 1;
			$state->{lineLength} += 1;
			if ($char eq ' ' || $char eq "\t") {
				$state->{wrapSpan} = $o;
				$state->{wrapIndex} = $index;
				$state->{wrapPosition} = $position;
				$state->{wrapReturn} = $state->{lineLength};
			} elsif ($state->{wrapSpan} && $state->{lineLength} > $state->{maxLength}) {
				my $text = $state->{wrapSpan}->{text}->[$state->{wrapIndex}];
				$text = substr($text, 0, $state->{wrapPosition})."\n".$state->{indent}.substr($text, $state->{wrapPosition} + 1);
				$state->{wrapSpan}->{text}->[$state->{wrapIndex}] = $text;
				$state->{lineLength} -= $state->{wrapReturn};
				$position += length $state->{indent} if $state->{wrapSpan} == $o && $state->{wrapIndex} == $index;
				$state->{wrapSpan} = undef;
			}
		}
	}
}

package CDS::UnionList;

sub new {
	my $class = shift;
	my $privateRoot = shift;
	my $label = shift;

	my $o = bless {
		privateRoot => $privateRoot,
		label => $label,
		unsaved => CDS::Unsaved->new($privateRoot->unsaved),
		items => {},
		parts => {},
		hasPartsToMerge => 0,
		}, $class;

	$o->{unused} = CDS::UnionList::Part->new;
	$o->{changes} = CDS::UnionList::Part->new;
	$privateRoot->addDataHandler($label, $o);
	return $o;
}

sub privateRoot { shift->{privateRoot} }
sub unsaved { shift->{unsaved} }
sub items {
	my $o = shift;
	 values %{$o->{items}} }
sub parts {
	my $o = shift;
	 values %{$o->{parts}} }

sub get {
	my $o = shift;
	my $id = shift;
	 $o->{items}->{$id} }

sub getOrCreate {
	my $o = shift;
	my $id = shift;

	my $item = $o->{items}->{$id};
	return $item if $item;
	my $newItem = $o->createItem($id);
	$o->{items}->{$id} = $newItem;
	return $newItem;
}

# abstract sub createItem($o, $id)
# abstract sub forgetObsoleteItems($o)

sub forget {
	my $o = shift;
	my $id = shift;

	my $item = $o->{items}->{$id} // return;
	$item->{part}->{count} -= 1;
	delete $o->{items}->{$id};
}

sub forgetItem {
	my $o = shift;
	my $item = shift;

	$item->{part}->{count} -= 1;
	delete $o->{items}->{$item->id};
}

# *** MergeableData interface

sub addDataTo {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	for my $part (sort { $a->{hashAndKey}->hash->bytes cmp $b->{hashAndKey}->hash->bytes } values %{$o->{parts}}) {
		$record->addHashAndKey($part->{hashAndKey});
	}
}

sub mergeData {
	my $o = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';

	my @hashesAndKeys;
	for my $child ($record->children) {
		push @hashesAndKeys, $child->asHashAndKey // next;
	}

	$o->merge(@hashesAndKeys);
}

sub mergeExternalData {
	my $o = shift;
	my $store = shift;
	my $record = shift; die 'wrong type '.ref($record).' for $record' if defined $record && ref $record ne 'CDS::Record';
	my $source = shift; die 'wrong type '.ref($source).' for $source' if defined $source && ref $source ne 'CDS::Source';

	my @hashes;
	my @hashesAndKeys;
	for my $child ($record->children) {
		my $hashAndKey = $child->asHashAndKey // next;
		next if $o->{parts}->{$hashAndKey->hash->bytes};
		push @hashes, $hashAndKey->hash;
		push @hashesAndKeys, $hashAndKey;
	}

	my $keyPair = $o->{privateRoot}->privateBoxReader->keyPair;
	my ($missing, $transferStore, $storeError) = $keyPair->transfer([@hashes], $store, $o->{privateRoot}->unsaved);
	return if defined $storeError;
	return if $missing;

	if ($source) {
		$source->keep;
		$o->{privateRoot}->unsaved->state->addMergedSource($source);
	}

	$o->merge(@hashesAndKeys);
	return 1;
}

sub merge {
	my $o = shift;

	for my $hashAndKey (@_) {
		next if ! $hashAndKey;
		next if $o->{parts}->{$hashAndKey->hash->bytes};
		my $part = CDS::UnionList::Part->new;
		$part->{hashAndKey} = $hashAndKey;
		$o->{parts}->{$hashAndKey->hash->bytes} = $part;
		$o->{hasPartsToMerge} = 1;
	}
}

# *** Reading

sub read {
	my $o = shift;

	return 1 if ! $o->{hasPartsToMerge};

	# Load the parts
	for my $part (values %{$o->{parts}}) {
		next if $part->{isMerged};
		next if $part->{loadedRecord};

		my ($record, $object, $invalidReason, $storeError) = $o->{privateRoot}->privateBoxReader->keyPair->getAndDecryptRecord($part->{hashAndKey}, $o->{privateRoot}->unsaved);
		return if defined $storeError;

		delete $o->{parts}->{$part->{hashAndKey}->hash->bytes} if defined $invalidReason;
		$part->{loadedRecord} = $record;
	}

	# Merge the loaded parts
	for my $part (values %{$o->{parts}}) {
		next if $part->{isMerged};
		next if ! $part->{loadedRecord};

		# Merge
		for my $child ($part->{loadedRecord}->children) {
			$o->mergeRecord($part, $child);
		}

		delete $part->{loadedRecord};
		$part->{isMerged} = 1;
	}

	$o->{hasPartsToMerge} = 0;
	return 1;
}

# abstract sub mergeRecord($o, $part, $record)

# *** Saving

sub hasChanges {
	my $o = shift;
	 $o->{changes}->{count} > 0 }

sub save {
	my $o = shift;

	$o->forgetObsoleteItems;
	$o->{unsaved}->startSaving;

	if ($o->{changes}->{count}) {
		# Take the changes
		my $newPart = $o->{changes};
		$o->{changes} = CDS::UnionList::Part->new;

		# Add all changes
		my $record = CDS::Record->new;
		for my $item (values %{$o->{items}}) {
			next if $item->{part} != $newPart;
			$item->addToRecord($record);
		}

		# Select all parts smaller than 2 * count elements
		my $count = $newPart->{count};
		while (1) {
			my $addedPart = 0;
			for my $part (values %{$o->{parts}}) {
				next if ! $part->{isMerged} || $part->{selected} || $part->{count} >= $count * 2;
				$count += $part->{count};
				$part->{selected} = 1;
				$addedPart = 1;
			}

			last if ! $addedPart;
		}

		# Include the selected items
		for my $item (values %{$o->{items}}) {
			next if ! $item->{part}->{selected};
			$item->setPart($newPart);
			$item->addToRecord($record);
		}

		# Serialize the new part
		my $key = CDS->randomKey;
		my $newObject = $record->toObject->crypt($key);
		my $newHash = $newObject->calculateHash;
		$newPart->{hashAndKey} = CDS::HashAndKey->new($newHash, $key);
		$newPart->{isMerged} = 1;
		$o->{parts}->{$newHash->bytes} = $newPart;
		$o->{privateRoot}->unsaved->state->addObject($newHash, $newObject);
		$o->{privateRoot}->dataChanged;
	}

	# Remove obsolete parts
	for my $part (values %{$o->{parts}}) {
		next if ! $part->{isMerged};
		next if $part->{count};
		delete $o->{parts}->{$part->{hashAndKey}->hash->bytes};
		$o->{privateRoot}->dataChanged;
	}

	# Propagate the unsaved state
	$o->{privateRoot}->unsaved->state->merge($o->{unsaved}->savingState);
	$o->{unsaved}->savingDone;
	return 1;
}

package CDS::UnionList::Item;

sub new {
	my $class = shift;
	my $unionList = shift;
	my $id = shift;

	$unionList->{unused}->{count} += 1;
	return bless {
		unionList => $unionList,
		id => $id,
		part => $unionList->{unused},
		}, $class;
}

sub unionList { shift->{unionList} }
sub id { shift->{id} }

sub setPart {
	my $o = shift;
	my $part = shift;

	$o->{part}->{count} -= 1;
	$o->{part} = $part;
	$o->{part}->{count} += 1;
}

# abstract sub addToRecord($o, $record)

package CDS::UnionList::Part;

sub new {
	my $class = shift;

	return bless {
		isMerged => 0,
		hashAndKey => undef,
		size => 0,
		count => 0,
		selected => 0,
		};
}

package CDS::Unsaved;

use parent -norequire, 'CDS::Store';

sub new {
	my $class = shift;
	my $store = shift;

	return bless {
		state => CDS::Unsaved::State->new,
		savingState => undef,
		store => $store,
		};
}

sub state { shift->{state} }
sub savingState { shift->{savingState} }

# *** Saving, state propagation

sub isSaving {
	my $o = shift;
	 defined $o->{savingState} }

sub startSaving {
	my $o = shift;

	die 'Start saving, but already saving' if $o->{savingState};
	$o->{savingState} = $o->{state};
	$o->{state} = CDS::Unsaved::State->new;
}

sub savingDone {
	my $o = shift;

	die 'Not in saving state' if ! $o->{savingState};
	$o->{savingState} = undef;
}

sub savingFailed {
	my $o = shift;

	die 'Not in saving state' if ! $o->{savingState};
	$o->{state}->merge($o->{savingState});
	$o->{savingState} = undef;
}

# *** Store interface

sub id {
	my $o = shift;
	 'Unsaved'."\n".unpack('H*', CDS->randomBytes(16))."\n".$o->{store}->id }

sub get {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	my $stateObject = $o->{state}->{objects}->{$hash->bytes};
	return $stateObject->{object} if $stateObject;

	if ($o->{savingState}) {
		my $savingStateObject = $o->{savingState}->{objects}->{$hash->bytes};
		return $savingStateObject->{object} if $savingStateObject;
	}

	return $o->{store}->get($hash, $keyPair);
}

sub book {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $o->{store}->book($hash, $keyPair);
}

sub put {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $o->{store}->put($hash, $object, $keyPair);
}

sub list {
	my $o = shift;
	my $accountHash = shift; die 'wrong type '.ref($accountHash).' for $accountHash' if defined $accountHash && ref $accountHash ne 'CDS::Hash';
	my $boxLabel = shift;
	my $timeout = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $o->{store}->list($accountHash, $boxLabel, $timeout, $keyPair);
}

sub modify {
	my $o = shift;
	my $additions = shift;
	my $removals = shift;
	my $keyPair = shift; die 'wrong type '.ref($keyPair).' for $keyPair' if defined $keyPair && ref $keyPair ne 'CDS::KeyPair';

	return $o->{store}->modify($additions, $removals, $keyPair);
}

package CDS::Unsaved::State;

sub new {
	my $class = shift;

	return bless {
		objects => {},
		mergedSources => [],
		dataSavedHandlers => [],
		};
}

sub objects { shift->{objects} }
sub mergedSources {
	my $o = shift;
	 @{$o->{mergedSources}} }
sub dataSavedHandlers {
	my $o = shift;
	 @{$o->{dataSavedHandlers}} }

sub addObject {
	my $o = shift;
	my $hash = shift; die 'wrong type '.ref($hash).' for $hash' if defined $hash && ref $hash ne 'CDS::Hash';
	my $object = shift; die 'wrong type '.ref($object).' for $object' if defined $object && ref $object ne 'CDS::Object';

	$o->{objects}->{$hash->bytes} = {hash => $hash, object => $object};
}

sub addMergedSource {
	my $o = shift;

	push @{$o->{mergedSources}}, @_;
}

sub addDataSavedHandler {
	my $o = shift;

	push @{$o->{dataSavedHandlers}}, @_;
}

sub merge {
	my $o = shift;
	my $state = shift;

	for my $key (keys %{$state->{objects}}) {
		$o->{objects}->{$key} = $state->{objects}->{$key};
	}

	push @{$o->{mergedSources}}, @{$state->{mergedSources}};
	push @{$o->{dataSavedHandlers}}, @{$state->{dataSavedHandlers}};
}

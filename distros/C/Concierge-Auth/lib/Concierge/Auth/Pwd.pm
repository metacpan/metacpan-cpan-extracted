package Concierge::Auth::Pwd v0.5.1;
use v5.36;

# ABSTRACT: Password-file Concierge::Auth backend using Crypt::Passphrase

use Carp			qw/carp croak/;
use Fcntl			qw/:flock/;
use Crypt::Passphrase;
use parent			qw/Concierge::Auth::Base/;

## Constants for validation
use constant {
    MIN_ID_LENGTH     	=> 2,
    MAX_ID_LENGTH     	=> 32,
    MIN_PASSWORD_LENGTH	=> 8,
    MAX_PASSWORD_LENGTH	=> 72,    # bcrypt limit
};

## Pre-compiled regex for ID validation - accepts email addresses
my $ID_ALLOWED_CHARS	= qr/^[a-zA-Z0-9._@-]+$/;
## Password file field separator
my $FIELD_SEPARATOR		= "\t";

## new: instantiate the auth object with a passwd file
## Complains if no file is provided unless the argument
## no_file => 1 is provided, but still instantiates
## the auth object; without a passwd file, the auth object
## can only provide the utility methods:
## encryptPwd(), gen_random_token(), gen_random_string(),
## gen_word_phrase(), gen_uuid()
## A file may be designated after instantiation with
## the method setFile().
## Dies if it can't open/create a designated file.
## Complains if it can't set permissions on the file.
sub new {
	my ($class, %args)	= @_;

	my $self	= bless {
		auth => Crypt::Passphrase->new(
			encoder		=> 'Argon2',
			validators	=> [ 'Bcrypt' ],
		)
	}, $class;

	if ($args{no_file}) {
		carp "Utilities only; no ID and password checks";
		# Still functional:
		return $self;
	}
	unless ($args{file}) {
		carp "No auth file provided for ID and password checks";
		# Still functional:
		return $self;
	}

	if (-e $args{file}) {
		open my $afh, "<", $args{file} or
			croak ("Can't read auth file ($args{file}). $! ");
		close $afh;
	} else {
		open my $afh, ">", $args{file} or
			croak ("Can't open/create auth file ($args{file}). $! ");
		close $afh;
	}

 	chmod 0600, $args{file} or carp $!;
	$self->{auth}->{file}	= $args{file};
	$self;
}

# =============================================================================
# CONTRACT METHODS (Concierge::Auth::Base)
# These are the methods Concierge calls, common to every Concierge::Auth
# backend. Each is self-contained: password-file I/O is written directly
# inline here, with no intermediate backend-primitive methods to hop
# through. ID/credential validation is inlined too, except where the same
# check is needed by more than one contract method (see validatePwd below).
#
# Full ID format policy (length, character set) is only enforced in
# enroll(), since that's the only place a *new* ID is established and
# needs to conform to storage policy going forward. The other four methods
# operate on an ID that either does or doesn't already exist on file, so a
# malformed-but-nonempty ID simply fails to match -- no separate rejection
# message is needed for it.
# =============================================================================

## validatePwd: checks password format constraints (length). Needed by
## both enroll and change_credentials (each establishes a new credential
## value), so kept as a shared utility rather than duplicated. Not used by
## authenticate: a wrong-length submitted password simply fails to match
## the stored hash, so a separate format check there would be redundant.
sub validatePwd ($self, $password) {
	return { success => 0, message => "Password cannot be empty" }
		unless defined $password && length($password) > 0;
	return { success => 0, message => sprintf(
		"Password must be between %d and %d characters",
		MIN_PASSWORD_LENGTH, MAX_PASSWORD_LENGTH
	) } unless length($password) >= MIN_PASSWORD_LENGTH
		&& length($password) <= MAX_PASSWORD_LENGTH;
	return { success => 1 };
}

## authenticate: verifies a credential (password) for a user_id.
## Pure check, no side effects.
sub authenticate ($self, $user_id, $credential) {
	return { success => 0, message => "ID cannot be empty" }
		unless defined $user_id && length($user_id) > 0;
	return { success => 0, message => "Password cannot be empty" }
		unless defined $credential && length($credential) > 0;

	my $sep		= $FIELD_SEPARATOR;
	my $pfile	= $self->{auth}->{file};

	open my $pfh, "<", $pfile
		or return { success => 0, message => "authenticate: Cannot open auth file: $!" };
	flock($pfh, LOCK_SH) or do {
		close $pfh;
		return { success => 0, message => "authenticate: Cannot lock file for reading: $!" };
	};
	while (<$pfh>) {
		if (/^\Q$user_id\E$sep([^$sep]+)$sep\|/) {
			my $phash = $1;
			close $pfh;
			return $self->{auth}->verify_password($credential, $phash)
				? { success => 1 }
				: { success => 0, message => "authenticate: Invalid password" };
		}
	}
	close $pfh;
	return { success => 0, message => "authenticate: User ID not found" };
}

## is_id_known: is user_id a known identity in the password file?
## Empty/missing IDs and missing records/files are all simply "not known"
## -- there is no failure branch for this backend, short of a genuine I/O
## error on a file that does exist.
sub is_id_known ($self, $user_id) {
	return { success => 1, known => 0 }
		unless defined $user_id && length($user_id) > 0;

	my $pfile	= $self->{auth}->{file};
	return { success => 1, known => 0 } unless $pfile && -e $pfile;

	open my $pfh, "<", $pfile
		or return { success => 0, message => "is_id_known: Cannot open auth file: $!" };
	flock($pfh, LOCK_SH) or do {
		close $pfh;
		return { success => 0, message => "is_id_known: Cannot lock file for reading: $!" };
	};
	my $sep = $FIELD_SEPARATOR;
	while (<$pfh>) {
		if (/^\Q$user_id\E$sep/) {
			close $pfh;
			return { success => 1, known => 1 };
		}
	}
	close $pfh;
	return { success => 1, known => 0 };
}

## enroll: establishes user_id as a known identity with the given
## credential. $opts is accepted for interface compatibility with other
## backends but unused here. Fails if the ID is already on file.
sub enroll ($self, $user_id, $credential, $opts = undef) {
	return { success => 0, message => "ID cannot be empty" }
		unless defined $user_id && length($user_id) > 0;
	return { success => 0, message => sprintf(
		"ID must be between %d and %d characters",
		MIN_ID_LENGTH, MAX_ID_LENGTH
	) } unless length($user_id) >= MIN_ID_LENGTH
		&& length($user_id) <= MAX_ID_LENGTH;
	return { success => 0, message => "ID contains invalid characters" }
		unless $user_id =~ $ID_ALLOWED_CHARS;

	my $vp = $self->validatePwd($credential);
	return $vp unless $vp->{success};

	my $sep		= $FIELD_SEPARATOR;
	my $pfile	= $self->{auth}->{file};

	if ($pfile && -e $pfile) {
		open my $chfh, "<", $pfile
			or return { success => 0, message => "enroll: Cannot open auth file: $!" };
		flock($chfh, LOCK_SH) or do {
			close $chfh;
			return { success => 0, message => "enroll: Cannot lock file for reading: $!" };
		};
		while (<$chfh>) {
			if (/^\Q$user_id\E$sep/) {
				close $chfh;
				return { success => 0, message => "ID $user_id previously used" };
			}
		}
		close $chfh;
	}

	my $phash	= $self->{auth}->hash_password($credential);

	open my $pfh, ">>", $pfile
		or return { success => 0, message => "enroll: Cannot open auth file: $!" };
	flock($pfh, LOCK_EX) or do {
		close $pfh;
		return { success => 0, message => "enroll: Cannot lock file for writing: $!" };
	};
	print $pfh join( $sep => $user_id, $phash, "|\n") or do {
		close $pfh;
		return { success => 0, message => "enroll: Cannot write to file: $!" };
	};
	close $pfh or return { success => 0, message => "enroll: Cannot close file: $!" };

	return { success => 1, user_id => $user_id, status => 'created' };
}

## change_credentials: replaces the credential on file for an existing
## user_id. Fails if the ID is not known.
sub change_credentials ($self, $user_id, $new_credential) {
	return { success => 0, message => "ID cannot be empty" }
		unless defined $user_id && length($user_id) > 0;

	my $vp = $self->validatePwd($new_credential);
	return $vp unless $vp->{success};

	my $sep		= $FIELD_SEPARATOR;
	my $pfile	= $self->{auth}->{file} || '';

	return { success => 0, message => "Auth file not OK" }
		unless $pfile && -e $pfile && -r $pfile;

	my $phash	= $self->{auth}->hash_password($new_credential);

	open my $fh, "+<", $pfile
		or return { success => 0, message => "change_credentials: Cannot open file: $!" };
	flock($fh, LOCK_EX) or do {
		close $fh;
		return { success => 0, message => "change_credentials: Cannot lock file: $!" };
	};
	my @lines	= <$fh>;

	my $success	= 0;
	my @output;
	for my $line ( @lines ) {
		if ( $line =~ /^\Q$user_id\E$sep/) {
			push @output => join( $sep => $user_id, $phash, "|\n" );
			$success++;
			next;
		}
		push @output, $line;
	}
	unless (
		seek($fh, 0, 0)
		and truncate($fh, 0)
		and print $fh @output
		and close $fh
	) {
		close $fh;
		return { success => 0, message => "change_credentials: File update failed: $!" };
	}

	return $success
		? { success => 1, user_id => $user_id }
		: { success => 0, message => "ID $user_id not found to reset password" };
}

## revoke: removes user_id as a known identity. Symmetric with enroll.
## No ID format policy check here -- revoke operates on an existing ID, so
## a malformed-but-nonempty ID just fails to match any record on file.
sub revoke ($self, $user_id) {
	return { success => 0, message => "ID cannot be empty" }
		unless defined $user_id && length($user_id) > 0;

	my $sep		= $FIELD_SEPARATOR;
	my $pfile	= $self->{auth}->{file} || '';

	return { success => 0, message => "File $pfile no good" }
		unless $pfile && -e $pfile;

	open my $fh, "+<", $pfile
		or return { success => 0, message => "revoke: Cannot open file: $!" };
	flock($fh, LOCK_EX) or do {
		close $fh;
		return { success => 0, message => "revoke: Cannot lock file: $!" };
	};
	my @lines	= <$fh>;

	my $success	= 0;
	my @output;
	for my $line ( @lines ) {
		if ( $line =~ /^\Q$user_id\E$sep/) {
			$success++;
			next;
		}
		push @output, $line;
	}
	unless (
		seek($fh, 0, 0)
		and truncate($fh, 0)
		and print $fh @output
		and close $fh
	) {
		close $fh;
		return { success => 0, message => "revoke: File update failed: $!" };
	}

	return $success
		? { success => 1, user_id => $user_id }
		: { success => 0, message => "ID $user_id not found to delete" };
}

# =============================================================================
# BACKEND-SPECIFIC METHODS
# Everything below is specific to how the password-file backend satisfies
# the contract above. These are not part of Concierge::Auth::Base and other
# backends (e.g. an LDAP backend) are not expected to implement them.
# =============================================================================

## Class Methods for Responses
## confirm, reject, reply
## NOT called with object arrow notation:
##    $self->reject # !WRONG
## Once instantiated, the auth object will not die/croak;
## Instead, all methods that check or validate respond with
##	`confirm ($msg)` # wantarray ? (1, $msg) : 1;
##  	or
##  `reject ($msg)`  # wantarray ? (0, $msg) : 0;
##  	or the more general
##  `reply ($bool, $msg)` # wantarray ? ($bool, $msg) : $bool
## Use explicit `return` to assure correct contrl flow:
## `return confirm($msg);`
## `return reply( $result, $msg);`
sub confirm {
	my $message = shift || "Auth confirmation";
	wantarray ? (1, $message) : 1;
}
sub reject {
	my $message = shift || "Auth rejection";
	wantarray ? (0, $message) : 0;
}
## First arg is 1|0 or other Perl true/false value
sub reply {
	my $bool	= shift // 0;
	my $message = shift || ( $bool ? "Auth confirmation" : "Auth rejection" );
	wantarray ? ($bool, $message) : $bool;
}

## Password file handling

## setFile: sets or changes the passwd file
## creates the file if necessary
sub setFile {
	my $self	= shift;
	my $file	= shift;

	return reject( "No filename" ) unless $file =~ /\S/;

	if (-e $file) {
		open my $afh, "<", $file or
			return reject(  "Can't read auth file ($file). $!" );
		close $afh;
	} else {
		open my $afh, ">", $file or
			return reject(  "Can't open/create auth file ($file). $!" );
		close $afh;
	}

 	chmod 0600, $file or carp $!;

 	if ( -e $file && -r $file ) {
		$self->{auth}->{file}	= $file;
		return confirm( "Valid file" );
 	}

	return reject( "Invalid file" );
}

## rmFile: deletes the passwd file
sub rmFile {
	my $self	= shift;

 	my $pfile	= $self->{auth}->{file} || '';
 	unless ( $pfile and -e $pfile ) {
 		return reject( "No valid file to remove" );
 	}

	unless (unlink $pfile) {
		return reject( "Unable to unlink file: $! " );
	}

	$self->{auth}->{file} = '';

	return reply( $pfile, "Password file removed" );
}

sub clearFile {
	my $self	= shift;

	my ($pfile,$msg)	= $self->rmFile();
	return reply( 0, "No valid file to clear: $msg" ) unless $pfile;

	my ($ok,$setmsg)		= $self->setFile($pfile);
	return reject( "File not cleared: $setmsg" ) unless $ok;
    return confirm( "File cleared" );
}

## Utilities

## encryptPwd: returns encrypted password
sub encryptPwd {
	my $self	= shift;
	my $passwd	= shift;

    my $vp	= $self->validatePwd($passwd);
    return reject( $vp->{message} ) unless $vp->{success};

	return $self->{auth}->hash_password($passwd);
}

## pfile: returns the passwd file, if any
sub pfile {
	my $self	= shift;
	return defined $self->{auth}->{file}
		? reply($self->{auth}->{file}, "Auth file" )
		: reject( "No auth file" );
}

# Generator methods (gen_uuid, gen_random_id, gen_random_token,
# gen_random_string, gen_word_phrase, gen_token, gen_crypt_token) are
# NOT defined here -- they are inherited as working defaults from
# Concierge::Auth::Base, which delegates to Concierge::Auth::Generators.
# See L<Concierge::Auth::Base/The Generators Guarantee>.

1;

__END__

=head1 NAME

Concierge::Auth::Pwd - Password-file Concierge::Auth backend using Crypt::Passphrase

=head1 VERSION

v0.5.1

=head1 SYNOPSIS

    use Concierge::Auth::Pwd;

    # Initialize with a password file
    my $auth = Concierge::Auth::Pwd->new( file => '/path/to/auth.pwd' );

    # Or without a file (generators and utilities only)
    my $auth = Concierge::Auth::Pwd->new( no_file => 1 );

    # --- Concierge::Auth::Base contract methods ---

    my $result = $auth->enroll('alice', 'secret123');
    my $result = $auth->authenticate('alice', 'secret123');
    my $result = $auth->is_id_known('alice');
    my $result = $auth->change_credentials('alice', 'newsecret456');
    my $result = $auth->revoke('alice');

    # --- Backend-specific methods (password-file only) ---

    my ($ok, $msg) = $auth->setFile('/path/to/other.pwd');
    my $hash        = $auth->encryptPwd('secret123');

    # Generate tokens and random values (inherited from Concierge::Auth::Base)
    my ($uuid, $msg)   = $auth->gen_uuid();           # v4 UUID
    my ($id, $msg)     = $auth->gen_random_id();       # 40-char hex ID
    my ($token, $msg)  = $auth->gen_random_token(32);
    my ($string, $msg) = $auth->gen_random_string(16);
    my ($phrase, $msg) = $auth->gen_word_phrase(4, 4, 7, '-');

=head1 DESCRIPTION

Concierge::Auth::Pwd is the built-in password-file backend for
Concierge::Auth. It implements the L<Concierge::Auth::Base> contract
(C<authenticate>, C<is_id_known>, C<enroll>, C<change_credentials>,
C<revoke>) on top of a password store backed by L<Crypt::Passphrase>
with Argon2 encoding and Bcrypt validation for legacy password
migration. Passwords are stored in a tab-separated file with
file-locking for concurrent access.

Token and random value generation (C<gen_uuid>, C<gen_random_id>,
C<gen_random_token>, C<gen_random_string>, C<gen_word_phrase>) is not
implemented by this module -- it is inherited from
L<Concierge::Auth::Base>'s default implementations, which delegate to
L<Concierge::Auth::Generators> (using L<Crypt::PRNG> for
cryptographically secure random output). See
L<Concierge::Auth::Base/The Generators Guarantee>.

Concierge::Auth::Pwd is one backend of L<Concierge::Auth>, 
the authentication component of the Concierge suite, alongside 
L<Concierge::Sessions> (session management) and L<Concierge::Users> 
(user data storage). It can also be used standalone.

=head2 Two Method Layers

This module itself defines two layers of methods:

=over 4

=item * B<Contract methods> (C<authenticate>, C<is_id_known>, C<enroll>,
C<change_credentials>, C<revoke>) -- the interface defined by
L<Concierge::Auth::Base>. These are what C<Concierge> calls, and every
Concierge::Auth backend (this one, or an alternative such as an
LDAP-backed backend) implements them. Password-file I/O and validation
are written directly inline in these methods -- there are no
intermediate backend-primitive methods to hop through. They return the
C<{ success => 1|0, ... }> hashref convention used throughout the rest
of the Concierge suite. C<validatePwd> is kept as a small shared helper
since both C<enroll> and C<change_credentials> need it; it also returns
the hashref convention.

=item * B<Backend-specific methods> (file-management and encryption) --
specific to how B<this> backend manages its password file, independent
of the contract logic above. Other backends are not expected to
implement these, and application code that wants to remain
backend-agnostic should prefer the contract methods. These retain the
original wantarray-sensitive C<(bool, message)> dual-return convention:
C<$value> in scalar context, C<($value, $message)> in list context.

=back

A third set of methods -- token/random value generation -- is
available on every instance but is not defined in this module at all;
see L</DESCRIPTION> above.

=head1 CONSTRUCTOR

=head2 new

    my $auth = Concierge::Auth::Pwd->new(%args);

Creates a new backend object. The Crypt::Passphrase encoder (Argon2) is
initialized immediately.

B<Arguments:>

=over 4

=item C<file> -- path to the password file. Created if it does not
exist. File permissions are set to C<0600>. Croaks if the file cannot
be opened or created.

=item C<no_file> -- if true, skip file setup. The object can still
generate tokens and hash passwords, but cannot perform ID or password
checks.

=back

If neither C<file> nor C<no_file> is provided, the object is still
created (with a warning), but file-dependent methods will fail.

=head1 CONTRACT METHODS

=head2 authenticate

    my $result = $auth->authenticate($user_id, $password);

Verifies that C<$password> is valid for C<$user_id>. Pure check, no
side effects. Malformed/empty IDs or passwords are rejected without a
file scan; a wrong-length password otherwise simply fails to match the
stored hash, so no separate format check is applied to it here.

Returns C<{ success => 1 }> or C<{ success => 0, message => '...' }>.

=head2 is_id_known

    my $result = $auth->is_id_known($user_id);

Checks whether C<$user_id> has a record in the password file. Empty,
malformed, or missing IDs and missing files are all simply "not known"
for this backend -- there is no failure branch short of a genuine I/O
error on a file that does exist.

Returns C<{ success => 1, known => 1|0 }>.

=head2 enroll

    my $result = $auth->enroll($user_id, $password);

Creates a new password record for C<$user_id>. C<$user_id> must meet
the length and character constraints (this is the only contract method
that enforces ID format policy, since it's the only one establishing a
new ID). Fails if the ID already exists (use C<change_credentials> to
change an existing password).

Returns C<{ success => 1, user_id => $user_id, status => 'created' }>
or C<{ success => 0, message => '...' }>.

=head2 change_credentials

    my $result = $auth->change_credentials($user_id, $new_password);

Replaces the stored password hash for an existing C<$user_id>. Fails if
the ID is not found.

Returns C<{ success => 1, user_id => $user_id }> or
C<{ success => 0, message => '...' }>.

=head2 revoke

    my $result = $auth->revoke($user_id);

Removes the password record for C<$user_id>. Fails if the ID is not
found. No ID format policy check is applied -- a malformed-but-nonempty
ID simply fails to match any record on file.

Returns C<{ success => 1, user_id => $user_id }> or
C<{ success => 0, message => '...' }>.

=head2 validatePwd

    my $result = $auth->validatePwd($password);

Checks whether C<$password> meets the length constraints. Shared by
C<enroll> and C<change_credentials>, both of which establish a new
credential value; not used by C<authenticate>, since a wrong-length
submitted password simply fails to match the stored hash.

Returns C<{ success => 1 }> or C<{ success => 0, message => '...' }>.

=head1 BACKEND-SPECIFIC METHODS

=head2 File Management

=head3 setFile

    my ($ok, $msg) = $auth->setFile($path);

Sets (or changes) the password file path. Creates the file if it does
not exist and sets permissions to C<0600>.

=head3 rmFile

    my ($file, $msg) = $auth->rmFile();

Deletes the password file and clears the stored path. In list context,
returns the deleted file path on success.

=head3 clearFile

    my ($ok, $msg) = $auth->clearFile();

Removes and re-creates the password file, effectively deleting all
records.

=head3 pfile

    my ($file, $msg) = $auth->pfile();

Returns the path to the configured password file.

=head2 Utilities

=head3 encryptPwd

    my $hash = $auth->encryptPwd($password);

Returns the Argon2 hash of C<$password>. Validates password constraints
first.

=head2 Token and Value Generation

C<gen_uuid>, C<gen_random_id>, C<gen_random_token>, C<gen_random_string>,
and C<gen_word_phrase> are available on every instance but are not
implemented in this module -- they are inherited default
implementations from L<Concierge::Auth::Base>, which delegate to
L<Concierge::Auth::Generators> and use its dual-return convention:
C<($value, $message)> in list context, C<$value> in scalar context.
See L<Concierge::Auth::Base/GENERATOR METHODS> for the full list and
L<Concierge::Auth::Base/The Generators Guarantee> for why this backend
does not need to (but could) override them.

=head1 SEE ALSO

L<Concierge::Auth::Base> -- the backend contract this module implements

L<Concierge::Auth::Generators> -- functional interface to the generators

L<Concierge::Sessions>, L<Concierge::Users> -- companion Concierge
components

L<Crypt::Passphrase>, L<Crypt::PRNG>

=head1 AUTHOR

Bruce Van Allen <bva@cruzio.com>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of the Artistic License 2.0.

=cut

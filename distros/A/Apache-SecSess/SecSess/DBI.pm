#
# DBI.pm - basic DB interface for Apache::SecSess::* objects
#
# renamed from Id: SecSessDBI.pm,v 1.8 2002/05/06 06:33:17 pliam Exp
# $Id: DBI.pm,v 1.1 2002/05/19 05:15:29 pliam Exp $
#

package Apache::SecSess::DBI;
use strict;

use IO::File;
use DBI;

use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

#
# object and DB initialization
#

## new
sub new {
	my $class = shift;
	my $self = bless({@_}, $class);
	$self->_init;
	return $self;
}

## init object only means acquiring DBI login info
sub _init {
	my $self = shift;
	my ($usage, $file, $fh, $dbistr, $dbiuser, $dbipw);

	## define usage
	$usage = sprintf("usage: %s->new([%s] || [%s]);\n", ref($self),
		"dbifile => 'filename'",
		"dbistr => 'DBI string', dbiuser => 'DBI user', "
			. "dbipw => 'DBI password'"
	);

	## must provide some way to connect
	if ($self->{dbistr} && defined($self->{dbiuser}) && 
		defined($self->{dbipw})) { 
			return; 
	}
	unless ($file = $self->{dbifile}) { die $usage; }

	## read login info from file
	unless ($fh = IO::File->new($file)) {
		die "Cannot open DBI login file '$file'\n";
	}
	chomp($self->{dbistr} = <$fh>); 
	chomp($self->{dbiuser} = <$fh>); 
	chomp($self->{dbipw} = <$fh>);
	unless ($self->{dbistr} && $self->{dbiuser} && $self->{dbipw}) { 
		die "DBI login file has missing data."; 
	}
}

## initiate or restart the database connection
sub refresh_dbh {
	my $self = shift;

	unless (ref($self->{dbh}) && $self->{dbh}->ping) {
		$self->{dbh} = DBI->connect(
			$self->{dbistr}, $self->{dbiuser}, $self->{dbipw}
		) || die "WARNING: cannot connect to database.";
	}
}

#
# query methods
#

## is the user ID valid (whether or not enabled)
sub is_valid_user {
	my $self = shift;
	my($uid) = @_;

	unless ($self->get_user_record($uid)) { return 0; }
	return 1;
}

## retrieve user's status field
sub get_user_status {
	my $self = shift;
	my($uid) = @_;

	my $rec = $self->get_user_record($uid);
	unless ($rec) { return 'unknown'; }
	return $rec->{status};
}

## get the full name
sub get_full_name {
	my $self = shift;
	my($uid) = @_;

	my $rec = $self->get_user_record($uid);
	unless ($rec) { return undef; }
	return $rec->{name};
}

## get UNIX-style password hash
sub get_pwhash {
	my $self = shift;
	my($uid) = @_;
	return $self->get_stored_token($uid, 'unixpw');
}

## get stored token 
sub get_stored_token {
	my $self = shift;
	my($uid, $authid) = @_;
	my($uasth, $token);

	# set up DB query statement
	$self->refresh_dbh;
	$uasth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT token
		FROM userauthen
		WHERE usrid = ? AND authid = ?
ENDSQL
	$uasth->execute($uid, $authid);
	
	# process query output
	($token) = $uasth->fetchrow_array;
	$uasth->finish;

	return $self->dbunquote($token);
}

## valid a user/password against database
sub validate_user_pass {
	my $self = shift;
	my($uid, $pw) = @_;

	## this little extra step is necessary for crypt() to work
	unless ($uid && $pw) { return 'empty'; }
	my $pwhash = $self->get_pwhash($uid);

	return $self->validate_stored_token($uid, crypt($pw, $pwhash), 'unixpw');
}

## validate a general stored token (eg, password, PIN, etc)
sub validate_stored_token {
	my $self = shift;
	my($uid, $token, $authid) = @_;
	my($status);

	unless ($uid) { return 'empty'; } # empty uid argument
	$status = $self->get_user_status($uid);
	unless ($status eq 'enabled') { return $status; } # disabled or unknown
	unless ($token) { return 'empty'; } # empty token argument
	unless ($token eq $self->get_stored_token($uid, $authid)) {
		$self->note_auth_failure($uid, $authid);
		return 'again'; # 'again' means 'wrong' but may be visible in URL
	}
	$self->note_auth_success($uid, $authid);
	return 'OK';
}

## protect against online guessing attacks
sub note_auth_failure {
	my $self = shift;
	my($uid, $authid) = @_;
	my($asth, $maxfail, $uasth, $failcount, $usth);

	## determine if we must count failures at all
	$self->refresh_dbh;
	$asth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT maxfail
		FROM authens
		WHERE authid = ?
ENDSQL
	$asth->execute($authid);
	$maxfail = $asth->fetchrow_array;
	$asth->finish;
	unless ($maxfail) { return; }

	## get current failure count
	$uasth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT failcount
		FROM userauthen
		WHERE usrid = ? AND authid = ?
ENDSQL
	$uasth->execute($uid, $authid);
	$failcount = $uasth->fetchrow_array;
	$uasth->finish;

	if (++$failcount <= $maxfail) { # bump count
		$uasth = $self->{dbh}->prepare(<<'ENDSQL');
			UPDATE userauthen
			SET failcount = ?
			WHERE usrid = ? AND authid = ?
ENDSQL
		$uasth->execute($failcount, $uid, $authid);
		$uasth->finish;
		return;
	}

	## warn of impending doom
	warn "Too many login failures, disabling user '$uid'";

	## maximum failure count exceeded, must disable
	$usth = $self->{dbh}->prepare(<<'ENDSQL');
		UPDATE users
		SET status = ?
		WHERE usrid = ?
ENDSQL
	$usth->execute('disabled', $uid);
	$usth->finish;
}

## reset failure count if necessary
sub note_auth_success{
	my $self = shift;
	my($uid, $authid) = @_;
	my($asth, $maxfail, $uasth);

	## determine if we must count failures at all
	$self->refresh_dbh;
	$asth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT maxfail
		FROM authens
		WHERE authid = ?
ENDSQL
	$asth->execute($authid);
	$maxfail = $asth->fetchrow_array;
	$asth->finish;
	unless ($maxfail) { return; }

	## if we're counting consecutive failures, we must reset the count
	$uasth = $self->{dbh}->prepare(<<'ENDSQL');
		UPDATE userauthen
		SET failcount = ?
		WHERE usrid = ? AND authid = ?
ENDSQL
	$uasth->execute(0, $uid, $authid);
	$uasth->finish;
}

## (re)enable a user and reset failure counts
sub enable_user {
	my $self = shift;
	my($uid) = @_;
	my($usth, $uasth);

	## set status field
	$usth = $self->{dbh}->prepare(<<'ENDSQL');
		UPDATE users
		SET status = ?
		WHERE usrid = ?
ENDSQL
	$usth->execute('enabled', $uid);
	$usth->finish;

	## reset *all* failure counts at once
	$uasth = $self->{dbh}->prepare(<<'ENDSQL');
		UPDATE userauthen
		SET failcount = ?
		WHERE usrid = ?
ENDSQL
	$uasth->execute(0, $uid);
	$uasth->finish;
}

## change user's password
sub change_password {
	my $self = shift;
	my($uid, $pw) = @_;
	my(@salt, $hash, $sth);

	# prepare new hash
	@salt = ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand(64), rand(64)];
	$hash = crypt($pw, join('', @salt));

	# prepare set statement
	$self->refresh_dbh;
	$sth = $self->{dbh}->prepare(<<'ENDSQL');
		UPDATE userauthen
		SET token = ?
		WHERE usrid = ? AND authid = ? 
ENDSQL
	$sth->execute($self->dbquote($hash), $uid, 'unixpw');
	$sth->finish;
}

## return list of groups to which user belongs
sub get_groups {
	my $self = shift;
	my($uid) = @_;
	my($h);
	unless ($h = $self->get_groups_hash($uid)) { return undef; }
	return keys %$h;
}

## extraordinary privileges (in group w/ ID 'super' or 'admin')
sub is_super_user {
	my $self = shift;
	my($uid) = @_;
	return scalar(grep(/^super$/, $self->get_groups($uid)));
}
sub is_administrator {
	my $self = shift;
	my($uid) = @_;
	return scalar(grep(/^admin$/, $self->get_groups($uid)));
}

## return user's default group
sub get_default_group {
	my $self = shift;
	my($uid) = @_;

	my $rec = $self->get_user_record($uid);
	unless ($rec) { return undef; }
	return $rec->{grpid};
}

## get user record
sub get_user_record {
	my $self = shift;
	my($uid) = @_;
	my($usth, $rec);

	# fetch record from users relation
	$self->refresh_dbh;
	$usth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT *
		FROM users
		WHERE usrid = ?
ENDSQL
	$usth->execute($uid);
	$rec = $usth->fetchrow_hashref;
	$usth->finish;
	unless ($rec) { return undef; }

	# unquote the values
	for (keys %{$rec}) {
		$rec->{$_} = $self->dbunquote($rec->{$_});
	}

	return $rec;
}

## get group info as hash ref {grpid => description, ...} 
sub get_groups_hash {
	my $self = shift;
	my($uid) = @_;
	my($ugsth, $row, $grph);

	# set up DB query statement
	$self->refresh_dbh;
	$ugsth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT groups.grpid AS grpid, groups.descr AS descr
		FROM usergroup, groups
		WHERE usergroup.grpid = groups.grpid AND usergroup.usrid = ?
ENDSQL
	$ugsth->execute($uid);

	# process rows
	while ($row = $ugsth->fetchrow_hashref) {
		$grph->{$self->dbunquote($row->{grpid})} 
			= $self->dbunquote($row->{descr});
	}
	$ugsth->finish;

	return $grph;
}

#
# certificate email -> uid resolution (needs work)
#
sub x509email_to_uid {
	my $self = shift;
	my($email) = @_;
	my($uasth, $rows);

	## fetch record from users relation
	$self->refresh_dbh;
	# note: without an index, this is linear search
	$uasth = $self->{dbh}->prepare(<<'ENDSQL');
		SELECT usrid
		FROM userauthen
		WHERE authid = ? AND token = ?
ENDSQL
	$uasth->execute('x509email', $self->dbquote($email));
	$rows = $uasth->fetchall_arrayref;
	$uasth->finish;

	## parse results
	unless (scalar(@$rows) == 1) { return undef; }
	return $self->dbunquote($rows->[0][0]);
}

#
# utilities
#

## quote and unquote strings of the DB
sub dbquote { # (unfortunately must be an object method)
	my $self = shift;
	my($s) = @_;
	$self->refresh_dbh;
	return $self->{dbh}->quote(shift); 
}
sub dbunquote { 
	my $self = shift;
	my($s) = @_;
	$s =~ s/^'//; # leading quote
	$s =~ s/'[^']*$//; # trailing quote
	$s =~ s/\s+$//; # trailing space (if no quote)
	return $s;
}

1;

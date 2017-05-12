# -*- Mode: perl -*-
#
# $Id: File.pm,v 0.1 2001/04/22 17:57:04 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: File.pm,v $
# Revision 0.1  2001/04/22 17:57:04  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use strict;

package CGI::MxScreen::Session::Medium::File;

#
# Session storage is a file, indexed by a session ID.
#
# In the generated HTML, the session is identified by two parameters:
#
#    _mxscreen_session       the session ID
#    _mxscreen_token         a random token, saved with context
#
# The random token is generated each time the context is saved to the file.
# It is used at retrieve time to validate the session ID: noone could guess
# both the session ID and the associated token at the same time.
# 
# Note that since we generate a token each time we save, using "Back" from
# the browser to resubmit an old form is bound to fail, since the token
# will have changed.
#
# It is up to the user to ensure that old session files are removed from the
# file system, according to a suitable session expiring policy.
#

require CGI::MxScreen::Session::Medium;
use vars qw(@ISA);
@ISA = qw(CGI::MxScreen::Session::Medium);

use Carp::Datum;
use Getargs::Long;
use Log::Agent;
use Fcntl;
use File::Basename;
use File::Path;

require LockFile::Simple;
require CGI;

use constant MX_SESSION_ID 	=> "_mxscreen_session";
use constant MX_TOKEN 		=> "_mxscreen_token";

#
# ->make
#
# Creation routine.
#
# Arguments:
#   -directory	root directory where sessions are stored
#   -nfs		whether stored data are on a network filesystem
#	-max_hold	maximum expected lock holding time, for stale lock detection
#
sub make {
	DFEATURE my $f_;
	my $self = bless {}, shift;
	my $MAX_HOLD = 60;					# If CGI takes more than that, uh!

	my ($directory, $nfs, $max) = xgetargs(@_,
		-directory	=> 's',
		-nfs		=> ['i', 0],
		-max_hold	=> ['i', $MAX_HOLD],
	);

	$self->{directory} = $directory;
	$self->{shared} = $nfs;
	$self->{lockmgr} = LockFile::Simple->make(
		-delay		=> 1,
		-hold		=> $max,
		-max		=> $max,			# After that, will be stale
		-nfs		=> $nfs,
		-stale		=> 1,
	);

	return DVAL $self;
}

#
# Attribute access
#

sub directory	{ $_[0]->{directory} }
sub shared		{ $_[0]->{shared} }
sub lockmgr		{ $_[0]->{lockmgr} }

#
# ->_id_to_path
#
# Convert a session ID into a path.
#
# Because traditional UNIX filesystems handle huge directories "inefficiently",
# we hash the session files under 2 extra layers.
#
sub _id_to_path {
	DFEATURE my $f_;
	my $self = shift;
	my ($id) = @_;

	require Digest::MD5;
	my $hash = Digest::MD5::md5_base64($id);
	$hash =~ tr|+/=|-_.|;

	my $path = $self->{directory} . '/' .
		join("/", split(//, substr($hash, 0, 2))) . "/$id";
	$path = $1 if $path =~ /^(.*)$/;	# untaint

	return DVAL $path;
}

#
# ->session_id			-- defined
#
# Retrieve session ID from the CGI environment.
# For a file, the session ID is stored in _mxscreen_session
#
sub session_id {
	DFEATURE my $f_;
	my $self = shift;

	my $id = CGI::param(MX_SESSION_ID);
	CGI::delete(MX_SESSION_ID);				# Invisible to end-user

	return DVAL $id;
}

#
# ->is_available		-- defined
#
# Look whether ID is free to use as a session ID.
# If it is free, atomically reserve it.
#
# Returns true if ID is OK for use, false if it's not available.
#
sub is_available {
	DFEATURE my $f_;
	my $self = shift;
	my ($id) = @_;

	#
	# Check that no session bearing the same ID is still recorded within
	# the filesystem.
	#

	my $path    = $self->_id_to_path($id);
	my $lockmgr = $self->lockmgr;

	#
	# Create all the missing directories that lead to the session path,
	# before attempting to lock the file.
	#

	my $dir  = dirname $path;
	mkpath($dir) unless -d $dir;
	my $lock = $lockmgr->lock($path);

	if (-f $path) {
		$lock->release if defined $lock;
		logtrc 'info', "$path already exists for session $id";
		return DVAL undef;
	}

	#
	# Create empty file to reserve the entry.
	#

	local *FILE;
	open(FILE, ">$path") || logerr "can't create $path: $!";
	close FILE;

	$lock->release if defined $lock;

	return DVAL 1;			# Session ID reserved, and OK to use
}

#
# ->retrieve		-- defined
#
# Retrieve context by session ID.
#
sub retrieve {
	DFEATURE my $f_;
	my $self = shift;
	my ($id) = @_;

	DREQUIRE defined $self->serializer, "already called set_serializer()";

	my $path       = $self->_id_to_path($id);
	my $lockmgr    = $self->{lockmgr};
	my $lock       = $lockmgr->lock($path);

	my $array = $self->_retrieve_locked($path);
	$lock->release if defined $lock;

	return DVAL undef unless defined $array;

	my $token = CGI::param(MX_TOKEN);
	CGI::delete(MX_TOKEN);				# Invisible to end-user

	if ($array->[0] ne $token) {
		logerr "context token mismatch";
		return DVAL undef;
	}

	return DVAL $array->[1];
}

#
# ->_retrieve_locked
#
# retrieve context from (locked) file.
#
sub _retrieve_locked {
	DFEATURE my $f_;
	my $self = shift;
	my ($path) = @_;

	my $serializer = $self->serializer;

	local *FILE;
	unless (sysopen(FILE, $path, O_RDONLY)) {
		logerr "can't open session file $path: $!";
		return DVAL undef;
	}
	my $frozen;
	binmode FILE;
	unless (sysread(FILE, $frozen, -s(FILE))) {
		logerr "can't read session file $path: $!";
		close FILE;
		return DVAL undef;
	}
	close FILE;
	unless (length $frozen) {
		logwarn "no data in session file $path, session expired";
		return undef;
	}

	return DVAL $serializer->deserialize($frozen);
}

#
# ->store		-- defined
#
# Store context by session ID.
#
# Returns hash of (parameter => value) to be generated in the HTML
# to identify the session.
#
sub store {
	DFEATURE my $f_;
	my $self = shift;
	my ($id, $context) = @_;

	DREQUIRE defined $self->serializer, "already called set_serializer()";

	my $path       = $self->_id_to_path($id);
	my $lockmgr    = $self->{lockmgr};
	my $lock       = $lockmgr->lock($path);

	#
	# We're storing the context, with a random key pre-pended to validate
	# the tupple session-ID/random-key at retrieve time.  This prevents
	# forging a session ID.
	#
	# We use the _generate_session_id feature from our parent to get
	# a random token.
	#

	my $store = [$self->_generate_session_id, $context];

	$self->_store_locked($path, $store);
	$lock->release if defined $lock;

	#
	# Return the hidden parameters to generate in the HTML output.
	#

	my $ret = {
		&MX_SESSION_ID	=> $id,
		&MX_TOKEN		=> $store->[0],
	};

	return DVAL $ret;
}

#
# ->_store_locked
#
# Store context into (locked) file.
#
sub _store_locked {
	DFEATURE my $f_;
	my $self = shift;
	my ($path, $context) = @_;

	my $serializer = $self->serializer;

	local *FILE;
	unless (sysopen(FILE, $path, O_WRONLY|O_CREAT|O_TRUNC)) {
		logerr "can't create session file $path: $!";
		return DVOID;
	}
	my $frozen = $serializer->serialize($context);
	binmode FILE;
	unless (syswrite(FILE, $frozen)) {
		logerr "can't write to session file $path: $!";
		close FILE;
		return DVOID;
	}
	unless (close FILE) {
		logerr "can't flush session file $path: $!";
		return DVOID;
	}

	return DVOID;
}

1;

=head1 NAME

CGI::MxScreen::Session::Medium::File - File session medium

=head1 SYNOPSIS

 # Not meant to be used directly

=head1 DESCRIPTION

This saves the session within a file on the server side.  Session
files are created under a set of directories, to avoid having directories
with two many files in them, which is inefficient on most filesystems
(reiserfs excepted).  An MD5 hash of the session ID is taken to compute two
sub directories, resulting in session files being stored as:

    W/N/192.168.0.3-987001261-28947
    k/5/192.168.0.3-987177890-16666

You can see the pattern used for session ids: the IP address of the client
making the request, a timestamp indicating the start of the session, and
the PID of the process.  However, this is used only when the targetted
session ID is free, otherwise, a random cryptic session ID is generated.

Because sessions will use disk space, you need an expiration policy.
If someone attempts to continue a session that has been removed,
C<CGI::MxScreen> will return an error, and that someone will have to
restart the whole session, thereby potentially loosing all the work
already done.

On my web server, I use the following command to expire sessions after
a week of inactivity:

    cd /var/tmp/web-sessions
    find . -type f -atime +7 | xargs rm -f

The creation routine takes the following arguments:

=over 4

=item C<-directory> => I<path>

Mandatory argument, giving the root directory where sessions are saved.

=item C<-max_hold> => I<seconds>

Optional argument, defining the timeout after which a lock is declared stale.
Defaults is 60 seconds.

=item C<-nfs> => I<flag>

Optional, tells whether session files are read from a local or a network
filesystem (e.g. NFS).  Assumes local filesystem by default.

=back

You can configure this session medium in the configuration file as
explained in L<CGI::MxScreen::Config> by saying:

    $mx_medium = ["+File", -directory => "/var/tmp/www-sessions"];

You can further say:

    $mx_serializer = ["+Storable", -compress => 1];

to store sessions in compressed forms, although I advise you not to,
for performance reasons.  Actually, you should look at
L<CGI::MxScreen::Session::Medium::Raw_File> if you want fast session files.


=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

CGI::MxScreen::Session::Medium::Browser(3),
CGI::MxScreen::Session::Medium::Raw_File(3).

=cut


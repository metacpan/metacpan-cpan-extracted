#
# Apache::Auth::UserDB::File::Digest
# A Apache digest authentication file user database manager class.
#
# (C) 2003-2007 Julian Mehnle <julian@mehnle.net>
# $Id: Digest.pm 31 2007-09-18 01:39:14Z julian $
#
##############################################################################

package Apache::Auth::UserDB::File::Digest;

use version; our $VERSION = qv('0.120');

use warnings;
use strict;

use base qw(Apache::Auth::UserDB::File);

use Carp;

use Apache::Auth::User::Digest;

# Constants:
##############################################################################

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

# Implementation:
##############################################################################

sub _parse_entry {
    my ($self, $entry) = @_;
    
    $entry =~ /^([^:]*):([^:]*):([^:]*)$/
        or croak('Malformed userdb entry encountered: "' . $entry . '"');
    
    return Apache::Auth::User::Digest->new(
        name            => $1,
        realm           => $2,
        password_digest => $3
    );
}

sub _build_entry {
    my ($self, $user) = @_;
    
    return join(':',
        $user->name,
        $user->realm,
        $user->password_digest
    );
}

TRUE;

#################################################################
#
#   $Id: Invalid.pm,v 1.1 2006/05/17 20:40:14 erwan Exp $
#

package MockDB::Invalid;

use strict;
use warnings;
use base qw/Class::DBI::AutoIncrement/; # has no parents, which should trick Class::DBI::AutoIncrement into croaking

__PACKAGE__->table('invalid');
__PACKAGE__->columns(All => qw(seqid));
__PACKAGE__->autoincrement('seqid');

1;


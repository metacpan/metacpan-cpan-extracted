#################################################################
#
#   $Id: BookMin.pm,v 1.1.1.1 2006/04/28 13:58:15 erwan Exp $
#

package MockDB::BookMin;

use strict;
use warnings;
use base qw(Class::DBI::AutoIncrement MockDB::DBI);

__PACKAGE__->table('book');
__PACKAGE__->columns(All => qw(seqid author title isbn));
__PACKAGE__->autoincrement('seqid', Min => 17);

1;


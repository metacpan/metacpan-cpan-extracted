# $Id: Hlagh.pm,v 1.3 2008-06-24 17:33:32 cantrelld Exp $

use strict;
use warnings;

package DBIx::Class::SingletonRows::Tests::TestSchema::Hlagh;
use base qw(DBIx::Class);
__PACKAGE__->load_components(qw(SingletonRows Core));
__PACKAGE__->table('hlagh');
__PACKAGE__->add_columns(qw(key1 key2 somedata));
__PACKAGE__->set_primary_key(qw(key1 key2));

1;

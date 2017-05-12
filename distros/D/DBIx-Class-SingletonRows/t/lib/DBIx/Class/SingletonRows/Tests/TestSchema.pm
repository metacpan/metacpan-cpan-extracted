# $Id: TestSchema.pm,v 1.2 2008-06-18 15:59:11 cantrelld Exp $

use strict;
use warnings;

package DBIx::Class::SingletonRows::Tests::TestSchema;
use base qw(DBIx::Class::Schema);
__PACKAGE__->load_classes(qw(Hlagh));

1;

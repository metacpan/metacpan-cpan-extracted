package DBIx::QuickORM::DB::Percona;
use strict;
use warnings;

our $VERSION = '0.000002';

use parent 'DBIx::QuickORM::DB::MySQL';
use DBIx::QuickORM::Util::HashBase;

sub sql_spec_keys { qw/percona mysql/ }

sub supports_uuid { () }
sub supports_json { () }

1;

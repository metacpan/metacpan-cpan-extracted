package SVN::Dump::Change::Rmfile;
BEGIN {
  $SVN::Dump::Change::Rmfile::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change::Rm';

has '+operation' => ( default => 'file_deletion' );

# Files can't be entities.
sub is_entity { 0 }

1;

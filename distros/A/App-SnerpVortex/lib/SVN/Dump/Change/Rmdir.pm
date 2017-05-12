package SVN::Dump::Change::Rmdir;
BEGIN {
  $SVN::Dump::Change::Rmdir::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change::Rm';

has '+operation' => ( default => 'directory_deletion' );

1;

package SVN::Dump::Change::Rename;
BEGIN {
  $SVN::Dump::Change::Rename::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change::Copy';

has '+operation' => ( default => 'rename' );

1;

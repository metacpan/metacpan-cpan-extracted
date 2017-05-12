package SVN::Dump::Change::Cpdir;
BEGIN {
  $SVN::Dump::Change::Cpdir::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change::Copy';

has '+operation' => ( default => 'directory_copy' );

1;

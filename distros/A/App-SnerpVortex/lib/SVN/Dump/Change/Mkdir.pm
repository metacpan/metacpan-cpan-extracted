package SVN::Dump::Change::Mkdir;
BEGIN {
  $SVN::Dump::Change::Mkdir::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change';

has '+operation' => ( default => 'directory_creation' );

1;

package SVN::Dump::Change::Mkfile;
BEGIN {
  $SVN::Dump::Change::Mkfile::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change::Edit';

has '+operation' => ( default => 'file_creation' );

1;

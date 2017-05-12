package SVN::Dump::Change::Cpfile;
BEGIN {
  $SVN::Dump::Change::Cpfile::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change::Copy';

has '+operation'  => ( default => 'file_copy' );
has content       => ( is => 'ro', isa => 'Maybe[Str]' );

# Files can't be entities.
sub is_entity { 0 }

1;

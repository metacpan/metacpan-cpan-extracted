package SVN::Dump::Change::Edit;
BEGIN {
  $SVN::Dump::Change::Edit::VERSION = '1.000';
}

use Moose;
extends 'SVN::Dump::Change';

has content => (
	is => 'ro',
	isa => 'Maybe[Str]',
	required => 1,
	documentation => "Content of the change. Maybe[Str] because some changes (e.g. MediaWiki's r3671) only change properties",
);

has '+operation' => ( default => 'file_change' );

# Files can't be entities.
sub is_entity { 0 }

1;

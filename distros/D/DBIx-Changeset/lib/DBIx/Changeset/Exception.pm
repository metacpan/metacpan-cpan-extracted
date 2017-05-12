package DBIx::Changeset::Exception;

use warnings;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::Exceptions - the Exceptions base

=head1 EXCEPTIONS

=cut

use Exception::Class ( 
	'DBIx::Changeset::Exception::ObjectCreateException' => { description => 'Object Creation Error' },
	'DBIx::Changeset::Exception::ReadRecordException' => { description => 'Could not write from record' },
	'DBIx::Changeset::Exception::WriteRecordException' => { description => 'Could not write to record' },
	'DBIx::Changeset::Exception::DuplicateRecordNameException' => { description => 'Could create record as it already exists', fields => [ 'filename' ] },
	'DBIx::Changeset::Exception::ReadCollectionException' => { description => 'Could not read from collections changeset_location' },
	'DBIx::Changeset::Exception::MissingAddTemplateException' => { description => 'Could not read create_template' },
	'DBIx::Changeset::Exception::LoaderException' => { description => 'Could not load changeset record into database' },
	'DBIx::Changeset::Exception::ReadHistoryRecordException' => { description => 'Could not read from history record' },
	'DBIx::Changeset::Exception::WriteHistoryRecordException' => { description => 'Could not write to history record' },
);

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset::Exceptions

package DBIx::Changeset::Record::Disk;

use warnings;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

use base qw/DBIx::Changeset::Record/;
use IO::File;
use File::Spec;
use Encode;
require Digest::MD5;

=head1 NAME

DBIx::Changeset::Record::Disk - Read changeset files from the disk

=head1 SYNOPSIS

Read changeset files from the disk

this is a factory object and should be called the DBIx::Changeset::Record factory

    use DBIx::Changeset::Record;

    my $foo = DBIx::Changeset::Record->new('Disk', $opts);
    ...
    $foo->read('/moose/moose.sql');

=head1 METHODS

=head2 read
	This will read a file from the disk in the given location returning the data
	this is normally called from validate (which will set the id in the File object)
=cut
sub read {
	my ($self) = @_;
	my $fh = new IO::File;
	my $file = File::Spec->catfile($self->changeset_location, $self->uri);
	my $data;
	if ($fh->open("< $file")) {
		while( <$fh> ) {
			$data .= $_;
		}
		$fh->close;
	} else {
		DBIx::Changeset::Exception::ReadRecordException->throw(error => 'Could not open file for reading.'); 
	}
	return $data;
}

=head2 write
	This is the write interface implement in your own class
=cut
sub write {
	my ($self, $data) = @_;
	my $fh = IO::File->new();
	my $file = File::Spec->catfile($self->changeset_location, $self->uri);
	if ( -e $file ) {
		DBIx::Changeset::Exception::DuplicateRecordNameException->throw(error => 'Could not open file for writing as it already exists.', filename => $file);
		return;
	}
	if ($fh->open("> $file")) {
		printf $fh $data;
		$fh->close;
	} else {
		DBIx::Changeset::Exception::WriteRecordException->throw(error => 'Could not open file for writing.'); 
	}
	return;
}

=head2 md5

	Return the md5 of the files contents

=cut
sub md5 {
	my $self = shift;

	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8( $self->read ) );

	return $md5;
}


=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset::Record::Disk

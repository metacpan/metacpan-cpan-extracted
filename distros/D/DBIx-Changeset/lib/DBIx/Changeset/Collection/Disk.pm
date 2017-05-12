package DBIx::Changeset::Collection::Disk;

use warnings;
use strict;

use base qw/DBIx::Changeset::Collection/;
use DBIx::Changeset::Record;
use IO::Dir;
use File::Slurp qw/read_file/;
use POSIX qw/strftime/;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::Collection::Disk - Read changeset files from the disk

=head1 SYNOPSIS

Read changeset files from the disk

this is a factory object and should be called the DBIx::Changeset::Collection factory

    use DBIx::Changeset::Collection;

    my $foo = DBIx::Changeset::Collection->new('disk', $opts);
    ...
    $foo->retrieve('moose.sql');

=head1 METHODS

=head2 retrieve_all
=cut
sub retrieve_all {
	my ($self) = @_;
	$self->retrieve_like(qr/\.sql$/xm);
	return;
}

sub retrieve_like {
	my ($self,$regex) = @_;
	
	my $d = IO::Dir->new($self->changeset_location);
	
	if ( ( defined $d ) && ( -d $self->changeset_location ) ) {
		my @files = ();
		while (defined($_ = $d->read)) {
			next unless $_ =~ m!$regex!mx;
			push @files, DBIx::Changeset::Record->new('disk', { changeset_location => $self->changeset_location, uri => $_ });
		}
		$self->files(\@files);
		undef $d;
	} else {
		# Exception
		DBIx::Changeset::Exception::ReadCollectionException->throw(error => 'Could not open changeset_location for reading.'); 
	}
	
	$self->sort_changesets();

	return;
}

=head2 add_changeset

=cut

sub add_changeset {
	my ($self,$name) = @_;

	### create the record
	$name = POSIX::strftime("%Y%m%d_$name", localtime(time));

	my $record = DBIx::Changeset::Record->new('disk', { changeset_location => $self->changeset_location, uri => $name.".sql" });

	### read in the record template
	my $template;
	if ( $self->create_template ) {
		# open and read the template
		$template = read_file($self->create_template);
	} else {
		# Exception
		DBIx::Changeset::Exception::MissingAddTemplateException->throw(error => 'Missing create template path');
	}
	
	$record->generate_uid($template);
	$record->validate();

	unless ( defined $self->files ) {
		$self->files([]);
	}

	push @{$self->files}, $record;

	$self->sort_changesets();

	return File::Spec->catfile($self->changeset_location, $record->uri);
}

=head2 sort_changesets

	Sort the changesets in the collection from oldest to newest based ont eh date in the uri

=cut

sub sort_changesets {
	my $self = shift;
	
	my @sorted = sort {
		my $auri = $a->uri;
		my $buri = $b->uri;

		$auri cmp $buri;

	} @{$self->files};

	$self->files(\@sorted);

	return;
}

=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset::Collection::Disk

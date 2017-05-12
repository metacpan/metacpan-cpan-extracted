package DBIx::Changeset::Record;

use warnings;
use strict;

use base qw/Class::Factory DBIx::Changeset/;
use Data::UUID;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.11';
}

=head1 NAME

DBIx::Changeset::Record - Factory Interface to changeset files

=cut

=head1 SYNOPSIS

Factory Interface to changeset files

Perhaps a little code snippet.

    use DBIx::Changeset::Record;

    my $foo = DBIx::Changeset::Record->new('type', $opts);
    ...
	$foo->read('/moose/moose.sql');

=head1 INTERFACE

=head2 read
	This is the read interface implement in your own class
=cut
sub read {
die "Define read() in implementation"
}

=head2 write
	This is the write interface implement in your own class
=cut
sub write {
die "Define write() in implementation"
}

=head1 METHODS

=head2 init
 Called automatically to intialise the factory objects takes params passed to new and assigns them to
 accessors if they exist
=cut

sub init {
	my ( $self, $params ) = @_;

	DBIx::Changeset::Exception::ObjectCreateException->throw( error => 'Attempt to create Record Object without a uri.' ) unless defined $params->{'uri'};

	foreach my $field ( keys %{$params} ) {
		$self->{ $field } = $params->{ $field } if ( $self->can($field) );
	}
	return $self;
}

=head2 validate
	Validate that the file data is correct
=cut
sub validate {
	my ($self) = @_;
	my $file = $self->read($self->uri);
	
	if ($file =~ m!^/\*.*?tag:\s*(\S+)!mx) {
		$self->id($1);
		$self->valid(1);
	} else {
		$self->valid(0);
	}
	
	return;
}

=head2 generate_uid
	Generates a uid writing it to the file
=cut
sub generate_uid {
	my ($self, $data) = @_;
	my $ug = new Data::UUID;
	$data = $self->read() unless defined $data;
    $self->id($ug->to_string($ug->create()));
	### check for existing id
	if ($data =~ m!^/\*.*?tag:\s*(\S+)!mx) {
		### replace it
		my $id = sprintf('* tag: %s', $self->id);
		$data =~ s!\*.*?tag:\s*(\S+)!$id!exm;
	} else {
		### tack it on the end
		$data .= sprintf("\n/* tag: %s */\n",$self->id);
	}
	$self->write($data);
	return;
}

=head1 ACCESSORS

=head2 valid
	Has this file been processed as valid default false
args:
	bool
returns:
	bool

=head2 skipped
	Has this file been skipped default false
args: 
	bool
returns:
	bool

=head2 outstanding
	Is this file outstanding default false
args: 
	bool
returns:
	bool

=head2 id
	The UID of the file
args: 
	bool
returns:
	bool

=head2 uri
	The location of the file data * READ ONLY *
args: 
	string
returns:
	string
=cut

my @ACCESSORS = qw/id valid skipped outstanding forced/;
__PACKAGE__->mk_accessors(@ACCESSORS);

my @RO_ACCESSORS = qw/uri/;
__PACKAGE__->mk_ro_accessors(@RO_ACCESSORS);

=head1 OVERRIDEN METHODS

=head2 get

 Override the ger accessor for id and valid so that if they are undef
 validate is called.

=cut

sub get {
	my ($self, $key) = @_;

	if ( ($key eq 'id') || ($key eq 'valid') ) {
		my $value = $self->SUPER::get($key);
		unless ( defined $value ) {
			$self->validate();
		}
	} 
	return $self->SUPER::get($key);	
}


=head1 TYPES
 Default types included

=head2 disk
	Simply reads files from disk expects a uri of a filename
=cut
__PACKAGE__->register_factory_type( disk => 'DBIx::Changeset::Record::Disk' );


=head1 COPYRIGHT & LICENSE

Copyright 2004-2008 Grox Pty Ltd.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with this module.

=cut

1; # End of DBIx::Changeset

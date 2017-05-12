package ALPM;
use warnings;
use strict;

our $VERSION;
BEGIN {
	$VERSION = '3.06';
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);
}

## PUBLIC METHODS ##

sub dbs
{
	my($self) = @_;
	return ($self->localdb, $self->syncdbs);
}

sub db
{
	my($self, $name) = @_;
	for my $db ($self->dbs){
		return $db if($db->name eq $name);
	}
	return undef;
}

sub search
{
	my($self, @qry) = @_;
	return map { $_->search(@qry) } $self->dbs;
}

1;

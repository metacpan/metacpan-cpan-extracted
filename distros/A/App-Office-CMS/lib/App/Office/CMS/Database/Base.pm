package App::Office::CMS::Database::Base;

use Any::Moose;
use common::sense;

has db =>
(
	is  => 'rw',
	isa => 'Any',
);

# If Moose...
#use namespace::autoclean;

our $VERSION = '0.92';

# --------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> db -> log($level, $s);

} # End of log.

# --------------------------------------------------

no Any::Moose;

# If Moose...
#__PACKAGE__ -> meta -> make_immutable;

1;

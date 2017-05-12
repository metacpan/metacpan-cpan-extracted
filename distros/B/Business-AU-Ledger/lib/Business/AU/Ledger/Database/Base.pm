package Business::AU::Ledger::Database::Base;

use Moose;

has db     => (is => 'rw', isa => 'Business::AU::Ledger::Database');
has simple => (is => 'rw', isa => 'DBIx::Simple');

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> db -> log($s);

}	# End of log.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

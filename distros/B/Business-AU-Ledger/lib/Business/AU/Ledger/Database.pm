package Business::AU::Ledger::Database;

use Business::AU::Ledger::Database::Payment;
use Business::AU::Ledger::Database::Receipt;

use Log::Dispatch;
use Log::Dispatch::DBI;

use Moose;

has last_insert_id => (is => 'rw', isa => 'Int');
has logger         => (is => 'rw', isa => 'Log::Dispatch');
has payment        => (is => 'rw', isa => 'Business::AU::Ledger::Database::Payment');
has receipt        => (is => 'rw', isa => 'Business::AU::Ledger::Database::Receipt');
has simple         => (is => 'rw', isa => 'DBIx::Simple');

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> logger(Log::Dispatch -> new);
	$self -> logger -> add
	(
		Log::Dispatch::DBI -> new
		(
		 dbh       => $self -> simple -> dbh,
		 min_level => 'info',
		 name      => 'Ledger',
		)
	);
	$self -> payment(Business::AU::Ledger::Database::Payment -> new(db => $self, simple => $self -> simple) );
	$self -> receipt(Business::AU::Ledger::Database::Receipt -> new(db => $self, simple => $self -> simple) );

	return $self;

}	# End of BUILD.

# -----------------------------------------------

sub get_last_insert_id
{
	my($self, $table_name) = @_;

	$self -> last_insert_id($self -> simple -> dbh -> last_insert_id(undef, undef, $table_name, undef) );

}	# End of get_last_insert_id.

# -----------------------------------------------

sub get_month_name
{
	my($self, $number) = @_;
	my($month) = $self -> simple -> query('select name from months where id = ?', $number) -> hash;

	$self -> log(__PACKAGE__ . ". Leaving get_month_name: $number => $$month{'name'}");

	return $$month{'name'};

}	# End of get_month_name.

# -----------------------------------------------

sub get_month_number
{
	my($self, $name) = @_;
	my($month) = $self -> simple -> query('select id from months where name = ?', $name) -> hash;

	$self -> log(__PACKAGE__ . ". Leaving get_month_number. $name => $$month{'id'}");

	return $$month{'id'};

}	# End of get_month_number.

# -----------------------------------------------

sub get_months
{
	my($self, $number) = @_;
	my $month = $self -> simple -> query('select * from months') -> hashes;

	$self -> log(__PACKAGE__ . '. Leaving get_months');

	return $month;

}	# End of get_months.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> logger -> log(level => 'info', message => $s ? $s : '');

}	# End of log.

# -----------------------------------------------

sub validate_month
{
	my($self, $month_name) = @_;
	my($name)  = ucfirst lc $month_name;
	my(@month) = $self -> simple -> query('select code, name from months') -> hashes;
	my($ok)    = '';

	for (@month)
	{
		if ( ($name eq $$_{'code'}) || ($name eq $$_{'name'}) )
		{
			$ok = $$_{'name'};

			last;
		}
	}

	$self -> log(__PACKAGE__ . ". Leaving validate_month. $month_name => $ok");

	return $ok;

}	# End of validate_month.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

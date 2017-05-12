package Business::AU::Ledger::View::Reconciliation;

use JSON::XS;

use Moose;

extends 'Business::AU::Ledger::View::Base';

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub initialize
{
	my($self)         = @_;
	my($month)        = $self -> db -> get_months;
	my($start_month)  = $self -> session -> param('start_month');
	my($start_number) = $self -> db -> get_month_number($start_month) - 1;

	my($i);
	my($j);
	my(@output);

	for $i ($start_number .. ($start_number + 11) )
	{
		$j = $i;

		if ($j > 11)
		{
			$j -= 12;
		}

		push @output,
		{
			balance    => 0.00,
			difference => 0.00,
			month      => $$month[$j]{'name'},
			receipts   => 0.00,
		};
	}

	$self -> log(__PACKAGE__ . '. Leaving initialize');

	return JSON::XS -> new -> encode({results => [@output]});

} # End of initialize.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> db -> log($s);

} # End of log.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

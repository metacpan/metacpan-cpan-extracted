package App::Office::Contacts::Donations::View::Report;

use Date::Simple;

use Moose;

extends 'App::Office::Contacts::View::Base';

with 'App::Office::Contacts::View::Role::Report';
with 'App::Office::Contacts::Donations::View::Role::Report';

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub format_donation_amount_report
{
	my($self, $donation) = @_;

	$self -> log(debug =>  'Entered format_donation_total_report');

	my($count) = 0;
	my($total) = 0;

	my(@row);

	for (reverse sort{$$donation{$a}{'amount'} <=> $$donation{$b}{'amount'} } keys %$donation)
	{
		$count++;

		$total += $$donation{$_}{'amount'};

		push @row,
		{
			amount => $$donation{$_}{'amount'},
			name   => $_,
			number => $count,
			type   => $$donation{$_}{'type'},
		};
	}

	push @row,
	{
		amount => $total,
		name   => 'Total',
		number => '',
		type   => '',
	};

	return [@row];

} # End of format_donation_amount_report.

# -----------------------------------------------

sub format_donation_date_report
{
	my($self, $donation) = @_;

	$self -> log(debug =>  'Entered format_donation_date_report');

	$donation  = [sort{$$a{'timestamp'} cmp $$b{'timestamp'} || $$a{'name'} cmp $$b{'name'} } @$donation];
	my($total) = 0;

	my(@row);

	for (@$donation)
	{
		$total += $$_{'amount'};

		push @row,
		{
			amount    => '$' . $$_{'amount'},
			name      => $$_{'name'},
			timestamp => $$_{'timestamp'},
		};
	}

	push @row,
	{
		amount    => '$' . $total,
		name      => 'Total',
		timestamp => '',
	};

	return \@row;

} # End of format_donation_date_report.

# -----------------------------------------------

sub generate_report
{
	my($self, $input, $report_name) = @_;

	my($report);

	if ($report_name eq 'Records')
	{
		$report = $self -> generate_record_report($input);
	}
	else
	{
		$report = $self -> generate_donation_total_report($input, $report_name);

		if ($report_name eq 'Donations_by_amount')
		{
			$report = $self -> format_donation_amount_report($report);
		}
		elsif ($report_name eq 'Donations_by_date')
		{
			$report = $self -> format_donation_date_report($report);
		}
	}

	return $report;

} # End of generate_report.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

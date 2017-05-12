package Business::AU::Ledger::View::Context;

use Business::AU::Ledger::Util::Validate;

use JSON::XS;

use Moose;

extends 'Business::AU::Ledger::View::Base';

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub format
{
	my($self, $input) = @_;

	$self -> log(__PACKAGE__ . '. Leaving format');

	return
	[
	 {
		 month => $$input{'start_month'},
		 time  => 'From',
		 year  => $$input{'start_year'},
	 },
	 {
		 month => $$input{'end_month'},
		 time  => 'To',
		 year  => $$input{'end_year'},
	 }
	];

} # End of format.

# -----------------------------------------------

sub get
{
	my($self, $input) = @_;

	$self -> log(__PACKAGE__ . '. Leaving get');

	return
	{
		end_month   => $self -> session -> param('end_month'),
		end_year    => $self -> session -> param('end_year'),
		start_month => $self -> session -> param('start_month'),
		start_year  => $self -> session -> param('start_year'),
	};

} # End of get.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> db -> log($s);

} # End of log.

# -----------------------------------------------

sub process
{
	my($self, $input) = @_;
	my($msgs)   = $input -> msgs;
	my(%prompt) = map{my($s) = $_; $s =~ s/^field_//; $s =~ tr/_/ /; ($_ => ucfirst $s)} keys %$msgs;
	my($error)  = $input -> has_invalid || $input -> has_missing;

	my($output);

	if ($error)
	{
		my($msg);
		my(@msg);

		for $msg (sort keys %$msgs)
		{
			if ($msg =~ /^field_/)
			{
				push @msg, {time => "$prompt{$msg}: $$msgs{$msg}"};
			}
		}

		$output = {results => [@msg]};
	}
	else
	{
		# Use scalar context to retrieve a hash ref.

		my $input            = $input -> valid;
		my($month_number)    = $self -> db -> get_month_number($$input{'start_month'});
		my($start_date)      = Date::Simple::ymd($$input{'start_year'}, $month_number, 1);
		my($end_date)        = Date::Simple::ymd($$input{'start_year'} + 1, $month_number, 1);
		$end_date            -= 1; # Last day of previous month. May be previous year.
		my(@ymd)             = $end_date -> as_ymd;
		$end_date            = $end_date - Date::Simple::days_in_month($ymd[0], $ymd[1]) + 1;
		@ymd                 = $end_date -> as_ymd;
		$$input{'end_month'} = $self -> db -> get_month_name($ymd[1]);
		$$input{'end_year'}  = $ymd[0];
		my($row)             = $self -> format($input);

		$self -> session -> param(start_month => $$input{'start_month'}, start_year => $$input{'start_year'});
		$self -> session -> param(end_month   => $$input{'end_month'},   end_year   => $$input{'end_year'});

		if ($#$row >= 0)
		{
			$output = {results => $row};
		}
		else
		{
			$output = {results => [{time => 'No output produced'}]};
		}
	}

	$self -> log(__PACKAGE__ . '. Leaving process');

	return JSON::XS -> new -> encode($output);

} # End of process.

# -----------------------------------------------

sub update
{
	my($self)   = @_;
	my($input)  = Business::AU::Ledger::Util::Validate -> new(db => $self -> db, query => $self -> query) -> update_context;
	my($output) = $self -> process($input);

	$self -> log(__PACKAGE__ . '. Leaving update');

	return $output;

} # End of update.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

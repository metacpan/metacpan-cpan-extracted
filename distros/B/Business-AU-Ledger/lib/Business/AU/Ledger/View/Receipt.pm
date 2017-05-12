package Business::AU::Ledger::View::Receipt;

use Business::AU::Ledger::Util::Validate;

use Date::Simple;

use JSON::XS;

use Moose;

extends 'Business::AU::Ledger::View::Base';

has field_width => (is => 'rw', isa => 'HashRef');
has row_count   => (is => 'rw', isa => 'Int');

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> field_width
	(
	 {
		 amount      => 12,
		 bank_amount => 12,
		 comment     => 20,
		 day         =>  5, # For 'Total'.
		 gst_amount  => 12,
		 reference   => 10,
	 }
	);
	$self -> row_count(0);

} # End of BUILD;

# -----------------------------------------------

sub format
{
	my($self, $output) = @_;

	my($field);
	my($row, @row);

	for $row (@$output)
	{
		$field = $self -> format_fields($row);

		push @row, $field;
	}

	$self -> log(__PACKAGE__ . '. Leaving format');

	return [@row];

} # End of format.

# -----------------------------------------------

sub format_fields
{
	my($self, $default) = @_;
	$default            ||= {};

	# Ensure all fields, except menus, have defaults.

	for (qw/amount bank_amount comment day error gst_amount reference timestamp/)
	{
		if (! defined $$default{$_})
		{
			$$default{$_} = '';
		}
	}

	$self -> row_count($self -> row_count + 1);

	# The 'day' field will either come from the timestamp in a pre-existing record, or a total, or we leave it blank.

	if ($$default{'timestamp'})
	{
		($$default{'day'} = substr($$default{'timestamp'}, 8, 2) ) =~ s/^0//;

	}
	else
	{
		if ($$default{'day'} ne 'Total')
		{
			$$default{'day'} = '';
		}
	}

	my($field_width)    = $self -> field_width;
	my($row_count)      = $self -> row_count;
	my($result)         =
	{
		amount       => qq|<input type="text" name="amount_$row_count" id="amount_$row_count" size="$$field_width{'amount'}" value="$$default{'amount'}" />|,
		bank_amount  => qq|<input type="text" name="bank_amount_$row_count" id="bank_amount_$row_count" size="$$field_width{'amount'}" value="$$default{'bank_amount'}" />|,
		category     => $self -> build_select('receipt', 'category_code', "_$row_count", $$default{'category_code_id'} || 1),
		comment      => qq|<input type="text" name="comment_$row_count" id="comment_$row_count" size="$$field_width{'comment'}" value="$$default{'comment'}" />|,
		day          => qq|<input type="text" name="day_$row_count" id="day_$row_count" size="$$field_width{'day'}" value="$$default{'day'}" />|,
		error        => $$default{'error'},
		gst_amount   => qq|<input type="text" name="gst_amount_$row_count" id="gst_amount_$row_count" size="$$field_width{'gst_amount'}" value="$$default{'gst_amount'}" />|,
		gst_category => $self -> build_select('receipt', 'gst_code', "_$row_count", $$default{'gst_code_id'} || 1),
		reference    => qq|<input type="text" name="reference_$row_count" id="reference_$row_count" size="$$field_width{'reference'}" value="$$default{'reference'}" />|,
		submit       => qq|<input type="submit" name="submit_$row_count" id="submit_$row_count" value="Submit" />|,
		tx_detail    => $self -> build_select('receipt', 'tx_detail', "_$row_count", $$default{'tx_detail_id'} || 1),
	};

	# Clean up the total line.

	if (! $$default{'timestamp'})
	{
		if ($$default{'day'} eq 'Total')
		{
			for (qw/category tx_detail gst_category reference submit/)
			{
				$$result{$_} = '';
			}
		}
	}

	return $result;

} # End of format_fields.

# -----------------------------------------------

sub initialize
{
	my($self)  = @_;
	my($input) = Business::AU::Ledger::Util::Validate -> new(db => $self -> db, query => $self -> query) -> initialize_receipts;

	# Output all existing data (or errors).

	my($output) = $self -> process($input);

	# Output a row for new data.

	push @$output, $self -> format_fields;

	$self -> log(__PACKAGE__ . '. Leaving initialize');

	return JSON::XS -> new -> encode({results => $output});

} # End of initialize.

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
		my($prompt);

		for $msg (sort keys %$msgs)
		{
			if ($msg =~ /^field_/)
			{
				# Remove row_count part of field name.
				# I don't know why the row_count is preceeded by ' ' and not '_'.

				($prompt = $prompt{$msg}) =~ s/\s\d+$//;

				push @msg, "$prompt: $$msgs{$msg}";
			}
		}

		$output = [{error => [@msg]}];
	}
	else
	{
		# Use scalar context to retrieve a hash ref.

		$input = $input -> valid;

		# Init phase uses 'initialize', receipt phase uses 'month'.
		#
		# If the current month is before the first month of the financial year,
		# then it (the current month) is in the next year.

		my($month_number)       = $self -> db -> get_month_number($$input{'initialize'} || $$input{'month'});
		my($year)               = $self -> session -> param('start_year');
		my($start_month)        = $self -> session -> param('start_month');
		my($start_month_number) = $self -> db -> get_month_number($start_month);

		if ($month_number < $start_month_number)
		{
			$year++;
		}

		if (! $$input{'initialize'})
		{
			# Remove row_count from field names.

			my($id);
			my($key);

			# But first ...
			# Save the row_count associated with submit, since it's the only
			# row of input we are going to process. (The problem is that all
			# rows are submitted because they're all on the same form).

			for $key (keys %$input)
			{
				if ($key !~ /^submit/)
				{
					next;
				}

				($_ = $key) =~ s/_(\d+)$//;
				$id = $1;
			}

			# Now zap all input except the values with the same id.

			my($value);

			for $key (keys %$input)
			{
				# Skip the special cases, which are zapped below.

				if ($key !~ /\w_\d+/)
				{
					next;
				}

				$value      = delete $$input{$key};
				($_ = $key) =~ s/_(\d+)$//;

				if ($id != $1)
				{
					next;
				}

				$$input{$_} = $value;
			}

			# Convert user's value for 'day' into a timestamp.

			$$input{'timestamp'} = $self -> calculate_timestamp($$input{'month'}, $$input{'day'});

			# Remove CGI fields which are not database fields.

			for (qw/day rm sid submit/)
			{
				delete $$input{$_};
			}

			# Set defaults for optional fields.

			$$input{'comment'}     ||= '';
			$$input{'bank_amount'} ||= 0.00;
			$$input{'month'}       = $month_number;
			$$input{'gst_amount'}  ||= 0.00;
			$$input{'reference'}   ||= '';

			for (sort keys %$input)
			{
				$self -> log("Saving $_ => $$input{$_}");
			}

			$self -> db -> receipt -> add($input);
		}

		# This code goes here so we pick up the new record.

		$output = $self -> db -> receipt -> get_receipts_via_ym($year, $month_number);

		if ($#$output >= 0)
		{
			$output = $self -> total($output);
		}

		$output = $self -> format($output);
	}

	$self -> log(__PACKAGE__ . '. Leaving process');

	return $output;

} # End of process.

# --------------------------------------------------

sub submit
{
	my($self)  = @_;
	my($input) = Business::AU::Ledger::Util::Validate -> new(db => $self -> db, query => $self -> query) -> receipt;

	# Output all existing data (or errors).

	my($output) = $self -> process($input);

	# Output a row for new data.

	push @$output, $self -> format_fields;

	$self -> log(__PACKAGE__ . ". Leaving submit. Row count now: @{[scalar @$output]}");

	return JSON::XS -> new -> encode({results => $output});

} # End of submit.

# -----------------------------------------------

sub total
{
	my($self, $output) = @_;
	my(@key) = (qw/amount bank_amount gst_amount/);

	my(%total);

	for (@key)
	{
		$total{$_} = 0;
	}

	$total{'day'} = 'Total';

	my($row);

	for $row (@$output)
	{
		for (@key)
		{
			$total{$_} += $$row{$_};
		}
	}

	my($field_width) = $self -> field_width;

	for (@key)
	{
		# We avoid '%-' to right-justify, to make the total line stand out.

		$total{$_} = sprintf "\%$$field_width{$_}.2f", $total{$_};
	}

	$self -> log(__PACKAGE__ . '. Leaving total');

	push @$output, \%total;

	return $output;

} # End of total.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

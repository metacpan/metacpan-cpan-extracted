package Business::AU::Ledger::Database::Payment;

use Moose;

extends 'Business::AU::Ledger::Database::Base';

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub add
{
	my($self, $payment) = @_;

	eval
	{
		$self -> simple -> begin;
		$self -> save_payment_record('add', $payment);
		$self -> simple -> commit;
	};

	if ($@)
	{
		warn "add_payment died: $@";

		eval{$self -> simple -> rollback};

		die $@;
	}

	$self -> log(__PACKAGE__ . '. Leaving add');

} # End of add.

# -----------------------------------------------

sub get_payment_category_codes
{
	my($self) = @_;
	my $category = $self -> simple -> query('select name, id from category_codes where tx_type_id = 1') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_payment_category_codes");

	return $category;

} # End of get_payment_category_codes.

# -----------------------------------------------

sub get_payment_gst_codes
{
	my($self) = @_;
	my $gst   = $self -> simple -> query('select name, id from gst_codes where tx_type_id = 1') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_payment_gst_codes");

	return $gst;

} # End of get_payment_gst_codes.

# -----------------------------------------------

sub get_payment_payment_methods
{
	my($self) = @_;
	my $payment_method = $self -> simple -> query('select name, id from payment_methods') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_payment_payment_methods");

	return $payment_method;

} # End of get_payment_payment_methods.

# -----------------------------------------------

sub get_payment_tx_details
{
	my($self) = @_;
	my $detail = $self -> simple -> query('select name, id from tx_details') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_payment_tx_details");

	return $detail;

} # End of get_payment_tx_details.

# -----------------------------------------------

sub get_payments_via_ym
{
	my($self, $year, $month) = @_;
	my($timestamp) = sprintf('%4i-%02i', $year, $month);
	my $payment = $self -> simple -> query("select * from payments where to_char(timestamp, 'YYYY-MM') = '$timestamp'") -> hashes;

	$self -> log(__PACKAGE__ . ". Leaving get_payments_via_ym: $timestamp");

	return $payment;

} # End of get_payments_via_ym.

# --------------------------------------------------

sub save_payment_record
{
	my($self, $context, $payment) = @_;
	my($table_name)               = 'payments';
	my(@field)                    = (qw/category_code gst_code month payment_method tx_detail amount comment gst_amount petty_cash_in petty_cash_out private_use_amount private_use_percent reference timestamp/);
	my($data)                     = {};
	my(%id)                       =
	(
	 category_code  => 1,
	 gst_code       => 1,
	 month          => 1,
	 payment_method => 1,
	 tx_detail      => 1,
	);

	my($field_name);

	for (@field)
	{
		if ($id{$_})
		{
			$field_name = "${_}_id";
		}
		else
		{
			$field_name = $_;
		}

		$$data{$field_name} = $$payment{$_};
	}

	my($id);
	my($sql);
	my(@where);

	if ($context eq 'add')
	{
		$sql = "insert into $table_name";
	}
	else
	{
		$id    = $$payment{'id'};
		$sql   = "update $table_name set";
		@where = ('where id = ', $id);
	}

	$self -> simple -> iquery($sql, $data, @where);

	if ($context eq 'add')
	{
		$self -> db -> get_last_insert_id($table_name);

		$$payment{'id'} = $$data{'id'} = $self -> db -> last_insert_id;
	}

	$self -> log(__PACKAGE__ . '. Leaving save_payment_record');

} # End of save_payment_record.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

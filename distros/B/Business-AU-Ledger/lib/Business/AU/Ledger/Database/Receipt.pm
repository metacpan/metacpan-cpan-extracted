package Business::AU::Ledger::Database::Receipt;

use Moose;

extends 'Business::AU::Ledger::Database::Base';

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub add
{
	my($self, $receipt) = @_;

	eval
	{
		$self -> simple -> begin;
		$self -> save_receipt_record('add', $receipt);
		$self -> simple -> commit;
	};

	if ($@)
	{
		warn "add_receipt died: $@";

		eval{$self -> simple -> rollback};

		die $@;
	}

	$self -> log(__PACKAGE__ . '. Leaving add');

} # End of add.

# -----------------------------------------------

sub get_receipt_category_codes
{
	my($self) = @_;
	my $category = $self -> simple -> query('select name, id from category_codes where tx_type_id = 2') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_receipt_category_codes");

	return $category;

} # End of get_receipt_category_codes.

# -----------------------------------------------

sub get_receipt_gst_codes
{
	my($self) = @_;
	my $gst   = $self -> simple -> query('select name, id from gst_codes where tx_type_id = 2') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_receipt_gst_codes");

	return $gst;

} # End of get_receipt_gst_codes.

# -----------------------------------------------

sub get_receipt_tx_details
{
	my($self) = @_;
	my $detail = $self -> simple -> query('select name, id from tx_details') -> map;

	$self -> log(__PACKAGE__ . ". Leaving get_receipt_tx_details");

	return $detail;

} # End of get_receipt_tx_details.

# -----------------------------------------------

sub get_receipts_via_ym
{
	my($self, $year, $month) = @_;
	my($timestamp) = sprintf('%4i-%02i', $year, $month);
	my $receipt = $self -> simple -> query("select * from receipts where to_char(timestamp, 'YYYY-MM') = '$timestamp'") -> hashes;

	$self -> log(__PACKAGE__ . ". Leaving get_receipts_via_ym");

	return $receipt;

} # End of get_receipts_via_ym.

# --------------------------------------------------

sub save_receipt_record
{
	my($self, $context, $receipt) = @_;
	my($table_name)               = 'receipts';
	my(@field)                    = (qw/category_code gst_code month tx_detail amount bank_amount comment gst_amount reference timestamp/);
	my($data)                     = {};
	my(%id)                       =
	(
	 category_code => 1,
	 gst_code      => 1,
	 month         => 1,
	 tx_detail     => 1,
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

		$$data{$field_name} = $$receipt{$_};
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
		$id    = $$receipt{'id'};
		$sql   = "update $table_name set";
		@where = ('where id = ', $id);
	}

	$self -> simple -> iquery($sql, $data, @where);

	if ($context eq 'add')
	{
		$self -> db -> get_last_insert_id($table_name);

		$$receipt{'id'} = $$data{'id'} = $self -> db -> last_insert_id;
	}

	$self -> log(__PACKAGE__ . '. Leaving save_receipt_record');

} # End of save_receipt_record.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

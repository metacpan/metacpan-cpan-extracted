package Business::AU::Ledger::Util::Validate;

use Data::FormValidator;
use Data::FormValidator::Constraints qw/:closures/;

use Moose;

use Regexp::Common qw/number/;

has db    => (is => 'rw', isa => 'Business::AU::Ledger::Database');
has query => (is => 'rw', isa => 'CGI');

use namespace::autoclean;

our $myself;
our $VERSION = '0.88';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	$myself   = $self;

} # End of BUILD.

# -----------------------------------------------

sub clean_user_data
{
	my($data, $max_length) = @_;
	my($integer)           = 0;
	$data = '' if (! defined($data) || (length($data) == 0) || (length($data) > $max_length) );
	$data = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i);	# http://www.perl.com/pub/a/2002/02/20/css.html.
	$data = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);		# Ditto, but much more strict.
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	$data = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

	return $data;

}	# End of clean_user_data.

# --------------------------------------------------

sub filter_initialize
{
	my($value) = @_;
	$value     =~ s/^Initialize\s//;

	return $value;

} # End of filter_initialize.

# --------------------------------------------------

sub fix_double_quotes
{
	my($value) = @_;
	$value     =~ tr/"/'/;

	return $value;

} # End of fix_double_quotes.

# --------------------------------------------------

sub initialize_payments
{
	my($self) = @_;

	return Data::FormValidator -> check($self -> query, $self -> initialize_payments_profile);

} # End of initialize_payments.

# -----------------------------------------------

sub initialize_payments_profile
{
	my($self) = @_;

	return
	{
		constraint_methods =>
		{
			initialize => sub {return validate_month(pop)},
			month      => sub {return validate_month(pop)},
			rm         => sub {return pop eq 'initialize_payments' ? 1 : 0},
		},
		field_filters =>
		{	# These apply before constraints.
			initialize => sub {return filter_initialize(shift)},
		},
		filters                => [sub {return clean_user_data(shift, 250)}, 'strip'],
		missing_optional_valid => 1,
		msgs                   =>
		{
			any_errors => 'error',
			prefix     => 'field_',
		},
		required => [qw/initialize month rm sid/],
	};

} # End of initialize_payments_profile.

# --------------------------------------------------

sub initialize_receipts
{
	my($self) = @_;

	return Data::FormValidator -> check($self -> query, $self -> initialize_receipts_profile);

} # End of initialize_receipts.

# -----------------------------------------------

sub initialize_receipts_profile
{
	my($self) = @_;

	return
	{
		constraint_methods =>
		{
			initialize => sub {return validate_month(pop)},
			month      => sub {return validate_month(pop)},
			rm         => sub {return pop eq 'initialize_receipts' ? 1 : 0},
		},
		field_filters =>
		{	# These apply before constraints.
			initialize => sub {return filter_initialize(shift)},
		},
		filters                => [sub {return clean_user_data(shift, 250)}, 'strip'],
		missing_optional_valid => 1,
		msgs                   =>
		{
			any_errors => 'error',
			prefix     => 'field_',
		},
		required => [qw/initialize month rm sid/],
	};

} # End of initialize_receipts_profile.

# --------------------------------------------------

sub payment
{
	my($self) = @_;

	return Data::FormValidator -> check($self -> query, $self -> payment_profile);

} # End of payment.

# -----------------------------------------------

sub payment_profile
{
	my($self) = @_;

	return
	{
		constraint_method_regexp_map =>
		{
			qr/(?:(?:|gst_|private_use_|)amount|petty_cash_(?:in|out)|private_use_percent)/ => validate_amount(),
		},
		constraint_methods =>
		{
			day   => sub {return validate_day(pop)},
			month => sub {return validate_month(pop)},
			rm    => sub {return pop eq 'submit_payment' ? 1 : 0},
		},
		filters                => [sub {return clean_user_data(shift, 250)}, 'strip'],
		missing_optional_valid => 1,
		msgs                   =>
		{
			any_errors => 'error',
			prefix     => 'field_',
		},
		optional_regexp => qr/^(?:gst_amount|gst_code|petty_cash_in|petty_cash_out|private_use_amount|private_use_percent|reference|tx_detail)_\d+$/,
		required        => [qw/month rm sid/],
		required_regexp => qr/^(?:amount|category_code|day|payment_method|submit)_\d+$/,
	};

} # End of payment_profile.

# --------------------------------------------------

sub receipt
{
	my($self) = @_;

	return Data::FormValidator -> check($self -> query, $self -> receipt_profile);

} # End of receipt.

# -----------------------------------------------

sub receipt_profile
{
	my($self) = @_;

	return
	{
		constraint_methods=>
		{
			day   => sub {return validate_day(pop)},
			month => sub {return validate_month(pop)},
			rm    => sub {return pop eq 'submit_receipt' ? 1 : 0},
		},
		filters                => [sub {return clean_user_data(shift, 250)}, 'strip'],
		missing_optional_valid => 1,
		msgs                   =>
		{
			any_errors => 'error',
			prefix     => 'field_',
		},
		optional_regexp => qr/^(?:bank_amount|comment|gst_amount|gst_code|reference|tx_detail)_\d+$/,
		required        => [qw/month rm sid/],
		required_regexp => qr/^(?:amount|category_code|day|submit)_\d+$/,
	};

} # End of receipt_profile.

# --------------------------------------------------

sub update_context
{
	my($self) = @_;

	return Data::FormValidator -> check($self -> query, $self -> update_context_profile);

} # End of update_context.

# -----------------------------------------------

sub update_context_profile
{
	my($self) = @_;

	return
	{
		constraint_methods =>
		{
			rm          => sub {return pop eq 'update_context' ? 1 : 0},
			start_month => sub {return validate_month(pop)},
			start_year  => sub {return validate_year(pop)},
		},
		defaults =>
		{	# These apply before field_filters.
			comment => '', # Stop undef being passed thru to Postgres.
		},
		filters                => [sub {return clean_user_data(shift, 250)}, 'strip'],
		missing_optional_valid => 1,
		msgs                   =>
		{
			any_errors => 'error',
			prefix     => 'field_',
		},
		required => [qw/rm sid start_month start_year submit_context/],
	};

} # End of update_context_profile.

# --------------------------------------------------

sub validate_amount
{
	return sub
	{
		my($dfv, $value) = @_;
		my($field) = $dfv -> get_current_constraint_field;

		# Zap a leading $, if any;

		$value =~ s/^\$//;

		# Zap any embedded commas, if any.

		$value =~ tr/,//d;

		# Reject an empty field for 'amount'.

		if ( ($field =~ /^amount_\d+/) && (length($value) == 0) )
		{
			return 0;
		}

		# Accept up to 2 decimal places.

		return $RE{num}{decimal}{-places=>'0,2'} ? 1 : 0;
	};

} # End of validate_amount.

# --------------------------------------------------

sub validate_day
{
	my($value) = @_;

	# Can really only validate this when we know what month it is in.

	return $value > 0 and $value < 32 ? 1 : 0;

} # End of validate_day.

# --------------------------------------------------

sub validate_month
{
	my($value) = @_;

	return $myself -> db -> validate_month($value);

} # End of validate_month.

# --------------------------------------------------

sub validate_year
{
	my($value) = @_;

	return ($value >= 2000) && ($value <= 2031) ? $value : 0;

} # End of validate_year.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

package Business::AU::Ledger::View::Base;

use HTML::Template;

use Moose;

has config      => (is => 'rw', isa => 'HashRef');
has db          => (is => 'rw', isa => 'Business::AU::Ledger::Database');
has form_action => (is => 'rw', isa => 'Str');
has query       => (is => 'rw', isa => 'CGI');
has session     => (is => 'rw', isa => 'CGI::Session');

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub build_select
{
	my($self, $tx_type, $table, $suffix, $default) = @_;
	$suffix     .= '';
	my($key)    = "${tx_type}_${table}";
	my($method) = "get_${key}s";
	my(%object) =
	(
	 payment_category_code  => 'payment',
	 payment_gst_code       => 'payment',
	 payment_payment_method => 'payment',
	 payment_tx_detail      => 'payment',
	 receipt_category_code  => 'receipt',
	 receipt_gst_code       => 'receipt',
	 receipt_tx_detail      => 'receipt',
	);
	my($owner)    = $object{$key};
	my($option)   = scalar $self -> db -> $owner -> $method;
	my($template) = $self -> load_tmpl('select.tmpl');

	if (! defined $default)
	{
		$default = 1;
	}

	$template -> param(name => "$table$suffix");
	$template -> param(loop => [map{ {default => ($$option{$_} == $default ? 1 : 0), name => $_, value => $$option{$_} } } sort keys %$option]);

	return $template -> output;

} # End of build_select.

# -----------------------------------------------

sub calculate_timestamp
{
	my($self, $month_name, $day) = @_;
	my($month_number) = $self -> db -> get_month_number($month_name);

	# To get the year, we need to determine if the user's month is in the start year or the end year.

	my($start_year)         = $self -> session -> param('start_year');
	my($start_month)        = $self -> session -> param('start_month');
	my($start_month_number) = $self -> db -> get_month_number($start_month);

	# If the current month is before the first month of the financial year,
	# then it (the current month) is in the next year.

	if ($month_number < $start_month_number)
	{
		$start_year++;
	}

	return sprintf '%4i-%02i-%02i %02i:%02i:%02i', $start_year, $month_number, $day, 12, 0, 0;

} # End of calculate_timestamp.

# -----------------------------------------------

sub load_tmpl
{
	my($self, $name, @arg) = @_;

	return HTML::Template -> new(path => ${$self -> config}{'tmpl_path'}, filename => $name, @arg);

} # End of load_tmpl.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> db -> log($s);

}	# End of log.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

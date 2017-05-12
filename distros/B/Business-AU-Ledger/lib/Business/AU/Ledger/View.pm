package Business::AU::Ledger::View;

use Date::Simple;

use Business::AU::Ledger::View::Context;
use Business::AU::Ledger::View::Payment;
use Business::AU::Ledger::View::Receipt;
use Business::AU::Ledger::View::Reconciliation;

use Moose;

extends 'Business::AU::Ledger::View::Base';

has context        => (is => 'rw', isa => 'Business::AU::Ledger::View::Context');
has payment        => (is => 'rw', isa => 'Business::AU::Ledger::View::Payment');
has receipt        => (is => 'rw', isa => 'Business::AU::Ledger::View::Receipt');
has reconciliation => (is => 'rw', isa => 'Business::AU::Ledger::View::Reconciliation');
has web_page       => (is => 'rw', isa => 'HTML::Template');

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> context(Business::AU::Ledger::View::Context -> new
	(
	 config => $self -> config,
	 db => $self -> db,
	 query => $self -> query,
	 session => $self -> session,
	) );

	$self -> payment(Business::AU::Ledger::View::Payment -> new
	(config => $self -> config,
	 db => $self -> db,
	 query => $self -> query,
	 session => $self -> session,
	) );

	$self -> receipt(Business::AU::Ledger::View::Receipt -> new
	(config => $self -> config,
	 db => $self -> db,
	 query => $self -> query,
	 session => $self -> session,
	) );

	$self -> reconciliation(Business::AU::Ledger::View::Reconciliation -> new
	(config => $self -> config,
	 db => $self -> db,
	 query => $self -> query,
	 session => $self -> session,
	) );

	$self -> web_page($self -> load_tmpl('web.page.tmpl') );
	$self -> web_page -> param(css_url => ${$self -> config}{'css_url'});
	$self -> web_page -> param(yui_url => ${$self -> config}{'yui_url'});

} # End of BUILD;

# -----------------------------------------------

sub build_about
{
	my($self)     = @_;
	my($template) = $self -> load_tmpl('table.even.odd.tmpl', loop_context_vars => 1);

	my(@tr);

	push @tr, {left_td => 'Program', right_td => "Business::AU::Ledger V $VERSION"};
	push @tr, {left_td => 'Author', right_td => 'Ron Savage'};

	$template -> param(tr_loop => \@tr);

	$template = $template -> output;
	$template =~ s/\n//g;

	return $template;

} # End of build_about.

# -----------------------------------------------

sub build_context
{
	my($self)     = @_;
	my($template) = $self -> load_tmpl('update.context.tmpl');
	my($year)     = Date::Simple -> today -> year;

	$template -> param(rm          => 'update_context');
	$template -> param(sid         => $self -> session -> id);
	$template -> param(start_month => ${$self -> config}{'start_month'});
	$template -> param(start_year  => $year);

	$template = $template -> output;
	$template =~ s/\n//g;

	my($js) = $self -> load_tmpl('update.context.js');

	$js -> param(form_action => $self -> form_action);

	return ($js -> output, $template);

} # End of build_context.

# -----------------------------------------------

sub build_monthly_tabs
{
	my($self) = @_;
	my($js)   = $self -> load_tmpl('monthly.tabs.js');

	$js -> param(form_action => $self -> form_action);
	$js -> param(sid         => $self -> session -> id);

	return $js -> output;

} # End of build_monthly_tabs.

# -----------------------------------------------

sub build_payments
{
	my($self)     = @_;
	my($template) = $self -> load_tmpl('update.payments.tmpl');

	$template -> param(result => 'Financial Year not yet defined');

	$template = $template -> output;
	$template =~ s/\n//g;

	return $template;

} # End of build_payments.

# -----------------------------------------------

sub build_receipts
{
	my($self)     = @_;
	my($template) = $self -> load_tmpl('update.receipts.tmpl');

	$template -> param(result => 'Financial Year not yet defined');

	$template = $template -> output;
	$template =~ s/\n//g;

	return $template;

} # End of build_receipts.

# -----------------------------------------------

sub build_reconciliation
{
	my($self)     = @_;
	my($template) = $self -> load_tmpl('update.reconciliation.tmpl');

	$template -> param(result     => 'Financial Year not yet defined');

	$template = $template -> output;
	$template =~ s/\n//g;

	my($js) = $self -> load_tmpl('update.reconciliation.js');

	$js -> param(form_action => $self -> form_action);
	$js -> param(sid         => $self -> session -> id);

	return ($js -> output, $template);

} # End of build_reconciliation.

# -----------------------------------------------

sub build_tab_set
{
	my($self)           = @_;
	my($about)          = $self -> build_about;
	my($monthly_tabs)   = $self -> build_monthly_tabs;
	my(@context)        = $self -> build_context;
	my($payments)       = $self -> build_payments;
	my($receipts)       = $self -> build_receipts;
	my(@reconciliation) = $self -> build_reconciliation;

	# These things are being declared globally.

	my($head_js) = <<EJS;
$monthly_tabs
$context[0]
$reconciliation[0]

function make_context_start_month_focus(eve)
{
	document.context_form.start_month.focus();
}

var div_name;
var form_name;

var payments_tab_set;
var receipts_tab_set;
var tab_set = new YAHOO.widget.TabView();

var payments_month = new Array(12);
var receipts_month = new Array(12);

var about_tab;
var context_tab;
var payments_tab;
var receipts_tab;
var reconciliations_tab;
EJS
	# Note: These things are called by YAHOO.util.Event.onDOMReady(init).

	my($head_init) = <<EJS;
context_tab = new YAHOO.widget.Tab
({
	label: 'Options',
	content: '$context[1]',
	active: true
});
tab_set.addTab(context_tab);
context_tab.addListener('click', make_context_start_month_focus);

payments_tab = new YAHOO.widget.Tab
({
	label: 'Payments',
	content: '$payments',
	active: false
});
tab_set.addTab(payments_tab);
//payments_tab.addListener('click', make_search_name_focus);

receipts_tab = new YAHOO.widget.Tab
({
	label: 'Receipts',
	content: '$receipts',
	active: false
});
tab_set.addTab(receipts_tab);
//receipts_tab.addListener('click', make_search_name_focus);

reconciliations_tab = new YAHOO.widget.Tab
({
	label: 'Reconciliations',
	content: '$reconciliation[1]',
	active: false
});
tab_set.addTab(reconciliations_tab);
//reconciliations_tab.addListener('click', make_search_name_focus);

about_tab = new YAHOO.widget.Tab
({
	label: 'About',
	content: '$about'
});
tab_set.addTab(about_tab);

tab_set.appendTo('container');

make_context_start_month_focus();
EJS

	$self -> web_page -> param(head_js   => $head_js);
	$self -> web_page -> param(head_init => $head_init);
	$self -> log(__PACKAGE__ . '. Leaving build_tab_set');

	return $self -> web_page -> output;

} # End of build_tab_set.

# --------------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;

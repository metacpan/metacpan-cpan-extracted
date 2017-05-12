package Business::AU::Ledger;

use base 'CGI::Application';
use strict;
use warnings;

use Business::AU::Ledger::Database;
use Business::AU::Ledger::Util::Config;
use Business::AU::Ledger::View;

use CGI::Session;
use DBIx::Simple;

use Hash::FieldHash qw(:all);

fieldhash my %config  => 'config';
fieldhash my %db      => 'db';
fieldhash my %session => 'session';
fieldhash my %simple  => 'simple';
fieldhash my %view    => 'view';

our $VERSION = '0.88';

# -----------------------------------------------

sub initialize_payments
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving initialize_payments');

	return $self -> view -> payment -> initialize;

} # End of initialize_payments.

# -----------------------------------------------

sub initialize_receipts
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving initialize_receipts');

	return $self -> view -> receipt -> initialize;

} # End of initialize_receipts.

# -----------------------------------------------

sub initialize_reconciliation
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving initialize_reconciliation');

	return $self -> view -> reconciliation -> initialize;

} # End of initialize_reconciliation.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> db -> log($s);

} # End of log.

# -----------------------------------------------

sub setup
{
	my($self) = @_;
	my($q)    = $self -> query;

	$self -> run_modes([qw/initialize_payments initialize_receipts initialize_reconciliation submit_payment submit_receipt tab_set update_context update_payments update_receipts/]);
	$self -> start_mode('tab_set');

	$self -> config(Business::AU::Ledger::Util::Config -> new -> config);

	my($config) = $self -> config;
	my($attr)   =
	{
		AutoCommit => $$config{'AutoCommit'},
		RaiseError => $$config{'RaiseError'},
	};

	$self -> simple(DBIx::Simple -> connect($$config{'dsn'}, $$config{'username'}, $$config{'password'}, $attr) );
	$self -> db(Business::AU::Ledger::Database -> new(simple => $self -> simple) );

	$self -> session
	(
	 CGI::Session -> new
	 (
	  $$config{'session_driver'},
	  $q,
	  {
		  Handle    => $self -> simple -> dbh,
		  TableName => $$config{'session_table_name'},
	  },
	  {
		  name => 'sid',
	  }
	 )
	);

	$self -> log('.' x 50);
	$self -> log('sid => ' . $self -> session -> id);
	$self -> log('.' x 50);
	$self -> log("Param: $_ => " . $q -> param($_) ) for $q -> param;
	$self -> log(__PACKAGE__ . '. Leaving setup');

	$self -> view(Business::AU::Ledger::View -> new
	(
	 config      => $self -> config,
	 db          => $self -> db,
	 form_action => $self -> query -> url(-absolute => 1),
	 query       => $q,
	 session     => $self -> session,
	) );

} # End of setup.

# -----------------------------------------------

sub submit_payment
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving submit_payment');

	return $self -> view -> payment -> submit;

} # End of submit_payment.

# -----------------------------------------------

sub submit_receipt
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving submit_receipt');

	return $self -> view -> receipt -> submit;

} # End of submit_receipt.

# -----------------------------------------------

sub tab_set
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving tab_set');

	return $self -> view -> build_tab_set;

} # End of tab_set.

# -----------------------------------------------

sub update_context
{
	my($self) = @_;

	$self -> log(__PACKAGE__ . '. Leaving update_context');

	return $self -> view -> context -> update;

} # End of update_context.

# -----------------------------------------------

1;

=head1 NAME

C<Business::AU::Ledger> - A simple, web-based, payments/receipts manager

=head1 Synopsis

A CGI script:

	#!/usr/bin/perl

	use Business::AU::Ledger;

	Business::AU::Ledger -> new -> run;

=head1 Description

C<Business::AU::Ledger> is a pure Perl module.

It is based on C<CGI::Application>.

It provides a web-based interface to a database of payment, receipt and reconciliation transactions.

The database schema is shipped in docs/schema.png.

=head1 TODO

This version is being released as 0.80 rather than the 1.00 I wanted, because of the following
missing features.

AFAICT, the transactions themselves are reliably stored and retrieved from the database.

Nevertheless, I do not regard this code as production-ready, because of this TODO list.

These items are not listed in any particular order:

=over 4

=item Reconciliations

These are simply not coded yet.

=item REST-style usage

The code uses the CGI::Application standard way of specifying state via the 'rm' hidden CGI form
field.

I would prefer to switch to REST-style usage of the path info to transmit such information.

This would make it easy to use FCGI::ProcManager to speed things up.

=item Allow specific transactions to be deleted

There is no Delete button displayed. You need to blank out all fields and submit the transaction.

Another column containing Delete buttons makes the display wider :-(.

=item Handle split cheques

Another tab on the screen needs to be designed and coded for these.

=item Categories and Types

The lists for Category and Type of transaction are loaded into the database at initialization time
from text files.

There is no way for the user to update these lists.

=item Petty Cash

How, exactly, to handle Petty Cash?

I personally don't use it, but I assume some people do.

=item Co-dependent fields

Given one of the Private Use % and $ columns, the other can be calculated. Perhaps only get user input
for one of them.

=item In-situ Updates

Performing an in-situ update of a displayed transaction requires knowing the id of each.

=item Test Data

It would be good to have a command-line script which jammed a few transactions into the database
for testing purposes.

=item Non-web interface

The POD should explain how to use the given modules to circumvent the web interface.

=back

=head1 Constructor and initialization

new(...) returns an object of type C<Business::AU::Ledger>.

This is the class's contructor.

Usage: Business::AU::Ledger -> new.

=head1 Method: setup

This method lists the valid run modes, which are:

=over 4

=item initialize_payments

=item initialize_receipts

=item submit_payment

=item submit_receipt

=item tab_set

=item update_context

=item update_payments

=item update_receipts

=back

=head1 Installation and Configuration

=head2 Installation

There are several steps in the installation process:

=over 4

=item Install the database server

You will edit .htledger.conf, as explained below, to tell Business::AU::Ledger
how to connect to the database.

=item Install the Perl module Business::AU::Ledger

This is the same as installing any other Perl module.

Note, however, that you will I<always> need to download the distro from CPAN,
because other installation and configuration steps use files not installed in the
Perl module tree.

Note, also, that installing the module will install a file called .htledger.conf in Perl's module tree,
and in the next few steps you may wish to edit that file. In this case, the file's permissions become relevant.

=item Install the HTML templates

Unpack the distro, and copy (recursively) the directory htdocs/assets/ to your web server's doc root directory.

If you do not wish to use the recommended directory structure, put the contents of
htdocs/assets/css/business/au/ledger/ and htdocs/assets/templates/business/au/ledger/ anywhere you want,
and edit the file lib/Business/AU/Ledger/.htledger.conf (css_url and tmpl_path) to match.

=item Install the YUI (see FAQ below)

Download YUI from http://developer.yahoo.com/yui/ and install it in your web server's doc root directory.

Then, if necessary, edit lib/Business/AU/Ledger/.htledger.conf, where it says yui_url=/yui.

=item Install lib/Business/AU/Ledger/.htledger.conf

Installing the module will have installed the version of .htledger.conf as shipped within the distro.

If you edit your local copy of .htledger.conf, you must use your edited copy to overwrite the version installed
automatically.

Specifically, the database credentials in this file will need to be edited, since several programs use them
to connect to the database.

=item Install the CGI script ledger.cgi

Copy cgi-bin/ledger.cgi into your web server's cgi-bin directory, and mark it as executable.

=back

=head2 Configuation

=over 4

=item Initialize the database tables

In the unpacked distro dir, run:

	perl scripts/create.tables.pl
	perl scripts/populate.tables.pl

Check that this worked by logging on to your database server, via the command line say, and running:

	select * from tx_details

You should get 15 rows output.

=item Point your web client at http://127.0.0.1/cgi-bin/ledger.cgi

To start, you must specify the first month of your financial year.

After that, click on Payments or Receipts, then on the name of a month.

Lastly, click on Initialize to display any transactions already in the database for that month.

=back

=head1 FAQ

=head2 Q: How do you handle the ATO's requirements for BAS and GST?

ATO is Australian Tax Office.

BAS is Business Activity Statement, the basic document by which many businesses report turnover details.

GST is Goods and Services Tax.

The answer is: I don't (for which I'm extremely grateful).

That is, I run my business in such a way as to simply not need to account for those details. I do this
by performing contract programming services via a contract with Freelance Global ( http://www.freelance-global.com/ ),
an organization operated by my accountant (M. Kelson).

Organizations wishing to hire me sign a contract with Freelance, not with me directly.
Hence I avoid the need to manage BAS- and GST-related components of financial transactions.

However, I do understand they are important, and will eventually add those features if those of you needing them
give me the support I need.

=head2 Q: What happened to the Petty Cash/Private Use columns in the Payments input screen?

A: I don't use those fields. If they vanished from one version to the next, it's because
I commented them out in assets/templates/business/au/ledger/monthly.tabs.js, and forgot to re-enable them
before releasing the new version. Sorry!

Commenting them out means the required display width is narrower, and so I can use a bigger screen font.

You can safely just uncomment lines 57 .. 60 of that file.

=head2 Q: What's the basic design of the code?

A: MVC (Model, View, Controller).

The Model component is implemented in Business::AU::Ledger::Database and Business::AU::Ledger::Database::*.

The View component is in Business::AU::Ledger::View and Business::AU::Ledger::View::*.

The Controller is this module, Business::AU::Ledger.

=head2 Q: How do I configure things?

A: See lib/Business/AU/Ledger/.htledger.conf.

See also the previous section 'Installation and Configuration'.

See also the discussion below regarding the AU namespace.

=head2 Q: Which JavaScript library do you use?

A: YUI, the Yahoo! User Interface Library ( http://developer.yahoo.com/yui/ ).

I'm using V 2.7.0 of YUI.

=head2 Q: Can you, or will you, rewrite it to use a different JavaScript (non-YUI) package?

A: Don't be ridiculous.

=head2 Q: Why is it in the AU namespace?

A: Some of the code, a very small amount, depends on the Australian taxation system.

In fact, one reason for the Options tab (one day) is to allow for tax years which don't start in July the way ours do.
The default value for the month which starts each financial year can also be set in .htledger.conf.

There are, of course, various place where Australian-specific output is generated. Here I'm referring to
the columns in the Payments and Receipts tabs.

See Business::AU::Ledger::View::Payments and ::Receipts, in particular. See also the corresponding JavaScript
file assets/templates/business/au/ledger/monthly.tabs.js.

Of course, the pop-up menus for various columns contain data specific to the ATO's classification system.
See the files in the data/ directory, which initalize the corresonding database tables.

=head1 Author

C<Business::AU::Ledger> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2009.

Home page: http://savage.net.au/index.html

=head1 Copyright

	Australian copyright (c) 2009,  Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	the Artistic or the GPL licences, copies of which is available at:
	http://www.opensource.org/licenses/index.html

=cut


package Business::Cashcow;

use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);
$VERSION = '0.61';


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Cashcow macro $constname";
	}
    }
    no strict 'refs';
    *$AUTOLOAD = sub () { $val };
    goto &$AUTOLOAD;
}

bootstrap Business::Cashcow $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Business::Cashcow - Perl wrapper for Cascow, a lib for making Dankort payment.

=head1 SYNOPSIS

A module for clearing Internet payment transactions with the Danish PBS
through a SSL connection, provided by the excellent OpenSSL library.
CashCow will clear the following kinds of transactions between a customer
and PBS:

	Dankort 
	Visa/Dankort 
	Eurocard 
	MasterCard 
	Visa

This module is a perl wrapper for the c lib cashcow, se http://www.cashcow.dk/
for more info.

=head1 DESCRIPTION

Business::Cashcow::InitCashcow("passphrase", "rc4key");

Call this function to load the /etc/cashcow.ini file and setup state
regarding keys and certificates. Returns true if private key was
successfully unlocked using the supplied passphase, false
otherwise.

  my $transaction = {card_number => '76009244561',
                     card_expirymonth => 7,
                     card_expiryyear => 8,
                     transaction_reference => '99910326',
                     transaction_amount => 7.25,
                     transaction_currency => 208,
                     merchant_name => 'Enterprise Advertising A/S',
                     merchant_address => 'Aarhusgade 108E, 3.',
                     merchant_city => 'Koebenhavn',
                     merchant_zip => '2100 OE',
                     merchant_region => '',
                     merchant_country => 'DNK',
                     merchant_poscode => 0,    # POS_ECOMMERCE_SSL
                     merchant_number => '2133334',
                     merchant_terminalid => 'INET01',
                     result_action => 0,
                     result_approval => '',
                     result_ticket => '',
                     cashcow => ''
                    };

  Business::Cashcow::RequestAuth($transaction, $ticket, "secret");

This function make the initial communucation to verify the card etc. It
returns on of the folowing status messages:

  'action_approved',
  'action_decline',
  'action_partly_approved',
  'action_amount_error',
  'action_invalid_transaction',
  'action_no_reply',
  'action_system_error',
  'action_expired_card',
  'action_retransmit',
  'action_internal_error'

and sets $ticket to a ticket to be used as reference of the transaction in
Cashcow::RequestCapture. It shoud be called as a response of an order.

  Business::Cashcow::RequestCapture($ticket,"secret",7.25);

This function compleetes the payment. It should be called when the
merchant has fullfilled the order.

=head1 BUGS

The software is an alpha, so don't blame me, but bug (and success)
reports are also welcome.

=head1 AUTHOR

Gustav Kristoffer Ek <stoffer@netcetera.dk>

Copyright 1999 Gustav Kristoffer Ek. All rights reserved. This program
is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

sub InitCashcow;
sub AuthRequest;
sub RequestCapture;


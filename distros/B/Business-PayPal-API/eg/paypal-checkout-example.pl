#!/usr/bin/perl
#
# paypal-checkout  --  Interface zu PayPals ExpressCheckout SOAP-API
#
############################################
#
# Copyright (C) 2006 by Andy Spiegl, KasCada
#
# This perl script is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.6 or,
# at your option, any later version of Perl 5 you may have available.
#
############################################
#
# History:
#
# v0.1  2005-12-09: erste funktionierende Version
#
############################################

my $VERSION = "0.1";

############################################

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

use Business::PayPal::API::ExpressCheckout;

use Data::Dumper;

# security for shell calls:
$ENV{'PATH'} = '/bin:/usr/bin';
delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

############################################
# globale VARIABLEN
############################################

my $debug           = 0;
my $errors_occurred = 0;

# some self detection
my $self = $0;
$self =~ s|.*/||;

my $hostname = `/bin/hostname -f`;
chomp $hostname;
$hostname = "none" unless $hostname;

my $TMPDIR = $ENV{'TEMP'} || $ENV{'TMPDIR'} || "/tmp";

############################################
# konfigurierbare VARIABLEN
############################################

# unser PayPal-Username, PayPal-Passwort und PayPal-Signature
# werden über das Environment oder als Parameter übergeben.
my $pp_username  = $ENV{'PP_USERNAME'}  if $ENV{'PP_USERNAME'};
my $pp_password  = $ENV{'PP_PASSWORD'}  if $ENV{'PP_PASSWORD'};
my $pp_signature = $ENV{'PP_SIGNATURE'} if $ENV{'PP_SIGNATURE'};

############################################
# command line options
############################################
# option defaults
my $showhelp    = 0;
my $showmanpage = 0;
my $showversion = 0;
my $step        = 0;
my ( $OrderTotal, $InvoiceID, $BuyerEmail, $OrderDescription );
my $ReturnURL               = 'http://blafaselfoo.sonst.was/paypal/return';
my $CancelURL               = 'http://blafaselfoo.sonst.was/paypal/cancel';
my $PageStyle               = '';
my $cpp_header_image        = '';
my $cpp_header_border_color = '';
my $cpp_header_back_color   = '';
my $cpp_payflow_color       = '';
my $Token;
my $PayerID;

GetOptions(
    "help|usage"  => \$showhelp,     # show usage
    "manpage"     => \$showmanpage,  # show manpage
    "version"     => \$showversion,  # show programm version
    "debug+"      => \$debug,        # (incremental option)
    "username=s"  => \$pp_username,  # 3-token PayPal-Zugangsdaten
    "password=s"  => \$pp_password,  # 3-token PayPal-Zugangsdaten
    "signature=s" => \$pp_signature, # 3-token PayPal-Zugangsdaten
    "step=i"      => \$step,         # wievielter Schritt des Zahlungsvorgangs
    "OrderTotal=s"       => \$OrderTotal,          # Betrag in Euro
    "OrderDescription=s" => \$OrderDescription,    # 127 Zeichen Beschreibung
    "InvoiceID=s"        => \$InvoiceID,           # eindeutige Rechnungs-ID
    "BuyerEmail=s"       => \$BuyerEmail,          # E-Mail des Kunden
    "ReturnURL=s"        => \$ReturnURL,           # redirect-URL nach Kauf
    "CancelURL=s"        => \$CancelURL,           # redirect-URL bei Abbruch
    "PageStyle=s"        => \$PageStyle,
    "cpp_header_image=s" => \$cpp_header_image,
    "cpp_header_border_color=s" => \$cpp_header_border_color,
    "cpp_header_back_color=s"   => \$cpp_header_back_color,
    "cpp_payflow_color=s"       => \$cpp_payflow_color,
    "Token=s"                   => \$Token,                   # PayPal-Token
    "PayerID=s"                 => \$PayerID,                 # PayPal-PayerID

) or pod2usage( -exitstatus => 1, -verbose => 0 );

# turn off buffering (sinnvoll für Debugging)
$| = 1 if $debug;

# are there more arguments?
if ( $#ARGV >= 0 ) {
    pod2usage(
        -message    => "ERROR: unknown arguments \"@ARGV\".\n",
        -exitstatus => 2,
        -verbose    => 0
    );
}

pod2usage( -exitstatus => 0, -verbose => 1 ) if $showhelp;
pod2usage( -exitstatus => 0, -verbose => 2 ) if $showmanpage;

if ($showversion) { print "$self - Version: $VERSION\n"; exit; }

if ($debug) {
    print "DEBUG-Modus($debug): schalte $self in Debugmodus.\n";
}

############################################
# Hauptprogramm
############################################

print "Starte $self (v$VERSION)\n" if $debug;

# ohne Zugangsdaten können wir gleich aufhören
if ( not( $pp_username and $pp_password and $pp_signature ) ) {
    &error_exit(
        "Environment-Variablen PP_USER, PP_PASS und PP_SIGNATURE müssen gesetzt sein oder per Parameter angegeben werden.",
        5
    );
}
&print_debug( "PayPal-Username: $pp_username",  1 );
&print_debug( "PayPal-Passwort: $pp_password",  1 );
&print_debug( "PayPal-Signatur: $pp_signature", 1 );

# Authentifizierungsdaten an API-Modul übergeben
#  see Business::PayPal::API documentation for parameters
my $pp = new Business::PayPal::API::ExpressCheckout(
    Username  => $pp_username,
    Password  => $pp_password,
    Signature => $pp_signature,
    sandbox   => 0
);

if ( $debug >= 2 ) {
    $Business::PayPal::API::Debug = 1;
}

# Zahlungsvorgang Schritt 1
if ( $step == 1 ) {

    # Parameter prüfen
    ##################
    if ( not $OrderTotal ) {
        &error_exit( "OrderTotal fehlt.", 11 );
    }
    &print_debug( "OrderTotal: $OrderTotal:", 1 );

    if ( not $OrderDescription ) {
        &error_exit( "OrderDescription fehlt.", 12 );
    }
    if ( length($OrderDescription) > 127 ) {
        &print_debug(
            "Achtung, kürze zu lange OrderDescription auf 127 Zeichen.", 1 );
        $OrderDescription = substr( $OrderDescription, 1, 127 );
    }
    &print_debug( "OrderDescription: $OrderDescription", 1 );

    if ( not $InvoiceID ) {
        &error_exit( "InvoiceID fehlt.", 13 );
    }
    &print_debug( "InvoiceID: $InvoiceID:", 1 );

    if ( not $BuyerEmail ) {
        &error_exit( "BuyerEmail fehlt.", 14 );
    }
    &print_debug( "BuyerEmail: $BuyerEmail:", 1 );

    if ( not $ReturnURL ) {
        &error_exit( "ReturnURL nicht angegeben.", 15 );
    }
    &print_debug( "ReturnURL: $ReturnURL:", 1 );

    if ( not $CancelURL ) {
        &error_exit( "CancelURL nicht angegeben.", 16 );
    }
    &print_debug( "CancelURL: $CancelURL:", 1 );

    # und jetzt abschicken
    ######################
    my %response = $pp->SetExpressCheckout(
        OrderTotal => $OrderTotal,
        MaxAmount => $OrderTotal, # es fällt keine Steuer und kein Shipping an
        currencyID                => 'EUR',
        InvoiceID                 => $InvoiceID,
        NoShipping                => 1,
        LocaleCode                => 'de_DE',
        BuyerEmail                => $BuyerEmail,
        OrderDescription          => $OrderDescription,
        ReturnURL                 => $ReturnURL,
        CancelURL                 => $CancelURL,
        PageStyle                 => $PageStyle,
        'cpp-header-image'        => $cpp_header_image,
        'cpp-header-border-color' => $cpp_header_border_color,
        'cpp-header-back-color'   => $cpp_header_back_color,
        'cpp-payflow-color'       => $cpp_payflow_color,
    );

    if ( $debug >= 2 ) {
        print "----SetExpressCheckout---------------\n";
        print Data::Dumper->Dump( [ \%response ], [qw(response)] );
        print "-------------------------------------\n";
    }

    # hat's geklappt?
    if ( $response{'Ack'} ne "Success" ) {
        &error_exit(
                  "PayPal hat \""
                . $response{'Ack'}
                . "\" gemeldet: ("
                . $response{'Errors'}[0]->{'ErrorCode'} . ") "
                . $response{'Errors'}[0]->{'LongMessage'}
                . " (CorrelationID: "
                . $response{'CorrelationID'} . ")",
            18
        );
    }

    my $token = $response{'Token'};

    print "Token: $token\n";
    print
        "Redirect: https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=$token\n";

    foreach my $field ( keys %response ) {
        next if $field =~ /^Token|Version|Build|Ack$/;

        print $field, ": ", $response{$field}, "\n";
    }
}

# Zahlungsvorgang Schritt 2
elsif ( $step == 2 ) {

    # Parameter prüfen
    ##################
    if ( not $Token ) {
        &error_exit( "Token muss angegeben werden.", 20 );
    }
    &print_debug( "Token: $Token:", 1 );

    # Kunden Checkout Details von PayPal abholen
    ############################################
    my %details = $pp->GetExpressCheckoutDetails($Token);

    if ( $debug >= 2 ) {
        print "------GetExpressCheckoutDetails---------\n";
        print Data::Dumper->Dump( [ \%details ], [qw(details)] );
        print "----------------------------------------\n";
    }

    # hat's geklappt?
    if ( $details{Ack} ne "Success" ) {
        &error_exit(
                  "PayPal hat \""
                . $details{'Ack'}
                . "\" gemeldet: ("
                . $details{'Errors'}[0]->{'ErrorCode'} . ") "
                . $details{'Errors'}[0]->{'LongMessage'}
                . " (CorrelationID: "
                . $details{'CorrelationID'} . ")",
            28
        );
    }

    # als erstes die PayerID ausgeben
    my $PayerID = "(noch unbekannt)";
    $PayerID = $details{PayerID} if $details{PayerID};
    print "PayerID: $PayerID\n";

    foreach my $field ( keys %details ) {
        next if $field =~ /^PayerID|Token|Version|Build|Ack$/;

        print $field, ": ", $details{$field}, "\n";
    }
}

# Zahlungsvorgang Schritt 3
elsif ( $step == 3 ) {

    # Parameter prüfen
    ##################
    if ( not $OrderTotal ) {
        &error_exit( "OrderTotal fehlt.", 6 );
    }
    &print_debug( "OrderTotal: $OrderTotal:", 1 );

    if ( not $Token ) {
        &error_exit( "Token muss angegeben werden.", 30 );
    }
    &print_debug( "Token: $Token:", 1 );

    if ( not $PayerID ) {
        &error_exit( "PayerID muss angegeben werden.", 31 );
    }
    &print_debug( "PayerID: $PayerID:", 1 );

    # PayPal zur Ausführung der Zahlung auffordern
    ##############################################
    my %payinfo = $pp->DoExpressCheckoutPayment(
        Token         => $Token,
        PaymentAction => 'Sale',
        PayerID       => $PayerID,
        currencyID    => 'EUR',
        OrderTotal    => $OrderTotal,
    );

    if ( $debug >= 2 ) {
        print "----DoExpressCheckoutPayment---------------\n";
        print Data::Dumper->Dump( [ \%payinfo ], [qw(payinfo)] );
        print "-------------------------------------------\n";
    }

    # hat's geklappt?
    if ( $payinfo{'Ack'} ne "Success" ) {
        &error_exit(
                  "PayPal hat \""
                . $payinfo{'Ack'}
                . "\" gemeldet: ("
                . $payinfo{'Errors'}[0]->{'ErrorCode'} . ") "
                . $payinfo{'Errors'}[0]->{'LongMessage'}
                . " (CorrelationID: "
                . $payinfo{'CorrelationID'} . ")",
            38
        );
    }

    foreach my $field ( keys %payinfo ) {
        next if $field =~ /^PayerID|Token|Version|Build|Ack$/;

        print $field, ": ", $payinfo{$field}, "\n";
    }
}

else {
    print "Parameter \"step\" muss zwischen 1 und 3 liegen.\n";
}

&cleanup_and_exit();

############################################
# Hilfsroutinen
############################################
sub print_error {
    my ($text) = @_;

    print STDERR "ERROR: " . $text . "\n";

    $errors_occurred++;

    if ( $errors_occurred > 10 ) {
        print STDERR
            "ERROR: Zu viele Fehler ($errors_occurred) aufgetreten -> Abbruch\n";
        &cleanup_and_exit();
    }
}

sub print_debug {
    my ( $text, $debug_level ) = @_;

    $debug_level = 0 unless $debug_level;

    if ( $debug >= $debug_level ) {
        print "DEBUG($debug_level): " . $text . "\n";
    }
}

sub error_exit {
    my ( $text, $exitcode ) = @_;

    &print_error($text);
    &cleanup_and_exit($exitcode);
}

# nötige Aufräumarbeiten am Ende
sub cleanup {
    &print_debug( "cleanup done.", 1 );
}

# Exitcode als optionaler Parameter
sub cleanup_and_exit {
    my ($exitcode) = @_;
    $exitcode = 0 unless $exitcode;

    &cleanup();

    if ($errors_occurred) {
        &print_debug(
            "Fertig, aber es sind $errors_occurred Fehler aufgetreten.\n",
            1
        );
        exit 100 + $errors_occurred unless $exitcode;
    }

    &print_debug( "$self (v$VERSION) beendet.\n", 1 );
    exit $exitcode;
}

#----------------------------------------------------------------------------
# Doku
#----------------------------------------------------------------------------

__END__

=head1 NAME

paypal-checkout  --  Interface zu PayPals ExpressCheckout SOAP-API

=head1 SYNOPSIS

C<paypal-checkout> [--help|--usage] [--version] [--manpage] [--debug]
 [--username] [--password] [--signature]
 [--step]
 [--OrderTotal] [--OrderDescription] [--InvoiceID] [--BuyerEmail]
 [--Token]


=head1 DESCRIPTION

B<paypal-checkout> ist ein (mehr oder weniger) komfortables Interface zu
PayPals ExpressCheckout SOAP-API, um Zahlungen von Kunden per PayPal
entgegenzunehmen.  Der Kunde wird dafür zu der PayPal-Webseite
weitergeleitet, wo er die Zahlung bestätigen muss und dann zur
ursprünglichen Website (also unserer) zurückgeleitet wird, um den Vorgang
abzuschliessen.

Der Ablauf ist folgender:

B<Schritt 1>

 paypal-checkout --step 1 \
                 --OrderTotal '1.23' \
                 --InvoiceID  'Rechnung12346' \
                 --OrderDescription '127 bytes to describe the order' \
                 --ReturnURL 'http://blafaselfoo.sonst.was/paypal/return' \
                 --CancelURL 'http://blafaselfoo.sonst.was/paypal/cancel'
                 --BuyerEmail 'kunde@seineemailadresse.de' \

Als Antwort kommt dann z.B.:
 Token: EC-15K077519T503945L
 Redirect: https://www.paypal.com/cgi-bin/webscr?cmd=_express-checkout&token=EC-15K077519T503945L
 Timestamp: 2006-07-04T18:06:15Z
 CorrelationID: 5edc524d89b9d

Der Kunde wird von PayPal nach seiner Zahlungsbestätigung dann auf die
folgende URL zurückgeleitet:
 http://blafaselfoo.sonst.was/paypal/return?token=EC-15K077519T503945L&PayerID=...

Oder wenn er den "Abbrechen"-Knopf drückt hierhin:
 http://blafaselfoo.sonst.was/paypal/cancel?token=EC-15K077519T503945L

[NB: Falls schon ein '?' in der URL vorkommt, wird '&token=...' angehängt]

PayPal akzeptiert auch noch diese Parameter zur Gestaltung der Webseite mit
unserem Firmenlayout:
 PageStyle
 cpp_header_image
 cpp_header_border_color
 cpp_header_back_color
 cpp_payflow_color


B<Schritt 2>

Nun können wir uns die Kundendaten von Paypal abholen:

 paypal-checkout --step 2 \
                 --Token 'EC-15K077519T503945L'

Als Antwort kommt dann z.B.:
 PayerID: XXXXXXXXXXX
 FirstName: Heinz-Otto
 LastName: Meier
 Payer: kunde@seineemailadresse.de
 InvoiceID: Rechnung12346
 Timestamp: 2006-07-04T16:30:43Z
 CorrelationID: f585a8a8426b1

Weitere mögliche Felder sind:
 ContactPhone
 PayerStatus
 PayerBusiness
 Name
 Street1
 Street2
 CityName
 StateOrProvince
 PostalCode
 Country

"PayerID" ist immer in der ersten Zeile (da diese ID für den 3.Schritt
benötigt wird), danach folgen optional alle weiteren Felder, die PayPal
über diesen Kunden bekannt gibt.


B<Schritt 3>

Und schließlich müssen wir noch die Zahlung endgültig durchführen.  Dabei
muss die PayerID (s. 2.Schritt) und der Betrag (der auch anders als im
1.Schritt sein darf) nochmals angegeben werden:

 paypal-checkout --step 3 \
                 --Token EC-15K077519T503945L \
                 --PayerID XXXXXXXXXXX \
                 --OrderTotal '1.23' \

PayPal akzeptiert auch noch diese (momentan nicht implementierten) Parameter:
 OrderDescription
 ItemTotal
 ShippingTotal
 HandlingTotal
 TaxTotal
 InvoiceID
 ButtonSource
  (An identification code for use by third-party applications to identify transactions.)
 NotifyURL
  (Your URL for receiving Instant Payment Notification (IPN) about this transaction.
   NOTE: If you do not specify NotifyURL in the request, the notification
   URL from your Merchant Profile is used, if one exists.)
 PDI_Name, PDI_Amount, PDI_Number, PDI_Quantity, PDI_Tax
  (PDI=PaymentDetailsItem)

Als Antwort kommt dann z.B.:
 TaxAmount: 0.00
 PaymentType: instant
 PaymentStatus: Completed
 PendingReason: none
 Timestamp: 2006-07-04T16:51:31Z
 GrossAmount: 0.12
 CorrelationID: ec073855c7f6
 TransactionID: 4BP770794S779432R
 TransactionType: express-checkout
 PaymentDate: 2006-07-04T16:51:30Z

Weitere mögliche Felder sind:
 FeeAmount
 SettleAmount
 TaxAmount
 ExchangeRate


=head1 OPTIONS

Alle Optionen können mit einem eindeutigen Anfang abgekürzt werden.

=over 3

=item B<--debug>

Debugmeldungen ausgeben (kann mehrfach angegeben werden, um detailliertere Informationen zu sehen).

=item B<--help>, B<--usage>

Syntax anzeigen

=item B<--manpage>

Die komplette Manpage anzeigen

=item B<--version>

Programmversion anzeigen

=back


=head3 Optionen für Schritt 1

=over 3

=item B<--OrderTotal>

Abzubuchender Betrag in Euro ohne Währungssymbol.  Dezimalpunkt ist ein
Punkt.  Kommas werden als Tausenderpunkte interpretiert.  Maximal zulässig
sind 10000 US Dollar.

Da in unserem Fall keine Steuer und kein Shipping mehr dazukommen wird
dieser Betrag auch als C<MaxAmount> an PayPal übergeben, so dass er dem
Kunden auf der PayPal-Seite als endgültiger Betrag angezeigt wird.  Leider
funktioniert das nicht.  Der Kunde sieht auf der PayPal-Seite keinen Betrag!

=item B<--OrderDescription>

Beschreibender Text zur Zahlung, die dem Kunden auf der PayPal-Seite
angezeigt wird.  Für unsere Buchhaltung sollten hier zumindest KundenNummer
und Rechnungsnummer angegeben sein.  Auch der Betrag wäre hier wohl
wünschenswert, da der Kunden auf der PayPal-Seite den Betrag nicht
angezeigt bekommt!  (Warum wohl?)

=item B<--InvoiceID>

Unsere (eindeutige) Rechnungs-ID.

=item B<--BuyerEmail>

PayPal beschreibt diesen Parameter so:
  Email address of the buyer as entered during checkout. PayPal uses this
  value to pre-fill the PayPal membership sign-up portion of the PayPal
  login page.

  Character length and limit: 127 single-byte alphanumeric characters

=item B<--ReturnURL>

Nach der Zahlungsbestätigung wird der Kunde zu dieser URL weitergeleitet.

=item B<--CancelURL>

In dem Fall, dass der Kunde die Zahlungsbestätigung abbricht, wird er zu
dieser URL weitergeleitet.

=item B<--PageStyle>

PayPal beschreibt diesen Parameter so:
  Sets the Custom Payment Page Style for payment pages associated with this
  button/link. PageStyle corresponds to the HTML variable page_style for
  customizing payment pages. The value is the same as the Page Style Name
  you chose when adding or editing the page style from the Profile subtab
  of the My Account tab of your PayPal account.  Character length and
  limitations: 30 single-byte alphabetic characters.

=item B<--cpp-header-image>

PayPal beschreibt diesen Parameter so:
  A URL for the image you want to appear at the top left of the payment
  page. The image has a maximum size of 750 pixels wide by 90 pixels
  high. PayPal recommends that you provide an image that is stored on a
  secure (https) server.  Character length and limitations: 127

=item B<--cpp-header-border-color>

PayPal beschreibt diesen Parameter so:
  Sets the border color around the header of the payment page. The border
  is a 2-pixel perimeter around the header space, which is 750 pixels wide
  by 90 pixels high.  Character length and limitations: Six character HTML
  hexadecimal color code in ASCII

=item B<--cpp-header-back-color>

PayPal beschreibt diesen Parameter so:
  Sets the background color for the header of the payment page.

  Character length and limitation: Six character HTML hexadecimal color
  code in ASCII

=item B<--cpp-payflow-color>

PayPal beschreibt diesen Parameter so:
  Sets the background color for the payment page.

  Character length and limitation: Six character HTML hexadecimal color
  code in ASCII

=back


=head3 Optionen für Schritt 2

=over 3

=item B<--Token>

Zur Identifikation des Zahlungsvorgangs muss das Token aus Schritt 1 an
PayPal übergeben werden.

=back


=head3 Optionen für Schritt 3

=over 3

=item B<--OrderTotal>

Abzubuchender Betrag in Euro ohne Währungssymbol.  Dezimalpunkt ist ein
Punkt.  Kommas werden als Tausenderpunkte interpretiert.  Maximal zulässig
sind 10000 US Dollar.  Der Betrag darf den Betrag aus Schritt 1 nicht
übersteigen, aber PayPal akzeptiert trotzdem einen höheren Betrag und bucht
ihn auch brav ab!  Das lädt ja direkt zum Betrug ein!  Allerdings bekommt
der Kunde danach ja noch eine Bestätigung per E-Mail, in der der richtige
Betrag steht.

=item B<--Token>

Zur Identifikation des Zahlungsvorgangs muss das Token aus Schritt 1 an
PayPal übergeben werden.

=item B<--PayerID>

Zur Identifikation des Zahlungsvorgangs muss die PayerID aus Schritt 2 an
PayPal übergeben werden.

=back


=head1 EXITCODES

B<0>  Alles bestens

Alles andere bedeutet nichts Gutes.


=head1 BUGS

Ich habe folgendes seltsame Verhalten festgestellt:

Wenn ein Kunde _nach_ der Bezahlung nochmal die PayPal-Seite mit der
Zahlungsaufforderung aufruft und dort dann auf "Zurück zur Kaufabwicklung
des Händlers" klickt, wird er zu dieser URL umgeleitet:
 http://blafaselfoo.sonst.was/paypal/cancel?submit.x=Zur%C3%BCck+zur+Kaufabwicklung+des+H%C3%A4ndlers&form_charset=UTF-8


=head1 SEE ALSO

L<SOAP::Lite>, L<Business::PayPal::API>, L<Business::PayPal::API::ExpressCheckout>,
L<https://www.paypal.com/IntegrationCenter/ic_expresscheckout.html>,
L<https://developer.paypal.com/en_US/pdf/PP_APIReference.pdf>

=head1 AUTHOR

Dr. Andy Spiegl E<lt>paypalcheckout.Spiegl@kascada.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Andy Spiegl

This perl script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

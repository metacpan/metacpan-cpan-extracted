package Business::PayPal::API::MassPay;
$Business::PayPal::API::MassPay::VERSION = '0.76';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw( MassPay );

sub MassPay {
    my $self = shift;
    my %args = @_;

    ## set some defaults
    $args{currencyID}   ||= 'USD';
    $args{ReceiverType} ||= 'EmailAddress';
    $args{MassPayItems} ||= [];
    $args{Version}      ||= "1.0";

    my %types = (
        EmailSubject => 'xs:string',
        Version      => 'xsd:string',

        #                  ReceiverType => 'ebl:ReceiverInfoCodeType',  ## EmailAddress | UserID
    );

    my %attr = (
        Version => { xmlns      => $self->C_xmlns_ebay },
        Amount  => { currencyID => $args{currencyID} },
    );

    ## mass pay item
    my %mpi_type = (
        ReceiverEmail => 'ebl:EmailAddressType',
        ReceiverID    => 'xs:string',
        Amount        => 'ebl:BasicAmountType',
        UniqueId      => 'xs:string',
        Note          => 'xs:string',
    );

    my @recipients = @{ $args{MassPayItems} };

    my @masspay = ();

    for my $type ( sort keys %types ) {
        next unless $args{$type};
        if ( $attr{$type} ) {
            push @masspay,
                SOAP::Data->name( $type => $args{$type} )
                ->type( $types{$type} )->attr( { %{ $attr{$type} } } );
        }
        else {
            push @masspay,
                SOAP::Data->name( $type => $args{$type} )
                ->type( $types{$type} );
        }
    }

    if ( $args{ReceiverType} eq 'UserID' ) {
        delete $mpi_type{ReceiverEmail};
    }

    else {
        delete $mpi_type{ReceiverID};
    }

    for my $rcpt (@recipients) {
        my @rcpt = ();
        for my $type ( keys %mpi_type ) {
            next unless $mpi_type{$type};
            if ( $attr{$type} ) {
                push @rcpt,
                    SOAP::Data->name( $type => $rcpt->{$type} )
                    ->type( $mpi_type{$type} )->attr( { %{ $attr{$type} } } );
            }

            else {
                push @rcpt,
                    SOAP::Data->name( $type => $rcpt->{$type} )
                    ->type( $mpi_type{$type} );
            }
        }

        push @masspay,
            SOAP::Data->name( MassPayItem => \SOAP::Data->value(@rcpt) )
            ->type("ns:MassPayRequestItemType");
    }

    my $request
        = SOAP::Data->name( MassPayRequest => \SOAP::Data->value(@masspay) )
        ->type("ns:MassPayRequestType");

    my $som = $self->doCall( MassPayReq => $request )
        or return;

    my $path = '/Envelope/Body/MassPayResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::MassPay - PayPal MassPay API

=head1 VERSION

version 0.76

=head1 SYNOPSIS

    use Business::PayPal::API::MassPay;

    ## see Business::PayPal::API documentation for parameters
    my $pp = Business::PayPal::API::MassPay->new( ... );

    my %response = $pp->MassPay(
        EmailSubject => "Here's your moola",
        MassPayItems => [
            {   ReceiverEmail => 'joe@somewhere.tld',
                Amount        => '95.44',
                Note          => 'Thanks for your stuff!'
            },
            {   ReceiverEmail => 'bob@elsewhere.tld',
                Amount        => '15.31',
                Note          => 'We owe you one'
            },
        ]
    );

=head1 DESCRIPTION

B<Business::PayPal::API::MassPay> implements PayPal's B<Mass Pay> API
using SOAP::Lite to make direct API calls to PayPal's SOAP API
server. It also implements support for testing via PayPal's
I<sandbox>. Please see L<Business::PayPal::API> for details on using
the PayPal sandbox.

=head2 MassPay

Implements PayPal's B<Mass Pay> API call. Supported parameters
include:

  EmailSubject
  MassPayItems

The B<MassPayItem> parameter is a list reference of hashrefs, each
containing the following fields:

  ReceiverEmail
  Amount
  UniqueId
  Note

as described in the PayPal "Web Services API Reference" document.

Returns a hash containing the generic response structure (as per the
PayPal Web Services API).

Example:

  my %resp = $pp->MassPay( EmailSubject => "This is the subject",
                           MassPayItems => [ { ReceiverEmail => 'joe@test.tld',
                                               Amount => '24.00',
                                               UniqueId => "123456",
                                               Note => "Enjoy the money. Don't spend it all in one place." } ] );

  unless( $resp{Ack} !~ /Success/ ) {
    die "Failed: " . $resp{Errors}[0]{LongMessage} . "\n";
  }

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of B<Business::PayPal::API> for
information on handling errors.

=head1 EXPORT

None by default.

=head1 SEE ALSO

L<https://developer.paypal.com/en_US/pdf/PP_APIReference.pdf>

=head1 AUTHORS

=over 4

=item *

Scott Wiersdorf <scott@perlcode.org>

=item *

Danny Hembree <danny@dynamical.org>

=item *

Bradley M. Kuhn <bkuhn@ebb.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006-2017 by Scott Wiersdorf, Danny Hembree, Bradley M. Kuhn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: PayPal MassPay API


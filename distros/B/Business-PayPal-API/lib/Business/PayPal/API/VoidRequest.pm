package Business::PayPal::API::VoidRequest;
$Business::PayPal::API::VoidRequest::VERSION = '0.76';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(DoVoidRequest);

sub DoVoidRequest {
    my $self = shift;
    my %args = @_;

    my %types = (
        AuthorizationID => 'xs:string',
        Note            => 'xs:string',
    );

    my @ref_trans = (
        $self->version_req,
        SOAP::Data->name( AuthorizationID => $args{AuthorizationID} )
            ->type( $types{AuthorizationID} ),
    );

    if ( $args{Note} ) {
        push @ref_trans,
            SOAP::Data->name( Note => $args{Note} )->type( $types{Note} )
            if $args{Note};
    }
    my $request
        = SOAP::Data->name( DoVoidRequest => \SOAP::Data->value(@ref_trans) )
        ->type("ns:VoidRequestType");

    my $som = $self->doCall( DoVoidReq => $request )
        or return;

    my $path = '/Envelope/Body/DoVoidResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som, $path, \%response,
        { AuthorizationID => 'AuthorizationID' }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::VoidRequest - PayPal VoidRequest API

=head1 VERSION

version 0.76

=head1 SYNOPSIS

    use Business::PayPal::API::VoidRequest;

    # see Business::PayPal::API documentation for parameters
    my $pp = Business::PayPal::API::VoidRequest->new( ... );

    my %response = $pp->DoVoidRequest(
        AuthorizationID => $transid Note => "Please come again!" );

=head1 DESCRIPTION

B<Business::PayPal::API::VoidRequest> implements PayPal's
B<VoidRequest> API using SOAP::Lite to make direct API calls to
PayPal's SOAP API server. It also implements support for testing via
PayPal's I<sandbox>. Please see L<Business::PayPal::API> for details
on using the PayPal sandbox.

=head2 DoVoidRequest

Implements PayPal's B<DoVoidRequest> API call. Supported
parameters include:

  AuthorizationID
  Note

The B<AuthorizationID> is the original ID. Not a subsequent ID from a
B<ReAuthorizationRequest>. The note is a 255 character message for
whatever purpose you deem fit.

Returns a hash containing the results of the transaction. The B<Ack>
element is likely the only useful return value at the time of this
revision (the Nov. 2005 errata to the Web Services API indicates that
the documented fields 'AuthorizationID', 'GrossAmount', etc. are I<not>
returned with this API call).

Example:

  my %resp = $pp->DoVoidRequest( AuthorizationID => $trans_id,
                                 Note            => 'Sorry about that.' );

  unless( $resp{Ack} !~ /Success/ ) {
      for my $error ( @{$response{Errors}} ) {
          warn "Error: " . $error->{LongMessage} . "\n";
      }
  }

=head2 ERROR HANDLING

See the B<ERROR HANDLING> section of B<Business::PayPal::API> for
information on handling errors.

=head2 EXPORT

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

# ABSTRACT:  PayPal VoidRequest API


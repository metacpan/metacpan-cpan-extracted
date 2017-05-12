package Business::PayPal::API::GetBalance;
$Business::PayPal::API::GetBalance::VERSION = '0.76';
use 5.008001;
use strict;
use warnings;

use SOAP::Lite 0.67;
use Business::PayPal::API ();

our @ISA       = qw(Business::PayPal::API);
our @EXPORT_OK = qw(GetBalance);              ## fake exporter

sub GetBalance {
    my $self = shift;
    my %args = @_;

    my @trans = ( $self->version_req, );

    my $request
        = SOAP::Data->name( GetBalanceRequest => \SOAP::Data->value(@trans) )
        ->type("ns:GetBalanceRequestType");

    my $som = $self->doCall( GetBalanceReq => $request )
        or return;

    my $path = '/Envelope/Body/GetBalanceResponse';

    my %response = ();
    unless ( $self->getBasic( $som, $path, \%response ) ) {
        $self->getErrors( $som, $path, \%response );
        return %response;
    }

    $self->getFields(
        $som, $path,
        \%response,
        {
            Balance          => 'Balance',
            BalanceTimeStamp => 'BalanceTimeStamp',
        }
    );

    return %response;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Business::PayPal::API::GetBalance - PayPal GetBalance API

=head1 VERSION

version 0.76

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

# ABSTRACT: PayPal GetBalance API

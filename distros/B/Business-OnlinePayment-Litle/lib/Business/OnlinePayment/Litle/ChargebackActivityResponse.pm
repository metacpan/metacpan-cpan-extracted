package Business::OnlinePayment::Litle::ChargebackActivityResponse;
use strict;
use warnings;

# ABSTRACT: Business::OnlinePayment::Litle::ChargebackActivityResponse - Response Objects

our $VERSION = '0.959'; #VERSION


sub new{
    my ($class, $args) = @_;
    my $self = bless $args, $class;

    $self->_build_subs(
            qw( hash case_id merchant_id order_number invoice_number is_success reason_code reason_code_description ));
    $self->case_id( $args->{'caseId'});
    $self->merchant_id( $args->{'merchantId'});
    $self->order_number( $args->{'litleTxnId'});
    $self->invoice_number( $args->{'orderId'});
    $self->reason_code( $args->{'reasonCode'});
    $self->reason_code_description( $args->{'reasonCodeDescription'});
    $self->hash( $args ); 
    $self->is_success( 1 );

    return $self;
}

sub _build_subs {
    my $self = shift;

    foreach(@_) {
        next if($self->can($_));
        eval "sub $_ { my \$self = shift; if(\@_) { \$self->{$_} = shift; } return \$self->{$_}; }"; ## no critic 
    }
}

1;

__END__

=pod

=head1 NAME

Business::OnlinePayment::Litle::ChargebackActivityResponse - Business::OnlinePayment::Litle::ChargebackActivityResponse - Response Objects

=head1 VERSION

version 0.959

=head1 NAME

Business::OnlinePayment::Litle::ChargebackActivityResponse

=head2 METHODS

Additional methods created by this package.

=over

=item new

Create a new chargeback activity response object.

=back

=head1 AUTHOR

Jason Hall <jayce@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jason Hall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

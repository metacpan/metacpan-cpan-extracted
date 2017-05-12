package Business::OnlinePayment::Braintree;

use 5.006;
use strict;
use warnings;

use Business::OnlinePayment 3.01;
use Net::Braintree;

use base 'Business::OnlinePayment';

=head1 NAME

Business::OnlinePayment::Braintree - Online payment processing through Braintree

=head1 VERSION

Version 0.020

=cut

our $VERSION = '0.020';

=head1 SYNOPSIS

    use Business::OnlinePayment;

    $tx = new Business::OnlinePayment('Braintree',
                                      merchant_id => 'your merchant id',
                                      public_key => 'your public key',
                                      private_key => 'your private key',
                                     );

    $tx->test_transaction(1); # sandbox transaction for development and tests
  
    $tx->content(amount => 100,
                 card_number => '4111 1111 1111 1111',
                 expiration => '1212');

    $tx->submit();

    if ($tx->is_success) {
        print "Card processed successfully: " . $tx->authorization . "\n";
    } else {
        print "Card was rejected: " . $tx->error_message . "\n";
    }

=head1 DESCRIPTION

Online payment processing through Braintree based on L<Net::Braintree>.

The documentation for L<Net::Braintree> is located at
L<https://www.braintreepayments.com/docs/perl>.

=head1 NOTES

This is supposed to cover the complete Braintree Perl API finally.

=head1 METHODS

=head2 submit

Submits transaction to Braintree gateway.

=cut

sub submit {
    my $self = shift;
    my $config = Net::Braintree->configuration;
    my %content = $self->content;
    my ($action, $result, $transaction, $result_code);

    # sandbox vs production
    if ($self->test_transaction) {
	$config->environment('sandbox');
    }
    else {
	$config->environment('production');
    }

    # transaction
    $action = lc($content{action});

    if ($action eq 'normal authorization' ) {
        $result = $self->sale(1);
    }
    elsif ($action eq 'authorization only') {
        $result = $self->sale(0);
    }
    elsif ($action eq 'post authorization') {
        $result = Net::Braintree::Transaction->submit_for_settlement($content{order_number}, $content{amount});
    }
    elsif ($action eq 'credit' ) {
        $result = Net::Braintree::Transaction->refund($content{order_number}, $content{amount});
    }
    elsif ($action eq 'void' ) {
        $result = Net::Braintree::Transaction->void($content{order_number});
    }
    else {
        $self->error_message( "unsupported action for Braintree: $content{action}" );
        return 0;
    }

    my %result_codes = (
        2000 => 'declined',
        2001 => 'nsf',
        2002 => 'nsf',
        2003 => 'nsf',
        2010 => 'declined',
        2012 => 'declined',
        2013 => 'declined',
        2014 => 'declined',
        2022 => 'declined',
        2038 => 'declined',
        2041 => 'declined',
        2044 => 'declined',
        2046 => 'declined',
        2047 => 'pickup',
        2053 => 'stolen',
    );

    $transaction = $result->transaction;

    if ( $transaction ) {
        $result_code = $transaction->processor_response_code;

        $self->result_code($result_code);
        $self->order_number($transaction->id);
    }

    if ($result->is_success()) {
        $self->is_success(1);
        $self->authorization($transaction->id);
        $self->card_token($transaction->id);
    }
    else {
        $self->is_success(0);
        $self->error_message($result->message);
        $self->failure_status($result_codes{$result_code})
          if ( $result_code && $result_codes{$result_code} );
    }
}

=head2 sale $submit

Performs sale transaction with Braintree. Used both
for settlement ($submit is a true value) and
authorization ($submit is a false value).

=cut

sub sale {
    my ($self, $submit) = @_;
    my %content = $self->content;

    # get rid of slash inside expiration value
    $content{expiration} =~ s%/%%;

    my %args = (
            amount => $content{amount},
            order_id => $content{invoice_number},
            credit_card => {
                number => $content{card_number},
                expiration_month => substr($content{expiration},0,2),
                expiration_year => substr($content{expiration},2,2),
                cvv => $content{cvv},
            },
            billing => {
                first_name => $content{first_name},
                last_name => $content{last_name},
                company => $content{company},
                street_address => $content{address},
                locality => $content{city},
                region => $content{state},
                postal_code => $content{zip},
                country_code_alpha2 => $content{country}
            },
            options => {
	            submit_for_settlement => $submit,
            }
        );

    if (exists $content{merchant_account_id}
        && $content{merchant_account_id}) {
        $args{merchant_account_id} = $content{merchant_account_id};
    }

    my $result = Net::Braintree::Transaction->sale(\%args);

    return $result;
}

=head2 set_defaults

Sets defaults for the Braintree merchant id, public and private key.

=cut
    
sub set_defaults {
    my ($self, %opts) = @_;
    my $config = Net::Braintree->configuration;

    $self->build_subs(qw(card_token));

    $config->merchant_id($opts{merchant_id});
    $config->public_key($opts{public_key});
    $config->private_key($opts{private_key});

    return;
}

=head1 AUTHOR

Stefan Hornburg (Racke), C<< <racke at linuxia.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-onlinepayment-braintree at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-OnlinePayment-Braintree>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Business::OnlinePayment::Braintree


You can also look for information at:

=over 4

=item * Github issues (report bugs here)

L<https://github.com/interchange/Business-OnlinePayment-Braintree/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-OnlinePayment-Braintree>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Business-OnlinePayment-Braintree>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-OnlinePayment-Braintree/>

=back


=head1 ACKNOWLEDGEMENTS

Grant for the following enhancements (RT #88525):

=over 4

=item billing address transmission

=item order number transmission

=item refund ability

=item added submit_for_settlement to complete the "sale" action

=back

Peter Mottram for the following enhancements (GH #5):

=over 4

=item Failure status

Set failure status from error codes provided by Braintree.

=item CVV

Pass cvv to Braintree.

=back

Evan Brown (GH #7, #8):

Add support for post authorization action.
Add support for the void action and the card_token transaction result method.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Net::Braintree>

=cut

1; # End of Business::OnlinePayment::Braintree

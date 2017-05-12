package Business::BalancedPayments;

our $VERSION = '1.0600'; # VERSION

use Business::BalancedPayments::V10;
use Business::BalancedPayments::V11;
use Carp qw(croak);

sub client {
    my ($class, %args) = @_;
    $args{version} ||= 1.1;
    croak "only versions 1.0 and 1.1 are supported"
        unless $args{version} == 1 or $args{version} == 1.1;
    return $args{version} == 1
        ? Business::BalancedPayments::V10->new(%args)
        : Business::BalancedPayments::V11->new(%args);
}

# ABSTRACT: Balanced Payments API bindings


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BalancedPayments - Balanced Payments API bindings

=head1 VERSION

version 1.0600

=head1 SYNOPSIS

    use Business::BalancedPayments;

    my $bp = Business::BalancedPayments->client(secret => 'abc123');

    my $customer = $bp->create_customer;

    my $card = $bp->create_card({
        card_number      => '5105105105105100',
        expiration_month => 12,
        expiration_year  => 2020,
        security_code    => 123,
    });

    $bp->add_card($card, customer => $customer);

=head1 DESCRIPTION

This module provides bindings for the
L<Balanced|https://www.balancedpayments.com> API.

=head1 METHODS

The client methods documented here are for v1.1 of the Balanced API
L<https://docs.balancedpayments.com/1.1/api>.
See L<Business::BalancedPayments::V10> for the v1.0 methods.

For the C<get_*> methods, the C<$id> param can be the id of the resource or
a uri. For example, the following two lines are equivalent:

    $bp->get_card('CC6J123');
    $bp->get_card('/cards/CC6J123');

=head2 client

    my $bp = Business::BalancedPayments->client(
        secret  => $secret,
        version => 1.1,     # optional, defaults to 1.1
        logger  => $logger, # optional
        retries => 3,       # optional
    );

Returns a new Balanced client object.
Parameters:

=over 4

=item secret

Required. The Balanced Payments secret key for your account.

=item version

Optional. Defaults to C<'1.1'>.
The only supported versions currently are C<'1.0'> and C<'1.1'>.
Note that version C<'1.0'> was officially deprecated March 2014. 

=back

See L<WebService::Client> for other supported parameters such as C<logger>,
C<retries>, and C<timeout>.

=head2 get_card

    get_card($id)

Returns the card for the given id.

Example response:

    {
      'id' => 'CC6J',
      'href' => '/cards/CC6J',
      'address' => {
        'city' => undef,
        'country_code' => undef,
        'line1' => undef,
        'line2' => undef,
        'postal_code' => undef,
        'state' => undef
      },
      'avs_postal_match' => undef,
      'avs_result' => undef,
      'avs_street_match' => undef,
      'bank_name' => 'BANK OF HAWAII',
      'brand' => 'MasterCard',
      'can_credit' => 0,
      'can_debit' => 1,
      'category' => 'other',
      'created_at' => '2014-09-21T05:55:17.564617Z',
      'cvv' => undef,
      'cvv_match' => undef,
      'cvv_result' => undef,
      'expiration_month' => 12,
      'expiration_year' => 2020,
      'fingerprint' => 'fc4c',
      'is_verified' => $VAR1->{'cards'}[0]{'can_debit'},
      'links' => { 'customer' => undef },
      'meta' => {},
      'name' => undef,
      'number' => 'xxxxxxxxxxxx5100',
      'type' => 'credit',
      'updated_at' => '2014-09-21T05:55:17.564619Z'
    }

=head2 create_card

    create_card($card)

Creates a card.
Returns the card card that was created.

Example:

    my $card = $bp->create_card({
        number           => '5105105105105100',
        expiration_month => 12,
        expiration_year  => 2020,
    });

=head2 add_card

    add_card($card, customer => $customer);

Associates a card with a customer.
It expects a card hashref, such as one returned by L</get_card>,
and a customer hashref, such as one returned by L</get_customer>.
Returns the card.

Example:

    my $customer = $bp->create_customer;
    my $card = $bp->get_card($card_id);
    $bp->add_card($card, customer => $customer);

=head2 get_customer

    get_customer($id)

Returns the customer for the given id.

Example response:

    {
      'address' => {
        'city' => undef,
        'country_code' => undef,
        'line1' => undef,
        'line2' => undef,
        'postal_code' => undef,
        'state' => undef
      },
      'business_name' => undef,
      'created_at' => '2014-10-02T07:59:26.311760Z',
      'dob_month' => undef,
      'dob_year' => undef,
      'ein' => undef,
      'email' => 'foo@bar.com',
      'href' => '/customers/CUe3pf7nX93sMvrd9qcC29W',
      'id' => 'CUe3pf7nX93sMvrd9qcC29W',
      'links' => {
        'destination' => undef,
        'source' => undef
      },
      'merchant_status' => 'no-match',
      'meta' => {},
      'name' => undef,
      'phone' => undef,
      'ssn_last4' => undef,
      'updated_at' => '2014-10-02T07:59:26.405946Z'
    }

=head2 create_customer

    create_customer($customer)

Creates a customer.
A customer hashref is optional.
Returns the customer.

Example:

    $bp->create_customer({ name => 'Bob', email => 'bob@foo.com' });

=head2 update_customer

    update_customer($customer)

Updates a customer.
Returns the updated customer.

Example:

    my $customer = $bp->get_customer($customer_id);
    $customer->{email} = 'sue@foo.com';
    $bp->update_customer($customer);

=head2 get_hold

    get_hold($id)

Returns the card hold for the given id.

Example response:

    {
      'amount' => 123,
      'created_at' => '2014-10-03T03:39:46.933465Z',
      'currency' => 'USD',
      'description' => undef,
      'expires_at' => '2014-10-10T03:39:47.051257Z',
      'failure_reason' => undef,
      'failure_reason_code' => undef,
      'href' => '/card_holds/HL7b0bw2Ooe6G3yad7dR1rRr',
      'id' => 'HL7b0bw2Ooe6G3yad7dR1rRr',
      'links' => {
        'card' => 'CC7af3NesZk2bYR5GxqLLmfe',
        'debit' => undef,
        'order' => undef
      },
      'meta' => {},
      'status' => 'succeeded',
      'transaction_number' => 'HL7JT-EWF-5CQ6',
      'updated_at' => '2014-10-03T03:39:47.094448Z',
      'voided_at' => undef
    }

=head2 create_hold

    create_hold($hold_data, card => $card)

Creates a card hold.
The C<$hold_data> hashref must contain an amount.
The card param is a hashref such as one returned from L</get_card>.
Returns the created hold.

=head2 capture_hold

    capture_hold($hold, debit => $debit)

Captures a previously created card hold.
This creates a debit.
The C<$debit> hashref is optional and can contain an amount.
Any amount up to the amount of the hold may be captured.
Returns the created debit.

Example:

    my $hold = $bp->get_hold($hold_id);
    my $debit = $bp->capture_hold(
        $hold,
        debit => {
            amount                  => 1000,
            description             => 'money for stuffs',
            appears_on_statement_as => 'ACME 123',
        }
    );

=head2 void_hold

    void_hold($hold)

Cancels the hold.
Once voided, the hold can no longer be captured.
Returns the voided hold.

Example:

    my $hold = $bp->get_hold($hold_id);
    my $voided_hold = $bp->void_hold($hold);

=head2 get_debit

    get_debit($id)

Returns the debit for the given id.

Example response:

    {
      'amount' => 123,
      'appears_on_statement_as' => 'BAL*Tilt.com',
      'created_at' => '2014-10-06T05:01:39.045336Z',
      'currency' => 'USD',
      'description' => undef,
      'failure_reason' => undef,
      'failure_reason_code' => undef,
      'href' => '/debits/WD6F5x4VpYx4hfB02tGIqNU1',
      'id' => 'WD6F5x4VpYx4hfB02tGIqNU1',
      'links' => {
        'card_hold' => 'HL6F4q5kJGxt1ftH8vgZZJkh',
        'customer' => undef,
        'dispute' => undef,
        'order' => undef,
        'source' => 'CC6DFWepK7eeL03cZ06Sb9Xf'
      },
      'meta' => {},
      'status' => 'succeeded',
      'transaction_number' => 'WAVD-B0K-R7TX',
      'updated_at' => '2014-10-06T05:01:39.542306Z'
    }

=head2 create_debit

    create_debit($debit, card => $card)
    create_debit($debit, bank => $bank)

Debits a card or a bank.
The C<$debit> hashref must contain an amount.
The card param is a hashref such as one returned from L</get_card>.
The bank param is a hashref such as one returned from L</get_bank_account>.
Returns the created debit.

Example:

    my $card = $bp->get_card($card_id);
    my $debit = $bp->create_debit({ amount => 123 }, card => $card);

=head2 refund_debit

    refund_debit($debit)

Refunds a debit.
Returnds the refund.

Example:

    my $debit = $bp->get_debit($debit_id);
    my $refund = $bp->refund_debit($debit);

Example response:

    {
      'amount' => 123,
      'created_at' => '2014-10-06T04:57:44.959806Z',
      'currency' => 'USD',
      'description' => undef,
      'href' => '/refunds/RF2pO6Fz8breGs2TAIpfE2nr',
      'id' => 'RF2pO6Fz8breGs2TAIpfE2nr',
      'links' => {
        'debit' => 'WD2hQV9COFX0aPMSIzyeAuAg',
        'dispute' => undef,
        'order' => undef
      },
      'meta' => {},
      'status' => 'succeeded',
      'transaction_number' => 'RFRGL-EU1-A39B',
      'updated_at' => '2014-10-06T04:57:48.161218Z'
    }

=head2 get_bank_account

    get_bank_account($id)

Returns the bank account for the given id.

Example response:

    {
      'account_number' => 'xxxxxxxx6789',
      'account_type' => 'checking',
      'address' => {
        'city' => undef,
        'country_code' => 'USA',
        'line1' => '123 Abc St',
        'line2' => undef,
        'postal_code' => '94103',
        'state' => undef
      },
      'bank_name' => '',
      'can_credit' => bless( do{\(my $o = 1)}, 'JSON::XS::Boolean' ),
      'can_debit' => bless( do{\(my $o = 0)}, 'JSON::XS::Boolean' ),
      'created_at' => '2014-10-06T06:40:14.649386Z',
      'fingerprint' => 'cc552495fc90556293db500b985bacc918d9fb4d37b42052adf64',
      'href' => '/bank_accounts/BA4TAWvO3d3J14i6BdjJUZsp',
      'id' => 'BA4TAWvO3d3J14i6BdjJUZsp',
      'links' => {
        'bank_account_verification' => undef,
        'customer' => undef
      },
      'meta' => {},
      'name' => 'Bob Smith',
      'routing_number' => '110000000',
      'updated_at' => '2014-10-06T06:40:14.649388Z'
    }

=head2 create_bank_account

    create_bank_account($bank)

Creates a bank account.
Returns the bank account that was created.

Example:

    my $bank = $bp->create_bank_account({
        account_number => '000123456789',
        acount_type    => 'checking',
        name           => 'Bob Smith',
        routing_number => '110000000',
        address => {
            line1       => '123 Abc St',
            postal_code => '94103',
        },
    });

=head2 add_bank_account

    add_bank_account($bank, customer => $customer)

Associates a bank account to the given customer.
Returns the bank account.

Example:

    my $bank = $bp->add_bank_account($bank_id);
    my $customer = $bp->get_customer($customer_id);
    $bank = $bp->add_bank_account($bank, customer => $customer);

=head2 get_credit

    get_credit($id)

Returns the credit for the given id.

Example response:

    {
      'amount' => 123,
      'appears_on_statement_as' => 'Tilt.com',
      'created_at' => '2014-10-06T06:52:00.522212Z',
      'currency' => 'USD',
      'description' => undef,
      'failure_reason' => undef,
      'failure_reason_code' => undef,
      'href' => '/credits/CR27ns5sg1FFgHsGy5VEhowd',
      'id' => 'CR27ns5sg1FFgHsGy5VEhowd',
      'links' => {
        'customer' => undef,
        'destination' => 'BA26JfFfg1vqrCoXPzSSxtKg',
        'order' => undef
      },
      'meta' => {},
      'status' => 'succeeded',
      'transaction_number' => 'CR4F7-4XQ-JLDG',
      'updated_at' => '2014-10-06T06:52:03.558485Z'
    }

=head2 create_credit

    create_credit($credit, bank_account => $bank)
    create_credit($credit, card => $card)

Sends money to a bank account or a credit card.
The C<$credit> hashref must contain an amount.
A bank_account or card param is required.
Returns the created credit.

Example:

    my $bank = $bp->get_bank_account($bank_account_id);
    my $credit = $bp->create_credit({ amount => 123 }, bank_account => $bank);

=head2 get_bank_verification

    get_bank_verification($id)

Gets a bank account verification.

Example response:

    {
      'attempts' => 0,
      'attempts_remaining' => 3,
      'created_at' => '2014-10-06T08:01:59.972034Z',
      'deposit_status' => 'succeeded',
      'href' => '/verifications/BZnWun9Itq7FVtj1nludGjC',
      'id' => 'BZnWun9Itq7FVtj1nludGjC',
      'links' => {
        'bank_account' => 'BAdFCPv3GkIlXEWQrdTyIW9'
      },
      'meta' => {},
      'updated_at' => '2014-10-06T08:02:00.268756Z',
      'verification_status' => 'pending'
    }

=head2 create_bank_verification

    create_bank_verification(bank_account => $bank)

Create a new bank account verification.
This initiates the process of sending micro deposits to the bank account which
will be used to verify bank account ownership.
A bank_account param is required.
Returns the created bank account verification.

Example:

    my $bank = $bp->get_bank_account($bank_account_id);
    my $verification = $bp->create_bank_verification(bank_account => $bank);

=head2 confirm_bank_verification

    confirm_bank_verification($verification,
        amount_1 => $amount_1, amount_2 => $amount_2);

Confirm the trial deposit amounts that were sent to the bank account.
Returns the bank account verification.

Example:

    my $ver = $bp->get_bank_account($bank_account_id);
    $verification =
        $bp->confirm_bank_verification($ver, amount_1 => 1, amount_2 => 2);

=head2 get_disputes

    get_disputes({
        $start_date => '2014-01-01T12:00:00',
        $end_date   => DateTime->now,
        $limit      => 10,
        $offset     => 0,
    })

Lists all disputes (chargebacks).
All of the parameters are optional and must be passed inside of a HashRef.
The C<$start_date> and C<$end_date> parameters can either be DateTime objects, or
ISO8601 formatted strings.
The C<$limit> and C<$offset> parameters must be valid integers.

Example response:

    {
        disputes => [
            {
                amount          => 6150,
                created_at      => '2013-12-06T02:05:13.656744Z',
                currency        => 'USD',
                href            => '/disputes/DT1234567890',
                id              => 'DT1234567890',
                initiated_at    => '2013-09-11T00:00:00Z',
                links           => {
                    transaction => 'WD1234567890'
                },
                meta       => {},
                reason     => 'clerical',
                respond_by => '2013-10-15T00:00:00Z',
                status     => 'lost',
                updated_at => '2013-12-06T20:59:33.884181Z'
            },
            {
                amount          => 10250,
                created_at      => '2013-12-06T01:55:28.882064Z',
                currency        => 'USD',
                href            => '/disputes/DT0987654321',
                id              => 'DT0987654321',
                initiated_at    => '2013-08-28T00:00:00Z',
                links           => {
                    transaction => 'WD0987654321'
                },
                meta       => {},
                reason     => 'clerical',
                respond_by => '2013-10-02T00:00:00Z',
                status     => 'lost',
                updated_at => '2013-12-06T21:04:11.158050Z'
            }
        ],
        links => {
            disputes.events      => '/disputes/{disputes.id}/events',
            disputes.transaction => '/resources/{disputes.transaction}',
        },
        meta {
            first    => '/disputes?limit=10&offset=0',
            href     => '/disputes?limit=10&offset=0',
            last     => '/disputes?limit=10&offset=300',
            limit    => 10,
            next     => '/disputes?limit=10&offset=10',
            offset   => 0,
            previous => undef,
            total    => 100
        }
    }

=head2 get_dispute

    get_dispute('DT1234567890')

Fetches a dispute (chargeback).
The C<$id> of the dispute is a required parameter.

Example response:

    {
        amount          => 6150,
        created_at      => '2013-12-06T02:05:13.656744Z',
        currency        => 'USD',
        href            => '/disputes/DT1234567890',
        id              => 'DT1234567890',
        initiated_at    => '2013-09-11T00:00:00Z',
        links           => {
            transaction => 'WD1234567890'
        },
        meta       => {},
        reason     => 'clerical',
        respond_by => '2013-10-15T00:00:00Z',
        status     => 'lost',
        updated_at => '2013-12-06T20:59:33.884181Z'
    }

=head1 AUTHORS

=over 4

=item *

Ali Anari <ali@tilt.com>

=item *

Khaled Hussein <khaled@tilt.com>

=item *

Naveed Massjouni <naveed@tilt.com>

=item *

Al Newkirk <al@tilt.com>

=item *

Will Wolf <will@tilt.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Crowdtilt, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

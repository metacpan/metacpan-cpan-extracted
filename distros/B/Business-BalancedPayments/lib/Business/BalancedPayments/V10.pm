package Business::BalancedPayments::V10;
use Moo;
extends 'Business::BalancedPayments::Base';

our $VERSION = '1.0600'; # VERSION

use Carp qw(croak);

has marketplaces_uri => ( is => 'ro', default => '/v1/marketplaces' );

sub get_account {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    return $self->get($self->_uri('accounts', $id));
}

sub get_account_by_email {
    my ($self, $email) = @_;
    croak 'The email param is missing' unless $email;
    return $self->get($self->_uri->('accounts') . "?email_address=$email");
}

sub create_account {
    my ($self, $account, %args) = @_;
    my $card = $args{card};
    $account ||= {};
    croak 'The account param must be a hashref' unless ref $account eq 'HASH';

    if ($card) {
        croak 'The card param must be a hashref' unless ref $card eq 'HASH';
        croak 'The card is missing a uri' unless $card->{uri};
        $account->{card_uri} = $card->{uri};
    }
    return $self->post($self->_uri('accounts'), $account);
}

sub update_account {
    my ($self, $account) = @_;
    croak 'The account param must be a hashref' unless ref $account eq 'HASH';
    croak 'The account must have an id or uri field'
        unless $account->{uri} || $account->{id};
    my $acc_uri = $account->{uri} || $self->_uri('accounts', $account->{id});
    return $self->put($acc_uri, $account);
}

sub add_card {
    my ($self, $card, %args) = @_;
    my $account = $args{account};
    croak 'The card param must be a hashref' unless ref $card eq 'HASH';
    croak 'The account param must be a hashref' unless ref $account eq 'HASH';
    croak 'The account requires a cards_uri field' unless $account->{cards_uri};
    return $self->post($account->{cards_uri}, $card);
}

sub add_bank_account {
    my ($self, $bank_account, %args) = @_;
    my $account = $args{account};
    croak 'The bank_account param must be a hashref'
        unless ref $bank_account eq 'HASH';
    croak 'The account param must be a hashref' unless ref $account eq 'HASH';
    croak 'The bank_accounts_uri field is missing from the account object'
        unless $account->{bank_accounts_uri};
    return $self->post($account->{bank_accounts_uri}, $bank_account);
}

sub create_hold {
    my ($self, $hold, %args) = @_;
    croak 'The hold param must be a hashref' unless ref $hold eq 'HASH';
    croak 'The hold is missing an amount field' unless $hold->{amount};
    my $card = $args{card};
    my $account = $args{account};
    croak 'An account or card must be provided' unless $account or $card;
    my $holds_uri;
    if ($card) {
        croak 'The card param must be a hashref' unless ref $card eq 'HASH';
        $holds_uri = $card->{account}{holds_uri};
    } elsif ($account) {
        croak 'The account must be a hashref' unless ref $account eq 'HASH';
        $holds_uri = $account->{holds_uri};
    }
    die 'Could not find a holds_uri' unless $holds_uri;
    $hold->{source_uri} ||= $card->{uri} if $card and $card->{uri};
    return $self->post($holds_uri, $hold);
}

sub capture_hold {
    my ($self, $hold, $params) = @_;
    croak 'The hold param is missing' unless $hold;
    croak 'The optional extra params must be a hashref'
        if $params and ref $params ne 'HASH';
    my $hold_uri = ref $hold eq 'HASH' ? $hold->{uri} : $hold;
    my $data = { hold_uri => $hold_uri, %$params };
    return $self->post($self->_uri('debits'), $data);
}

sub create_debit {
    my ($self, $debit, %args) = @_;
    croak 'The debit param must be a hashref' unless ref $debit eq 'HASH';
    croak 'No amount found' unless $debit->{amount};
    my $card = $args{card};
    my $account = $args{account};
    croak 'An account or card must be provided' unless $account or $card;
    my $debits_uri;
    if ($card) {
        croak 'The card param must be a hashref' unless ref $card eq 'HASH';
        $debits_uri = $card->{account}{debits_uri};
    } elsif ($account) {
        croak 'The account must be a hashref' unless ref $account eq 'HASH';
        $debits_uri = $account->{debits_uri};
    }
    die 'Could not find a debits_uri' unless $debits_uri;
    $debit->{source_uri} ||= $card->{uri} if $card and $card->{uri};
    return $self->post($debits_uri, $debit);
}

sub get_hold {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    return $self->get($self->_uri('holds', $id));
}

sub get_refund {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    return $self->get($self->_uri('refunds', $id));
}

sub get_refunds {
    my ($self, $debit) = @_;
    croak 'The debit param is missing' unless defined $debit;
    return $self->get($debit->{refunds_uri});
}

sub void_hold {
    my ($self, $hold) = @_;
    croak 'The hold param must be a hashref' unless ref $hold eq 'HASH';
    croak 'No hold uri found' unless $hold->{uri};
    return $self->put($hold->{uri}, { is_void => 'True' });
}

sub refund_debit {
    my ($self, $debit) = @_;
    croak 'The debit param must be a hashref' unless ref $debit eq 'HASH';
    croak 'No amount found' unless $debit->{amount};
    croak 'No debit uri found' unless $debit->{uri} || $debit->{debit_uri};
    $debit->{debit_uri} ||= $debit->{uri};
    return $self->post($self->_uri('refunds'), $debit);
}

sub confirm_bank_verification {
    my ($self, $id, %args) = @_;
    my $verification_id = $args{verification_id};
    croak 'The id param is missing' unless defined $id;
    croak 'The verification_id param is missing' unless defined $verification_id;
    my $uri = join '/',
        $self->_uri('bank_accounts', $id), 'verifications', $verification_id;
    my $amount_1 = $args{amount_1} or croak 'The amount_1 param is missing';
    my $amount_2 = $args{amount_2} or croak 'The amount_2 param is missing';
    return $self->put($uri => {amount_1 => $amount_1, amount_2 => $amount_2});
}

sub create_bank_verification {
    my ($self, $id) = @_;
    croak 'The id param is missing' unless defined $id;
    my $uri = $self->_uri('bank_accounts', $id) . '/verifications';
    return $self->post($uri => {});
}

sub update_bank_account {
    my ($self, $bank) = @_;
    croak 'The bank account must be a hashref' unless ref $bank eq 'HASH';
    croak 'The bank account must have an id or uri field'
        unless $bank->{uri} || $bank->{id};
    my $bank_uri = $bank->{uri} || $self->_uri('bank_accounts', $bank->{id});
    return $self->put($bank_uri, $bank);
}

sub invalidate_bank_account {
    my ($self, $bank_id) = @_;
    croak 'A bank id is required' unless defined $bank_id;
    return $self->update_bank_account({ id => $bank_id, is_valid => 0 });
}

sub create_credit {
    my ($self, $credit, %args) = @_;
    my $account = $args{account};
    my $bank_account = $args{bank_account};
    croak 'The credit param must be a hashref' unless ref $credit eq 'HASH';
    croak 'The credit must contain an amount' unless exists $credit->{amount};
    croak 'An account or bank_account param is required'
        unless $account or $bank_account;
    my $credits_uri;
    if ($account) {
        croak 'The account param must be a hashref'
            unless ref $account eq 'HASH';
        $credits_uri = $account->{credits_uri};
    }
    if ($bank_account) {
        croak 'The bank_account param must be a hashref'
            unless ref $bank_account eq 'HASH';
        croak 'The bank_account is a uri' unless $bank_account->{uri};
        croak 'The bank_account is missing an credits_uri'
            unless $bank_account->{account}{credits_uri};
        $credits_uri = $bank_account->{account}{credits_uri};
        $credit->{bank_account_uri} = $bank_account->{uri};
    }
    croak 'No credits_uri found' unless $credits_uri;
    return $self->post($credits_uri, $credit);
}

sub get_transactions {
    my ($self) = @_;
    return $self->get($self->_uri('transactions'));
}

sub _build_marketplace {
    my ($self) = @_;
    my $data = $self->get($self->marketplaces_uri);
    return $data->{items}[0];
}

sub _build_uris {
    my ($self) = @_;
    return {
        map { (split /_uri$/)[0] => $self->marketplace->{$_} }
            grep { /_uri$/ } keys %{ $self->marketplace }
    };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::BalancedPayments::V10

=head1 VERSION

version 1.0600

=head1 METHODS

These methods for version 1.0 of the Balanced API
L<https://docs.balancedpayments.com/1.0/api>.
Note that version 1.0 was officially deprecated March 2014. 

For the C<get_*> methods, the C<$id> param can be the id of the resource or
a uri. For example, the following two lines are equivalent:

    $bp->get_card('CC92QRQcwUCp5zpzKS');
    $bp->get_card('/v1/marketplaces/MK98f1/cards/CC92QRQcwUCp5zpzKS');

=head2 get_transactions

    get_transactions()

Returns the transactions for this marketplace.

=head2 get_card

    get_card($id)

Returns the credit card for the given id.

Example response:

    {
        account          => { ... },
        brand            => "MasterCard",
        card_type        => "mastercard",
        created_at       => "2012-06-07T11:00:40.003671Z",
        expiration_month => 12,
        expiration_year  => 2020,
        id               => "CC92QRQcwUCp5zpzEz7lXKS",
        is_valid         => 1,
        last_four        => 5100,
        name             => undef,
        uri              => "/v1/marketplaces/MK98f1/cards/CC92QRQcwUCp5zpzKS",
    }

=head2 create_card

    create_card({
        card_number      => '5105105105105100',
        expiration_month => 12,
        expiration_year  => 2020,
        security_code    => 123,
    })

Creates a credit card. Returns the card object.

=head2 get_customer

    get_customer($id)

Returns the customer for the given id.

Example response:

    {
      address              => {},
      bank_accounts_uri    => "/v1/customers/CU4I/bank_accounts",
      business_name        => undef,
      cards_uri            => "/v1/customers/CU4I/cards",
      created_at           => "2014-09-21T06:14:54.996408Z",
      credits_uri          => "/v1/customers/CU4I/credits",
      debits_uri           => "/v1/customers/CU4I/debits",
      destination          => undef,
      dob                  => undef,
      ein                  => undef,
      email                => 'bob@foo.com',
      facebook             => undef,
      holds_uri            => "/v1/customers/CU4I/holds",
      id                   => "CU4I",
      is_identity_verified => 0,
      meta                 => {},
      name                 => "Bob",
      phone                => undef,
      refunds_uri          => "/v1/customers/CU4I/refunds",
      reversals_uri        => "/v1/customers/CU4I/reversals",
      source               => undef,
      ssn_last4            => undef,
      transactions_uri     => "/v1/customers/CU4I/transactions",
      twitter              => undef,
      uri                  => "/v1/customers/CU4I",
    }

=head2 create_customer

    create_customer()
    create_customer({ name => 'Bob', email => 'bob@foo.com' })

Creates a customer.
A customer hashref is optional.
Returns the customer object.

=head2 get_account

    get_account($id)

Returns the account for the given id.

Example response:

 {
     id                => "AC7A",
     uri               => "/v1/marketplaces/MK98/accounts/AC7A",
     email_address     => "naveed\@crowdtilt.com",
     meta              => {},
     name              => undef,
     roles             => [],
     created_at        => "2012-06-07T21:01:38.801460Z",
     bank_accounts_uri => "/v1/marketplaces/MK98/accounts/AC7A/bank_accounts",
     cards_uri         => "/v1/marketplaces/MK98/accounts/AC7A/cards",
     credits_uri       => "/v1/marketplaces/MK98/accounts/AC7A/credits",
     debits_uri        => "/v1/marketplaces/MK98/accounts/AC7A/debits",
     holds_uri         => "/v1/marketplaces/MK98/accounts/AC7A/holds",
     refunds_uri       => "/v1/marketplaces/MK98/accounts/AC7A/refunds",
     transactions_uri  => "/v1/marketplaces/MK98/accounts/AC7A/transactions",
 }

=head2 get_account_by_email

    get_account_by_email($email)

Returns the account for the given email address.
See L</get_account> for an example response.

=head2 create_account

    create_account()
    create_account($account)
    create_account($account, card => $card)

Creates an account.
An account hashref is optional.
The account hashref, if passed in, must have an email_address field:

    $bp->create_account({ email_address => 'bob@crowdtilt.com' });

It is possible to create an account and associate it with a credit card at the
same time.
You can do this in 2 ways.
You can provide a card such as one returned by calling L</get_card>:

    my $card = $bp->get_card($card_id);
    $bp->create_account({ email_address => 'bob@crowdtilt.com' }, card => $card)

Alternatively, you can provide a card_uri inside the account hashref:

    my $card = $bp->get_card($card_id);
    $bp->create_account({
        email_address => 'bob@crowdtilt.com',
        card_uri      => $card->{uri},
    });

Returns an account hashref.
See L</get_account> for an example response.

=head2 update_account

    update_account($account)

Updates an account.
It expects an account hashref, such as one returned by L</get_account>.
The account hashref must contain a uri or id field.

=head2 add_card

    add_card($card, account => $account)

Adds a card to an account.
It expects a card hashref, such as one returned by L</get_card>,
and an account hashref, such as one returned by L</get_account>.

Returns an account hashref.
See L</get_account> for an example response.

=head2 get_debit

    get_debit($debit_id)

Returns the debit with the given id.
Example response:

  {
    id                       =>  "WD1xtdUeixQIfJEsg4RwwHjQ",
    transaction_number       =>  "W553-201-5667",
    amount                   =>  50,
    fee                      =>  1,
    description              =>  undef,
    appears_on_statement_as  =>  "example.com",
    available_at             =>  "2012-10-25T04:48:19.337522Z",
    created_at               =>  "2012-10-25T04:48:19.443904Z",
    uri                      =>  "/v1/marketplaces/MK98/debits/WD2L",
    refunds_uri              => "/v1/marketplaces/MK98/debits/WD2L/refunds",
    account                  =>  { ...  },
    hold                     =>  { ...  },
    meta                     =>  { ...  },
    source => {
      brand            => "MasterCard",
      card_type        => "mastercard",
      created_at       => "2012-06-07T11:00:40.003671Z",
      expiration_month => 12,
      expiration_year  => 2020,
      id               => "CC92QRQcwUCp5zpzEz7lXKS",
      is_valid         => 1,
      last_four        => 5100,
      name             => undef,
      uri => "/v1/marketplaces/MK98/accounts/AC7A/cards/CC92QRQcwUCp5zpzEz7lXKS",
    },
  }

=head2 create_debit

    create_debit($debit, account => $account)
    create_debit($debit, card => $card)

Creates a debit.
It expects a debit hashref which at least contains an amount field.
An account or card must be provided.

    my $account = $bp->get_account($account_id);
    $bp->create_debit ({ account => 250 }, account => $account);

    my $card = bp->get_card($card_id);
    $bp->create_debit({ amount => 250 }, card => $card);

Successful creation of a debit will return an associated hold as part of the
response.
This hold was created and captured behind the scenes automatically.
See L</get_debit> for an example response.

=head2 get_hold

    get_hold($hold_id)

Returns the hold with the given id.
Example response:

 {
   id          => "HL5byxIzSvf0entZuO9eEsWJ",
   uri         => "/v1/marketplaces/MK98/holds/HL5byxIzSvf0entZuO9eEsWJ",
   amount      => 200,
   description => undef,
   created_at  => "2012-06-08T09:23:53.745746Z",
   expires_at  => "2012-06-15T09:23:53.705009Z",
   fee         => 35,
   is_void     => 0,
   account     => { ... },
   debit       => { ... },
   meta        => { ... },
   source      => { ... },
 }

=head2 create_hold

    create_hold($hold, account => $account)
    create_hold($hold, card => $card)

Creates a hold for the given account.
It expects a hold hashref which at least contains an amount field.

An account or card must be provided.
If an account is provided, Balanced defaults to charging the most recently
added card for the account.

    my $account = $bp->get_account($account_id);
    $bp->create_hold ({ account => 250 }, account => $account);

You can pass in a card if you want to charge a specific card:

    my $card = bp->get_card($card_id);
    $bp->create_hold({ amount => 250 }, card => $card);

See L</get_hold> for an example response.

=head2 capture_hold

    capture_hold($hold)
    capture_hold($hold, {
        amount                  => ...,
        appears_on_statement_as => ...,
        meta                    => ...,
        description             => ...,
        on_behalf_of_uri        => ...,
        source_uri              => ...,
        bank_account_uri        => ...,
    })

Capturing a hold will create a debit representing the flow of funds from the
buyer's account to your marketplace.
The C<hold> param is required and may be a hold object or a hold uri.
A an optional hashref of extra parameters may be provided.
They will be passed on to Balanced.

    my $hold = $bp->get_hold($hold_id);
    my $merchant_account = $bp->get_account($merchant_id);
    $bp->capture_hold($hold, { on_behalf_of_uri => $merchant_account->{uri} });

Returns a debit hashref.
Example response:

 {
   id                      => "WD2Lpzyz8Okbhx2Nbw7YuTP3",
   transaction_number      => "W476-365-3767",
   uri                     => "/v1/marketplaces/MK98/debits/WD2L",
   amount                  => 50,
   appears_on_statement_as => "example.com",
   available_at            => "2012-06-08T09:57:27.686977Z",
   created_at              => "2012-06-08T09:57:27.750828Z",
   description             => undef,
   fee                     => 1,
   meta                    => { ... },
   hold                    => { ... },
   account                 => { ... },
   source                  => { ... },
   refunds_uri             => "/v1/marketplaces/MK98/debits/WD2L/refunds",
 }

 =head2 get_refund

     get_refund($id)

 Gets a refund by id.

     $bp->get_refund($id);

 Returns a refund hashref.
 Example response.
   {
     id                       =>  'RF74',
     transaction_number       =>  'RF966-744-5492',
     amount                   =>  323,
     fee                      =>  -10,
     description              =>  '',
     appears_on_statement_as  =>  'example.com',
     created_at               =>  '2012-08-27T16:54:46.595330Z',
     debit                    =>  { ... },
     meta                     =>  { ... },
     account                  =>  { ... },
     uri                      =>  '/v1/marketplaces/MP35/refunds/RF74',
   }

=head2 get_refunds

    get_refunds($debit)

Gets the refunds associated with a specific debit.

    my $debit = $bp->get_debit($debit_id);
    $bp->get_refunds($debit);

Returns a refunds hashref.
Example response.
  {
    items => [
      {
        id                       =>  'RF74',
        transaction_number       =>  'RF966-744-5492',
        amount                   =>  323,
        fee                      =>  -10,
        description              =>  '',
        appears_on_statement_as  =>  'example.com',
        created_at               =>  '2012-08-27T16:54:46.595330Z',
        debit                    =>  { ... },
        meta                     =>  { ... },
        account                  =>  { ... },
        uri                      =>  '/v1/marketplaces/MP35/refunds/RF74',
      }
    ],
    offset    => 0,
    limit     => 10,
    next_uri  => undef,
    total     => 1,
    uri       => '/v1/marketplaces/MP35/debits/WD2L/refunds?limit=10&offset=0',
    first_uri => '/v1/marketplaces/MP35/debits/WD2L/refunds?limit=10&offset=0',
    last_uri  => '/v1/marketplaces/MP35/debits/WD2L/refunds?limit=10&offset=0',
    previous_uri => undef,
  }

=head2 void_hold

    void_hold($hold)

Voids a hold.

    my $hold = $bp->get_hold($hold_id);
    $bp->void_hold($hold);

Returns a hold hashref.
See L</get_hold> for an example response.

=head2 refund_debit

    refund_debit($debit)

Refunds a debit.
If no amount is found in the debit hashref,
then Balanced refunds the entire amount.

    my $account = $bp->get_account($account_id);
    my $debit = $bp->capture_hold(
        $bp->create_hold({ amount => 305 }, account => $account)
    );
    $bp->refund_debit($debit);

Example response:

    {
        id                      => "RFrFB30adjtze8HSIoghLPr",
        uri                     => "/v1/marketplaces/MK98/refunds/RFrFB30adLPr",
        amount                  => 305,
        created_at              => "2012-06-11T11:31:59.414827Z",
        description             => undef,
        fee                     => -10,
        meta                    => {},
        transaction_number      => "RF536-609-0270",
        appears_on_statement_as => "example.com",
        account                 => { ... },
        debit                   => { ... },
    }

=head2 get_bank_account

    get_bank_account($id)

Returns the bank account for the given id.

Example response:

    {
        id          =>  "BA3gES",
        uri         =>  "/v1/marketplaces/MK98/bank_accounts/BA3gES",
        name        =>  "WHC III Checking",
        bank_name   =>  "SAN MATEO CREDIT UNION",
        bank_code   =>  321174851,
        last_four   =>  1234,
        created_at  =>  "2012-06-12T15:00:59.248638Z",
        is_valid    =>  1,
        account     =>  { ... },
    }

=head2 confirm_bank_verification

    confirm_bank_verification($bank_id, verification_id => $verification_id,
        amount_1 => $x, amount_2 => $y)

Returns the bank account verification status for the given ids.

Example response:

    {
        _type              => "bank_account_authentication",
        _uris              => {},
        attempts           => 0,
        created_at         => "2014-01-09T03:11:11.080804Z",
        id                 => "BZ5nDyPcUn2QNkgQn4o62gjM",
        remaining_attempts => 3,
        state              => "deposit_succeeded",
        updated_at         => "2014-01-09T03:11:11.490600Z",
        uri                => "/v1/bank_accounts/BA5lj/verifications/BZ5nD"
    }

=head2 create_bank_account

    create_bank_account($bank_account)

Creates a bank account.
A bank account hashref is required:

    $bp->create_bank_account({
        name           => "WHC III Checking",
        account_number => "12341234",
        bank_code      => "321174851",
    });

Returns a bank account hashref.
See L</get_bank_account> for an example response.

=head2 create_bank_verification

    create_bank_verification($bank_id)

Returns the bank account verification receipt for the request.

Example response:

    {
        _type              => "bank_account_authentication",
        _uris              => {},
        attempts           => 1,
        created_at         => "2014-01-09T03:11:20.160110Z",
        id                 => "BZ5xQsMUtax4itwPTPM2Ducu",
        remaining_attempts => 2,
        state              => "verified",
        updated_at         => "2014-01-09T03:11:21.482255Z",
        uri                => "/v1/bank_accounts/BA5vJy/verifications/BZ5xQs"
    }

=head2 add_bank_account

    add_bank_account($bank_account, account => $account)

Adds a bank account to an account.
It expects a bank account hashref and an account hashref:

    my $account = $bp->get_account($account_id);
    $bp->add_bank_account(
        {
            name           => "WHC III Checking",
            account_number => "12341234",
            bank_code      => "321174851",
        },
        account => $account
    );

This operation implicitly adds the "merchant" role to the account.

Returns a bank account hashref.
See L</get_bank_account> for an example response.

=head2 update_bank_account

    update_bank_account($bank_account)

Updates a bank account.
A bank account hashref must be provided which must contain an id or uri for
the bank account.
Balanced only allows you to update the is_valid and meta fields.
You may invalidate a bank account by passing is_valid with a false value.
Once a bank account has been invalidated it cannot be re-activated.

    $bp->update_bank_account({
        id       => 'BA3gES',
        is_valid => 0,
        meta     => { foo => 'bar' },
    });

Returns a bank account hashref.
See L</get_bank_account> for an example response.

=head2 invalidate_bank_account

    invalidate_bank_account($bank_account_id);

Invalidates a bank account.
A bank account id is required.
This is a convenience method that does the equivalent of:

    update_bank_account({ id => $bank_id, is_valid => 0 });

Returns a bank account hashref.
See L</get_bank_account> for an example response.

=head2 get_credit

    get_credit($credit_id);

Gets a credit.
This is a way to get information about a specific credit, which can be useful
to check its status or get fee information about it.

=head2 create_credit

    create_credit($credit, account => $account);
    create_credit($credit, bank_account => $bank_account);

Creates a credit.
This is a way of sending money to merchant accounts.
The credit hashref should at least contain an amount field.
An account or bank account hashref is required.
You may pass in a bank account if you would like to specify a specific bank
account to send money to.

    my $bank_account = $bp->get_bank_account($bank_account_id);
    $bp->create_credit({ amount => 50 }, bank_account => $bank_account);

If an account is provided, Balanced will default to crediting the most recently
added bank account.
The account should have the merchant role.

    my $account = $bp->get_account($account_id);
    $bp->create_credit({ amount => 50 }, account => $account);

Returnds a credit hashref.
Example response:

    {
        id                  => "CR4GkfkOzYNBjFXW5Mxtpn1I",
        uri                 => "/v1/marketplaces/MK98/credits/CR4Gkf",
        amount              => 50,
        created_at          => "2012-06-12T18:51:21.097085Z",
        description         => undef,
        meta                => {},
        transaction_number  => "CR382-740-3389",
        account             => { ... },
        destination         => {
            bank_code  => 321174851,
            bank_name  => "SAN MATEO CREDIT UNION",
            created_at => "2012-06-12T15:00:59.248638Z",
            id         => "BA3gESxjg9yO61fj3CVUhGQm",
            is_valid   => 1,
            last_four  => 1234,
            name       => "WHC III Checking",
            uri => "/v1/marketplaces/MK98/accounts/AC78/bank_accounts/BA3g",
        },
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

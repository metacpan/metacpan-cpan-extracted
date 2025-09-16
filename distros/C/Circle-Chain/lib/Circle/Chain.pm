package Circle::Chain;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
use Carp;
use Circle::User;
use Circle::Wallet;
use Circle::Block;
use Circle::Node;

our @EXPORT_OK = qw([
  send_register_verify_code register send_verify_code login
  logout send_pay_verify_code set_pay_password
  have_pay_password send_reset_password_verify_code
  reset_password add_contacts list_contacts
  save_or_update_user_info get_user_info

  create_wallet list_wallet balance_of_address
  balance_of_wallet assets_of_address assets_of_wallet
  public_key_hash_from_address send_to pay
  search_tx_by_type search_tx_by_time let_me_try
  public_address_of_uid public_balance_of_address
  public_assets_of_address public_search_transaction

  get_block_hashlist get_block get_block_header_list get_block_data
  get_blocktails_hashlist get_blocktails_po get_tx_by_txid search_tx_by_txid
  search_tx_by_address search_utxos

  subscribe serverFeatures broadcastTransaction
);
our %EXPORT_TAGS = (
    user => [
        qw(
          send_register_verify_code
          register
          send_verify_code
          login
          logout
          send_pay_verify_code
          set_pay_password
          have_pay_password
          send_reset_password_verify_code
          reset_password
          add_contacts
          list_contacts
          save_or_update_user_info
          get_user_info
        )
    ],
    wallet => [
        qw(
          create_wallet
          list_wallet
          balance_of_address
          balance_of_wallet
          assets_of_address
          assets_of_wallet
          public_key_hash_from_address
          send_to pay
          search_tx_by_type
          search_tx_by_time
          let_me_try
          public_address_of_uid
          public_balance_of_address
          public_assets_of_address
          public_search_transaction
        )
    ],
    block => [
        qw(
          get_block_hashlist
          get_block
          get_block_header_list
          get_block_data
          get_blocktails_hashlist
          get_blocktails_po
          get_tx_by_txid
          search_tx_by_txid
          search_tx_by_address
          search_utxos
        )
    ],
    node => [
        qw(
          subscribe
          serverFeatures
          broadcastTransaction
        )
    ],
);

=head1 NAME

Circle::Chain - The Circle::Chain SDks.

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Circle::Chain qw(:user :wallet :block :node);
    # 1. first register or login
    my $response = send_register_verify_code(
        {
            email => 'circle-node@gmail.com'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot send register verify code:' . $response->{status};
    }

    # receive you verify code in email or your mobile phone.
    $response = register(
        {
            email          => 'circle-node@gmail.com',
            passwordInput1 => '<password>',
            passwordInput2 => '<password>',
            verifyCode     => '<verify_code>'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot register status' . $response->{status};
    }
    $response = send_verify_code(
        {
            email => 'circle-node@gmail.com'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot send login verify code:' . $response->{status};
    }

    # receive you verify code in email or your mobile phone.
    $response = login(
        {
            email      => 'circle-node@gmail.com',
            verifyCode => '<verify_code>',
            password   => '<password>'
        }
    );
    if ( $response->{status} != 200 ) {
        croak 'cannot login status' . $response->{status};
    }

    # 2. new user will create wallet.
    $response = create_wallet();
    my $address;
    if ( $response->{status} == 200 ) {
        $address = $response->{data};
    }
    $response = balance_of_address($address);
    # $response->{status} == 200, get the balance: $response->{data}
    $response = assets_of_address($address);
    # $response->{status} == 200, get the assets: $response->{data}
    # if you created wallets
    $response = list_wallet();
    # $response->{status} == 200, get the address list: $response->{data}

    # 3. anonymous user will invoke get_block_hashlist api.
    my $response = get_block_hashlist(0);
    if ( $response->{status} != 200 ) {
        croak 'cannot get block hash list:' . $response->{status};
    }
    ...

=head1 EXPORT

If you want to use user module:

    use Circle::Chain ':user';

for user module, the exported subroutines:

=over

=item 1. send_register_verify_code

=item 2. register

=item 3. send_verify_code

=item 4. login

=item 5. logout

=item 6. send_pay_verify_code

=item 7. set_pay_password

=item 8. have_pay_password

=item 9. send_reset_password_verify_code

=item 10. reset_password

=item 11. add_contacts

=item 12. list_contacts

=item 13. save_or_update_user_info

=item 14. get_user_info

=back

If you want to use block module:

    use Circle::Chain ':block';

for block module, the exported subroutines:

=over

=item 1. get_block_hashlist

=item 2. get_block

=item 3. get_block_header_list

=item 4. get_block_data

=item 5. get_blocktails_hashlist

=item 6. get_blocktails_po

=item 7. get_tx_by_txid

=item 8. search_tx_by_txid

=item 9. search_tx_by_address

=item 10. search_utxos

=back


If you want to use wallet module:

    use Circle::Chain ':wallet';

for wallet module, the exported subroutines:

=over

=item 1. create_wallet

=item 2. list_wallet

=item 3. balance_of_address

=item 4. balance_of_wallet

=item 5. assets_of_address

=item 6. assets_of_wallet

=item 7. public_key_hash_from_address

=item 8. send_to

=item 9. pay

=item 10. search_tx_by_type

=item 11. search_tx_by_time

=item 12. let_me_try

=item 13. public_address_of_uid

=item 14. public_balance_of_address

=item 15. public_assets_of_address

=item 16. public_search_transaction

=back

If you want to use node module:

    use Circle::Chain ':node';

for node module, the exported subroutines:

=over

=item 1. subscribe

=item 2. serverFeatures

=item 3. broadcastTransaction

=back

=head1 SUBROUTINES/METHODS

please refer to L<Circle::User>, L<Circle::Wallet>, L<Circle::Block>, L<Circle::Node> modules.

=cut

=head1 AUTHOR

charles li, C<< <lidh04 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-circle-chain at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Circle-Chain>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

See L<Circle::Common> for circle common module.

See L<Circle::User> for circle user module .

See L<Circle::Wallet> for circle wallet module.

See L<Circle::Block> for circle block module.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Circle::Chain


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Circle-Chain>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Circle-Chain>

=item * Search CPAN

L<https://metacpan.org/release/Circle-Chain>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by charles li.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Circle::Chain

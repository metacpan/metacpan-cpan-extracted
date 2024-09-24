package Circle::Wallet;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
use Carp;
use Time::HiRes    qw(gettimeofday);
use Circle::Common qw(load_config http_json_post http_json_get);

our @EXPORT = qw(
  create_wallet
  list_wallet
  balance_of_address
  balance_of_wallet
  assets_of_address
  assets_of_wallet
  public_key_hash_from_address
  send_to
  pay
  search_tx_by_type
  search_tx_by_time
  let_me_try

  public_address_of_uid
  public_balance_of_address
  public_assets_of_address
  public_search_transaction
);

=head1 NAME

Circle::Wallet - the circle chain SDK in PERL

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Circle::Wallet;
    # first of all, you must login and then do the following operations.
    # how to login please refer to Circle::User module.
    # first time to use, each user has 3 wallets to create.
    my $response = create_wallet();
    my $address;
    if ($response->{status} == 200) {
        $address = $response->{data};
    }
    $response = balance_of_address($address);
    # $response->{status} == 200, get the balance: $response->{data}
    $response = assets_of_address($address);
    # $response->{status} == 200, get the assets: $response->{data}
    # if you created 3 wallets
    $response = list_wallet();
    # $response->{status} == 200, get the address list: $response->{data}
    ...

=head1 EXPORT

The default exported methods:

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

=cut

=head1 SUBROUTINES/METHODS

=head2 create_wallet

create wallet in the cloud.

=cut

sub create_wallet {
    my $url = _build_create_wallet_url();
    return http_json_post( $url, {} );
}

sub _build_create_wallet_url {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $base_uri    = $wallet_path->{createWallet};
    my $host        = get_host();
    return "${host}${base_uri}";
}

=head2 list_wallet

list the wallet address

   my $response = list_wallet();
   if ($response->{status} == 200) {
      my $addresses = $response->{data};
      // process address list here.
   }

=cut

sub list_wallet {
    my $url = _build_list_wallet_url();
    return http_json_get($url);
}

sub _build_list_wallet_url {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $base_uri    = $wallet_path->{listWallet} . '?phone=';
    my $host        = get_host();
    return "${host}${base_uri}";
}

=head2 balance_of_address

get the balance of the address

   my $response = balance_of_address( $address, $type ); # type: 1 ownership, 2 identity
   if ($response->{status} == 200) {
     my $balance = $response->{data};
     // process the balance here.
   }

=cut

sub balance_of_address {
    my ($address) = @_;
    my $url = _build_balance_of_address($address);
    return http_json_get($url);
}

sub _build_balance_of_address {
    my ($address)   = @_;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{balanceOfAddress};
    return "${host}${base_uri}?address=${address}";
}

sub get_host {
    my $config   = load_config();
    my $http     = $config->{http};
    my $protocol = $http->{protocol};
    my $host     = $http->{host};
    return "$protocol://$host";
}

=head2 balance_of_wallet

get the balance of the wallets

   $response = balance_of_wallet();
   if ($response->{status} == 200) {
     my $balance_infos = $response->{data};
     // process balance_infos data here.
   }

=cut

sub balance_of_wallet {
    my $url = _build_balance_of_wallet();
    return http_json_get($url);
}

sub _build_balance_of_wallet {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{balanceOfWallet};
    return "${host}${base_uri}";
}

=head2 assets_of_address

get the assets of the address

  my $response = assets_of_address( $address, $type);  # type: 1 ownership, 2 identity
  if ($response->{status} == 200) {
    my $asset_infos = $response->{data};
    // process assets info here.
  }

=cut

sub assets_of_address {
    my ( $address, $type ) = @_;
    my $url = _build_assets_of_address( $address, $type );
    return http_json_get($url);
}

sub _build_assets_of_address {
    my ( $address, $type ) = @_;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{assetsOfAddress};
    return "${host}${base_uri}?address=${address}&type=${type}";
}

=head2 assets_of_wallet

get the assets of the wallet

  my $response = assets_of_wallet();
  if ($response->{status} == 200) {
    my $assets_infos = $response->{data};
    // process assets info here.
  }

=cut

sub assets_of_wallet {
    my $url = _build_assets_of_wallet();
    return http_json_get($url);
}

sub _build_assets_of_wallet {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{assetsOfWallet};
    return "${host}${base_uri}";
}

=head2 public_key_hash_from_address

get the public key hash from address

  my $response = public_key_hash_from_address( $address );
  if ($response->{status} == 200) {
    my $public_key_hash = $response->{data};
    // process public key hash here.
  }

=cut

sub public_key_hash_from_address {
    my ($address) = @_;
    my $url = _build_public_key_hash_from_address($address);
    return http_json_get($url);
}

sub _build_public_key_hash_from_address {
    my ($address)   = @_;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{pubKeyHashFromAddress};
    return "${host}${base_uri}?address=${address}";
}

=head2 send_to

send assets to others

  my $response = send_to({
    from => '<from-address>',
    address => '<to-address>',
    email => 'test@gmail.com',
    transContent => {
      type => 1, # 1 ownership, 2 identity
      uuid => '<asset uuid string>',
    },
    payPassword => '<pay password>'
  });
  if ($response->{status} == 200) {
    my $success = $response->{data};
    // check the sendTo api success or failure here.
  }

=cut

sub send_to {
    my ($req) = @_;
    my $url = _build_send_to();
    return http_json_post( $url, $req );
}

sub _build_send_to {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{sendTo};
    return "${host}${base_uri}";
}

=head2 pay

pay balance to others

  my $response = pay({
    from => '<from-address>',
    to => '<to-address>',
    value => 1000, # send 1000 li to others.
    payPassword => '<pay password>'
  });
  if ($response->{status} == 200) {
    my $success = $response->{data};
    // check pay api success or failure.
  }

=cut

sub pay {
    my ($req) = @_;
    my $url = _build_pay();
    return http_json_post( $url, $req );
}

sub _build_pay {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{pay};
    return "${host}${base_uri}";
}

=head2 search_tx_by_type

search transaction by type.

  my $type = 0; // balance
  my $page_no = 1;
  my $page_size = 100;
  my $response = search_tx_by_type( $type, $page_no, $page_size );
  if ($response->{status} == 20) {
    my $tx_info_list = $response->{data};
    // process your tx info list here.
  }

=cut

sub search_tx_by_type {
    my ( $type, $page_no, $page_size ) = @_;
    my $url = _build_search_tx_by_type( $type, $page_no, $page_size );
    return http_json_get($url);
}

sub _build_search_tx_by_type {
    my ( $type, $page_no, $page_size ) = @_;
    $page_no   //= 1;
    $page_size //= 10;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{searchTxByType};
    return "${host}${base_uri}?type=${type}&pageNo=${page_no}&pageSize=${page_size}";
}

=head2 search_tx_by_time

search transaction by time

  my $start_time = 1764233300;
  my $end_time = 18343232300;
  my $page_size = 100;
  my $response = search_tx_by_time( $start_time, $end_time, $page_size );
  if ( $response->{status} == 20 ) {
    my $tx_info_list = $response->{data};
    // process your tx info list here .;
  }

=cut

sub search_tx_by_time {
    my ( $start_time, $end_time, $page_no, $page_size ) = @_;
    my $url = _build_search_tx_by_time( $start_time, $end_time, $page_no, $page_size );
    return http_json_get($url);
}

sub _build_search_tx_by_time {
    my ( $start_time, $end_time, $page_no, $page_size ) = @_;
    my ( $s, $usec ) = gettimeofday();
    my $milliseconds = int( $s * 1000 + $usec / 1000 );
    $end_time  //= $milliseconds;
    $page_no   //= 1;
    $page_size //= 10;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $base_uri    = $wallet_path->{searchTxByTime};
    my $host        = get_host();
    return "${host}${base_uri}?startTime=${start_time}&endTime=${end_time}&pageNo=${page_no}&pageSize=${page_size}";
}

=head2 let_me_try

let me try to mine the block, and get some assets and balances.

  my $response = let_me_try();
  if ($response->{status} == 200) {
    my $transaction_info = $response->{data};
    // process transaction info here.
  }

=cut

sub let_me_try {
    my $url = _build_let_me_try();
    return http_json_post($url);
}

sub _build_let_me_try {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{letMeTry};
    return "${host}${base_uri}";
}

=head2 public_address_of_uid

public api without user login, address of uid.

  my $response = public_address_of_uid( $uid );
  if ($response->{status} == 200) {
    my $address = $response->{data};
    // process address code here.
  }

=cut

sub public_address_of_uid {
    my ($uid) = @_;
    my $url = _build_public_address_uid($uid);
    return http_json_get($url, 0);
}

sub _build_public_address_uid {
    my ($uid)       = @_;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{getAddressByUid};
    return "${host}${base_uri}?uid=${uid}";
}

=head2 public_balance_of_address

public api without user login. balance_of_address

  my $response = public_balance_of_address( $address );
  if ($response->{status} == 200) {
    my $balance = $response->{data};
    // process balance code here.
  }

=cut

sub public_balance_of_address {
    my ($address) = @_;
    my $url = _build_public_address_address($address);
    return http_json_get($url, 0);
}

sub _build_public_address_address {
    my ($address)   = @_;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{getBalanceByAddress};
    return "${host}${base_uri}?address=${address}";
}

=head2 public_assets_of_address

public api without user login, assets of address

  my $response = public_assets_of_address( $address, $type ); # type: 1 ownership 2 identity
  if ($response->{status} == 200) {
    my $assets = $response->{data};
    // process assets here.
  }

=cut

sub public_assets_of_address {
    my ( $address, $type ) = @_;
    my $url = _build_public_assets_of_address( $address, $type );
    return http_json_get($url, 0);
}

sub _build_public_assets_of_address {
    my ( $address, $type ) = @_;
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{getAssetsOfAddress};
    return "${host}${base_uri}?address=${address}&type=${type}";
}

=head2 public_search_transaction

public api without user login, search transaction

  my $response = public_search_transaction({
    address => '<address>',
    inOut => 'IN', # IN/OUT
    transactionContent => {
      type => 1, # 0 balance, 1 ownership, 2 identity
       # uid hex string or (uid hex string + '' + data hash hex)
      uuid => '<uid hex string>',
    }
  });
  if ($response->{status} == 200) {
    my $trans = $response->{data};
    // process trans data here.
  }

=cut

sub public_search_transaction {
    my ($req) = @_;
    my $url = _build_public_search_transaction();
    return http_json_post( $url, $req, 0 );
}

sub _build_public_search_transaction {
    my $config      = load_config();
    my $wallet_path = $config->{wallet}->{path};
    my $host        = get_host();
    my $base_uri    = $wallet_path->{searchTransaction};
    return "${host}${base_uri}";
}

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

    perldoc Circle::Wallet


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Circle-Chain>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Circle-Chain>

=item * Search CPAN

L<https://metacpan.org/release/Circle-Chain>

=back


=head1 ACKNOWLEDGEMENTS

This module belong to author C<lidh04@gmail>

=cut

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by charles li.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Circle::Wallet

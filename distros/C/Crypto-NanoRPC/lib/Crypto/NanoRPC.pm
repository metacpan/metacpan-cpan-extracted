package Crypto::NanoRPC;

use 5.018001;
use strict;
use warnings;
use HTTP::Request;
use LWP::UserAgent;
use JSON;

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = ();

our $VERSION = '0.9.1';

my $rpc_actions = {
    # Node RPC's
    account_balance => [ 'account' ],
    account_block_count => [ 'account' ],
    account_get => [ 'key' ],
    account_history => [ 'account', 'count', [ 'raw', 'head', 'offset', 'reverse' ] ],
    account_info => [ 'account', [ 'representative', 'weight', 'pending' ] ],
    account_key => [ 'account' ],
    account_representative => [ 'account' ],
    account_weight => [ 'account' ],
    accounts_balances => [ 'accounts' ],    # accounts is reference to a list
    accounts_frontiers => [ 'accounts' ],
    accounts_pending => [ 'accounts', 'count' ],
    active_difficulty => [],
    available_supply => [],
    block_account => [ 'hash' ],
    block_count => [],
    block_count_type => [],
    block_confirm => [ 'hash' ],
    block_create => [ 'type', 'balance', 'representative', 'previous', [ 'account', 'wallet', 'source', 'destination', 'link', 'json_block', 'work' ] ],
    block_hash => [ 'block' ],
    block_info => [ 'hash', [ 'json_block' ] ],
    blocks => [ 'hashes' ],
    blocks_info => [ 'hashes', [ 'pending', 'source', 'balance', 'json_block' ] ],
    bootstrap => [ 'address', 'port' ],
    bootstrap_any => [],
    bootstrap_lazy => [ 'hash', [ 'force' ] ],
    bootstrap_status => [],
    chain => [ 'block', 'count', [ 'offset', 'reverse' ] ],
    confirmation_active => [ [ 'announcements' ] ],
    confirmation_height_currently_processing => [],
    confirmation_history => [ [ 'hash' ] ],
    confirmation_info => [ 'root', [ 'contents', 'representatives', 'json_block' ] ],
    confirmation_quorum => [ [ 'peer_details' ] ],
    database_txn_tracker => [ 'min_read_time', 'min_write_time' ],
    delegators => [ 'account' ],
    delegators_count => [ 'account' ],
    deterministic_key => [ 'seed', 'index' ],
    frontier_count => [],
    frontiers => [ 'account', 'count' ],
    keepalive => [ 'address', 'port' ],
    key_create => [],
    key_expand => [ 'key' ],
    ledger => [ 'account', 'count', [ 'representative', 'weight', 'pending', 'modified_since', 'sorting' ] ],
    node_id => [],
    node_id_delete => [],
    peers => [ [ 'peer_details' ] ],
    pending => [ 'account', [ 'count', 'threshold', 'source', 'include_active', 'sorting', 'include_only_confirmed' ] ],
    pending_exists => [ 'hash', [ 'include_active', 'include_only_confirmed' ] ],
    process => [ 'block', [ 'force', 'subtype', 'json_block' ] ],
    representatives => [ [ 'count', 'sorting' ] ],
    representatives_online => [ [ 'weight' ] ],
    republish => [ 'hash', [ 'sources', 'destinations' ] ],
    sign => [ 'block', [ 'key', 'wallet', 'account', 'json_block' ] ],
    stats => [ 'type' ],
    stats_clear => [],
    stop => [],
    successors => [ 'block', 'count', [ 'offset', 'reverse' ] ],
    validate_account_number => [ 'account' ],
    version => [],
    unchecked => [ 'count' ],
    unchecked_clear => [],
    unchecked_get => [ 'hash', [ 'json_block' ] ],
    unchecked_keys => [ 'key', 'count', [ 'json_block' ] ],
    unopened => [ [ 'account', 'count' ] ],
    uptime => [],
    work_cancel => [ 'hash' ],
    work_generate => [ 'hash', [ 'use_peers', 'difficulty' ] ],
    work_peer_add => [ 'address', 'port' ],
    work_peers => [],
    work_peers_clear => [],
    work_validate => [ 'work', 'hash', [ 'difficulty' ] ],

    # Wallet RPC's
    account_create => [ 'wallet', [ 'index', 'work' ] ],
    account_list => [ 'wallet' ],
    account_move => [ 'wallet', 'source', 'accounts' ],
    account_remove => [ 'wallet', 'account' ],
    account_representative_set => [ 'wallet', 'account', 'representative', [ 'work' ] ],
    accounts_create => [ 'wallet', 'count', [ 'work' ] ],
    password_change => [ 'wallet', 'password' ],
    password_enter => [ 'wallet', 'password' ],
    password_valid => [ 'wallet' ],
    receive => [ 'wallet', 'account', 'block', [ 'work' ] ],
    receive_minimum => [],
    receive_minimum_set => [ 'amount' ],
    search_pending => [ 'wallet' ],
    search_pending_all => [],
    send => [ 'wallet', 'source', 'destination', 'amount', [ 'work' ] ],
    wallet_add => [ 'wallet', 'key', [ 'work' ] ],
    wallet_add_watch => [ 'wallet', 'accounts' ],
    wallet_balances => [ 'wallet', [ 'threshold' ] ],
    wallet_change_seed => [ 'wallet', 'seed', [ 'count' ] ],
    wallet_contains => [ 'wallet', 'account' ],
    wallet_create => [ [ 'seed' ] ],
    wallet_destroy => [ 'wallet' ],
    wallet_export => [ 'wallet' ],
    wallet_frontiers => [ 'wallet' ],
    wallet_history => [ 'wallet', [ 'modified_since' ] ],
    wallet_info => [ 'wallet' ],
    wallet_ledger => [ 'wallet', [ 'representative', 'weight', 'pending', 'modified_since' ] ],
    wallet_lock => [ 'wallet' ],
    wallet_locked => [ 'wallet' ],
    wallet_pending => [ 'wallet', 'count', [ 'threshold', 'source', 'include_active', 'include_only_confirmed' ] ],
    wallet_representative => [ 'wallet' ],
    wallet_representative_set => [ 'wallet', 'representative', [ 'update_existing_accounts' ] ],
    wallet_republish => [ 'wallet', 'count' ],
    wallet_work_get => [ 'wallet' ],
    work_get => [ 'wallet', 'account' ],
    work_set => [ 'wallet', 'account', 'work' ],

    # Conversion RPC's  
    krai_from_raw => [ 'amount' ],
    krai_to_raw => [ 'amount' ],
    mrai_from_raw => [ 'amount' ],
    mrai_to_raw => [ 'amount' ],
    rai_from_raw => [ 'amount' ],
    rai_to_raw => [ 'amount' ],
};

sub new {
    my $class = shift;
    my $self = {
        url       => shift,
    };
    $self->{url} = 'http://[::1]:7076' unless defined $self->{url};
    $self->{request} = HTTP::Request->new( 'POST', $self->{url} );
    $self->{request}->content_type('application/json');
    $self->{ua} = LWP::UserAgent->new;
    bless $self, $class;
    return $self;
}

sub set_wallet {
    my $self = shift;
    $self->{wallet} = shift;
    return $self;
}

sub set_account {
    my $self = shift;
    $self->{account} = shift;
    return $self;
}

sub set_params {
    my ($self,$extra) = @_;
    if (ref $extra eq 'HASH') {
        $self->{$_} = $extra->{$_} for (keys %$extra);
    } else {
        # assume key/values were specified as array
        shift @_;
        while (@_) {
            my ($key,$value) = (shift,shift);
            $self->{$key} = $value;
        }
    }
    return $self;
}

sub AUTOLOAD {
    my ($self,$extra) = @_;
    if (ref $extra eq 'HASH') {
        $self->{$_} = $extra->{$_} for (keys %$extra);
    } else {
        # assume key/values were specified as array
        shift @_;
        while (@_) {
            my ($key,$value) = (shift,shift);
            $self->{$key} = $value;
        }
    }
    our $AUTOLOAD;
    my $action = $AUTOLOAD;
    $action =~ s/.*:://;
    if (defined $rpc_actions->{$action}) {
        my $options;
        my $json = '{"action": "'.$action.'"';
        foreach my $param (@{$rpc_actions->{$action}}) {
            return { error => "missing parameter $param" } unless defined $self->{$param};
            if (ref $param eq 'ARRAY') {
                $options = $param; next;
            }
            # assumes strings when params are not arrays
            $json .= ', "'.$param.'": "'.$self->{$param}.'"' if ref $self->{$param} ne 'ARRAY';
            $json .= ', "'.$param.'": '.$self->{$param} if ref $self->{$param} eq 'ARRAY';
        }
        if (ref $options eq 'ARRAY') {
            foreach my $option (@$options) {
                next unless defined $self->{$option};
                # assumes strings when options are not arrays
                $json .= ', "'.$option.'": "'.$self->{$option}.'"' if ref $self->{$option} ne 'ARRAY';
                $json .= ', "'.$option.'": '.$self->{$option} if ref $self->{$option} eq 'ARRAY';
            }
        }
        $json .= '}';
        return __do_rpc($self,$json);
    }
    return { error => "action $action not defined" };
}

sub rai_to_raw {
    my $rai = shift;
    return $rai * 1000000000000000000000000;
}

sub mrai_to_raw {
    my $rai = shift;
    return $rai * 1000000000000000000000000000000;
}

sub raw_to_rai {
    my $raw = shift;
    return $raw / 1000000000000000000000000;
}

sub raw_to_mrai {
    my $raw = shift;
    return $raw / 1000000000000000000000000000000;
}

sub __do_rpc {
    my ($self,$json) = @_;
    $self->{request}->content($json);
    my $response = $self->{ua}->request($self->{request});
    if ($response->is_success) {
        return decode_json($response->decoded_content);
    }
    return { error => "RPC call failed" };
}

1;
__END__

=head1 NAME

Crypto::NanoRPC - Perl module for interacting with Nano node

=head1 SYNOPSIS

  use Crypto::NanoRPC;
  $rpc = NanoRPC->new();
  $rpc = NanoRPC->new( 'http://[::1]:7076' );
 
  $rpc->set_params(
                        wallet => '000XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX',
                        account => 'nano_111111111111111111111111111111111111111111111111111111111111',
                  );
 
  $response = $rpc->account_balance();
  
  printf "Balance: %s\n", $response->{balance} unless defined $response->{error};


=head1 DESCRIPTION

=over 1

Object Oriented perl class for interacting with a Nano (rai) node

Implemented RPC calls are defined in the array rpc_actions in NanoRPC.pm. The required arguments can
be set using the set_params() method. The most common arguments, "wallet" and "account", have their own
set_ methods.

=back

=head1 METHODS

See L<https://docs.nano.org/commands/rpc-protocol/> for a list of RPC calls. This module implements the following RPCs:

=head2 Node RPCs

account_balance account_block_count account_get account_history account_info account_key account_representative account_weight accounts_balances accounts_frontiers accounts_pending active_difficulty available_supply block_account block_count block_count_type block_confirm block_create block_hash block_info blocks blocks_info bootstrap bootstrap_any bootstrap_lazy bootstrap_status chain confirmation_active confirmation_height_currently_processing confirmation_history confirmation_info confirmation_quorum database_txn_tracker delegators delegators_count deterministic_key frontier_count frontiers keepalive key_create key_expand ledger node_id node_id_delete peers pending pending_exists process representatives representatives_online republish sign stats stats_clear stop successors validate_account_number version unchecked unchecked_clear unchecked_get unchecked_keys unopened uptime work_cancel work_generate work_peer_add work_peers work_peers_clear work_validate

=head2 Wallet RPCs

account_create account_list account_move account_remove account_representative_set accounts_create password_change password_enter password_valid receive receive_minimum receive_minimum_set search_pending search_pending_all send wallet_add wallet_add_watch wallet_balances wallet_change_seed wallet_contains wallet_create wallet_destroy wallet_export wallet_frontiers wallet_history wallet_info wallet_ledger wallet_lock wallet_locked wallet_pending wallet_representative wallet_representative_set wallet_republish wallet_work_get work_get work_set

=head2 Unit Conversion RPCs

krai_from_raw krai_to_raw mrai_from_raw mrai_to_raw rai_from_raw rai_to_raw

=head1 DEPENDENCIES

These modules are required:

=over 1

=item HTTP::Request

=item LWP::UserAgent

=item JSON

=back

=head1 AUTHOR

Ruben de Groot, ruben at hacktor.com

Git Repository: L<https://github.com/hacktor/Crypto-NanoRPC>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Ruben de Groot

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

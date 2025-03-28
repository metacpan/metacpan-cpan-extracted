package Circle::Block;

use 5.006;
use strict;
use warnings;
use Exporter 'import';
use Carp;
use Try::Tiny;
use URL::Encode;
use Circle::Common qw(load_config build_url_template http_json_post http_json_get);

our $VERSION = '0.05';

our @EXPORT = qw(
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
);

sub _build_url_template {
    my ($path, $params_for) = @_;
    return build_url_template( "block", $path, $params_for );
}

sub get_block_hashlist {
    my ($base_height) = @_;
    my $url = _build_url_template(
        "blockchainHashListPath",
        {
            baseHeight => $base_height
        }
    );
    carp 'url: ' . $url;
    return http_json_get($url, 0);
}

sub get_block {
    my ($hash) = @_;
    my $url = _build_url_template(
        "blockchainPath",
        {
            hash => $hash
        }
    );
    return http_json_get($url);
}

sub get_block_header_list {
    my ($base_height) = @_;
    my $url = _build_url_template(
        "blockchainHeaderListPath",
        {
            baseHeight => $base_height
        }
    );
    return http_json_get($url, 0);
}

sub get_block_data {
    my ($hash) = @_;
    my $url = _build_url_template(
        "blockchainDataPath",
        {
            hash => $hash
        }
    );
    return http_json_get($url);
}

sub get_blocktails_hashlist {
    my ($base_height) = @_;
    my $url = _build_url_template(
        "blockchainTailsHashListPath",
        {
            baseHeight => $base_height
        }
    );
    return http_json_get($url, 0);
}

sub get_blocktails_po {
    my ($hash) = @_;
    my $url = _build_url_template(
        "blockchainTailsPOPath",
        {
            hash => $hash
        }
    );
    return http_json_get($url, 0);
}

sub get_tx_by_txid {
    my ($txid) = @_;
    my $url = _build_url_template(
        "transactionByTxIdPath",
        {
            txId => $txid
        }
    );
    return http_json_get($url, 0);
}

sub search_tx_by_txid {
    my ($txid) = @_;
    my $url = _build_url_template(
        "searchTxByTxIdPath",
        {
            txId => $txid
        }
    );
    return http_json_get($url, 0);
}

sub search_tx_by_address {
    my ( $address, $min_output_key, $limit ) = @_;
    $min_output_key //= '';
    $limit          //= 10;
    my $url = _build_url_template(
        "searchTxByAddressPath",
        {
            address      => $address,
            minOutputKey => $min_output_key,
            limit        => $limit
        }
    );
    return http_json_get($url, 0);
}

sub search_utxos {
    my ( $address, $min_output_key, $limit ) = @_;
    $min_output_key //= '';
    $limit          //= 10;
    my $url = _build_url_template(
        "searchUTXOsPath",
        {
            address      => $address,
            minOutputKey => $min_output_key,
            limit        => $limit
        }
    );
    return http_json_get($url, 0 );
}

1;

__END__

=head1 NAME

Circle::Block - the block module for Circle::Chain SDK

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    my $response = get_block_hashlist(0);
    if ($response->{status} != 200) {
        croak 'cannot get block hash list:' . $response->{status};
    }
    my $data = $response->{data};
    # process the block hash list data here.
    my $hash = $data->[0];
    $response = get_block($hash);
    if ($response->{status} != 200) {
        croak 'cannot get block:' . $response->{status};
    }
    // process block data here.


=head1 DESCRIPTION

The module provides block functions.

=head1 EXPORT

Export the following methods in default:

    our @EXPORT = qw(
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
    );

So you just use the module:

    use Circle::Block;


=head1 METHODS


=head2 get_block_hashlist( $base_height )

    my $response = get_block_hashlist(0);
    if ($response->{status} != 200) {
        croak 'cannot get block hash list:' . $response->{status};
    }
    my $data = $response->{data};
    # process the block hash list data here.


=head2 get_block( $hash )

    my $hash = 'xxxxxxxxx';
    my $response = get_block($hash);
    if ($response->{status} != 200) {
        croak 'cannot get block:' . $response->{status};
    }
    my $data = $response->{data};
    // process block data here.

=head2 get_block_header_list( $base_height )

    my $response = get_block_header_list(0);
    if ($response->{status} != 200) {
        croak 'cannot get block header list:' . $response->{status};
    }
    my $data = $response->{data};
    # process the block hash header list here.

=head2 get_block_data($hash)

    my $hash = 'xxxxxxxxx';
    my $response = get_block_data( $hash );
    if ($response->{status} != 200) {
        croak 'cannot get block data:' . $response->{status};
    }
    my $data = $response->{data};
    // process block data here.

=head2 get_blocktails_hashlist( $base_height )

    my $response = get_blocktails_hashlist(0);
    if ($response->{status} != 200) {
        croak 'cannot get block tails hashlist status: ' . $response->{status};
    }
    my $data = $response->{data};
    // process block tails hash list here.

=head2 get_blocktails_po( $hash )

    my $hash = 'xxxxxxxxx';
    my $response = get_blocktails_po($hash);
    if ($response->{status} != 200) {
        croak 'cannot get block tails data:' . $response->{status};
    }
    my $data = $response->{data};
    // process block tails here.

=head2 get_tx_by_txid( $txid )

    my $txid = 'xxxxxxxxx';
    my $response = get_tx_by_txid($txid);
    if ($response->{status} != 200) {
        croak 'cannot get tx by txid:' . $txid . ' status: ' . $response->{status};
    }
    my $data = $response->{data};
    // process tx here.


=head2 search_tx_by_txid( $txid )

    my $txid = 'xxxxxxxxx';
    my $response = search_tx_by_txid($txid);
    if ($response->{status} != 200) {
        croak 'cannot search tx by txid:' . $txid . ' status: ' . $response->{status};
    }
    my $data = $response->{data};
    // process tx list here.

=head2 search_tx_by_address( $address, $min_output_key, $limit )

    my $address = 'xxxxxxxxx';
    my $response = search_tx_by_address($address, '', 100);
    if ($response->{status} != 200) {
        croak 'cannot search tx by address:' . $address . ' status: ' . $response->{status};
    }
    my $data = $response->{data};
    // process tx list here

address: the searched address
min_output_key: the min output key to start with
limit: the batch count for the search.

how to set min_output_key? In the response, we can get outputs:

    my $min_output_key = $data->{minOutputKey};

=head2 search_utxos( $address, $min_output_key, $limit )

    my $address = 'xxxxxxxxx';
    my $response = search_utxos($address, '', 100);
    if ($response->{status} != 200) {
        croak 'cannot search utxos by address:' . $address . ' status: ' . $response->{status};
    }
    my $data = $response->{data};
    // process utxos here.

address: the searched address
min_output_key: the min output key to start with
limit: the batch count for the search.

how to set min_output_key? In the response,  we can get outputs:

    my $outputs = $data->{outputs};
    my $output = $outputs->[@{$outputs} - 1];
    $min_output_key = $output->{txIdStr} . ':' . $output->{idx};

=head1 SEE ALSO

See L<Circle::Common> for circle common module.

See L<Circle::Wallet> for circle wallet module.

See L<Circle::User> for circle user module.

=head1 COPYRIGHT AND LICENSE

Copyright 2024-2030 Charles li

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


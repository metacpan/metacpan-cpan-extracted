package App::cryp::Exchange::gdax;

our $DATE = '2018-06-24'; # DATE
our $VERSION = '0.010'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use POSIX qw(floor);

use Role::Tiny::With;
with 'App::cryp::Role::Exchange';

sub __parse_time {
    state $parser = do {
        require DateTime::Format::ISO8601;
        DateTime::Format::ISO8601->new;
    };
    my $dt = $parser->parse_datetime($_[0]);
    return undef unless $dt;
    $dt->epoch;
}

sub new {
    require Finance::GDAX::Lite;

    my ($class, %args) = @_;

    unless ($args{public_only}) {
        die "Please supply api_key, api_secret, api_passphrase"
            unless $args{api_key} && $args{api_secret}
            && defined $args{api_passphrase};
    }

    $args{_client} = Finance::GDAX::Lite->new(
        key => $args{api_key},
        secret => $args{api_secret},
        passphrase => $args{api_passphrase},
    );

    bless \%args, $class;
}

sub cancel_order {
    my ($self, %args) = @_;

    my $type = $args{type} or return [400, "Please specify type (buy/sell)"];
    my $pair = $args{pair} or return [400, "Please specify pair"];
    my ($basecur, $quotecur) = $pair =~ m!(.+)/(.+)!;
    my $order_id = $args{order_id} or return [400, "Please specify order_id"];

    my $apires = $self->{_client}->private_request(DELETE => "/orders/$order_id");
    return $apires unless $apires->[0] == 200;

    [200, "OK"];
}

my $cache_list_pairs;
sub create_limit_order {
    my ($self, %args) = @_;

    my $type = $args{type} or return [400, "Please specify type (buy/sell)"];
    my $cpair = $args{pair} or return [400, "Please specify pair"];
    my ($basecur, $quotecur) = $cpair =~ m!(.+)/(.+)!;
    my $price = $args{price} or return [400, "Please specify price"];

    my %api_args = (
        type => 'limit',
        side => $args{type},
        product_id => $self->to_native_pair($cpair),
    );

    # round down price according to quote_increment
  HANDLE_OVERPRECISE_PRICE:
    {
        unless ($cache_list_pairs) {
            my $res = $self->list_pairs(detail=>1);
            return [412, "Can't list_pairs(): $res->[0] - $res->[1]"]
                unless $res->[0] == 200;
            $cache_list_pairs = $res;
        }
        my $quote_increment;
        for my $product (@{ $cache_list_pairs->[2] }) {
            if ($product->{name} eq $cpair) {
                $quote_increment = $product->{quote_increment};
                last;
            }
        }
        $quote_increment //= $quotecur eq 'BTC' ? "0.00001" : "0.01";
        #log_trace "quote_increment: %s", $quote_increment;

        $price = floor($price/$quote_increment) * $quote_increment;
    }
    $api_args{price} = $price;

  SPECIFY_SIZE:
    {
        my $size;
        if (defined $args{base_size} && !(defined $args{quote_size})) {
            $size = $args{base_size};
        } elsif (!defined($args{base_size}) && defined $args{quote_size}) {
            $size = $args{quote_size} / $price;
        } else {
            return [400, "Please specify either base_size or quote_size"];
        }

        # handle overprecise size
        $size = floor($size / 0.00000001) * 0.00000001;
        $api_args{size} = $size;
    }

    my $apires = $self->{_client}->private_request(POST => "/orders", \%api_args);
    return $apires unless $apires->[0] == 200;

    my $info = {
        type => $type,
        pair => $cpair,
        order_id => $apires->[2]{id},
        price => $apires->[2]{price},
        base_size => $apires->[2]{size},
        quote_size => $apires->[2]{size} * $apires->[2]{price},
        status => $apires->[2]{status},
    };

    [200, "OK", $info];
}

sub data_canonical_currencies {
    state $data = {};
    $data;
}

sub data_native_pair_is_uppercase { 1 }

sub data_native_pair_separator { '-' }

sub data_reverse_canonical_currencies {
    state $data = {};
    $data;
}

sub get_order {
    my ($self, %args) = @_;

    my $type = $args{type} or return [400, "Please specify type (buy/sell)"];
    my $cpair = $args{pair} or return [400, "Please specify pair"];
    my $order_id = $args{order_id} or return [400, "Please specify order_id"];

    my $apires = $self->{_client}->private_request(GET => "/orders/$order_id");
    return $apires unless $apires->[0] == 200;

    my $info = {
        type => $type,
        pair => $cpair,
        order_id => $order_id,
        price => $apires->[2]{price},
        create_time => __parse_time($apires->[2]{created_at}),
        status => $apires->[2]{status},
        base_size => $apires->[2]{size},
        quote_size => $apires->[2]{size} * $apires->[2]{price},
        filled_base_size => $apires->[2]{filled_size},
        filled_quote_size => $apires->[2]{filled_size} * $apires->[2]{price},
    };

    [200, "OK", $info];
}

sub get_order_book {
    my ($self, %args) = @_;

    $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($args{pair});

    my $apires = $self->{_client}->public_request(GET => "/products/$npair/book?level=2");
    return $apires unless $apires->[0] == 200;

    $apires->[2]{buy}  = delete $apires->[2]{bids};
    $apires->[2]{sell} = delete $apires->[2]{asks};

    # remove the num-orders part
    for (@{ $apires->[2]{buy} }, @{ $apires->[2]{sell} }) {
        splice @$_, 2;
    }

    [200, "OK", $apires->[2]];
}

sub get_ticker {
    my ($self, %args) = @_;

    $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($args{pair});

    my $ticker = {};

    my $apires;

    $apires = $self->{_client}->public_request(GET => "/products/$npair/stats");
    return [$apires->[0], "Failed getting product ticker: $apires->[1]"]
        unless $apires->[0] == 200;
    # required information
    $ticker->{high}   = $apires->[2]{high};
    $ticker->{low}    = $apires->[2]{low};
    $ticker->{volume} = $apires->[2]{volume};

    # optional information
    $ticker->{open}   = $apires->[2]{open};

    $apires = $self->{_client}->public_request(GET => "/products/$npair/ticker");
    return [$apires->[0], "Failed getting product ticker: $apires->[1]"]
        unless $apires->[0] == 200;
    # required information
    $ticker->{last}   = $apires->[2]{price};
    $ticker->{buy}    = $apires->[2]{bid};
    $ticker->{sell}   = $apires->[2]{ask};

    [200, "OK", $ticker];
}

sub list_balances {
    my ($self, %args) = @_;

    my $apires = $self->{_client}->private_request(GET => "/accounts");
    return $apires unless $apires->[0] == 200;

    my @res;
    for (@{ $apires->[2] }) {
        my $rec = {
            currency  => $self->to_canonical_currency($_->{currency}),
            available => $_->{available},
            hold      => $_->{hold},
            total     => $_->{balance},
        };
        push @res, $rec;
    }

    [200, "OK", \@res];
}

sub list_open_orders {
    my ($self, %args) = @_;

    my $cpair = $args{pair};
    my $npair; $npair = $self->to_native_pair($cpair) if $cpair;

    my $apires = $self->{_client}->private_request(GET => "/orders".($npair ? "?product_id=$npair" : ""));
    return $apires unless $apires->[0] == 200;

    my @orders;

    for my $order0 (@{ $apires->[2] }) {
        my $order = {
            type => $order0->{side},
            pair => $self->to_canonical_pair($order0->{product_id}),
            order_id => $order0->{id},
            price => $order0->{price},
            create_time => __parse_time($order0->{created_at}),
            status => $order0->{status},
            base_size => $order0->{size},
            quote_size => $order0->{size} * $order0->{price},
            filled_base_size => $order0->{filled_size},
            filled_quote_size => $order0->{filled_size} * $order0->{price},
        };
        push @orders, $order;
    }
    [200, "OK", \@orders];
}

sub list_pairs {
    my ($self, %args) = @_;

    my $apires = $self->{_client}->public_request(GET => "/products");
    return $apires unless $apires->[0] == 200;

    my @res;
    for (@{ $apires->[2] }) {
        my $cpair = $self->to_canonical_pair($_->{id});
        my $rec = {
            name            => $cpair,
            base_currency   => $_->{base_currency},
            quote_currency  => $_->{quote_currency},
            min_base_size   => $_->{base_min_size},
            quote_increment => $_->{quote_increment},

            status          => $_->{status}, # online,
        };

        if ($args{native}) {
            $rec->{name} = $self->to_native_pair($rec->{name});
            $rec->{base_currency}  = $self->to_native_pair($rec->{base_currency});
            $rec->{quote_currency} = $self->to_native_pair($rec->{quote_currency});
        }

        push @res, $rec;
    }

    unless ($args{detail}) {
        @res = map { $_->{name} } @res;
    }

    [200, "OK", \@res];
}

1;
# ABSTRACT: Interact with GDAX

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Exchange::gdax - Interact with GDAX

=head1 VERSION

This document describes version 0.010 of App::cryp::Exchange::gdax (from Perl distribution App-cryp-exchange), released on 2018-06-24.

=for Pod::Coverage ^(.+)$

=head1 DRIVER-SPECIFIC NOTES

C<get_ticker()> is implemented by calling 2 separate API's,
/products/<product-id>/stats (for C<open>/C<high>/C<low>/C<volume> information)
and /products/<product-id>/ticker (for C<last>/C<buy>/C<sell> information).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-exchange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-exchange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-exchange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

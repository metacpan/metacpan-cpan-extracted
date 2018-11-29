package App::cryp::Exchange::indodax;

our $DATE = '2018-11-29'; # DATE
our $VERSION = '0.011'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use POSIX qw(floor);

use Role::Tiny::With;
with 'App::cryp::Role::Exchange';

sub new {
    require Finance::Indodax;

    my ($class, %args) = @_;

    unless ($args{public_only}) {
        die "Please supply api_key and api_secret"
            unless $args{api_key} && $args{api_secret};
    }

    $args{_client} = Finance::Indodax->new(
        key => $args{api_key},
        secret => $args{api_secret},
    );

    bless \%args, $class;
}

sub cancel_order {
    my ($self, %args) = @_;

    my $type  = $args{type} or return [400, "Please specify type (buy/sell)"];
    my $cpair = $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($cpair);
    my ($nbasecur, $nquotecur) = $npair =~ m!(.+)_(.+)!;
    my $order_id = $args{order_id} or return [400, "Please specify order_id"];

    my $apires;
    eval { $apires = $self->{_client}->cancel_order(
        type=>$type, pair=>$npair, order_id=>$order_id) };
    return [500, "Died: $@"] if $@;

    [200, "OK"];
}

sub create_limit_order {
    my ($self, %args) = @_;

    my $type  = $args{type} or return [400, "Please specify type (buy/sell)"];
    my $cpair = $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($cpair);
    my ($nbasecur, $nquotecur) = $npair =~ m!(.+)_(.+)!;
    my $price = $args{price} or return [400, "Please specify price"];

    my %api_args = (
        type => $args{type},
        pair => $npair,
    );

  HANDLE_OVERPRECISE_PRICE:
    {
        # indodax rounds price if overprecise, but its rounding behavior is not
        # consistent. for example, for BTC/IDR the price is rounded DOWN
        # (truncated) to the nearest 1000 IDR, so 50,123,100 and 50,123,900 both
        # are rounded to 50,123,000. but for XRP/BTC, the price is rounded to
        # the nearest. so 0.000012341 becomes 0.00001234 but 0.000012349 becomes
        # 0.00001235.

        # we fix the behavior as required by the role method: round down.

        my $pairs = $self->data_pairs;
        my $quote_increment;
        for my $pair (@$pairs) {
            if ($pair->{name} eq $cpair) {
                $quote_increment = $pair->{quote_increment};
                last;
            }
        }
        die "BUG: Undefined quote increment for pair $cpair"
            unless $quote_increment;
        #log_trace "quote_increment: %s", $quote_increment;

        $price = floor($price/$quote_increment) * $quote_increment;
    }
    $api_args{price} = $price;

  SPECIFY_SIZE:
    {
        my $size;
        if (defined $args{base_size} && !(defined $args{quote_size})) {
            $size = $type eq 'buy' ?
                $args{base_size} * $price : $args{base_size};
        } elsif (!defined($args{base_size}) && defined $args{quote_size}) {
            $size = $type eq 'buy' ?
                $args{quote_size} : $args{quote_size} / $price;
        } else {
            return [400, "Please specify either base_size or quote_size"];
        }

        # handle overprecise size
        $size = floor($size / 0.00000001) * 0.00000001;
        $api_args{ $type eq 'buy' ? $nquotecur : $nbasecur } = $size;
    }

    my $apires;
    eval { $apires = $self->{_client}->create_order(%api_args) };
    return [500, "Died during create_order(): $@"] if $@;

    my $order_id = $apires->{return}{order_id}
        or return [500, "Something bad happened, didn't get order_id"];

    # the create_order API doesn't return enough information that we want, so we
    # follow with get_order().
    eval { $apires = $self->{_client}->get_order(
        type=>$type, pair=>$npair, order_id=>$order_id) };
    return [500, "Died during get_order(): $@"] if $@;

    $price = $apires->{return}{order}{price};
    my ($base_size, $quote_size);
    if ($type eq 'buy') {
        my $key = "order_" . ($nquotecur eq 'idr' ? 'rp' : $nquotecur);
        $quote_size = $apires->{return}{order}{$key};
        $base_size  = $quote_size / $price;
    } else {
        my $key = "order_" . $nbasecur;
        $base_size  = $apires->{return}{order}{$key};
        $quote_size = $base_size * $price;
    }

    my $info = {
        type => $type,
        pair => $cpair,
        order_id => $order_id,
        price => $price,
        base_size => $base_size,
        quote_size => $quote_size,
        status => $apires->{return}{order}{status},
    };

    [200, "OK", $info];
}

sub data_canonical_currencies {
    state $data = {
        STR => 'XLM',
        DRK => 'DASH',
        NEM => 'XEM',
    };
    $data;
}

sub data_native_pair_is_uppercase { 0 }

sub data_native_pair_separator { '_' }

sub data_pairs {
    state $data = [
        {
            name => 'BTC/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },
        {
            name => 'ACT/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'ADA/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'BCD/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 100,
        },
        {
            name => 'BCH/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },
        {
            name => 'BTG/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },
        {
            name => 'ETH/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },
        {
            name => 'ETC/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },
        {
            name => 'IGNIS/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'LTC/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },
        {
            name => 'NXT/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'STQ/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'TEN/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'TRX/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'WAVES/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 100,
        },
        {
            name => 'XLM/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'XRP/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1,
        },
        {
            name => 'XZC/IDR',
            min_base_size => undef,
            min_quote_size => 50_000,
            quote_increment => 1000,
        },

        {
            name => 'BTS/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },
        {
            name => 'DASH/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.000001", # 100sat
        },
        {
            name => 'DOGE/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },
        {
            name => 'ETH/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.000001", # 100sat
        },
        {
            name => 'LTC/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.000001", # 100sat
        },
        {
            name => 'NXT/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },
        {
            name => 'TEN/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },
        {
            name => 'XEM/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },
        {
            name => 'XLM/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },
        {
            name => 'XRP/BTC',
            min_base_size => undef,
            min_quote_size => 0.001, # BTC
            quote_increment => "0.00000001", # 1sat
        },

    ];
    $data;
}

sub data_reverse_canonical_currencies {
    state $data = {
        XLM  => 'STR',
        DASH => 'DRK',
        XEM  => 'NEM',
    };
    $data;
}

sub get_order {
    my ($self, %args) = @_;

    my $type  = $args{type} or return [400, "Please specify type (buy/sell)"];
    my $cpair = $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($cpair);
    my ($nbasecur, $nquotecur) = $npair =~ m!(.+)_(.+)!;
    my $order_id = $args{order_id} or return [400, "Please specify order_id"];

    my $apires;
    eval { $apires = $self->{_client}->get_order(
        type=>$type, pair=>$npair, order_id=>$order_id) };
    return [500, "Died: $@"] if $@;

    # catch mistake
    $type = $apires->{return}{order}{type};

    my $price = $apires->{return}{order}{price};

    my ($base_size, $quote_size, $filled_base_size, $filled_quote_size);
    if ($type eq 'buy') {
        my $key = "order_" . ($nquotecur eq 'idr' ? 'rp' : $nquotecur);
        $quote_size = $apires->{return}{order}{$key};
        $base_size  = $quote_size / $price;
        my $rkey = "remain_" . ($nquotecur eq 'idr' ? 'rp' : $nquotecur);
        $filled_quote_size = $quote_size - $apires->{return}{order}{$rkey};
        $filled_base_size  = $filled_quote_size / $price;
    } else {
        my $key = "order_" . $nbasecur;
        $base_size = $apires->{return}{order}{$key};
        $quote_size = $base_size * $price;
        my $rkey = "remain_" . $nbasecur;
        $filled_base_size  = $base_size - $apires->{return}{order}{$rkey};
        $filled_quote_size = $filled_base_size * $price;
    }

    my $info = {
        type => $type,
        pair => $cpair,
        order_id => $order_id,
        create_time => $apires->{return}{order}{submit_time},
        price => $price,
        base_size => $base_size,
        quote_size => $quote_size,
        status => $apires->{return}{order}{status},
        filled_base_size => $filled_base_size,
        filled_quote_size => $filled_quote_size,
    };

    [200, "OK", $info];

}

sub get_order_book {
    my ($self, %args) = @_;

    $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($args{pair});

    my $apires;
    eval { $apires = $self->{_client}->get_depth(pair => $npair) };
    return [500, "Died: $@"] if $@;

    [200, "OK", $apires];
}

sub get_ticker {
    my ($self, %args) = @_;

    $args{pair} or return [400, "Please specify pair"];
    my $npair = $self->to_native_pair($args{pair});
    my ($basecur, $quotecur) = split /_/, $npair;

    my $ticker = {};

    my $apires;

    eval { $apires = $self->{_client}->get_ticker(pair=>$npair) };
    return [500, "Died: $@"] if $@;

    # required information
    $ticker->{high}   = $apires->{ticker}{high};
    $ticker->{low}    = $apires->{ticker}{low};
    $ticker->{last}   = $apires->{ticker}{"last"};
    $ticker->{volume} = $apires->{ticker}{"vol_$basecur"};
    $ticker->{buy}    = $apires->{ticker}{buy};
    $ticker->{sell}   = $apires->{ticker}{sell};

    # optional information
    $ticker->{quote_volume} = $apires->{ticker}{"vol_$quotecur"};

    [200, "OK", $ticker];
}

sub list_balances {
    my ($self, %args) = @_;

    my $apires;
    eval { $apires = $self->{_client}->get_info };
    return [500, "Died: $@"] if $@;

    my @recs;
    for my $currency0 (sort keys %{$apires->{return}{balance}}) {
        my $avail = $apires->{return}{balance}{$currency0} // 0;
        my $hold  = $apires->{return}{balance_hold}{$currency0} // 0;
        my $rec = {
            currency  => $self->to_canonical_currency($currency0),
            available => $avail,
            hold      => $hold,
            total     => $avail + $hold,
        };
        push @recs, $rec;
    }

    [200, "OK", \@recs];
}

sub list_open_orders {
    my ($self, %args) = @_;

    my $cpair = $args{pair};
    my $npair_arg; $npair_arg = $self->to_native_pair($cpair) if $cpair;

    my $apires;
    eval { $apires = $self->{_client}->get_open_orders(
        (pair => $npair_arg) x !!$npair_arg) };
    return [500, "Died: $@"] if $@;

    my @orders;

    my $all_orders; # hashref, key=cpair, value=orders
    if ($npair_arg) {
        $all_orders = {$npair_arg => $apires->{return}{orders}};
    } else {
        $all_orders = $apires->{return}{orders};
    }

    for my $npair (sort keys %$all_orders) {
        my $orders0 = $all_orders->{$npair};
        for my $order0 (@$orders0) {
            my ($nbasecur, $nquotecur) = split /_/, $npair;

            my ($base_size, $quote_size, $filled_base_size, $filled_quote_size);
            if ($order0->{type} eq 'buy') {
                my $key = "order_" . $nquotecur;
                $quote_size = $order0->{$key};
                $base_size  = $quote_size / $order0->{price};
                my $rkey = "remain_" . $nquotecur;
                $filled_quote_size = $quote_size - $order0->{$key};
                $filled_base_size  = $filled_quote_size / $order0->{price};
            } else {
                my $key = "order_" . $nbasecur;
                $base_size = $order0->{$key};
                $quote_size = $base_size * $order0->{price};
                my $rkey = "remain_" . $nbasecur;
                $filled_base_size  = $base_size - $order0->{$key};
                $filled_quote_size = $filled_base_size * $order0->{price};
            }

            my $order = {
                type => $order0->{type},
                pair => $self->to_canonical_pair($npair),
                order_id => $order0->{order_id},
                price => $order0->{price},
                create_time => $order0->{submit_time},
                status => "open",
                base_size => $base_size,
                quote_size => $quote_size,
                filled_base_size => $filled_base_size,
                filled_quote_size => $filled_quote_size,
            };
            push @orders, $order;
        }
    }
    [200, "OK", \@orders];
}

sub list_pairs {
    my ($self, %args) = @_;

    my @res;
    for my $rec0 (@{ $self->data_pairs }) {
        my $rec = {%$rec0};
        $rec->{name} =~ m!(.+)/(.+)!;
        $rec->{base_currency} = $1;
        $rec->{quote_currency} = $2;
        if ($args{native}) {
            $rec->{name} = $self->to_native_pair($rec->{name});
            $rec->{base_currency} = $self->to_native_currency($rec->{base_currency});
            $rec->{quote_currency} = $self->to_native_currency($rec->{quote_currency});
        }
        push @res, $rec;
    }

    unless ($args{detail}) {
        @res = map { $_->{name} } @res;
    }

    [200, "OK", \@res];
}

1;
# ABSTRACT: Interact with Indodax

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Exchange::indodax - Interact with Indodax

=head1 VERSION

This document describes version 0.011 of App::cryp::Exchange::indodax (from Perl distribution App-cryp-exchange), released on 2018-11-29.

=for Pod::Coverage ^(.+)$

=head1 DRIVER-SPECIFIC NOTES

C<get_ticker()> doesn't provide the optional C<open>, but provides the optional
C<quote_volume>.

C<list_pairs()> is manually maintained by this driver instead of using an API,
because Indodax does not provide an API to list markets/pairs (let alone a
public one). The closest is C<getInfo()> but that only gives balances of all
available coins and not pairs.

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

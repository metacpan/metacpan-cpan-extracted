package App::cryp::exchange;

our $DATE = '2018-11-29'; # DATE
our $VERSION = '0.011'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my $fnum0 = [number => {precision=>0}];
my $fnum8 = [number => {precision=>8}];

our %arg_req0_account = (
    account => {
        schema => 'cryptoexchange::account*',
        req => 1,
        pos => 0,
    },
);

our %arg_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

our %arg_native = (
    native => {
        schema => 'bool*',
    },
);

our %arg_req3_order_id = (
    order_id => {
        schema => ['str*'],
        req => 1,
        pos => 3,
    },
);

our %arg_1_pair = (
    pair => {
        schema => 'str*',
        pos => 1,
    },
);

our %arg_req1_pair = (
    pair => {
        schema => 'str*',
        # XXX completion
        req => 1,
        pos => 1,
    },
);

our %arg_req3_price = (
    price => {
        schema => ['float*', xmin=>0, 'x.perl.coerce_rules'=>['str_num_en']],
        req => 1,
        pos => 3,
    },
);

our %args_size = (
    base_size => {
        summary => 'Order amount, denominated in base currency (first currency of the pair)',
        schema => ['float*', xmin=>0, 'x.perl.coerce_rules'=>['str_num_en']],
    },
    quote_size => {
        summary => 'Order amount, denominated in quote currency (second currency of the pair)',
        schema => ['float*', xmin=>0, 'x.perl.coerce_rules'=>['str_num_en']],
    },
);

our %arg_type = (
    type => {
        schema => ['str*', in=>['buy','sell']],
        tags => ['category:filtering'],
        cmdline_aliases => {
            buy  => {is_flag=>1, code=>sub {$_[0]{type}='buy' }, summary=>'Alias for --type=buy' },
            sell => {is_flag=>1, code=>sub {$_[0]{type}='sell'}, summary=>'Alias for --type=sell'},
        },
    },
);

our %arg_req2_type = (
    type => {
        schema => ['str*', in=>['buy','sell']],
        req => 1,
        pos => 2,
        cmdline_aliases => {
            buy  => {is_flag=>1, code=>sub {$_[0]{type}='buy' }, summary=>'Alias for --type=buy' },
            sell => {is_flag=>1, code=>sub {$_[0]{type}='sell'}, summary=>'Alias for --type=sell'},
        },
    },
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Interact with cryptoexchanges using a common interface',
};

sub _init {
    my ($r) = @_;

  INSTANTIATE_EXCHANGE_CLIENT:
    {
        last unless $r->{args}{account};
        my ($exchange, $account) = $r->{args}{account} =~ m!(.+)/(.+)!
            or return [
                400, "Invalid cryptoexchange account syntax ".
                    "'$r->{args}{account}', please use EXCHANGE/ACCOUNT ".
                    "format"];
        my $mod = "App::cryp::Exchange::$exchange"; $mod =~ s/-/_/g;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g; require $mod_pm;

        my $hash = $r->{_cryp}{exchanges}{$exchange}{$account};
        my %args;
        if ($hash) {
            %args = map { $_ => $hash->{$_} } grep {/^api_/} keys %$hash;
        } else {
            log_warn "Unknown $exchange account $account, using public API ...";
            %args = (public_only => 1);
        }

        $r->{_stash}{exchange_client} = $mod->new(%args);
    }
    [200];
}

$SPEC{accounts} = {
    v => 1.1,
    summary => 'List exchange accounts',
    args => {
        # XXX filter by exchange (-I, -X)
        %arg_detail,
    },
    tags => ['category:etc'],
};
sub accounts {
    my %args = @_;

    my $crypconf = $args{-cmdline_r}{_cryp};

    my @res;
    for my $safename (sort keys %{$crypconf->{exchanges}}) {
        my $c = $crypconf->{exchanges}{$safename};

        for my $account (sort keys %$c) {
            push @res, {
                exchange => $safename,
                account  => $account,
            };
        }
    }

    unless ($args{detail}) {
        @res = map { "$_->{exchange}/$_->{account}" } @res;
    }

    my $resmeta = {
        'table.fields' => [qw/exchange account/],
    };

    [200, "OK", \@res, $resmeta];
}

$SPEC{balance} = {
    v => 1.1,
    summary => 'List account balance',
    args => {
        %arg_req0_account,
    },
};
sub balance {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $res = $xchg->list_balances;

    $res->[3] //= {};
    my $resmeta = $res->[3];
    $resmeta->{'table.fields'}        = ['currency', 'available', 'hold',  'total'];
    $resmeta->{'table.field_formats'} = [undef,      $fnum8 ,     $fnum8,  $fnum8];
    $resmeta->{'table.field_aligns'}  = ['left',     'right',     'right', 'right'];

    $res;
}

$SPEC{cancel_order} = {
    v => 1.1,
    summary => 'Cancel an order',
    args => {
        %arg_req0_account,
        %arg_req1_pair,
        %arg_req2_type,
        %arg_req3_order_id,
    },
};
sub cancel_order {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $xchg->cancel_order(%args);
}

$SPEC{create_limit_order} = {
    v => 1.1,
    summary => 'Create a limit order',
    args => {
        %arg_req0_account,
        %arg_req1_pair,
        %arg_req2_type,
        %arg_req3_price,
        %args_size,
    },
    args_rels => {
        req_one => [qw/base_size quote_size/],
    },
};
sub create_limit_order {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $xchg->create_limit_order(%args);
}

$SPEC{exchanges} = {
    v => 1.1,
    summary => 'List supported exchanges',
    args => {
        %arg_detail,
    },
    tags => ['category:etc'],
};
sub exchanges {
    require PERLANCAR::Module::List;

    my %args = @_;

    my $mods = PERLANCAR::Module::List::list_modules(
        "App::cryp::Exchange::", {list_modules=>1});

    my @res;
    for my $mod (sort keys %$mods) {
        my ($safename) = $mod =~ /::(\w+)\z/;
        $safename =~ s/_/-/g;
        push @res, {
            safename => $safename,
        };
    }

    unless ($args{detail}) {
        @res = map {$_->{safename}} @res;
    }

    my $resmeta = {
    };

    [200, "OK", \@res, $resmeta];
}

$SPEC{get_order} = {
    v => 1.1,
    summary => 'Get information about an order',
    args => {
        %arg_req0_account,
        %arg_req1_pair,
        %arg_req2_type,
        %arg_req3_order_id,
    },
};
sub get_order {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $xchg->get_order(%args);
}

$SPEC{open_orders} = {
    v => 1.1,
    summary => "List open orders",
    args => {
        %arg_req0_account,
        %arg_1_pair,
    },
};
sub open_orders {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $res = $xchg->list_open_orders(%args);

    $res->[3] //= {};
    my $resmeta = $res->[3];
    $resmeta->{'table.fields'}        = ['pair', 'type', 'order_id', 'create_time',      'price', 'base_size', 'quote_size', 'status', 'filled_base_size', 'filled_quote_size'];
    $resmeta->{'table.field_formats'} = [undef,  undef,  undef,      'iso8601_datetime', $fnum8 , $fnum8,      $fnum8,       undef,    $fnum8,             $fnum8];
    $resmeta->{'table.field_aligns'}  = ['left', 'left', 'left',     'left',             'right', 'right',     'right',      'left',   'right',            'right'];

    $res;
}

$SPEC{orderbook} = {
    v => 1.1,
    summary => 'Get order book on an exchange',
    args => {
        %arg_req0_account,
        %arg_req1_pair,
        %arg_type,
    },
};
sub orderbook {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $res = $xchg->get_order_book(
        pair => $args{pair},
    );
    return $res unless $res->[0] == 200;

    # display in a 2d table format which is more user-friendly for cli user
    my @rows;
    {
        last if $args{type} && $args{type} ne 'buy';
        for my $rec (@{ $res->[2]{buy} }) {
            push @rows, {
                type   => "buy",
                price  => $rec->[0],
                amount => $rec->[1],
            };
        }
    }

    {
        last if $args{type} && $args{type} ne 'sell';
        for my $rec (@{ $res->[2]{sell} }) {
            push @rows, {
                type   => "sell",
                price  => $rec->[0],
                amount => $rec->[1],
            };
        }
    }

    my $resmeta = {};
    $resmeta->{'table.fields'}        = ['type', 'price', 'amount'];
    $resmeta->{'table.field_formats'} = [undef,  $fnum8,  $fnum8];
    $resmeta->{'table.field_aligns'}  = ['left', 'right', 'right'];

    [200, "OK", \@rows, $resmeta];
}

$SPEC{pairs} = {
    v => 1.1,
    summary => 'List pairs supported by exchange',
    args => {
        %arg_req0_account,
        %arg_detail,
        %arg_native,
    },
};
sub pairs {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $res = $xchg->list_pairs(
        detail => $args{detail},
        native => $args{native},
    );

    if ($args{detail}) {
        $res->[3] //= {};
        my $resmeta = $res->[3];
        $resmeta->{'table.fields'}        = ['name', 'base_currency', 'quote_currency', 'min_base_size', 'min_quote_size', 'quote_increment', 'status'];
        $resmeta->{'table.field_formats'} = [undef,  undef,           undef,            undef,           undef,            undef,             undef];
        $resmeta->{'table.field_aligns'}  = ['left', 'left',          'left',           'number',        'number',         'number',          'left'];
    }

    $res;
}

$SPEC{ticker} = {
    v => 1.1,
    summary => "Get a pair's ticker (last 24h price & volume information)",
    args => {
        %arg_req0_account,
        %arg_req1_pair,
    },
};
sub ticker {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $res = _init($r); return $res unless $res->[0] == 200;
    my $xchg = $r->{_stash}{exchange_client};

    $xchg->get_ticker(%args);
}

1;
# ABSTRACT: Interact with cryptoexchanges using a common interface

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::exchange - Interact with cryptoexchanges using a common interface

=head1 VERSION

This document describes version 0.011 of App::cryp::exchange (from Perl distribution App-cryp-exchange), released on 2018-11-29.

=head1 SYNOPSIS

Please see included script L<cryp-exchange>.

=head1 FUNCTIONS


=head2 accounts

Usage:

 accounts(%args) -> [status, msg, payload, meta]

List exchange accounts.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 balance

Usage:

 balance(%args) -> [status, msg, payload, meta]

List account balance.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 cancel_order

Usage:

 cancel_order(%args) -> [status, msg, payload, meta]

Cancel an order.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<order_id>* => I<str>

=item * B<pair>* => I<str>

=item * B<type>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 create_limit_order

Usage:

 create_limit_order(%args) -> [status, msg, payload, meta]

Create a limit order.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<base_size> => I<float>

Order amount, denominated in base currency (first currency of the pair).

=item * B<pair>* => I<str>

=item * B<price>* => I<float>

=item * B<quote_size> => I<float>

Order amount, denominated in quote currency (second currency of the pair).

=item * B<type>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 exchanges

Usage:

 exchanges(%args) -> [status, msg, payload, meta]

List supported exchanges.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_order

Usage:

 get_order(%args) -> [status, msg, payload, meta]

Get information about an order.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<order_id>* => I<str>

=item * B<pair>* => I<str>

=item * B<type>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 open_orders

Usage:

 open_orders(%args) -> [status, msg, payload, meta]

List open orders.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<pair> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 orderbook

Usage:

 orderbook(%args) -> [status, msg, payload, meta]

Get order book on an exchange.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<pair>* => I<str>

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pairs

Usage:

 pairs(%args) -> [status, msg, payload, meta]

List pairs supported by exchange.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<detail> => I<bool>

=item * B<native> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 ticker

Usage:

 ticker(%args) -> [status, msg, payload, meta]

Get a pair's ticker (last 24h price & volume information).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<account>* => I<cryptoexchange::account>

=item * B<pair>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-exchange>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-exchange>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-exchange>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<App::cryp::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

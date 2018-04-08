package App::cryp::exchange;

our $DATE = '2018-04-04'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our $_complete_exchange = sub {
    require Complete::Util;

    my %args = @_;

    my $mods = PERLANCAR::Module::List::list_modules(
        "App::cryp::Exchange::", {list_modules=>1});

    my @safenames;
    for (sort keys %$mods) {
        s/.+:://;
        s/_/-/g;
        push @safenames, $_;
    }

    Complete::Util::complete_array_elem(
        word  => $args{word},
        array => \@safenames,
    );
};

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

our %arg_req0_exchange = (
    exchange => {
        schema => 'str*',
        completion => $_complete_exchange,
        req => 1,
        pos => 0,
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

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Interact with cryptoexchanges',
};

sub _instantiate_exchange {
    my ($r, $exchange, $account) = @_;

    my $mod = "App::cryp::Exchange::$exchange"; $mod =~ s/-/_/g;
    (my $mod_pm = "$mod.pm") =~ s!::!/!g; require $mod_pm;

    my $crypconf = $r->{_cryp};

    my %args = (
    );

    my $accounts = $crypconf->{exchanges}{$exchange} // {};
    for my $a (sort keys %$accounts) {
        if (!defined($account) || $account eq $a) {
            for (grep {/^api_/} keys %{ $accounts->{$a} }) {
                $args{$_} = $accounts->{$a}{$_};
            }
            last;
        }
    }
    $mod->new(%args);
}

$SPEC{list_exchanges} = {
    v => 1.1,
    summary => 'List supported exchanges',
    args => {
        %arg_detail,
    },
};
sub list_exchanges {
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

$SPEC{list_accounts} = {
    v => 1.1,
    summary => 'List exchange accounts',
    args => {
        # XXX filter by exchnage (-I, -X)
        %arg_detail,
    },
};
sub list_accounts {
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

$SPEC{list_pairs} = {
    v => 1.1,
    summary => 'List pairs supported by exchange',
    args => {
        %arg_req0_exchange,
        %arg_detail,
        %arg_native,
    },
};
sub list_pairs {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $xchg = _instantiate_exchange($r, $args{exchange});

    $xchg->list_pairs(
        detail => $args{detail},
        native => $args{native},
    );
}

$SPEC{get_order_book} = {
    v => 1.1,
    summary => 'Get order book on an exchange',
    args => {
        %arg_req0_exchange,
        %arg_req1_pair,
        %arg_type,
    },
};
sub get_order_book {
    my %args = @_;

    my $r = $args{-cmdline_r};

    my $xchg = _instantiate_exchange($r, $args{exchange});

    $xchg->get_order_book(
        pair => $args{pair},
        type => $args{type},
    );
}


1;
# ABSTRACT: Interact with cryptoexchanges

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::exchange - Interact with cryptoexchanges

=head1 VERSION

This document describes version 0.001 of App::cryp::exchange (from Perl distribution App-cryp-exchange), released on 2018-04-04.

=head1 SYNOPSIS

Please see included script L<cryp-exchange>.

=head1 FUNCTIONS


=head2 get_order_book

Usage:

 get_order_book(%args) -> [status, msg, result, meta]

Get order book on an exchange.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exchange>* => I<str>

=item * B<pair>* => I<str>

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_accounts

Usage:

 list_accounts(%args) -> [status, msg, result, meta]

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_exchanges

Usage:

 list_exchanges(%args) -> [status, msg, result, meta]

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
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_pairs

Usage:

 list_pairs(%args) -> [status, msg, result, meta]

List pairs supported by exchange.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<exchange>* => I<str>

=item * B<native> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
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

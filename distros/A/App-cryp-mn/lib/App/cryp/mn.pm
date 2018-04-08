package App::cryp::mn;

our $DATE = '2018-04-06'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %arg_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

our %args_filter_coins = (
    include_coins => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'include_coin',
        schema => ['array*', of=>'cryptocurrency::code*'],
        cmdline_aliases => {I=>{}},
        tags => ['category:filtering'],
    },
    exclude_coins => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'include_coin',
        schema => ['array*', of=>'cryptocurrency::code*'],
        cmdline_aliases => {X=>{}},
        tags => ['category:filtering'],
    },
);

sub _filter_coin {
    my ($code, $args) = @_;

    if ($args->{include_coins}) {
        return 0 unless grep {$code eq $_} @{$args->{include_coins}};
    }
    if ($args->{exclude_coins}) {
        return 0 if grep {$code eq $_} @{$args->{include_coins}};
    }
    1;
}

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Manage your masternodes',
};

$SPEC{list_coins} = {
    v => 1.1,
    summary => 'List supported coins',
    args => {
        %arg_detail,
    },
};
sub list_coins {
    require CryptoCurrency::Catalog;
    require PERLANCAR::Module::List;

    my %args = @_;

    my $cat = CryptoCurrency::Catalog->new;

    my $mods = PERLANCAR::Module::List::list_modules(
        "App::cryp::Masternode::", {list_modules=>1});

    my @res;
    for my $mod (sort keys %$mods) {
        my ($safename) = $mod =~ /::(\w+)\z/;
        $safename =~ s/_/-/g;
        my $coin = $cat->by_safename($safename);
        push @res, {
            code => $coin->{code},
            safename => $coin->{safename},
        };
    }

    unless ($args{detail}) {
        @res = map { $_->{code} } @res;
    }

    my $resmeta = {};
    $resmeta->{'table.fields'} = [qw/code safename/] if $args{detail};

    [200, "OK", \@res, $resmeta];
}

$SPEC{list_masternodes} = {
    v => 1.1,
    summary => 'List your masternodes',
    args => {
        %arg_detail,
        %args_filter_coins,
        with_status => {
            schema => 'bool*',
            cmdline_aliases => {s=>{}},
        },
    },
};
sub list_masternodes {
    my %args = @_;

    #use DDC; dd \%args;

    my $res = list_coins(detail=>1);

    my @res;
    for my $coin (@{$res->[2]}) {
        log_trace "Listing masternodes for $coin->{code} ...";
        unless (_filter_coin($coin->{code}, \%args)) {
            log_trace "Skipping coin $coin->{code} (excluded)";
            next;
        }

        (my $mod = "App::cryp::Masternode::$coin->{safename}") =~ s/-/_/g;
        (my $mod_pm = "$mod.pm") =~ s!::!/!g; require $mod_pm;
        my $drv = $mod->new;
        my $res = $drv->list_masternodes(
            -cmdline_r => $args{-cmdline_r},
            detail => $args{detail} // 0,
            with_status => $args{with_status} // 0,
        );
        unless ($res->[0] == 200) {
            log_error "Couldn't list masternodes for %s: %s, skipped",
                $coin->{code}, $res;
            next;
        }
        for my $rec0 (@{$res->[2]}) {
            my $rec = {
                coin => $coin->{code},
            };
            if ($args{detail}) {
                $rec->{$_} = $rec0->{$_} for keys %$rec0;
            } else {
                $rec->{name} = $rec0;
            }
            push @res, $rec;
        }
    }

    my $resmeta = {
        'table.fields'        => [qw/coin name ip port collateral_txid collateral_oidx status active_time last_seen/],
        'table.field_formats' => [undef, undef, undef, undef, undef, undef, undef, undef, 'iso8601_datetime'],
    };

    [200, "OK", \@res, $resmeta];
}

1;
# ABSTRACT: Manage your masternodes

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::mn - Manage your masternodes

=head1 VERSION

This document describes version 0.003 of App::cryp::mn (from Perl distribution App-cryp-mn), released on 2018-04-06.

=head1 SYNOPSIS

Please see included script L<cryp-mn>.

=head1 FUNCTIONS


=head2 list_coins

Usage:

 list_coins(%args) -> [status, msg, result, meta]

List supported coins.

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


=head2 list_masternodes

Usage:

 list_masternodes(%args) -> [status, msg, result, meta]

List your masternodes.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<exclude_coins> => I<array[cryptocurrency::code]>

=item * B<include_coins> => I<array[cryptocurrency::code]>

=item * B<with_status> => I<bool>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-cryp-mn>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cryp-mn>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cryp-mn>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::cryp> and other C<App::cryp::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

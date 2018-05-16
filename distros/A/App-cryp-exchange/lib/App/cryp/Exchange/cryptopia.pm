package App::cryp::Exchange::cryptopia;

our $DATE = '2018-05-10'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Log4perl;

use Role::Tiny::With;
with 'App::cryp::Role::Exchange';

sub new {
    require WebService::Cryptopia;

    my $log4perl_conf = <<'_';
log4perl.logger = TRACE, LogGer1
log4perl.appender.LogGer1 = Log::Log4perl::Appender::LogGer
log4perl.appender.LogGer1.layout = Log::Log4perl::Layout::SimpleLayout
_
    Log::Log4perl::init(\$log4perl_conf);

    my ($class, %args) = @_;

    die "Please supply api_key, api_secret"
        unless $args{api_key} && $args{api_secret};

    $args{_client} = WebService::Cryptopia->new(
        api_key    => $args{api_key},
        api_secret => $args{api_secret},
    );

    bless \%args, $class;
}

sub data_native_pair_separator { '/' }

sub data_canonical_currencies {
    # XXX
    state $data = {};
    $data;
}

sub data_reverse_canonical_currencies {
    state $data = {};
    $data;
}

sub list_pairs {
    my ($self, %args) = @_;

    my $res;
    eval { $res = $self->{_client}->api_public(method => 'GetTradePairs') };
    return [500, "Died: $@"] if $@;

    my @res;
    for (@$res) {
        my $pair;
        if ($args{native}) {
            $pair = $self->to_native_pair($_->{Label});
        } else {
            $pair = $self->to_canonical_pair($_->{Label});
        }
        push @res, {
            pair            => $pair,
            status          => $_->{Status}, # OK, Closing, Paused,
            status_detail   => $_->{StatusMessage},
            trade_fee       => $_->{TradeFee}, # in percent
            _id             => $_->{Id}, # e.g. 104 for LTC/BTC
        };
    }

    unless ($args{detail}) {
        @res = map { $_->{pair} } @res;
    }

    [200, "OK", \@res];
}

sub get_order_book {
    my ($self, %args) = @_;

    my $pair = $self->to_native_pair($args{pair});

    $pair =~ s!/!_!;

    my $res;
    eval { $res = $self->{_client}->api_public(
        method => "GetMarketOrders",
        parameters => [$pair],
    ) };
    return [500, "Died: $@"] if $@;

    $res->{buy}  = delete $res->{Buy};
    $res->{sell} = delete $res->{Sell};

    for (@{ $res->{buy} }, @{ $res->{sell} }) {
        $_ = [
            $_->{Price},
            $_->{Volume},
        ];
    }

    [200, "OK", $res];
}

1;
# ABSTRACT: Interact with Cryptopia

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cryp::Exchange::cryptopia - Interact with Cryptopia

=head1 VERSION

This document describes version 0.003 of App::cryp::Exchange::cryptopia (from Perl distribution App-cryp-exchange), released on 2018-05-10.

=for Pod::Coverage ^(.+)$

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

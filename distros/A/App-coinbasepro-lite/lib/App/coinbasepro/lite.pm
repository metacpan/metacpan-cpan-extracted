package App::coinbasepro::lite;

our $DATE = '2018-11-29'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my %args_common = (
    endpoint => {
        schema => 'str*', # XXX uri
        req => 1,
        pos => 0,
    },
    args => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'arg',
        schema => ['hash*', of=>'str'],
        pos => 1,
        greedy => 1,
    },
    method => {
        schema => 'str*',
        default => 'GET',
    },
);

my %args_credentials = (
    key => {
        schema => ['str*'],
        req => 1,
    },
    secret => {
        schema => ['str*'],
        req => 1,
    },
    passphrase => {
        schema => ['str*'],
        req => 1,
    },
);

my ($clipub, $clipriv);

sub _init {
    require Finance::CoinbasePro::Lite;
    my ($args) = @_;
    $clipub  //= Finance::CoinbasePro::Lite->new();
    $clipriv //= Finance::CoinbasePro::Lite->new(
        key        => $args->{key},
        secret     => $args->{secret},
        passphrase => $args->{passphrase},
    );
}

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Thin CLI for Coinbase Pro API',
    description => <<'_',

This package offers a thin CLI for accessing Coinbase Pro API (public or
private), mainly for debugging/testing.

_
};

$SPEC{public} = {
    v => 1.1,
    summary => 'Perform a public API request',
    args => {
        %args_common,
    },
};
sub public {
    my %args = @_;
    _init(\%args);
    $clipub->public_request(
        $args{method},
        $args{endpoint},
        $args{args},
    );
}

$SPEC{private} = {
    v => 1.1,
    summary => 'Perform a public API request',
    args => {
        %args_credentials,
        %args_common,
    },
};
sub private {
    my %args = @_;
    _init(\%args);
    $clipriv->private_request(
        $args{method},
        $args{endpoint},
        $args{args},
    );
}

1;
# ABSTRACT: Thin CLI for Coinbase Pro API

__END__

=pod

=encoding UTF-8

=head1 NAME

App::coinbasepro::lite - Thin CLI for Coinbase Pro API

=head1 VERSION

This document describes version 0.003 of App::coinbasepro::lite (from Perl distribution App-coinbasepro-lite), released on 2018-11-29.

=head1 SYNOPSIS

Please see included script L<coinbasepro-lite>.

=head1 DESCRIPTION


This package offers a thin CLI for accessing Coinbase Pro API (public or
private), mainly for debugging/testing.

=head1 FUNCTIONS


=head2 private

Usage:

 private(%args) -> [status, msg, payload, meta]

Perform a public API request.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<hash>

=item * B<endpoint>* => I<str>

=item * B<key>* => I<str>

=item * B<method> => I<str> (default: "GET")

=item * B<passphrase>* => I<str>

=item * B<secret>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 public

Usage:

 public(%args) -> [status, msg, payload, meta]

Perform a public API request.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<args> => I<hash>

=item * B<endpoint>* => I<str>

=item * B<method> => I<str> (default: "GET")

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

Please visit the project's homepage at L<https://metacpan.org/release/App-coinbasepro-lite>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-coinbasepro-lite>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-coinbasepro-lite>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::CoinbasePro::Lite>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

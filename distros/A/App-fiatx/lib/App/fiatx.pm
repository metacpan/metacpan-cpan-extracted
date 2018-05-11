package App::fiatx;

our $DATE = '2018-05-10'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %args_db = (
    db_name => {
        schema => 'str*',
        req => 1,
        tags => ['category:database-connection'],
    },
    # XXX db_host
    # XXX db_port
    db_username => {
        schema => 'str*',
        tags => ['category:database-connection'],
    },
    db_password => {
        schema => 'str*',
        tags => ['category:database-connection'],
    },
);

our %args_convert = (
    amount => {
        schema => 'num*',
        default => 1,
    },
    from => {
        schema => 'currency::code*',
        req => 1,
    },
    to => {
        schema => 'currency::code*',
        req => 1,
    },
    type => {
        summary => 'Which rate is wanted? e.g. sell, buy',
        schema => 'str*',
        default => 'sell', # because we want to buy
    },
);

our %args_caching = (
    max_age_cache => {
        summary => 'Above this age (in seconds), '.
            'we retrieve rate from remote source again',
        schema => 'posint*',
        default => 4*3600,
        cmdline_aliases => {
            no_cache => {is_flag=>1, code=>sub {$_[0]{max_age_cache} = 0}, summary=>'Alias for --max-age-cache=0'},
        },
    },
    max_age_current => {
        summary => 'Above this age (in seconds), '.
            'we no longer consider the rate to be "current" but "historical"',
        schema => 'posint*',
        default => 24*3600,
    },
);

sub _connect {
    my $args = shift;

    require DBIx::Connect::MySQL;
    DBIx::Connect::MySQL->connect(
        "dbi:mysql:database=$args->{db_name}",
        $args->{db_username},
        $args->{db_password},
        {RaiseError=>1},
    );
}

sub _supply {
    my ($args, $args_spec) = @_;

    my %res;
    for (keys %$args_spec) {
        if (exists $args->{$_}) {
            $res{$_} = $args->{$_};
        }
    }
    %res;
}

$SPEC{convert} = {
    v => 1.1,
    summary => 'Convert two currencies using current rate',
    args => {
        %args_db,
        %args_caching,
        %args_convert,
    },
};
sub convert {
    require Finance::Currency::FiatX;

    my %args = @_;

    my $dbh = _connect(\%args);

    Finance::Currency::FiatX::convert_fiat_currency(
        dbh => $dbh,

        _supply(\%args, \%args_caching),
        _supply(\%args, \%args_convert),
    );
}

1;
# ABSTRACT: Convert two currencies using current rate

__END__

=pod

=encoding UTF-8

=head1 NAME

App::fiatx - Convert two currencies using current rate

=head1 VERSION

This document describes version 0.002 of App::fiatx (from Perl distribution App-fiatx), released on 2018-05-10.

=head1 SYNOPSIS

See the included script L<fiatx>.

=head1 FUNCTIONS


=head2 convert

Usage:

 convert(%args) -> [status, msg, result, meta]

Convert two currencies using current rate.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<amount> => I<num> (default: 1)

=item * B<db_name>* => I<str>

=item * B<db_password> => I<str>

=item * B<db_username> => I<str>

=item * B<from>* => I<currency::code>

=item * B<max_age_cache> => I<posint> (default: 14400)

Above this age (in seconds), we retrieve rate from remote source again.

=item * B<max_age_current> => I<posint> (default: 86400)

Above this age (in seconds), we no longer consider the rate to be "current" but "historical".

=item * B<to>* => I<currency::code>

=item * B<type> => I<str> (default: "sell")

Which rate is wanted? e.g. sell, buy.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-fiatx>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-fiatx>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-fiatx>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Finance::Currency::FiatX>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

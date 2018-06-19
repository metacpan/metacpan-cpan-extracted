package App::fiatx;

our $DATE = '2018-06-19'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;

use Finance::Currency::FiatX;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Fiat currency exchange rate tool',
};

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

$SPEC{sources} = {
    v => 1.1,
    summary => 'List available sources',
    args => {
    },
};
sub sources {
    require PERLANCAR::Module::List;

    my @res;
    my $mods = PERLANCAR::Module::List::list_modules(
        'Finance::Currency::FiatX::Source::', {list_modules=>1});
    unless (keys %$mods) {
        return [412, "No source modules available"];
    }
    for my $src (sort keys %$mods) {
        $src =~ s/^Finance::Currency::FiatX::Source:://;
        push @res, $src;
    }

    [200, "OK", \@res];
}

$SPEC{spot_rate} = {
    v => 1.1,
    summary => 'Get spot (latest) rate',
    args => {
        %args_db,
        %Finance::Currency::FiatX::args_caching,
        %Finance::Currency::FiatX::args_spot_rate,
    },
};
sub spot_rate {
    my %args = @_;

    my $dbh = _connect(\%args);

    Finance::Currency::FiatX::get_spot_rate(
        dbh => $dbh,

        _supply(\%args, \%Finance::Currency::FiatX::args_caching),
        _supply(\%args, \%Finance::Currency::FiatX::args_spot_rate),
    );
}

$SPEC{all_spot_rates} = {
    v => 1.1,
    summary => 'Get all spot (latest) rates from a source',
    args => {
        %args_db,
        %Finance::Currency::FiatX::args_caching,
        %Finance::Currency::FiatX::arg_req0_source,
    },
};
sub all_spot_rates {
    my %args = @_;

    my $dbh = _connect(\%args);

    Finance::Currency::FiatX::get_all_spot_rates(
        dbh => $dbh,

        _supply(\%args, \%Finance::Currency::FiatX::args_caching),
        _supply(\%args, \%Finance::Currency::FiatX::arg_req0_source),
    );
}

1;
# ABSTRACT: Fiat currency exchange rate tool

__END__

=pod

=encoding UTF-8

=head1 NAME

App::fiatx - Fiat currency exchange rate tool

=head1 VERSION

This document describes version 0.005 of App::fiatx (from Perl distribution App-fiatx), released on 2018-06-19.

=head1 SYNOPSIS

See the included script L<fiatx>.

=head1 FUNCTIONS


=head2 all_spot_rates

Usage:

 all_spot_rates(%args) -> [status, msg, result, meta]

Get all spot (latest) rates from a source.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_name>* => I<str>

=item * B<db_password> => I<str>

=item * B<db_username> => I<str>

=item * B<max_age_cache> => I<posint> (default: 14400)

Above this age (in seconds), we retrieve rate from remote source again.

=item * B<source>* => I<str> (default: ":any")

Ask for a specific remote source.

If you want a specific remote source, you can specify it here. The default is
':any' which is to pick the first source that returns a recent enough current
rate.

Other special values: C<:highest> to return highest rate of all sources,
C<:lowest> to return lowest rate of all sources, ':newest' to return rate from
source with the newest last update time, ':oldest' to return rate from source
with the oldest last update time, ':average' to return arithmetic average of all
sources.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 sources

Usage:

 sources() -> [status, msg, result, meta]

List available sources.

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 spot_rate

Usage:

 spot_rate(%args) -> [status, msg, result, meta]

Get spot (latest) rate.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_name>* => I<str>

=item * B<db_password> => I<str>

=item * B<db_username> => I<str>

=item * B<from>* => I<currency::code>

=item * B<max_age_cache> => I<posint> (default: 14400)

Above this age (in seconds), we retrieve rate from remote source again.

=item * B<source> => I<str> (default: ":any")

Ask for a specific remote source.

If you want a specific remote source, you can specify it here. The default is
':any' which is to pick the first source that returns a recent enough current
rate.

Other special values: C<:highest> to return highest rate of all sources,
C<:lowest> to return lowest rate of all sources, ':newest' to return rate from
source with the newest last update time, ':oldest' to return rate from source
with the oldest last update time, ':average' to return arithmetic average of all
sources.

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

package App::fiatx;

our $DATE = '2018-06-27'; # DATE
our $VERSION = '0.007'; # VERSION

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

our %arg_per_type = (
    per_type => {
        summary => 'Return one row of result per rate type',
        schema => 'bool*',
        description => <<'_',

This allow seeing notes and different mtime per rate type, which can be
different between different types of the same source.

_
    },
);

my $fnum8 = [number => {precision=>8}];

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

my %arg_0_source = (
    source => {
        %{ $Finance::Currency::FiatX::arg_source{source} },
        pos => 0,
        default => ':all',
    },
);

my %arg_1_pair = (
    pair => {
        schema => 'currency::pair*',
        pos => 1,
    },
);

my %arg_2_type = (
    type => {
        %{ $Finance::Currency::FiatX::args_spot_rate{type} },
        pos => 2,
    },
);

$SPEC{spot_rates} = {
    v => 1.1,
    summary => 'Get spot (latest) rate(s) from a source',
    args => {
        %args_db,
        %Finance::Currency::FiatX::args_caching,
        %arg_0_source,
        %arg_1_pair,
        %arg_2_type,
        %arg_per_type,
    },
};
sub spot_rates {
    my %args = @_;

    my $source = $args{source};
    my $pair   = $args{pair};
    my $type   = $args{type};

    my ($from, $to); ($from, $to) = $pair =~ m!(.+)/(.+)! if $pair;

    my $dbh = _connect(\%args);

    my $rows0;

    if ($source ne ':all' && $pair && $type) {
        my $bres = Finance::Currency::FiatX::get_spot_rate(
            dbh => $dbh,
            max_age_cache => $args{max_age_cache},
            source        => $source,
            from          => $from,
            to            => $to,
            type          => $type,
        );
        return $bres unless $bres->[0] == 200 || $bres->[0] == 304;
        $rows0 = [$bres->[2]];
    } else {
        my $bres = Finance::Currency::FiatX::get_all_spot_rates(
            dbh => $dbh,
            max_age_cache => $args{max_age_cache},
            source        => $source,
        );
        return $bres unless $bres->[0] == 200 || $bres->[0] == 304;
        $rows0 = $bres->[2];
    }

    my @rows;
    my $resmeta = {};

    if ($args{per_type}) {
        for (@$rows0) {
            delete $_->{source} unless $source eq ':all';
            push @rows, $_;
        }
        $resmeta->{'table.fields'}        = ['source', 'pair', 'type' , 'rate' , 'note'];
        $resmeta->{'table.field_formats'} = [undef   , undef , undef  , $fnum8 , undef ];
        $resmeta->{'table.field_aligns'}  = ['left'  , 'left', 'right', 'right', 'left'];
        unless ($source eq ':all') {
            shift @{ $resmeta->{'table.fields'} };
            shift @{ $resmeta->{'table.field_formats'} };
            shift @{ $resmeta->{'table.field_aligns'} };
        }
    } else {
        my %sources;
        for my $r (@$rows0) {
            my $src = $r->{source} // '';
            $sources{ $src }++;
        }

        for my $src (sort keys %sources) {
            my %per_pair_rates;
            for my $r (@$rows0) {
                next unless ($r->{source} // '') eq $src;
                $per_pair_rates{ $r->{pair} } //= {
                    pair => $r->{pair},
                    mtime => 0,
                };
                $per_pair_rates{ $r->{pair} }{source} = $src
                    unless $source eq $src;
                next unless $r->{type} =~ /^(buy|sell)/;
                $per_pair_rates{ $r->{pair} }{ $r->{type} } = $r->{rate};
                $per_pair_rates{ $r->{pair} }{mtime} = $r->{mtime}
                    if $per_pair_rates{ $r->{pair} }{mtime} < $r->{mtime};
            }
            for my $pair (sort keys %per_pair_rates) {
                push @rows, $per_pair_rates{$pair};
            }
        }
        $resmeta->{'table.fields'}        = ['source', 'pair', 'buy'  , 'sell' , 'mtime'           ];
        $resmeta->{'table.field_formats'} = [undef   , undef , $fnum8 , $fnum8 , 'iso8601_datetime'];
        $resmeta->{'table.field_aligns'}  = ['left'  , 'left', 'right', 'right', 'left'];
        if ($source =~ /\A\w+\z/) {
            shift @{ $resmeta->{'table.fields'} };
            shift @{ $resmeta->{'table.field_formats'} };
            shift @{ $resmeta->{'table.field_aligns'} };
        }
        $resmeta->{'table.field_align_code'}  = sub { $_[0] =~ /^(buy|sell)/ ? 'right' : undef },
        $resmeta->{'table.field_format_code'} = sub { $_[0] =~ /^(buy|sell)/ ? $fnum8  : undef },
    }

  FILTER_ROWS:
    {
        my @rows_f;
        for (@rows) {
            next if $pair && $_->{pair} ne $pair;
            push @rows_f, $_;
        }
        @rows = @rows_f;
    }

    [200, "OK", \@rows, $resmeta];
}

1;
# ABSTRACT: Fiat currency exchange rate tool

__END__

=pod

=encoding UTF-8

=head1 NAME

App::fiatx - Fiat currency exchange rate tool

=head1 VERSION

This document describes version 0.007 of App::fiatx (from Perl distribution App-fiatx), released on 2018-06-27.

=head1 SYNOPSIS

See the included script L<fiatx>.

=head1 FUNCTIONS


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


=head2 spot_rates

Usage:

 spot_rates(%args) -> [status, msg, result, meta]

Get spot (latest) rate(s) from a source.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_name>* => I<str>

=item * B<db_password> => I<str>

=item * B<db_username> => I<str>

=item * B<max_age_cache> => I<nonnegint> (default: 14400)

Above this age (in seconds), we retrieve rate from remote source again.

=item * B<pair> => I<currency::pair>

=item * B<per_type> => I<bool>

Return one row of result per rate type.

This allow seeing notes and different mtime per rate type, which can be
different between different types of the same source.

=item * B<source> => I<str> (default: ":all")

Ask for a specific remote source.

If you want a specific remote source, you can specify it here. The default is
':any' which is to pick the first source that returns a recent enough current
rate.

Other special values: C<:highest> to return highest rate of all sources,
C<:lowest> to return lowest rate of all sources, ':newest' to return rate from
source with the newest last update time, ':oldest' to return rate from source
with the oldest last update time, ':average' to return arithmetic average of all
sources.

=item * B<type> => I<str>

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

package App::ListNewCPANDists;

our $DATE = '2017-07-02'; # DATE
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

my $sch_date = ['date*', 'x.perl.coerce_to' => 'DateTime'];
my $URL_PREFIX = 'https://fastapi.metacpan.org/v1';

our $db_schema_spec = {
    latest_v => 1,
    install => [
        'CREATE TABLE release (
            name TEXT NOT NULL PRIMARY KEY,
            dist TEXT NOT NULL,
            time INTEGER NOT NULL
        )',
        'CREATE UNIQUE INDEX ix_release__dist ON release(name,dist)',
    ],
};

sub _json_encode {
    require JSON;
    JSON->new->encode($_[0]);
}

sub _json_decode {
    require JSON;
    JSON->new->decode($_[0]);
}

sub _create_schema {
    require SQL::Schema::Versioned;

    my $dbh = shift;

    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $dbh, spec => $db_schema_spec);
    die "Can't create/update schema: $res->[0] - $res->[1]\n"
        unless $res->[0] == 200;
}

sub _db_path {
    my ($cpan, $index_name) = @_;
    "$cpan/$index_name";
}

sub _connect_db {
    require DBI;

    my ($cpan, $index_name) = @_;

    my $db_path = _db_path($cpan, $index_name);
    log_trace("Connecting to SQLite database at %s ...", $db_path);
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db_path", undef, undef,
                           {RaiseError=>1});
    #$dbh->do("PRAGMA cache_size = 400000"); # 400M
    _create_schema($dbh);
    $dbh;
}

sub _set_args_default {
    my $args = shift;
    if (!$args->{cpan}) {
        require File::HomeDir;
        $args->{cpan} = File::HomeDir->my_home . '/cpan';
    }
    $args->{index_name} //= 'index-lncd.db';
}

sub _init {
    my ($args) = @_;

    unless ($App::ListNewCPANDists::state) {
        _set_args_default($args);
        my $state = {
            dbh => _connect_db($args->{cpan}, $args->{index_name}),
            cpan => $args->{cpan},
            index_name => $args->{index_name},
        };
        $App::ListNewCPANDists::state = $state;
    }
    $App::ListNewCPANDists::state;
}

sub _http_tiny {
    state $obj = do {
        require HTTP::Tiny;
        HTTP::Tiny->new;
    };
    $obj;
}

sub _get_dist_first_release {
    require Time::Local;

    my ($state, $dist) = @_;

    # save an API call if we can find a cache in database
    my $dbh = $state->{dbh};
    my ($relinfo) = $dbh->selectrow_hashref(
        "SELECT * FROM release WHERE dist=? ORDER BY time LIMIT 1",
        {},
        $dist,
    );
    return $relinfo if $relinfo;

    my $res = _http_tiny->post("$URL_PREFIX/release/_search?size=1&sort=date", {
        content => _json_encode({
            query => {
                terms => {
                    distribution => [$dist],
                },
            },
            fields => [qw/name date version version_numified/],
        }),
    });

    die "Can't retrieve first release information of distribution '$dist': ".
        "$res->[0] - $res->[1]\n" unless $res->{success};
    my $api_res = _json_decode($res->{content});
    my $hit = $api_res->{hits}{hits}[0];
    die "No release information for distribution '$dist'" unless $hit;
    $hit->{fields}{date} =~ /^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)/
        or die "Can't parse date '$hit->{fields}{date}'";
    my $time = Time::Local::timegm($6, $5, $4, $3, $2-1, $1);
    $relinfo = {
        name => $hit->{fields}{name},
        time => $time,
        dist => $dist,
    };
    # cache to database
    $dbh->do("INSERT INTO release (name,time,dist) VALUES (?,?,?)", {},
             $relinfo->{name}, $relinfo->{time}, $relinfo->{dist},
         );
    $relinfo;
}

$SPEC{list_new_cpan_dists} = {
    v => 1.1,
    summary => 'List new CPAN distributions in a given time period',
    args => {
        from_time => {
            schema => $sch_date,
            req => 1,
            pos => 0,
        },
        to_time   => {
            schema => $sch_date,
            pos => 1,
        },
    },
};
sub list_new_cpan_dists {
    my %args = @_;

    my $state = _init(\%args);
    my $dbh = $state->{dbh};

    my $from_time = $args{from_time};
    my $to_time   = $args{to_time};
    if (!$to_time) {
        $to_time = $from_time->clone;
        $to_time->set_hour(23);
        $to_time->set_minute(59);
        $to_time->set_second(59);
    }
    if ($args{-orig_to_time} && $args{-orig_to_time} !~ /T\d\d:\d\d:\d\d/) {
        $to_time->set_hour(23);
        $to_time->set_minute(59);
        $to_time->set_second(59);
    }

    log_trace("Retrieving releases from %s to %s ...",
              $from_time->datetime, $to_time->datetime);

    # list all releases in the time period and collect unique list of
    # distributions
    my $res = _http_tiny->post("$URL_PREFIX/release/_search?size=5000&sort=name", {
        content => _json_encode({
            query => {
                range => {
                    date => {
                        gte => $from_time->datetime,
                        lte => $to_time->datetime,
                    },
                },
            },
            fields => [qw/name author distribution abstract date version version_numified/],
        }),
    });
    return [$res->{status}, "Can't retrieve releases: $res->{reason}"]
        unless $res->{success};

    my $api_res = _json_decode($res->{content});
    my %dists;
    my @res;
    my $num_hits = @{ $api_res->{hits}{hits} };
    my $i = 0;
    for my $hit (@{ $api_res->{hits}{hits} }) {
        $i++;
        my $dist = $hit->{fields}{distribution};
        next if $dists{ $dist }++;
        log_trace("[#%d/%d] Got distribution %s", $i, $num_hits, $dist);
        # find the first release of this distribution
        my $relinfo = _get_dist_first_release($state, $dist);
        unless ($relinfo->{time} >= $args{from_time}->epoch &&
                    $relinfo->{time} <= $args{to_time}->epoch) {
            log_trace("First release of distribution %s is not in this time period, skipped", $dist);
            next;
        }
        push @res, {
            dist => $dist,
            release => $hit->{fields}{name},
            author => $hit->{fields}{author},
            version => $hit->{fields}{version},
            abstract => $hit->{fields}{abstract},
            date => $hit->{fields}{date},
        };
    }

    my %resmeta = (
        'table.fields' => [qw/dist release author version date abstract/],
    );

    [200, "OK", \@res, \%resmeta];
}

$SPEC{list_monthly_new_cpan_dists} = {
    v => 1.1,
    summary => 'List new CPAN distributions in a given month',
    args => {
        month => {
            schema => ['int*', min=>1, max=>12],
            req => 1,
            pos => 0,
        },
        year => {
            schema => ['int*', min=>1990, max=>9999],
            req => 1,
            pos => 1,
        },
    },
};
sub list_monthly_new_cpan_dists {
    require DateTime;
    require Time::Local;

    my %args = @_;

    my $mon = delete $args{month};
    my $year = delete $args{year};
    my $from_time = Time::Local::timegm(0, 0, 0, 1, $mon-1, $year);
    $mon++; if ($mon == 13) { $mon = 1; $year++ }
    my $to_time = Time::Local::timegm(0, 0, 0, 1, $mon-1, $year) - 1;
    list_new_cpan_dists(
        %args,
        from_time => DateTime->from_epoch(epoch => $from_time),
        to_time   => DateTime->from_epoch(epoch => $to_time),
    );
}

$SPEC{list_monthly_new_cpan_dists_html} = {
    v => 1.1,
    summary => 'List new CPAN distributions in a given month (HTML format)',
    args => {
        month => {
            schema => ['int*', min=>1, max=>12],
            req => 1,
            pos => 0,
        },
        year => {
            schema => ['int*', min=>1990, max=>9999],
            req => 1,
            pos => 1,
        },
    },
};
sub list_monthly_new_cpan_dists_html {
    require HTML::Entities;

    my %args = @_;

    my $res = list_monthly_new_cpan_dists(%args);

    my @html;

    push @html, "<table>\n";

    my $cols = $res->[3]{'table.fields'};
    push @html, "<tr>\n";
    for my $col (@$cols) {
        next if $col eq 'release' || $col eq 'date';
        push @html, "<th>$col</th>\n";
    }
    push @html, "</tr>\n\n";

    {
        no warnings 'uninitialized';
        for my $row (@{ $res->[2] }) {
            push @html, "<tr>\n";
            for my $col (@$cols) {
                next if $col eq 'release' || $col eq 'date';
                my $cell = HTML::Entities::encode_entities($row->{$col});
                if ($col eq 'author') {
                    $cell = qq(<a href="https://metacpan.org/author/$cell">$cell</a>);
                } elsif ($col eq 'dist') {
                    $cell = qq(<a href="https://metacpan.org/release/$row->{author}/$row->{release}">$cell</a>);
                }
                push @html, "<td>$cell</td>\n";
            }
            push @html, "</tr>\n";
        }
        push @html, "</table>\n";
    }

    [200, "OK", join("", @html), {'cmdline.skip_format'=>1}];
}

1;

# ABSTRACT: List new CPAN distributions in a given time period

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ListNewCPANDists - List new CPAN distributions in a given time period

=head1 VERSION

This document describes version 0.005 of App::ListNewCPANDists (from Perl distribution App-ListNewCPANDists), released on 2017-07-02.

=head1 FUNCTIONS


=head2 list_monthly_new_cpan_dists

Usage:

 list_monthly_new_cpan_dists(%args) -> [status, msg, result, meta]

List new CPAN distributions in a given month.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<month>* => I<int>

=item * B<year>* => I<int>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_monthly_new_cpan_dists_html

Usage:

 list_monthly_new_cpan_dists_html(%args) -> [status, msg, result, meta]

List new CPAN distributions in a given month (HTML format).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<month>* => I<int>

=item * B<year>* => I<int>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_new_cpan_dists

Usage:

 list_new_cpan_dists(%args) -> [status, msg, result, meta]

List new CPAN distributions in a given time period.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<from_time>* => I<date>

=item * B<to_time> => I<date>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-ListNewCPANDists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ListNewCPANDists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ListNewCPANDists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

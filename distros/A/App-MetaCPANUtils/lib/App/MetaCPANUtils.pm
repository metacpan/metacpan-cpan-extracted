package App::MetaCPANUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-01'; # DATE
our $DIST = 'App-MetaCPANUtils'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our $release_fields = [
    # name for cli user, source field in API, include by default?
    ['release'     , 'name'        , 1],
    ['date'        , 'date'        , 1],
    ['author'      , 'author'      , 1],
    ['maturity'    , 'maturity'    , 1],
    ['version'     , 'version'     , 1], # main module's $VERSION
    ['first'       , 'first'       , 0], # useless? this field follows version defined in $VERSION so several releases might have first=1 e.g. see releases of XML-API-0.02 to 0.13 where $VERSION is set to 0.02
    ['distribution', 'distribution', 1],
    ['abstract'    , 'abstract'    , 1],

    ['download_url', 'download_url', 0],
];
our %argopt_release_fields = (
    fields => {
        schema => ['array*', of=>['str*', in=>[ map {$_->[0]} @$release_fields ]]],
        default => [ map {$_->[0]} grep {$_->[2]} @$release_fields ],
        cmdline_aliases=>{f=>{}},
        tags => ['category:result'],
    },
);

our %argoptf_author = (
    author => {
        schema => "cpan::pause_id*",
        tags => ['category:filtering'],
    },
);
our %argoptf_distribution = (
    distribution => {
        schema => "cpan::distname*",
        tags => ['category:filtering'],
    },
);
our %argoptf_module = (
    distribution => {
        schema => "cpan::modname*",
        tags => ['category:filtering'],
    },
);
our %argoptf_from_date = (
    from_date => {
        schema => ["date*", "x.perl.coerce_to" => "DateTime"],
        tags => ['category:filtering'],
    },
);
our %argoptf_to_date = (
    to_date => {
        schema => ["date*", "x.perl.coerce_to" => "DateTime"],
        tags => ['category:filtering'],
    },
);

our %argopt_release_sort = (
    sort => {
        schema => ['str*', in=>[qw/release -release date -date/]],
        default => '-date',
    },
);

sub _resultset_to_envres {
    my ($resultset, $wanted_fields) = @_;

    my @rows;
    my $resmeta = {'table.fields' => $wanted_fields};
    while (my $obj = $resultset->next) {
        log_trace("API result: %s", $obj) if $ENV{METACPANUTILS_DUMP_API_RESULT};
        my $row = {};
        if (ref $obj eq 'MetaCPAN::Client::Release') {
            $row->{release}      = $obj->name         if grep {$_ eq 'release'}      @$wanted_fields;
            $row->{date}         = $obj->date         if grep {$_ eq 'date'}         @$wanted_fields;
            $row->{author}       = $obj->author       if grep {$_ eq 'author'}       @$wanted_fields;
            $row->{maturity}     = $obj->maturity     if grep {$_ eq 'maturity'}     @$wanted_fields;
            $row->{version}      = $obj->version      if grep {$_ eq 'version'}      @$wanted_fields;
            $row->{distribution} = $obj->distribution if grep {$_ eq 'distribution'} @$wanted_fields;
            $row->{abstract}     = $obj->abstract     if grep {$_ eq 'abstract'}     @$wanted_fields;
            $row->{first}        = $obj->first        if grep {$_ eq 'first'}        @$wanted_fields;
        } else {
            die "Can't handle result $obj";
        }
        push @rows, $row;
    }
    $resmeta->{'func.num_rows'} = @rows;
    [200, "OK", \@rows, $resmeta];
}

sub _fields_to_source {
    my ($wanted_fields, $fields) = @_;
    my $source = [];
    for my $f (@$fields) {
        if (grep { $_ eq $f->[0] } @$wanted_fields) {
            push @$source, $f->[1];
        }
    }
    $source;
}

$SPEC{list_recent_metacpan_releases} = {
    v => 1.1,
    args => {
        n => {
            schema => 'posint*',
            ## no longer true, will list several days' worth nowadays
#            description => <<'_',
#
#If not specified, will list all releases from today.
#
#_
            pos => 0,
        },
        %argopt_release_fields,
    },
    examples => [
        {
            summary => 'Show 100 latest releases and show their download URLs',
            src => '[[prog]] 100 -f download_url',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_recent_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;
    my $recent = $mcpan->recent($args{n});
    _resultset_to_envres($recent, $args{fields});
}

$SPEC{list_metacpan_releases} = {
    v => 1.1,
    args => {
        %argopt_release_fields,
        %argopt_release_sort,

        %argoptf_author,
        %argoptf_distribution,
        %argoptf_from_date,
        %argoptf_to_date,
    },
    examples => [
        {
            summary => 'Show releases in December 2020',
            src => '[[prog]] --from-date 2020-12-01 --to-date 2020-12-31',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            summary => "Show PERLANCAR's releases, show only their distribution, version, first (whether the release is the first release for the distribution), and download URL",
            src => '[[prog]] --author PERLANCAR -f distribution -f version -f first -f download_url',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub list_metacpan_releases {
    require MetaCPAN::Client;

    my %args = @_;

    my $mcpan = MetaCPAN::Client->new;

    my $query = {all=>[]};
    push @{ $query->{all} }, {author=>$args{author}}             if defined $args{author};
    push @{ $query->{all} }, {distribution=>$args{distribution}} if defined $args{distribution};
    log_trace "MetaCPAN API query: %s", $query;

    my $params = {};
    $params->{_source} = _fields_to_source($args{fields}, $release_fields);
    $params->{es_filter}{range}{date}{from} = $args{from_date}->ymd if defined $args{from_date};
    $params->{es_filter}{range}{date}{to}   = $args{to_date}  ->ymd if defined $args{to_date};
    if (defined $args{sort}) {
        $params->{sort} = [{date=>{order=>'asc'}}]  if $args{sort} eq 'date';
        $params->{sort} = [{date=>{order=>'desc'}}] if $args{sort} eq '-date';
        $params->{sort} = [{name=>{order=>'asc'}}]  if $args{sort} eq 'release';
        $params->{sort} = [{name=>{order=>'desc'}}] if $args{sort} eq '-release';
    }
    log_trace "MetaCPAN API query params: %s", $params;

    my $res = $mcpan->release($query, $params);

    _resultset_to_envres($res, $args{fields});
}


1;
# ABSTRACT: CLI utilities related to MetaCPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

App::MetaCPANUtils - CLI utilities related to MetaCPAN

=head1 VERSION

This document describes version 0.003 of App::MetaCPANUtils (from Perl distribution App-MetaCPANUtils), released on 2020-01-01.

=head1 DESCRIPTION

This distribution contains CLI utilities related to MetaCPAN:

=over

=item * L<list-metacpan-releases>

=item * L<list-recent-metacpan-releases>

=back

=head1 FUNCTIONS


=head2 list_metacpan_releases

Usage:

 list_metacpan_releases(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author> => I<cpan::pause_id>

=item * B<distribution> => I<cpan::distname>

=item * B<fields> => I<array[str]> (default: ["release","date","author","maturity","version","distribution","abstract"])

=item * B<from_date> => I<date>

=item * B<sort> => I<str> (default: "-date")

=item * B<to_date> => I<date>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_recent_metacpan_releases

Usage:

 list_recent_metacpan_releases(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<fields> => I<array[str]> (default: ["release","date","author","maturity","version","distribution","abstract"])

=item * B<n> => I<posint>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 METACPANUTILS_DUMP_API_RESULT

If set to true, will log the API result at the C<trace> level.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-MetaCPANUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-MetaCPANUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-MetaCPANUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://metacpan.org>

Other distributions providing CLIs for MetaCPAN: L<MetaCPAN::Clients>,
L<App::metacpansearch>.

MetaCPAN API Client: L<MetaCPAN::Client>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

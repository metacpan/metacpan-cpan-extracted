package App::CekBpom;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-09-09'; # DATE
our $DIST = 'App-CekBpom'; # DIST
our $VERSION = '0.005'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Exporter qw(import);
our @EXPORT_OK = qw(cek_bpom);

our %SPEC;

my $url_prefix = "https://cekbpom.pom.go.id/index.php";

my %search_types = (
    # name => [number in bpom website's form, shortcut alias if any]
    nomor_registrasi => [0],
    nama_produk => [1, 'n'],
    merk => [2, 'm'],
    jumlah_dan_kemasan => [3],
    bentuk_sediaan => [4],
    komposisi => [5],
    nama_pendaftar => [6, 'p'],
    npwp_pendaftar => [7],
);

$SPEC{cek_bpom} = {
    v => 1.1,
    summary => 'Search BPOM products via https://cekbpom.pom.go.id/',
    description => <<'_',

Uses <pm:LWP::UserAgent::Plugin> so you can add retry, caching, or additional
HTTP client behavior by setting `LWP_USERAGENT_PLUGINS` environment variable.

_
    args => {
        search_type => {
            summary => 'Select what field to search against',
            schema => ['str*', in=>[sort keys %search_types]],
            default => 'nama_produk',
            cmdline_aliases => {
                t=>{},
                (
                    map {
                        my $t = $_;
                        my @aliases;
                        push @aliases, ($t => {is_flag=>1, summary=>"Shortcut for --search-type=$t", code=>sub {$_[0]{search_type} = $t} });
                        my $shortcut = $search_types{$t}[1];
                        if (defined $shortcut) {
                            push @aliases, ($shortcut => {is_flag=>1, summary=>"Shortcut for --search-type=$t", code=>sub {$_[0]{search_type} = $t} });
                        }
                        @aliases;
                    } keys %search_types,
                ),
            },
        },
        query => {
            schema =>  'str*',
            req => 1,
            pos => 0,
        },
    },
};
sub cek_bpom {
    require HTTP::CookieJar::LWP;
    require LWP::UserAgent::Plugin;

    my %args = @_;
    defined(my $query = $args{query}) or return [400, "Please specify query"];

    my $jar = HTTP::CookieJar::LWP->new;
    my $ua = LWP::UserAgent::Plugin->new(
        cookie_jar => $jar,
    );

    my $search_type = $search_types{ $args{search_type} // 'nama_produk' }[0];
    unless (defined $search_type) {
        return [400, "Unknown search_type '$args{search_type}'"];
    }

    # first get the front page so we get the session ID
    log_trace "Requesting cekbpom front page ...";
    my $res = $ua->get($url_prefix);
    unless ($res->is_success) {
        return [$res->code, "Can't get front page ($url_prefix): ".$res->message];
    }
    my $ct = $res->content;
    unless ($ct =~ m!/home/produk/(\w{26})"!) {
        return [543, "Can't extract session ID from front page"];
    }
    my $session_id = $1;

    require URI::Escape;
    my $query_enc = URI::Escape::uri_escape($query);

    my $page_num = 0;
    my @rows;
    my $num_results = 100;
    my ($result_start, $result_end);
    while (1) {
        log_trace "Querying cekbpom ($num_results result(s)) ...";
        $res = $ua->get("$url_prefix/home/produk/$session_id/all/row/$num_results/page/$page_num/order/4/DESC/search/$search_type/$query_enc");
        unless ($res->is_success) {
            return [$res->code, "Can't get result page: ".$res->message];
        }
        my $ct = $res->content;
        unless ($ct =~ m!(\d+) - (\d+) Dari (\d+)!) {
            return [543, "Can't find signature in result page"];
        }
        ($result_start, $result_end, $num_results) = ($1, $2, $3);

        if ($result_end < $num_results && $result_end < 5000) {
            redo;
        }

        if ($ENV{CEK_BPOM_TRACE}) {
            log_trace $ct;
        }

        while ($ct =~ m!
                           <tr\stitle.+?\surldetil="/(?P<reg_id>[^"]+)">
                           <td[^>]*>(?P<nomor_registrasi>[^<]+)(?:<div>Terbit: (?P<tanggal_terbit>[^<]+))?</div></td>
                           <td[^>]*>(?P<nama>[^<]+)<div>Merk: (?P<merk>[^<]+)<br>Kemasan: (?P<kemasan>[^<]+)</div></td>
                           <td[^>]*>(?P<pendaftar>[^<]+)<div>(?P<kota_pendaftar>[^<]+)</div></td>
                       !sgx) {
            my $row = {%+};
            for (qw/kemasan/) { $row->{$_} =~ s/\R+//g }
            push @rows, $row;
        }
        last;
    }

    if (@rows < $num_results) {
        # XXX should've been a fatal error
        log_warn "Some results cannot be parsed (only got %d out of %d)", scalar(@rows), $num_results;
    } else {
        log_trace "Got $num_results result(s)";
    }

    my %resmeta;
    $resmeta{'table.fields'} = [qw/reg_id nomor_registrasi tanggal_terbit nama merk kemasan pendaftar kota_pendaftar/];

    [200, "OK", \@rows, \%resmeta];
}

1;
# ABSTRACT: Check BPOM products via the command-line (CLI interface for cekbpom.pom.go.id)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CekBpom - Check BPOM products via the command-line (CLI interface for cekbpom.pom.go.id)

=head1 VERSION

This document describes version 0.005 of App::CekBpom (from Perl distribution App-CekBpom), released on 2020-09-09.

=head1 DESCRIPTION

See included script L<cek-bpom>.

=head1 FUNCTIONS


=head2 cek_bpom

Usage:

 cek_bpom(%args) -> [status, msg, payload, meta]

Search BPOM products via https:E<sol>E<sol>cekbpom.pom.go.idE<sol>.

Uses L<LWP::UserAgent::Plugin> so you can add retry, caching, or additional
HTTP client behavior by setting C<LWP_USERAGENT_PLUGINS> environment variable.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<query>* => I<str>

=item * B<search_type> => I<str> (default: "nama_produk")

Select what field to search against.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-CekBpom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-CekBpom>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CekBpom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://cekbpom.pom.go.id/>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

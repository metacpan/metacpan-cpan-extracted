package LWP::UserAgent::Plugin::FilterLcpan;

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use HTTP::Response;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-19'; # DATE
our $DIST = 'App-lcpan'; # DIST
our $VERSION = '1.071'; # VERSION

sub before_mirror {
    my ($self, $r) = @_;

    my ($ua, $url, $filename) = @{ $r->{argv} };

    if ($r->{config}{include_author}) {
        my $ary = ref $r->{config}{include_author} eq 'ARRAY' ?
            $r->{config}{include_author} : [split /;/, $r->{config}{include_author}];
        if ($url =~ m!authors/id/./../(.+)/! && !($1 ~~ @$ary)) {
            say "mirror($url, $filename): author not included, skipping"
                if $r->{config}{verbose};
            return HTTP::Response->new(304);
        }
    }
    if ($r->{config}{exclude_author}) {
        my $ary = ref $r->{config}{exclude_author} eq 'ARRAY' ?
            $r->{config}{exclude_author} : [split /;/, $r->{config}{exclude_author}];
        if ($url =~ m!authors/id/./../(.+)/! && ($1 ~~ @$ary)) {
            say "mirror($url, $filename): author included, skipping"
                if $r->{config}{verbose};
            return HTTP::Response->new(304);
        }
    }
    if (my $max_size = $r->{config}{max_size}) {
        my $size = (-s $filename);
        if ($size && $size > $max_size) {
            say "mirror($url, $filename): local size ($size) > max_size ($max_size), skipping"
                if $r->{config}{verbose};
            return HTTP::Response->new(304);
        }

        # perform HEAD request to find out the size
        my $resp = $ua->head($url);
        {
            last unless $resp->is_success;
            last unless defined(my $len = $resp->header("Content-Length"));
            if ($len > $max_size) {
                say "mirror($url, $filename): remote size ($len) > max_size ($max_size), skipping"
                    if $r->{config}{verbose};
                return HTTP::Response->new(304);
            }
        }
    }

    1;
}

1;
# ABSTRACT: Filter mirror() based on some criteria

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Plugin::FilterLcpan - Filter mirror() based on some criteria

=head1 VERSION

This document describes version 1.071 of LWP::UserAgent::Plugin::FilterLcpan (from Perl distribution App-lcpan), released on 2022-09-19.

=head1 SYNOPSIS

 use LWP::UserAgent::Plugin 'FilterLcpan' => {
     max_size  => 20*1024*1024,
     #include_author => "PERLANCAR;KUERBIS",
     #exclude_author => "BBB;SPAMMER",
 };

 my $res  = LWP::UserAgent::Plugin->new->mirror("https://cpan.metacpan.org/authors/id/M/MO/MONSTAR/Mojolicious-Plugin-StrictCORS-0.01.tar.gz");

=head1 DESCRIPTION

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 include_author

String (semicolon-separated) or array.

=head2 exclude_author

String (semicolon-separated) or array.

=head2 max_size

Integer.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan>.

=head1 SEE ALSO

L<LWP::UserAgent::Plugin>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2018, 2017, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

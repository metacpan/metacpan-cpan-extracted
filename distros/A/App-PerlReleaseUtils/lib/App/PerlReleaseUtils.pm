package App::PerlReleaseUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-27'; # DATE
our $DIST = 'App-PerlReleaseUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

#our %argspec0_release = (
#    dist => {
#        schema => 'perl::relname*',
#        req => 1,
#        pos => 0,
#        completion => sub {
#            require Complete::Dist;
#            my %args = @_;
#            Complete::Dist::complete_dist(word=>$args{word});
#        },
#    },
#);

$SPEC{grep_perl_release} = {
    v => 1.1,
    args => {
        include_latest_versions => {
            summary => "Only include latest N version(s) of each dist",
            schema => 'posint*',
        },
        exclude_latest_versions => {
            summary => "Exclude latest N version(s) of each dist",
            schema => 'posint*',
        },
        include_dev_release => {
            schema => 'bool*',
            default => 1,
        },
        include_nondev_release => {
            schema => 'bool*',
            default => 1,
        },
    },
    args_rels => {
        choose_one => [qw/include_latest_versions exclude_latest_versions/],
    },
};
sub grep_perl_release {
    require Regexp::Pattern::Perl::Release;

    # XXX schema
    my %args = @_;
    $args{include_dev_release} //= 1;
    $args{include_nondev_release} //= 1;

    my $re = qr/\A(?:$Regexp::Pattern::Perl::Release::RE{perl_release_archive_filename}{pat})\z/;

    my @rels;
    my %dists;
    while (defined(my $line = <>)) {
        chomp $line;
        unless ($line =~ $re) {
            log_trace "Line excluded (not a perl release archive filename): $line";
            next;
        }
        my $rec = {
            release => $line,
            dist => $1,
            version0 => $2,
        };
        ($rec->{version} = $rec->{version0}) =~ s/-TRIAL/_001/;
        #log_trace "D:version=<%s>", $rec->{version};
        eval { $rec->{version_parsed} = version->parse($rec->{version}) };
        if ($@) {
            log_warn "Release %s: Can't parse version %s: %s, skipping this release", $line, $rec->{version}, $@;
            next;
        }
        $rec->{is_dev} = $rec->{version} =~ /_/ ? 1:0;

        if ($rec->{is_dev} && !$args{include_dev_release}) {
            log_trace "Line excluded (excluding dev perl release): $line";
            next;
        }
        if (!$rec->{is_dev} && !$args{include_nondev_release}) {
            log_trace "Line excluded (excluding non-dev perl release): $line";
            next;
        }

        $dists{ $rec->{dist} } //= [];
        push @rels, $rec;
        push @{ $dists{ $rec->{dist} } }, $rec;
    }

    if (defined($args{include_latest_versions}) || defined($args{exclude_latest_versions})) {
        my @res;
      DIST:
        for my $dist (keys %dists) {
          FILTER: {
                if (defined $args{include_latest_versions}) {
                    if (@{ $dists{$dist} } <= $args{include_latest_versions}) {
                        last FILTER;
                    }
                } elsif (defined $args{exclude_latest_versions}) {
                    if (@{ $dists{$dist} } <= $args{exclude_latest_versions}) {
                        last FILTER;
                    }
                }

                # sort each dist by version
                $dists{$dist} = [ sort {$a->{version_parsed} <=> $b->{version_parsed}} @{ $dists{$dist} } ];

                # only keep n latest versions
                if (defined $args{include_latest_versions}) {
                    my @removed = splice @{ $dists{$dist} }, 0, @{ $dists{$dist} } - $args{include_latest_versions};
                    log_trace "Excluding old releases of dist %s: %s", $dist, [map {$_->{release}} @removed];
                    # exclude n latest versions
                } elsif (defined $args{exclude_latest_versions}) {
                    my @removed = splice @{ $dists{$dist} }, @{ $dists{$dist} } - $args{exclude_latest_versions};
                    log_trace "Excluding latest releases of dist %s: %s", $dist, [map {$_->{release}} @removed];
                }
            } # FILTER
            push @res, map { $_->{release} } @{ $dists{$dist} };
        }
        return [200, "OK", \@res];

    } else {
        return [200, "OK", [map { $_->{release} } @rels]];
    }
}

1;
# ABSTRACT: Collection of utilities related to Perl distribution releases

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlReleaseUtils - Collection of utilities related to Perl distribution releases

=head1 VERSION

This document describes version 0.001 of App::PerlReleaseUtils (from Perl distribution App-PerlReleaseUtils), released on 2021-07-27.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
distribution releases:

=over

=item * L<grep-perl-release>

=back

=head1 FUNCTIONS


=head2 grep_perl_release

Usage:

 grep_perl_release(%args) -> [$status_code, $reason, $payload, \%result_meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<exclude_latest_versions> => I<posint>

Exclude latest N version(s) of each dist.

=item * B<include_dev_release> => I<bool> (default: 1)

=item * B<include_latest_versions> => I<posint>

Only include latest N version(s) of each dist.

=item * B<include_nondev_release> => I<bool> (default: 1)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PerlReleaseUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PerlReleaseUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PerlReleaseUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PerlReleaseUtils>, utilities related to Perl distribution releases.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package App::lcpan::Cmd::debian_dist2deb;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-17'; # DATE
our $DIST = 'App-lcpan-CmdBundle-debian'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Show Debian package name/version for a dist',
    description => <<'_',

This routine uses the simple rule of: converting the dist name to lowercase then
add "lib" prefix and "-perl" suffix. A small percentage of Perl distributions do
not follow this rule.

_
    args => {
        %App::lcpan::common_args,
        %App::lcpan::dists_args,
        check_exists_on_debian => {
            summary => 'Check each distribution if its Debian package exists, using Dist::Util::Debian::dist_has_deb',
            schema => 'bool*',
        },
        use_allpackages => {
            summary => 'Will be passed to Dist::Util::Debian::dist_has_deb',
            description => <<'_',

Using this option is faster if you need to check existence for many Debian
packages. See <pm:Dist::Util::Debian> documentation for more details.

_
            schema => 'bool*',
        },
        exists_on_debian => {
            summary => 'Only output debs which exist on Debian repository',
            'summary.alt.bool.not' => 'Only output debs which do not exist on Debian repository',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        exists_on_cpan => {
            summary => 'Only output debs which exist in database',
            'summary.alt.bool.not' => 'Only output debs which do not exist in database',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
        needs_update => {
            summary => 'Only output debs which has smaller version than its CPAN counterpart',
            'summary.alt.bool.not' => 'Only output debs which has the same version as its CPAN counterpart',
            schema => 'bool*',
            tags => ['category:filtering'],
        },
    },
};
sub handle_cmd {
    require Dist::Util::Debian;

    my %args = @_;

    my $state = App::lcpan::_init(\%args, 'ro');
    my $dbh = $state->{dbh};

    my @rows;
    my @fields = qw(dist deb);

    for my $dist (@{ $args{dists} }) {
        my $deb = Dist::Util::Debian::dist2deb($dist);
        my $row = {dist => $dist, deb => $deb};
        push @rows, $row;
    }

    {
        push @fields, "dist_version";
        my $sth = $dbh->prepare(
            "SELECT dist_name,dist_version FROM file WHERE is_latest_dist AND dist_name IN (".
                join(",", map { $dbh->quote($_) } @{ $args{dists} }).")");
        $sth->execute;
        my %versions;
        while (my $row = $sth->fetchrow_hashref) {
            $versions{$row->{dist_name}} = $row->{dist_version};
        }
        for (0..$#rows) {
            $rows[$_]{dist_version} = $versions{$rows[$_]{dist}};
        }
        if (defined $args{exists_on_cpan}) {
            @rows = grep { !(defined $_->{dist_version} xor $args{exists_on_cpan}) } @rows;
        }
    }

    if ($args{check_exists_on_debian} || defined $args{exists_on_debian} || defined $args{needs_update}) {
        push @fields, "deb_version";
        my $opts = {};
        $opts->{use_allpackages} = 1 if $args{use_allpackages} // $args{exists};

        my @res = Dist::Util::Debian::deb_ver($opts, map {$_->{deb}} @rows);
        for (0..$#rows) { $rows[$_]{deb_version} = $res[$_] }
        if (defined $args{exists_on_debian}) {
            @rows = grep { !(defined $_->{deb_version} xor $args{exists_on_debian}) } @rows;
        }
        if (defined $args{needs_update}) {
            my @frows;
            for (@rows) {
                my $v = $_->{deb_version};
                next unless defined $v;
                $v =~ s/-.+$//;
                if ($args{needs_update}) {
                    next unless version->parse($v) <  version->parse($_->{dist_version});
                } else {
                    next unless version->parse($v) == version->parse($_->{dist_version});
                }
                push @frows, $_;
            }
            @rows = @frows;
        }
    }

    [200, "OK", \@rows, {'table.fields' => \@fields}];
}

1;
# ABSTRACT: Show Debian package name/version for a dist

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::debian_dist2deb - Show Debian package name/version for a dist

=head1 VERSION

This document describes version 0.008 of App::lcpan::Cmd::debian_dist2deb (from Perl distribution App-lcpan-CmdBundle-debian), released on 2021-07-17.

=head1 SYNOPSIS

Convert some distribution names to Debian package names (using simple rule of
converting dist to lowercase and adding "lib" prefix and "-perl" suffix):

 % cat dists.txt
 HTTP-Tiny
 App-lcpan
 Data-Dmp
 Foo

 % lcpan debian-dist2deb < dists.txt
 +-----------+-------------------+--------------+
 | dist      | deb               | dist_version |
 +-----------+-------------------+--------------+
 | HTTP-Tiny | libhttp-tiny-perl | 0.070        |
 | App-lcpan | libapp-lcpan-perl | 1.014        |
 | Data-Dmp  | libdata-dmp-perl  | 0.22         |
 | Foo       | libfoo-perl       |              |
 +-----------+-------------------+--------------+

Like the above, but also check that Debian package exists in the Debian
repository (will show package version if exists, or undef if not exists):

 % lcpan debian-dist2deb --check-exists-on-debian < dists.txt
 +-----------+-------------------+--------------+-------------+
 | dist      | deb               | dist_version | deb_version |
 +-----------+-------------------+--------------+-------------+
 | HTTP-Tiny | libhttp-tiny-perl | 0.070        | 0.070-1     |
 | App-lcpan | libapp-lcpan-perl | 1.014        |             |
 | Data-Dmp  | libdata-dmp-perl  | 0.22         | 0.21-1      |
 | Foo       | libfoo-perl       |              |             |
 +-----------+-------------------+--------------+-------------+

Like the above, but download (and cache) allpackages.txt.gz first to speed up
checking if you need to check many Debian packages:

 % lcpan debian-dist2deb --check-exists-on-debian --use-allpackages

Only show dists where the Debian package exists on Debian repo
(C<--exists-on-debian> implicitly turns on C<--check-exists-on-debian>):

 % lcpan debian-dist2deb --exists-on-debian --use-allpackages < dists.txt
 +-----------+-------------------+--------------+-------------+
 | dist      | deb               | dist_version | deb_version |
 +-----------+-------------------+--------------+-------------+
 | HTTP-Tiny | libhttp-tiny-perl | 0.070        | 0.070-1     |
 | Data-Dmp  | libdata-dmp-perl  | 0.22         | 0.21-1      |
 +-----------+-------------------+--------------+-------------+

Reverse the filter (only show dists which do not have Debian packages):

 % lcpan debian-dist2deb --no-exists-on-debian --use-allpackages < dists.txt
 +-----------+-------------------+--------------+-------------+
 | dist      | deb               | dist_version | deb_version |
 +-----------+-------------------+--------------+-------------+
 | App-lcpan | libapp-lcpan-perl | 1.014        |             |
 | Foo       | libfoo-perl       |              |             |
 +-----------+-------------------+--------------+-------------+

Only show dists where the Debian package exists on Debian repo *and* the Debian
package version is less than the dist version:

 % lcpan debian-dist2deb --exists-on-debian --use-allpackages --needs-update < dists.txt
 +-----------+-------------------+--------------+-------------+
 | dist      | deb               | dist_version | deb_version |
 +-----------+-------------------+--------------+-------------+
 | Data-Dmp  | libdata-dmp-perl  | 0.22         | 0.21-1      |
 +-----------+-------------------+--------------+-------------+

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<debian-dist2deb>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show Debian package nameE<sol>version for a dist.

This routine uses the simple rule of: converting the dist name to lowercase then
add "lib" prefix and "-perl" suffix. A small percentage of Perl distributions do
not follow this rule.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<check_exists_on_debian> => I<bool>

Check each distribution if its Debian package exists, using Dist::Util::Debian::dist_has_deb.

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<dists>* => I<array[perl::distname]>

Distribution names (e.g. Foo-Bar).

=item * B<exists_on_cpan> => I<bool>

Only output debs which exist in database.

=item * B<exists_on_debian> => I<bool>

Only output debs which exist on Debian repository.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<needs_update> => I<bool>

Only output debs which has smaller version than its CPAN counterpart.

=item * B<use_allpackages> => I<bool>

Will be passed to Dist::Util::Debian::dist_has_deb.

Using this option is faster if you need to check existence for many Debian
packages. See L<Dist::Util::Debian> documentation for more details.

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-debian>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-debian>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-debian>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

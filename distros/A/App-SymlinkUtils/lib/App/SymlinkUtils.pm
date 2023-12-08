package App::SymlinkUtils;

use strict;
use warnings;
use Log::ger;

use File::Symlink::Util ();
use Perinci::Sub::Util qw(gen_modified_sub);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-25'; # DATE
our $DIST = 'App-SymlinkUtils'; # DIST
our $VERSION = '0.004'; # VERSION

my $res;

$res = gen_modified_sub(
    base_name => 'File::Symlink::Util::check_symlink',
    wrap_code => sub {
        my $orig = shift;
        my %args = @_;
        my $symlinks = delete $args{symlinks};
        my $res = $orig->(@_);
        # print the errors to stderr
        if ($res->[0] == 500) {
            warn "check-symlink: $_\n" for @{ $res->[2] };
        }
        $res;
    },
);
$res->[0] == 200 or die "Can't gen check_symlink(): $res->[0] - $res->[1]";

$res = gen_modified_sub(
    base_name => 'File::Symlink::Util::check_symlink',
    output_name => 'check_symlinks',
    summary => 'Perform various checks on symlinks',
    remove_args => ['symlink', 'target'],
    add_args => {
        symlinks => {
            summary => 'Symlinks to check',
            'x.name.is_plural' => 1,
            'x.name.singular' => 'symlink',
            schema => ['array*', of=>'filename*', min_len=>1],
            req => 1,
            pos => 0,
            slurpy => 1,
        },
    },
    output_code => sub {
        my %args = @_;
        my $symlinks = delete $args{symlinks};
        my $has_err;
        for my $symlink (@$symlinks) {
            log_info "check-symlinks: Checking $symlink ...";
            my $res = File::Symlink::Util::check_symlink(%args, symlink=>$symlink);
            # print the errors to stderr
            if ($res->[0] == 500) {
                warn "check-symlinks: $symlink: $_\n" for @{ $res->[2] };
                $has_err++;
            } elsif ($res->[0] != 200) {
                warn "check-symlinks: $symlink: $res->[0] - $res->[1]\n";
                $has_err++;
            }
        }
        $has_err ? [500, "Some symlinks failed checks"] : [200, "All symlinks OK"];
    },
);
$res->[0] == 200 or die "Can't gen check_symlinks(): $res->[0] - $res->[1]";

1;
# ABSTRACT: CLI utilities related to symbolic links (symlinks)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SymlinkUtils - CLI utilities related to symbolic links (symlinks)

=head1 VERSION

This document describes version 0.004 of App::SymlinkUtils (from Perl distribution App-SymlinkUtils), released on 2023-08-25.

=head1 DESCRIPTION

This distribution includes several utilities related to symlinks:

=over

=item * L<check-symlink>

=item * L<check-symlinks>

=back

=head1 FUNCTIONS


=head2 check_symlink

Usage:

 check_symlink(%args) -> [$status_code, $reason, $payload, \%result_meta]

Perform various checks on a symlink.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content_matches> => I<bool>

Whether content should match extension.

If set to true, will guess media type from content and check that file extension
exists nd matches the media type. Requires L<File::MimeInfo::Magic>, which is
only specified as a "Recommends" dependency by File-Symlink-Util distribution.

=item * B<ext_matches> => I<bool>

Whether extension should match.

If set to true, then if both symlink name and target filename contain filename
extension (e.g. C<jpg>) then they must match. Case variation is allowed (e.g.
C<JPG>) but other variation is not (e.g. C<jpeg>).

=item * B<is_abs> => I<bool>

Whether we should check that symlink target is an absolute path.

If set to true, then symlink target must be an absolute path. If
set to false, then symlink target must be a relative path.

=item * B<symlink>* => I<filename>

Path to the symlink to be checked.

=item * B<target> => I<filename>

Expected target path.

If specified, then target of symlink (after normalized to absolute path) will be
checked and must point to this target.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 check_symlinks

Usage:

 check_symlinks(%args) -> [$status_code, $reason, $payload, \%result_meta]

Perform various checks on symlinks.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<content_matches> => I<bool>

Whether content should match extension.

If set to true, will guess media type from content and check that file extension
exists nd matches the media type. Requires L<File::MimeInfo::Magic>, which is
only specified as a "Recommends" dependency by File-Symlink-Util distribution.

=item * B<ext_matches> => I<bool>

Whether extension should match.

If set to true, then if both symlink name and target filename contain filename
extension (e.g. C<jpg>) then they must match. Case variation is allowed (e.g.
C<JPG>) but other variation is not (e.g. C<jpeg>).

=item * B<is_abs> => I<bool>

Whether we should check that symlink target is an absolute path.

If set to true, then symlink target must be an absolute path. If
set to false, then symlink target must be a relative path.

=item * B<symlinks>* => I<array[filename]>

Symlinks to check.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-SymlinkUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SymlinkUtils>.

=head1 SEE ALSO

L<File::Symlink::Util>

L<Setup::File::Symlink>

L<App::CpMvUtils> has some utilities related to symlink:
L<cp-and-adjust-symlinks>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-SymlinkUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

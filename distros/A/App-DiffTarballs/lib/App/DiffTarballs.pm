package App::DiffTarballs;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-05-09'; # DATE
our $DIST = 'App-DiffTarballs'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use File::chdir;
use IPC::System::Options qw(system);

our %SPEC;

my %xcompletion_tarball = (
    'x.completion' => [filename => {
        filter => sub {-f $_[0] && $_[0] =~ /\.tar\.?/},
    }],
);

$SPEC{diff_tarballs} = {
    v => 1.1,
    summary => 'Diff contents of two tarballs',
    description => <<'_',

This utility extracts the two tarballs to temporary directories and then perform
`diff -ruN` against the two. It deletes the temporary directories afterwards.

_
    args => {
        tarball1 => {
            schema => 'filename*',
            %xcompletion_tarball,
            req => 1,
            pos => 0,
        },
        tarball2 => {
            schema => 'filename*',
            %xcompletion_tarball,
            req => 1,
            pos => 1,
        },
    },
    deps => {
        all => [
            {prog => 'tar'},
            {prog => 'diff'},
        ],
    },
    examples => [
        {
            argv => [qw/My-Dist-1.001.tar.gz My-Dist-1.002.tar.bz2/],
            summary => 'Show diff between two Perl releases',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub diff_tarballs {
    require Cwd;
    require File::Temp;
    require ShellQuote::Any::Tiny;

    my %args = @_;

    return [404, "No such file or directory: $args{tarball1}"]
        unless -f $args{tarball1};
    return [404, "No such file or directory: $args{tarball2}"]
        unless -f $args{tarball2};

    my $abs_tarball1 = Cwd::abs_path($args{tarball1});
    my $abs_tarball2 = Cwd::abs_path($args{tarball2});

    return [404, "No such file or directory: $args{tarball1}"]
        unless -f $args{tarball1};
    return [404, "No such file or directory: $args{tarball2}"]
        unless -f $args{tarball2};

    my $dir1 = File::Temp::tempdir(CLEANUP => 1);
    my $dir2 = File::Temp::tempdir(CLEANUP => 1);

    $CWD = $dir1;
    system({log=>1, die=>1}, "tar", "xf", $abs_tarball1);
    system({log=>1, die=>1}, "tar", "xf", $abs_tarball2);
    return [304, "$args{tarball1} and $args{tarball2} are the same file"]
        if $abs_tarball1 eq $abs_tarball2;

    my $cleanup = !$ENV{DEBUG};

    $dir1 = File::Temp::tempdir(CLEANUP => $cleanup);
    $dir2 = File::Temp::tempdir(CLEANUP => $cleanup);

    $CWD = $dir1;
    system({log=>1, die=>1}, "tar", "xf", $abs_tarball1);
    my @glob1 = glob("*");
    unless (@glob1 == 1) {
        return [412, "$args{tarball1} did not extract to ".
                    "a single file/directory"];
    }

    $CWD = $dir2;
    system({log=>1, die=>1}, "tar", "xf", $abs_tarball2);
    my @glob2 = glob("*");
    unless (@glob2 == 1) {
        return [412, "$args{tarball2} did not extract to ".
                    "a single file/directory"];
    }

    my $name1 = $glob1[0];
    my $name2 = $glob2[0];
    $name1 .= ".0" if $name1 eq $name2;

    rename "$dir1/$glob1[0]", "$dir2/$name1";

    my $diff_cmd = $ENV{DIFF} // do {
        "diff -ruN" .
            (exists $ENV{NO_COLOR} ? " --color=never" :
             defined $ENV{COLOR} ? ($ENV{COLOR} ? " --color=always" : " --color=never") :
             "");
    };
    system({log=>1, shell=>1}, join(
        " ",
        $diff_cmd,
        ShellQuote::Any::Tiny::shell_quote($name1),
        ShellQuote::Any::Tiny::shell_quote($name2),
    ));

    unless ($cleanup) {
        log_info("Not cleaning up temporary directory %s", $dir2);
    }

    [200];
}

1;
# ABSTRACT: Diff contents of two tarballs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DiffTarballs - Diff contents of two tarballs

=head1 VERSION

This document describes version 0.004 of App::DiffTarballs (from Perl distribution App-DiffTarballs), released on 2021-05-09.

=head1 SYNOPSIS

See the included script L<diff-tarballs>.

=head1 FUNCTIONS


=head2 diff_tarballs

Usage:

 diff_tarballs(%args) -> [status, msg, payload, meta]

Diff contents of two tarballs.

Examples:

=over

=item * Show diff between two Perl releases:

 diff_tarballs(
     tarball1 => "My-Dist-1.001.tar.gz",
   tarball2 => "My-Dist-1.002.tar.bz2"
 );

=back

This utility extracts the two tarballs to temporary directories and then perform
C<diff -ruN> against the two. It deletes the temporary directories afterwards.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<tarball1>* => I<filename>

=item * B<tarball2>* => I<filename>


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

=head2 DEBUG

Bool. If set to true, will cause temporary directories to not being cleaned up
after the program is done.

=head2 DIFF

String. Set diff command to use. Defaults to C<diff -ruN>. For example, you can
set it to C<diff --color -ruN> (C<--color> requires GNU diff 3.4 or later), or
C<colordiff -ruN>.

=head2 NO_COLOR

If set (and L</DIFF> is not set), will add C<--color=never> option to diff
command.

=head2 COLOR => bool

If set to true (and L</DIFF> is not set), will add C<--color=always> option to
diff command.

If set to false (and L</DIFF> is not set), will add C<--color=never> option to
diff command.

Note that L</NO_COLOR> takes precedence.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DiffTarballs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DiffTarballs>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DiffTarballs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

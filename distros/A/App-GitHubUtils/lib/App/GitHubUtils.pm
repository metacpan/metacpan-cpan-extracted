package App::GitHubUtils;

our $DATE = '2018-10-09'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to GitHub',
};

$SPEC{create_the_github_repo} = {
    v => 1.1,
    summary => 'Create github repo',
    description => <<'_',

This is a convenient no-argument-needed command to create GitHub repository.
Will use prog:github-cmd from pm:App::github::cmd to create the repository. To
find out the repo name to be created, will first check .git/config if it exists.
Otherwise, will just use the name of the current directory.

_
    args => {
    },
    deps => {
        prog => 'github-cmd',
    },
};
sub create_the_github_repo {
    require App::GitUtils;
    require Cwd;
    require IPC::System::Options;

    my $repo;
  SET_REPO_NAME:
    {
        my $res = App::GitUtils::info();
        if ($res->[0] == 200) {
            my $content = do {
                local $/;
                my $path = "$res->[2]{git_dir}/config";
                open my $fh, "<", $path or die "Can't open $path: $!";
                <$fh>;
            };
            if ($content =~ m!^\s*url\s*=\s*.+/([^/]+)\.git\s*$!m) {
                $repo = $1;
                last;
            }
        }
        $repo = Cwd::getcwd();
        $repo =~ s!.+/!!;
    }
    log_info "Creating repo '%s' ...", $repo;

    my ($out, $err);
    IPC::System::Options::system({log=>1, capture_stdout=>\$out, capture_stderr=>\$err}, "github-cmd", "create-repo", $repo);
    my $exit = $?;

    if ($exit) {
        if ($out =~ /name already exists/) {
            return [412, "Failed: Repo already exists"];
        } else {
            return [500, "Failed: $out"];
        }
    } else {
        return [200, "OK", undef, {'func.repo'=>$repo}];
    }
}

1;
# ABSTRACT: Utilities related to GitHub

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitHubUtils - Utilities related to GitHub

=head1 VERSION

This document describes version 0.003 of App::GitHubUtils (from Perl distribution App-GitHubUtils), released on 2018-10-09.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
GitHub:

=over

=item * L<create-the-github-repo>

=back

=head1 FUNCTIONS


=head2 create_the_github_repo

Usage:

 create_the_github_repo() -> [status, msg, result, meta]

Create github repo.

This is a convenient no-argument-needed command to create GitHub repository.
Will use prog:github-cmd from pm:App::github::cmd to create the repository. To
find out the repo name to be created, will first check .git/config if it exists.
Otherwise, will just use the name of the current directory.

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

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GitHubUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GitHubUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GitHubUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<github-cmd> from L<App::github::cmd>

L<Net::GitHub>

L<Pithub>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

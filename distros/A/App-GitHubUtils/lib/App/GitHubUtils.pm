package App::GitHubUtils;

our $DATE = '2020-04-27'; # DATE
our $VERSION = '0.005'; # VERSION

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

$SPEC{git_clone_from_github} = {
    v => 1.1,
    summary => 'git clone, with some conveniences',
    description => <<'_',

Instead of having to type:

    % git clone git@github.com:USER/PREFIX-NAME.git

you can just type:

    % git-clone-from-github NAME

The utility will try the `users` specified in config file, as well as
`prefixes` and clone the first repo that exists. You can put something like this
in `githubutils.conf`:

    [prog=git-clone-from-github]
    users = ["perlancar", "perlancar2"]
    prefixes = ["perl5-", "perl-"]
    suffixes = ["-p5"]

The utility will check whether repo in these URLs exist:

    git@github.com:perlancar/perl5-NAME.git
    git@github.com:perlancar/perl-NAME.git
    git@github.com:perlancar/NAME-p5.git
    git@github.com:perlancar2/perl5-NAME.git
    git@github.com:perlancar2/perl-NAME.git
    git@github.com:perlancar2/NAME-p5.git

_
    args => {
        name => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        users => {
            schema => ['array*', of=>'str*'],
            description => <<'_',

If not specified, will use `login` from `github-cmd.conf` file.

_
        },
        prefixes => {
            schema => ['array*', of=>'str*'],
        },
        suffixes => {
            schema => ['array*', of=>'str*'],
        },
    },
    deps => {
        all => [
            {prog => 'github-cmd'},
            {prog => 'git'},
        ],
    },
};
sub git_clone_from_github {
    require Perinci::CmdLine::Call;
    require Perinci::CmdLine::Util::Config;

    my %args = @_;

    my @users;
    if ($args{users} && @{ $args{users} }) {
        push @users, @{ $args{users} };
    } else {
        # get login from github-cmd.conf. XXX later we'll use
        # PERINCI_CMDLINE_DUMP_CONFIG/PERINCI_CMDLINE_DUMP_ARGS
        my $res = Perinci::CmdLine::Util::Config::read_config(
            config_filename => 'github-cmd.conf',
        );
        return $res unless $res->[0] == 200;
        return [412, "Cannot read 'login' from github-cmd.conf to use as users"]
            unless defined $res->[2]{GLOBAL}{login};
        push @users, $res->[2]{GLOBAL}{login};
    }

    my @repos;
    push @repos, $args{name};
    push @repos, "$_$args{name}" for @{ $args{prefixes} // [] };
    push @repos, "$args{name}$_" for @{ $args{suffixes} // [] };

    my @tried_names;

    my ($chosen_user, $chosen_repo);
  SEARCH:
    for my $user (@users) {
        for my $repo (@repos) {
            push @tried_names, "$user/$repo.git";
            log_info "Trying $user/$repo.git ...";
            my $res = Perinci::CmdLine::Call::call_cli_script(
                script => 'github-cmd',
                argv   => ['repo-exists', '--repo', $repo, '--user', $user],
            );
            return [500, "Can't check if repo $repo exists: ".
                        "$res->[0] - $res->[1]"] unless $res->[0] == 200;
            if ($res->[2]) {
                $chosen_user = $user;
                $chosen_repo = $repo;
                last SEARCH;
            }
        }
    }

    return [412, "Can't find any existing repo (tried ".
                join(", ", @tried_names).")"]
        unless defined $chosen_user;

    system(
        "git", "clone", "git\@github.com:$chosen_user/$chosen_repo.git",
        (defined $args{directory} ? ($args{directory}) : ()),
    );

    if ($?) {
        [500, "git clone failed with exit code ".($? < 0 ? $? : $? >> 8)];
    } else {
        [200];
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

This document describes version 0.005 of App::GitHubUtils (from Perl distribution App-GitHubUtils), released on 2020-04-27.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
GitHub:

=over

=item * L<create-the-github-repo>

=item * L<git-clone-from-github>

=back

=head1 FUNCTIONS


=head2 create_the_github_repo

Usage:

 create_the_github_repo() -> [status, msg, payload, meta]

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
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 git_clone_from_github

Usage:

 git_clone_from_github(%args) -> [status, msg, payload, meta]

git clone, with some conveniences.

Instead of having to type:

 % git clone git@github.com:USER/PREFIX-NAME.git

you can just type:

 % git-clone-from-github NAME

The utility will try the C<users> specified in config file, as well as
C<prefixes> and clone the first repo that exists. You can put something like this
in C<githubutils.conf>:

 [prog=git-clone-from-github]
 users = ["perlancar", "perlancar2"]
 prefixes = ["perl5-", "perl-"]
 suffixes = ["-p5"]

The utility will check whether repo in these URLs exist:

 git@github.com:perlancar/perl5-NAME.git
 git@github.com:perlancar/perl-NAME.git
 git@github.com:perlancar/NAME-p5.git
 git@github.com:perlancar2/perl5-NAME.git
 git@github.com:perlancar2/perl-NAME.git
 git@github.com:perlancar2/NAME-p5.git

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name>* => I<str>

=item * B<prefixes> => I<array[str]>

=item * B<suffixes> => I<array[str]>

=item * B<users> => I<array[str]>

If not specified, will use C<login> from C<github-cmd.conf> file.


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

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

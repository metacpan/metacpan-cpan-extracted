package App::GitHubUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-14'; # DATE
our $DIST = 'App-GitHubUtils'; # DIST
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to GitHub',
};

$SPEC{create_this_repo_on_github} = {
    v => 1.1,
    summary => 'Create this repo on github',
    description => <<'_',

This is a convenient no-argument-needed command to create GitHub repository of
the current ("this") repo. Will use <prog:github-cmd> from <pm:App::github::cmd>
to create the repository. To find out the repo name to be created, will first
check .git/config if it exists. Otherwise, will just use the name of the current
directory.

_
    args => {
        github_cmd_config_profile=>{
            schema => 'str*',
        },
    },
    deps => {
        prog => 'github-cmd',
    },
};
sub create_this_repo_on_github {
    require App::GitUtils;
    require Cwd;
    require IPC::System::Options;

    my %args = @_;

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
    IPC::System::Options::system(
        {log=>1, capture_stdout=>\$out, capture_stderr=>\$err},
        "github-cmd",
        defined($args{github_cmd_config_profile}) ? ("--config-profile", $args{github_cmd_config_profile}) : (),
        "create-repo", $repo);
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

This document describes version 0.008 of App::GitHubUtils (from Perl distribution App-GitHubUtils), released on 2021-08-14.

=head1 DESCRIPTION

This distribution provides the following command-line utilities related to
GitHub:

=over

=item * L<create-this-repo-on-github>

=item * L<git-clone-from-github>

=back

=head1 FUNCTIONS


=head2 create_this_repo_on_github

Usage:

 create_this_repo_on_github(%args) -> [$status_code, $reason, $payload, \%result_meta]

Create this repo on github.

This is a convenient no-argument-needed command to create GitHub repository of
the current ("this") repo. Will use L<github-cmd> from L<App::github::cmd>
to create the repository. To find out the repo name to be created, will first
check .git/config if it exists. Otherwise, will just use the name of the current
directory.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<github_cmd_config_profile> => I<str>


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 git_clone_from_github

Usage:

 git_clone_from_github(%args) -> [$status_code, $reason, $payload, \%result_meta]

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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

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

L<App::GitUtils>

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

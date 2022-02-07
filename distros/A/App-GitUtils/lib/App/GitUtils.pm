package App::GitUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-14'; # DATE
our $DIST = 'App-GitUtils'; # DIST
our $VERSION = '0.083'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Cwd qw(getcwd abs_path);
use File::chdir;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Day-to-day command-line utilities for git',
};

our %argopt_dir = (
    dir => {
        summary => 'A directory inside git repo',
        schema => 'dirname*',
        description => <<'_',

If not specified, will assume current directory is inside git repository and
will search `.git` upwards.

_
    },
);

our %args_common = (
    %argopt_dir,
);

our %arg_target_dir = (
    target_dir => {
        summary => 'Target repo directory',
        schema => 'dirname*',
        description => <<'_',

If not specified, defaults to `$repodir.bare/`.

_
    },
);

our $_complete_hook = sub {
    my %args = @_;

    my $word = $args{word} // '';
    my $res = list_hooks();
    return [] unless $res->[0] == 200;
    return $res->[2];
};

sub _search_git_dir {
    my $args = shift;

    my $orig_wd = getcwd;

    my $cwd;
    if (defined $args->{dir}) {
        $cwd = $args->{dir};
    } else {
        $cwd = $orig_wd;
    }

    my $res;
    while (1) {
        log_trace "Checking for .git/ in $cwd ..." if $ENV{GITUTILS_TRACE};
        do { $res = "$cwd/.git"; last } if -d "$cwd/.git";
        chdir ".." or goto EXIT;
        $cwd =~ s!(.+)/.+!$1! or last;
    }

  EXIT:
    chdir $orig_wd;
    return $res;
}

$SPEC{info} = {
    v => 1.1,
    summary => 'Return information about git repository',
    args => {
        %args_common,
    },
};
sub info {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure you're inside a git repo"]
        unless defined $git_dir;

    my ($repo_name) = $git_dir =~ m!.+/(.+)/\.git\z!
        or return [500, "Can't extract repo name from git dir '$git_dir'"];

    [200, "OK", {
        git_dir => $git_dir,
        repo_name => $repo_name,
        # more information in the future
    }];
}

$SPEC{list_hooks} = {
    v => 1.1,
    summary => 'List available hooks for the repository',
    args => {
        %args_common,
    },
};
sub list_hooks {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure you're inside a git repo"]
        unless defined $git_dir;

    my $hooks_dir = "$git_dir/hooks";
    opendir my($dh), $hooks_dir;
    my @res;
    for (sort readdir $dh) {
        next if /\.sample\z/; # skip sample names
        next unless -f "$hooks_dir/$_" && -x _;
        push @res, $_;
    }
    [200, "OK", \@res];
}

$SPEC{run_hook} = {
    v => 1.1,
    summary => 'Run a hook',
    description => <<'_',

Basically the same as:

    % .git/hooks/<hook-name>

except can be done anywhere inside git repo and provides tab completion.

_
    args => {
        %args_common,
        name => {
            summary => 'Hook name, e.g. post-commit',
            schema => ['str*', match => '\A[A-Za-z0-9-]+\z'],
            req => 1,
            pos => 0,
            completion => $_complete_hook,
        },
    },
};
sub run_hook {
    my %args = @_;

    my $git_dir = _search_git_dir(\%args);
    return [412, "Can't find .git dir, make sure you're inside a git repo"]
        unless defined $git_dir;

    my $name = $args{name};

    (-x "$git_dir/hooks/$name") or
        return [400, "Unknown or non-executable git hook: $name"];

    local $CWD = "$git_dir/..";
    exec ".git/hooks/$name";
    #[200]; # unreached
}

$SPEC{post_commit} = {
    v => 1.1,
    summary => 'Run post-commit hook',
    description => <<'_',

Basically the same as:

    % .git/hooks/post-commit

except can be done anywhere inside git repo.

_
    args => {
        %args_common,
    },
};
sub post_commit {
    run_hook(name => 'post-commit');
}

$SPEC{pre_commit} = {
    v => 1.1,
    summary => 'Run pre-commit hook',
    description => <<'_',

Basically the same as:

    % .git/hooks/pre-commit

except can be done anywhere inside git repo.

_
    args => {
        %args_common,
    },
};
sub pre_commit {
    run_hook(name => 'pre-commit');
}

$SPEC{clone_to_bare} = {
    v => 1.1,
    summary => 'Clone repository to a bare repository',
    args => {
        %args_common,
        %arg_target_dir,
    },
};
sub clone_to_bare {
    require IPC::System::Options;

    my %args = @_;

    my $res = info(%args);
    return $res unless $res->[0] == 200;

    my $src_dir = "$res->[2]{git_dir}/..";
    my $target_dir = abs_path($args{target_dir} // "$src_dir/../$res->[2]{repo_name}.bare");
    (-d $target_dir) and return [412, "Target dir '$target_dir' already exists"];
    (-e $target_dir) and return [412, "Target '$target_dir' already exists but not a dir"];

    mkdir $target_dir, 0755 or return [500, "Can't mkdir target dir '$target_dir': $!"];
    IPC::System::Options::system(
        {log=>1, die=>1},
        "git", "init", "--bare", $target_dir,
    );

    local $CWD = $src_dir;
    IPC::System::Options::system(
        {log=>1, die=>1},
        "git", "push", "--all", $target_dir,
    );
    [200];
}

1;
# ABSTRACT: Day-to-day command-line utilities for git

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitUtils - Day-to-day command-line utilities for git

=head1 VERSION

This document describes version 0.083 of App::GitUtils (from Perl distribution App-GitUtils), released on 2021-08-14.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<gu>

=item * L<this-repo>

=back

These utilities provide some shortcuts and tab completion to make it more
convenient when working with git con the command-line.

=head1 FUNCTIONS


=head2 clone_to_bare

Usage:

 clone_to_bare(%args) -> [$status_code, $reason, $payload, \%result_meta]

Clone repository to a bare repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.

=item * B<target_dir> => I<dirname>

Target repo directory.

If not specified, defaults to C<$repodir.bare/>.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 info

Usage:

 info(%args) -> [$status_code, $reason, $payload, \%result_meta]

Return information about git repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_hooks

Usage:

 list_hooks(%args) -> [$status_code, $reason, $payload, \%result_meta]

List available hooks for the repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 post_commit

Usage:

 post_commit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run post-commit hook.

Basically the same as:

 % .git/hooks/post-commit

except can be done anywhere inside git repo.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 pre_commit

Usage:

 pre_commit(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run pre-commit hook.

Basically the same as:

 % .git/hooks/pre-commit

except can be done anywhere inside git repo.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 run_hook

Usage:

 run_hook(%args) -> [$status_code, $reason, $payload, \%result_meta]

Run a hook.

Basically the same as:

 % .git/hooks/<hook-name>

except can be done anywhere inside git repo and provides tab completion.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dir> => I<dirname>

A directory inside git repo.

If not specified, will assume current directory is inside git repository and
will search C<.git> upwards.

=item * B<name>* => I<str>

Hook name, e.g. post-commit.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head2 GITUTILS_TRACE

Boolean. If set to true, will produce additional log statements using
L<Log::ger> at the trace level.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-GitUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GitUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GitUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::GitHubUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto (on PC, Jakarta)

Steven Haryanto (on PC, Jakarta) <stevenharyanto@gmail.com>

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

This software is copyright (c) 2021, 2020, 2018, 2015, 2014 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

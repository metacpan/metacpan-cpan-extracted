package App::GitUtils;

our $DATE = '2018-01-30'; # DATE
our $VERSION = '0.07'; # VERSION

use 5.010001;
use strict;
use warnings;

use Cwd;
use File::chdir;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Day-to-day command-line utilities for git',
};

our $_complete_hook = sub {
    my %args = @_;

    my $word = $args{word} // '';
    my $res = list_hooks();
    return [] unless $res->[0] == 200;
    return $res->[2];
};

sub _search_git_dir {
    my $orig_wd = getcwd;
    my $cwd = $orig_wd;

    my $res;
    while (1) {
        do { $res = "$cwd/.git"; last } if -d ".git";
        chdir ".." or return undef;
        $cwd =~ s!(.+)/.+!$1! or last;
    }

    chdir $orig_wd;
    return $res;
}

$SPEC{info} = {
    v => 1.1,
    summary => 'Return information about git repository',
};
sub info {
    my %args = @_;

    my $git_dir = _search_git_dir();
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
};
sub list_hooks {
    my %args = @_;

    my $git_dir = _search_git_dir();
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

    my $git_dir = _search_git_dir();
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
};
sub pre_commit {
    run_hook(name => 'pre-commit');
}

1;
# ABSTRACT: Day-to-day command-line utilities for git

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GitUtils - Day-to-day command-line utilities for git

=head1 VERSION

This document describes version 0.07 of App::GitUtils (from Perl distribution App-GitUtils), released on 2018-01-30.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<gu>

=back

These utilities provide some shortcuts and tab completion to make it more
convenient when working with git con the command-line.

=head1 FUNCTIONS


=head2 info

Usage:

 info() -> [status, msg, result, meta]

Return information about git repository.

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


=head2 list_hooks

Usage:

 list_hooks() -> [status, msg, result, meta]

List available hooks for the repository.

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


=head2 post_commit

Usage:

 post_commit() -> [status, msg, result, meta]

Run post-commit hook.

Basically the same as:

 % .git/hooks/post-commit

except can be done anywhere inside git repo.

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


=head2 pre_commit

Usage:

 pre_commit() -> [status, msg, result, meta]

Run pre-commit hook.

Basically the same as:

 % .git/hooks/pre-commit

except can be done anywhere inside git repo.

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


=head2 run_hook

Usage:

 run_hook(%args) -> [status, msg, result, meta]

Run a hook.

Basically the same as:

 % .git/hooks/<hook-name>

except can be done anywhere inside git repo and provides tab completion.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<name>* => I<str>

Hook name, e.g. post-commit.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

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

Below is the list of distributions that provide CLI utilities for various
purposes, with the focus on providing shell tab completion feature.

L<App::DistUtils>, utilities related to Perl distributions.

L<App::DzilUtils>, utilities related to L<Dist::Zilla>.

L<App::GitUtils>, utilities related to git.

L<App::IODUtils>, utilities related to L<IOD> configuration files.

L<App::LedgerUtils>, utilities related to Ledger CLI files.

L<App::PlUtils>, utilities related to Perl scripts.

L<App::PMUtils>, utilities related to Perl modules.

L<App::ProgUtils>, utilities related to programs.

L<App::WeaverUtils>, utilities related to L<Pod::Weaver>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

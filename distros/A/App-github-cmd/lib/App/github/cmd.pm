package App::github::cmd;

our $DATE = '2019-07-27'; # DATE
our $VERSION = '0.007'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{':package'} = {
    summary => 'Yet another github CLI',
    v => 1.1,
};

our %args_common = (
    login => {
        schema => 'str*',
        tags => ['common'],
    },
    pass => {
        schema => 'str*',
        tags => ['common'],
    },
    access_token => {
        schema => 'str*',
        tags => ['common'],
    },
);
our %argsrels_common = (
    req_all => [qw/login pass/],
    req_one => [qw/login access_token/],
);
our %arg0_user = (
    user => {
        schema => 'str*',
        req => 1,
        pos => 0,
    },
);
our %argopt0_user = (
    user => {
        schema => 'str*',
        pos => 0,
    },
);
our %argopt_user = (
    user => {
        schema => 'str*',
    },
);
our %arg0_repo = (
    repo => {
        schema => 'str*',
        req => 1,
        pos => 0,
    },
);
our %argopt_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

sub _init {
    my $args = shift;
    state $state = {};

    unless ($state->{_github}) {
        require Net::GitHub;
        my %ngargs;
        if ($args->{access_token}) {
            $ngargs{access_token} = $args->{access_token};
        } else {
            $ngargs{login} = $args->{login};
            $ngargs{pass}  = $args->{pass};
        }
        $state->{github} = Net::GitHub->new(%ngargs);
    }
    $state;
}

$SPEC{get_user} = {
    v => 1.1,
    summary => 'Get information about a user',
    args => {
        %args_common,
        %argopt0_user,
    },
};
sub get_user {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    my $user = $github->user->show($args{user});
    [200, "OK", $user];
}

$SPEC{get_repo} = {
    v => 1.1,
    summary => 'Get information about a repository',
    args => {
        %args_common,
        %argopt_user,
        %arg0_repo,
    },
};
sub get_repo {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    my $repo = $github->repos->get($args{user} // $args{login}, $args{repo});
    [200, "OK", $repo];
}

$SPEC{repo_exists} = {
    v => 1.1,
    summary => 'Check whether a repository exists',
    args => {
        %args_common,
        %argopt_user,
        %arg0_repo,
    },
};
sub repo_exists {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    my $repo;
    eval {
        $repo = $github->repos->get($args{user} // $args{login}, $args{repo});
    };
    my $err = $@;
    my $exists = $err && $err =~ /Not Found/ ? 0 : 1;
    [200, "OK", $exists, {'cmdline.exit_code' => $exists ? 0:1}];
}

$SPEC{list_repos} = {
    v => 1.1,
    summary => "List user's repositories",
    args => {
        %args_common,
        %argopt_detail,
        start => {
            schema => 'nonnegint*',
            default => 0,
        },
    },
};
sub list_repos {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    my @repos = $github->repos->list($args{start});
    unless ($args{detail}) {
        @repos = map { $_->{name} } @repos;
    }
    [200, "OK", \@repos];
}

$SPEC{create_repo} = {
    v => 1.1,
    summary => 'Create a repository',
    args => {
        %args_common,
        %arg0_repo,
        description => {
            schema => 'str*',
        },
        homepage => {
            schema => 'url*',
        },
    },
};
sub create_repo {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    my $repo = $github->repos->create({
        name => $args{repo},
        description => $args{description} // '(No description)',
        homepage    => $args{homepage} ? "$args{homepage}" : 'https://github.com',
    });
    [200, "OK", $repo];
}

$SPEC{delete_repo} = {
    v => 1.1,
    args => {
        %args_common,
        %argopt_user,
        %arg0_repo,
    },
};
sub delete_repo {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    $github->repos->delete($args{user} // $args{login}, $args{repo});
    [200, "OK"];
}

$SPEC{rename_repo} = {
    v => 1.1,
    summary => 'Rename a repository',
    args => {
        %args_common,
        %argopt_user,
        %arg0_repo,
        new_name => {
            schema => 'str*',
            req => 1,
            pos => 1,
        },
    },
};
sub rename_repo {
    my %args = @_;
    my $state = _init(\%args);
    my $github = $state->{github};

    my $rp;

    $rp = $github->repos->set_default_user_repo($args{user} // $args{login}, $args{repo});
    $rp = $github->repos->update({ name => $args{new_name} });
    [200, "OK", $rp];
}

1;
# ABSTRACT: Yet another github CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

App::github::cmd - Yet another github CLI

=head1 VERSION

This document describes version 0.007 of App::github::cmd (from Perl distribution App-github-cmd), released on 2019-07-27.

=head1 SYNOPSIS

Please see included script L<github-cmd>.

=head1 FUNCTIONS


=head2 create_repo

Usage:

 create_repo(%args) -> [status, msg, payload, meta]

Create a repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<description> => I<str>

=item * B<homepage> => I<url>

=item * B<login> => I<str>

=item * B<pass> => I<str>

=item * B<repo>* => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 delete_repo

Usage:

 delete_repo(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<login> => I<str>

=item * B<pass> => I<str>

=item * B<repo>* => I<str>

=item * B<user> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_repo

Usage:

 get_repo(%args) -> [status, msg, payload, meta]

Get information about a repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<login> => I<str>

=item * B<pass> => I<str>

=item * B<repo>* => I<str>

=item * B<user> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 get_user

Usage:

 get_user(%args) -> [status, msg, payload, meta]

Get information about a user.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<login> => I<str>

=item * B<pass> => I<str>

=item * B<user> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_repos

Usage:

 list_repos(%args) -> [status, msg, payload, meta]

List user's repositories.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<detail> => I<bool>

=item * B<login> => I<str>

=item * B<pass> => I<str>

=item * B<start> => I<nonnegint> (default: 0)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 rename_repo

Usage:

 rename_repo(%args) -> [status, msg, payload, meta]

Rename a repository.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<login> => I<str>

=item * B<new_name>* => I<str>

=item * B<pass> => I<str>

=item * B<repo>* => I<str>

=item * B<user> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 repo_exists

Usage:

 repo_exists(%args) -> [status, msg, payload, meta]

Check whether a repository exists.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<access_token> => I<str>

=item * B<login> => I<str>

=item * B<pass> => I<str>

=item * B<repo>* => I<str>

=item * B<user> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-github-cmd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-github-cmd>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-github-cmd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

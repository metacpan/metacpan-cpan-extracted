package App::PMUtils;

our $DATE = '2019-06-20'; # DATE
our $VERSION = '0.724'; # VERSION

use 5.010001;

our %SPEC;

our $arg_module_multiple = {
    schema => ['array*' => of=>'perl::modname*', min_len=>1],
    req    => 1,
    pos    => 0,
    greedy => 1,
    element_completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
};

our $arg_module_single = {
    schema => 'perl::modname*',
    req    => 1,
    pos    => 0,
    completion => sub {
        require Complete::Module;
        my %args = @_;
        Complete::Module::complete_module(word=>$args{word});
    },
};

$SPEC{pmpath} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl module',
    args => {
        module => $App::PMUtils::arg_module_multiple,
        all => {
            summary => 'Return all found files for each module instead of the first one',
            schema => 'bool',
            cmdline_aliases => {a=>{}},
        },
        abs => {
            summary => 'Absolutify each path',
            schema => 'bool',
            cmdline_aliases => {P=>{}},
        },
        pm => {
            schema => ['int*', min=>0],
            default => 1,
        },
        pmc => {
            schema => ['int*', min=>0],
            default => 0,
        },
        pod => {
            schema => ['int*', min=>0],
            default => 0,
        },
        prefix => {
            schema => ['int*', min=>0],
            default => 0,
        },
        dir => {
            summary => 'Show directory instead of path',
            description => <<'_',

Also, will return `.` if not found, so you can conveniently do this on a Unix
shell:

    % cd `pmpath -Pd Moose`

and it won't change directory if the module doesn't exist.

_
            schema  => ['bool', is=>1],
            cmdline_aliases => {d=>{}},
        },
    },
};
sub pmpath {
    require Module::Path::More;
    my %args = @_;

    my $mods = $args{module};
    my $res = [];
    my $found;

    for my $mod (@{$mods}) {
        my $mpath = Module::Path::More::module_path(
            module      => $mod,
            find_pm     => $args{pm},
            find_pmc    => $args{pmc},
            find_pod    => $args{pod},
            find_prefix => $args{prefix},
            abs         => $args{abs},
            all         => $args{all},
        );
        $found++ if $mpath;
        for (ref($mpath) eq 'ARRAY' ? @$mpath : ($mpath)) {
            if ($args{dir}) {
                require File::Spec;
                my ($vol, $dir, $file) = File::Spec->splitpath($_);
                $_ = $dir;
            }
            push @$res, @$mods > 1 ? {module=>$mod, path=>$_} : $_;
        }
    }

    if ($found) {
        [200, "OK", $res];
    } else {
        if ($args{dir}) {
            [200, "OK (not found)", "."];
        } else {
            [404, "No such module"];
        }
    }
}

$SPEC{pmdir} = do {
    my $meta = { %{ $SPEC{pmpath} } }; # shallow copy
    $meta->{summary} = "Get directory of locally installed Perl module/prefix";
    $meta->{description} = <<'_';

This is basically a shortcut for:

    % pmpath -Pd MODULE_OR_PREFIX_NAME

Sometimes I forgot that <prog:pmpath> has a `-d` option, and often intuitively
look for a <prog:pmdir> command.

_
    $meta->{args} = { %{ $SPEC{pmpath}{args} } }; # shalow copy
    delete $meta->{args}{all};
    delete $meta->{args}{dir};
    delete $meta->{args}{prefix};
    $meta;
};
sub pmdir {
    pmpath(@_, prefix=>1, dir=>1);
}

$SPEC{rel2mod} = {
    v => 1.1,
    summary => 'Convert release name (e.g. Foo-Bar-1.23.tar.gz) to '.
        'module name (Foo::Bar)',
    args => {
        releases => {
            #'x.name.is_plural' => 1,
            schema => ['array*', of=>'str*'],
            req => 1,
            pos => 0,
            greedy => 1,
            cmdline_src => 'stdin_or_args',
        },
    },
    result_naked => 1,
};
sub rel2mod {
    my %args = @_;

    #use DD; dd \%args;

    my @res;
    for (@{ $args{releases} }) {
        s!.+/!!; # remove directory path
        s/(.+)-v?\d.+/$1/;
        s/-/::/g;
        push @res, $_;
    }

    \@res;
}

1;
# ABSTRACT: Command-line utilities related to Perl modules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PMUtils - Command-line utilities related to Perl modules

=head1 VERSION

This document describes version 0.724 of App::PMUtils (from Perl distribution App-PMUtils), released on 2019-06-20.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to Perl
modules:

=over

=item * L<module-dir>

=item * L<pmbin>

=item * L<pmcat>

=item * L<pmchkver>

=item * L<pmcore>

=item * L<pmcost>

=item * L<pmdir>

=item * L<pmdoc>

=item * L<pmedit>

=item * L<pmgrep>

=item * L<pmhtml>

=item * L<pminfo>

=item * L<pmlatest>

=item * L<pmless>

=item * L<pmlines>

=item * L<pmlist>

=item * L<pmman>

=item * L<pmminversion>

=item * L<pmpath>

=item * L<pmstripper>

=item * L<pmuninst>

=item * L<pmversion>

=item * L<pmxs>

=item * L<podlist>

=item * L<podpath>

=item * L<pwd2mod>

=item * L<rel2mod>

=back

The main purpose of these utilities is tab completion.

=head1 FUNCTIONS


=head2 pmdir

Usage:

 pmdir(%args) -> [status, msg, payload, meta]

Get directory of locally installed Perl module/prefix.

This is basically a shortcut for:

 % pmpath -Pd MODULE_OR_PREFIX_NAME

Sometimes I forgot that L<pmpath> has a C<-d> option, and often intuitively
look for a L<pmdir> command.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abs> => I<bool>

Absolutify each path.

=item * B<module>* => I<array[perl::modname]>

=item * B<pm> => I<int> (default: 1)

=item * B<pmc> => I<int> (default: 0)

=item * B<pod> => I<int> (default: 0)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 pmpath

Usage:

 pmpath(%args) -> [status, msg, payload, meta]

Get path to locally installed Perl module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<abs> => I<bool>

Absolutify each path.

=item * B<all> => I<bool>

Return all found files for each module instead of the first one.

=item * B<dir> => I<bool>

Show directory instead of path.

Also, will return C<.> if not found, so you can conveniently do this on a Unix
shell:

 % cd C<pmpath -Pd Moose>

and it won't change directory if the module doesn't exist.

=item * B<module>* => I<array[perl::modname]>

=item * B<pm> => I<int> (default: 1)

=item * B<pmc> => I<int> (default: 0)

=item * B<pod> => I<int> (default: 0)

=item * B<prefix> => I<int> (default: 0)

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 rel2mod

Usage:

 rel2mod(%args) -> any

Convert release name (e.g. Foo-Bar-1.23.tar.gz) to module name (Foo::Bar).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<releases>* => I<array[str]>

=back

Return value:  (any)

=head1 FAQ

=for BEGIN_BLOCK: faq

=head2 What is the purpose of this distribution? Haven't other similar utilities existed?

For example, L<mpath> from L<Module::Path> distribution is similar to L<pmpath>
in L<App::PMUtils>, and L<mversion> from L<Module::Version> distribution is
similar to L<pmversion> from L<App::PMUtils> distribution, and so on.

True. The main point of these utilities is shell tab completion, to save
typing.

=for END_BLOCK: faq

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PMUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PMUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PMUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=for BEGIN_BLOCK: see_also

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

=for END_BLOCK: see_also

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

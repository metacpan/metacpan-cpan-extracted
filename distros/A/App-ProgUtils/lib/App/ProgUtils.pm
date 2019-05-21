package App::ProgUtils;

our $DATE = '2019-05-18'; # DATE
our $VERSION = '0.200'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our $_complete_program = sub {
    require Complete::File;
    require Complete::Program;
    require List::MoreUtils;

    my %args = @_;

    my $word = $args{word} // '';

    # combine all executables (including dirs) and programs in PATH
    my $c1 = Complete::File::complete_file(
        word   => $word,
        filter => sub { -x $_[0] },
        #ci    => 1, # convenience, not yet supported by C::U
    );
    my $c2 = Complete::Program::complete_program(
        word => $word,
        ci   => 1, # convenience
    );

    {
        words      => [ List::MoreUtils::uniq(sort(@$c1, @$c2)) ],
        path_sep   => '/',
    };
};

sub _search_program {
    require File::Which;

    my $prog = shift;
    if ($prog =~ m!/!) {
        return $prog;
    } else {
        return File::Which::which($prog) // $prog;
    }
}

$SPEC{list_all_programs_in_path} = {
    v => 1.1,
    summary => 'List all programs in PATH',
    args => {
        with_path => {
            schema => 'bool*',
            cmdline_aliases => {
                'x' => {is_flag=>1, summary => 'Show path of each program', code => sub { $_[0]{with_path} = 1 }},
            },
        },
    },
};
sub list_all_programs_in_path {
    my %args = @_;

    my $with_path = $args{with_path};

    my @dirs = split(($^O =~ /Win32/ ? qr/;/ : qr/:/), $ENV{PATH});
    my @all_progs;
    for my $dir (@dirs) {
        opendir my($dh), $dir or next;
        for (readdir($dh)) {
            push @all_progs, ($with_path ? "$dir/$_" : $_)
                if !(-d "$dir/$_") && (-x _);
        }
    }

    [200, "OK", \@all_progs];
}

1;
# ABSTRACT: Command line to manipulate programs in PATH

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProgUtils - Command line to manipulate programs in PATH

=head1 VERSION

This document describes version 0.200 of App::ProgUtils (from Perl distribution App-ProgUtils), released on 2019-05-18.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
programs found in PATH:

=over

=item * L<allprogs>

=item * L<list-all-programs-in-path>

=item * L<progcat>

=item * L<progedit>

=item * L<progless>

=item * L<proglist>

=item * L<progman>

=item * L<progpath>

=back

The main feature of these utilities is tab completion.

=head1 FUNCTIONS


=head2 list_all_programs_in_path

Usage:

 list_all_programs_in_path(%args) -> [status, msg, payload, meta]

List all programs in PATH.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<with_path> => I<bool>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
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

Please visit the project's homepage at L<https://metacpan.org/release/App-ProgUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ProgUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ProgUtils>

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

L<Complete::Program>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

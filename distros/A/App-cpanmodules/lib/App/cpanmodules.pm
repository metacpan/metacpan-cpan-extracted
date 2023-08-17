package App::cpanmodules;

use 5.010001;
use strict 'subs', 'vars';
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-17'; # DATE
our $DIST = 'App-cpanmodules'; # DIST
our $VERSION = '0.007'; # VERSION

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'The Acme::CPANModules CLI',
};

sub _complete_module {
    require Complete::Module;
    my %args = @_;

    Complete::Module::complete_module(
        %args,
        ns_prefix => 'Acme::CPANModules',
    );
}

my %arg0_module = (
    module => {
        schema => 'perl::modname*',
        cmdline_aliases => {m=>{}},
        completion => \&_complete_module,
        req => 1,
        pos => 0,
    },
);

my %args_filtering = (
    module => {
        schema => 'perl::modname*',
        cmdline_aliases => {m=>{}},
        completion => \&_complete_module,
        tags => ['category:filtering'],
    },
    mentions => {
        schema => ['perl::modname*'],
        tags => ['category:filtering'],
    },
);

my %args_related_and_alternate = (
    related => {
        summary => 'Filter based on whether entry is in related',
        'summary.alt.bool.yes' => 'Only list related entries',
        'summary.alt.bool.not' => 'Do not list related entries',
        schema => 'bool',
    },
    alternate => {
        summary => 'Filter based on whether entry is in alternate',
        'summary.alt.bool.yes' => 'Only list alternate entries',
        'summary.alt.bool.not' => 'Do not list alternate entries',
        schema => 'bool',
    },
);

my %arg_detail = (
    detail => {
        name => 'Return detailed records instead of just module name',
        schema => 'bool',
        cmdline_aliases => {l=>{}},
    },
);

$SPEC{list_acmemods} = {
    v => 1.1,
    summary => 'List all installed Acme::CPANModules modules',
    args => {
        %args_filtering,
        %arg_detail,
    },
};
sub list_acmemods {
    require Module::List::Tiny;

    my %args = @_;

    my $res = Module::List::Tiny::list_modules(
        'Acme::CPANModules::', {list_modules=>1, recurse=>1});

    my @res;
    for my $e (sort keys %$res) {
        my $list;
      READ: {
            last unless $args{detail} || $args{mentions};
            (my $e_pm = "$e.pm") =~ s!::!/!g;
            require $e_pm;
            $list = ${"$e\::LIST"};
        }
        $e =~ s/^Acme::CPANModules:://;
      FILTER: {
            if ($args{module}) {
                next unless $args{module} eq $e;
            }
            if ($args{mentions}) {
                my @mods_in_list =
                    grep {defined}
                    map {($_->{module}, @{$_->{related_modules} || []}, @{$_->{alternate_modules} || []}, )}
                    @{$list->{entries}};
                next unless grep { $_ eq $args{mentions} } @mods_in_list;
            }
        }
        if ($args{detail}) {
            my $has_benchmark = 0;
          L1:
            for my $entry (@{ $list->{entries} }) {
                if (grep {/^bench_/} keys %$entry) {
                    $has_benchmark = 1;
                    last L1;
                }
            }
            push @res, {
                acmemod => $e,
                summary => $list->{summary},
                num_entries => scalar(@{ $list->{entries} }),
                has_benchmark => $has_benchmark,
            };
        } else {
            push @res, $e;
        }
    }

    [200, "OK", \@res];
}

$SPEC{get_acmemod} = {
    v => 1.1,
    summary => 'Get contents of an Acme::CPANModules module',
    args => {
        %arg0_module,
    },
};
sub get_acmemod {
    my %args = @_;

    my $mod = "Acme::CPANModules::$args{module}";
    (my $mod_pm = "$mod.pm") =~ s!::!/!g;
    require $mod_pm;

    my $list = ${"$mod\::LIST"};

    [200, "OK", $list];
}

$SPEC{view_acmemod} = {
    v => 1.1,
    summary => 'View an Acme::CPANModules module as rendered POD',
    args => {
        %arg0_module,
    },
};
sub view_acmemod {
    require Pod::From::Acme::CPANModules;

    my %args = @_;

    my $res = get_acmemod(%args);
    return $res unless $res->[0] == 200;
    my $list = $res->[2];

    my %podargs;
    $podargs{list} = $list;
    my $podres = Pod::From::Acme::CPANModules::gen_pod_from_acme_cpanmodules(
        %podargs);

    my $pod = $podres->{pod}{DESCRIPTION};
    if ($list->{'x.app.cpanmodules.show_entries'} // 1) {
        $pod .= $podres->{pod}{'INCLUDED MODULES'};
    }
    [200, "OK", $pod, {
        "cmdline.page_result"=>1,
        "cmdline.pager"=>"pod2man | man -l -"}];
}

$SPEC{list_entries} = {
    v => 1.1,
    summary => 'List entries from an Acme::CPANModules module',
    args => {
        %arg0_module,
        %arg_detail,
        with_attrs => {
            'x.name.is_plural' => 1,
            'x.name.singular' => 'with_attr',
            summary => 'Include additional attributes from each entry',
            schema => ['array*', of=>'str*'],
        },
    },
};
sub list_entries {
    my %args = @_;

    my $res = get_acmemod(%args);
    return $res unless $res->[0] == 200;
    my $list = $res->[2];

    my $attrs = $args{with_attrs} // [];

    my @rows;
    for my $e (@{ $list->{entries} }) {
        my $mod = $e->{module};
        my $row = {
            module => $mod,
            summary => $e->{summary},
            rating => $e->{rating},
        };
        for (@$attrs) {
            $row->{$_} = $e->{$_};
        }
        push @rows, $row;
    } # for each entry

    my $detail = $args{detail} || @$attrs;

    unless ($detail) {
        @rows = map {$_->{module}} @rows;
    }

    [200, "OK", \@rows];
}


1;
# ABSTRACT: The Acme::CPANModules CLI

__END__

=pod

=encoding UTF-8

=head1 NAME

App::cpanmodules - The Acme::CPANModules CLI

=head1 VERSION

This document describes version 0.007 of App::cpanmodules (from Perl distribution App-cpanmodules), released on 2023-06-17.

=head1 SYNOPSIS

Use the included script L<cpanmodules>.

=head1 OBSERVED CPANMODULES PROPERTIES/ATTRIBUTES

=head2 x.app.cpanmodules.show_entries

Boolean. Default is true. If set to false, will not show entries in the
generated POD's Description.

=head1 FUNCTIONS


=head2 get_acmemod

Usage:

 get_acmemod(%args) -> [$status_code, $reason, $payload, \%result_meta]

Get contents of an Acme::CPANModules module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_acmemods

Usage:

 list_acmemods(%args) -> [$status_code, $reason, $payload, \%result_meta]

List all installed Acme::CPANModules modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<mentions> => I<perl::modname>

(No description)

=item * B<module> => I<perl::modname>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_entries

Usage:

 list_entries(%args) -> [$status_code, $reason, $payload, \%result_meta]

List entries from an Acme::CPANModules module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

(No description)

=item * B<module>* => I<perl::modname>

(No description)

=item * B<with_attrs> => I<array[str]>

Include additional attributes from each entry.


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 view_acmemod

Usage:

 view_acmemod(%args) -> [$status_code, $reason, $payload, \%result_meta]

View an Acme::CPANModules module as rendered POD.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<module>* => I<perl::modname>

(No description)


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

Please visit the project's homepage at L<https://metacpan.org/release/App-cpanmodules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-cpanmodules>.

=head1 SEE ALSO

L<Acme::CPANModules>

L<App::CPANModulesUtils> provides some other CLI's related to Acme::CPANModules.

L<lcpan> also has some subcommands (supplied by
L<App::lcpan::CmdBundle::cpanmodules>) to query Acme::CPANModules modules.

L<App::CPANAuthorsUtils> for L<Acme::CPANAuthors>

L<TableData::Acme::CPANModules>

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

This software is copyright (c) 2023, 2020, 2019, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-cpanmodules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

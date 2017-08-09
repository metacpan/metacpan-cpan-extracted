package App::PerlCriticUtils;

our $DATE = '2017-08-02'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

our %arg_policies = (
    policies => {
        schema => ['array*' => of=>'perl::modname*', min_len=>1],
        req    => 1,
        pos    => 0,
        greedy => 1,
        element_completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                ns_prefix=>'Perl::Critic::Policy', word=>$args{word});
        },
    },
);

our %arg_policy = (
    policy => {
        schema => 'perl::modname*',
        req    => 1,
        pos    => 0,
        completion => sub {
            require Complete::Module;
            my %args = @_;
            Complete::Module::complete_module(
                ns_prefix=>'Perl::Critic::Policy', word=>$args{word});
        },
    },
);

$SPEC{pcppath} = {
    v => 1.1,
    summary => 'Get path to locally installed Perl::Critic policy module',
    args => {
        %arg_policies,
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcppath {
    require Module::Path::More;
    my %args = @_;

    my $policies = $args{policies};
    my $res = [];
    my $found;

    for my $policy (@{$policies}) {
        my $mpath = Module::Path::More::module_path(
            module      => "Perl::Critic::Policy::$policy",
        );
        $found++ if $mpath;
        for (ref($mpath) eq 'ARRAY' ? @$mpath : ($mpath)) {
            push @$res, @$policies > 1 ? {policy=>$policy, path=>$_} : $_;
        }
    }

    if ($found) {
        [200, "OK", $res];
    } else {
        [404, "No such module"];
    }
}

$SPEC{pcpless} = {
    v => 1.1,
    summary => 'Show Perl::Critic policy module source code with `less`',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'less',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpless {
    require Module::Path::More;
    my %args = @_;
    my $policy = $args{policy};
    my $mpath = Module::Path::More::module_path(
        module => "Perl::Critic::Policy::$policy",
        find_pmc=>0, find_pod=>0, find_prefix=>0);
    if (defined $mpath) {
        system "less", $mpath;
        [200, "OK"];
    } else {
        [404, "Can't find policy $policy"];
    }
}

$SPEC{pcpcat} = {
    v => 1.1,
    summary => 'Print Perl::Critic policy module source code',
    args => {
        %arg_policies,
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpcat {
    require Module::Path::More;

    my %args = @_;
    my $policies = $args{policies};
    return [400, "Please specify at least one policy"] unless @$policies;

    my $has_success;
    my $has_error;
    for my $policy (@$policies) {
        my $path = Module::Path::More::module_path(
            module=>"Perl::Critic::Policy::$policy", find_pod=>0) or do {
                warn "pcpcat: No such policy '$policy'\n";
                $has_error++;
                next;
            };
        open my $fh, "<", $path or do {
            warn "pcpcat: Can't open '$path': $!\n";
            $has_error++;
            next;
        };
        print while <$fh>;
        close $fh;
        $has_success++;
    }

    if ($has_error) {
        if ($has_success) {
            return [207, "Some policies failed"];
        } else {
            return [500, "All policies failed"];
        }
    } else {
        return [200, "All policies OK"];
    }
}

$SPEC{pcpdoc} = {
    v => 1.1,
    summary => 'Show documentation of Perl::Critic policy module',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'perldoc',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpdoc {
    my %args = @_;
    my $policy = $args{policy};
    my @cmd = ("perldoc", "Perl::Critic::Policy::$policy");
    exec @cmd;
    # [200]; # unreachable
}

$SPEC{pcpman} = {
    v => 1.1,
    summary => 'Show manpage of Perl::Critic policy module',
    args => {
        %arg_policy,
    },
    deps => {
        prog => 'man',
    },
    examples => [
        {
            argv => ['Variables/ProhibitMatchVars'],
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub pcpman {
    my %args = @_;
    my $policy = $args{policy};
    my @cmd = ("man", "Perl::Critic::Policy::$policy");
    exec @cmd;
    # [200]; # unreachable
}

1;
# ABSTRACT: Command-line utilities related to Perl::Critic

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PerlCriticUtils - Command-line utilities related to Perl::Critic

=head1 VERSION

This document describes version 0.001 of App::PerlCriticUtils (from Perl distribution App-PerlCriticUtils), released on 2017-08-02.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
Perl::Critic:

=over

=item * L<pcpcat>

=item * L<pcpdoc>

=item * L<pcpless>

=item * L<pcpman>

=item * L<pcppath>

=back

=head1 FUNCTIONS


=head2 pcpcat

Usage:

 pcpcat(%args) -> [status, msg, result, meta]

Print Perl::Critic policy module source code.

Examples:

=over

=item * Example #1:

 pcpcat( policies => ["Variables/ProhibitMatchVars"]);

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policies>* => I<array[perl::modname]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pcpdoc

Usage:

 pcpdoc(%args) -> [status, msg, result, meta]

Show documentation of Perl::Critic policy module.

Examples:

=over

=item * Example #1:

 pcpdoc( policy => "Variables/ProhibitMatchVars");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policy>* => I<perl::modname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pcpless

Usage:

 pcpless(%args) -> [status, msg, result, meta]

Show Perl::Critic policy module source code with `less`.

Examples:

=over

=item * Example #1:

 pcpless( policy => "Variables/ProhibitMatchVars");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policy>* => I<perl::modname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pcpman

Usage:

 pcpman(%args) -> [status, msg, result, meta]

Show manpage of Perl::Critic policy module.

Examples:

=over

=item * Example #1:

 pcpman( policy => "Variables/ProhibitMatchVars");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policy>* => I<perl::modname>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 pcppath

Usage:

 pcppath(%args) -> [status, msg, result, meta]

Get path to locally installed Perl::Critic policy module.

Examples:

=over

=item * Example #1:

 pcppath( policies => ["Variables/ProhibitMatchVars"]);

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<policies>* => I<array[perl::modname]>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PerlCriticUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PerlCriticUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PerlCriticUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

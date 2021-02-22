package App::lcpan::Cmd::core_or_pp;

our $DATE = '2021-02-13'; # DATE
our $VERSION = '0.051'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require App::lcpan;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'Check that a module (with its prereqs) are all core/PP',
    args => {
        %App::lcpan::common_args,
        %App::lcpan::mods_args,
        with_prereqs => {
            schema => ['bool*', is=>1],
        },
        with_recursive_prereqs => {
            schema => ['bool*', is=>1],
        },
        core => {
            schema => ['bool*', is=>1],
        },
        pp => {
            schema => ['bool*', is=>1],
        },
        core_or_pp => {
            schema => ['bool*', is=>1],
        },
    },
    args_rels => {
        'choose_one&' => [
            [qw/with_prereqs with_recursive_prereqs/],
            [qw/core pp core_or_pp/],
        ],
    },
};
sub handle_cmd {
    require Module::CoreList::More;
    require Module::Path::More;
    require Module::XSOrPP;

    my %args = @_;

    my $with_prereqs = delete $args{with_prereqs};
    my $with_recursive_prereqs = delete $args{with_recursive_prereqs};
    my $core       = delete $args{core};
    my $pp         = delete $args{pp};
    my $core_or_pp = delete($args{core_or_pp}) // 1;
    my $mods0      = delete $args{modules};

    my $mods = {};
    if ($with_prereqs || $with_recursive_prereqs) {
        require App::lcpan::Cmd::mod2dist;

        my $res;
        $res = App::lcpan::Cmd::mod2dist::handle_cmd(%args, modules=>$mods0);
        #log_trace "mod2dist result: %s", $res;
        return [500, "Can't mod2dist: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;
        my $dists = ref($res->[2]) eq 'HASH' ? [sort keys %{$res->[2]}] : [$res->[2]];
        #log_trace "dists=%s", $dists;

        $res = App::lcpan::deps(
            %args,
            dists => $dists,
            (level => -1) x !!$with_recursive_prereqs,
        );
        return [500, "Can't deps: $res->[0] - $res->[1]"]
            unless $res->[0] == 200;

        for my $e (@{ $res->[2] }) {
            $e->{module} =~ s/^\s+//;
            $mods->{$e->{module}} = $e->{version};
            #log_trace "Added %s (%s) to list of modules to check",
            #    $e->{module}, $e->{version};
        }
        $mods->{$_} //= 0 for @$mods0;
    } else {
        $mods->{$_} = 0 for @$mods0;
    }

    my $what;
    my @errs;
  MOD:
    for my $mod (sort keys %$mods) {
        next if $mod eq 'perl'; # XXX check perl version
        my $v = $mods->{version};
        my $subject = "$mod".($v ? " (version $v)" : "");
        log_trace("Checking %s ...", $subject);
        if ($core) {
            $what //= "core";
            if (!Module::CoreList::More->is_still_core($mod, $v)) {
                push @errs, "$subject is not core";
            }
        } elsif ($pp) {
            $what //= "PP";
            if (!Module::Path::More::module_path(module => $mod)) {
                push @errs, "$subject is not installed, so can't check XS/PP";
                # XXX check installed module version
            } elsif (!Module::XSOrPP::is_pp($mod)) {
                push @errs, "$subject is not $what";
            }
        } else {
            $what //= "core/PP";
            if (Module::CoreList::More->is_still_core($mod, $v)) {
                next MOD;
            } elsif (!Module::Path::More::module_path(module => $mod)) {
                push @errs, "$subject is not installed, so can't check XS/PP";
                # XXX check installed module version
            } elsif (!Module::XSOrPP::is_pp($mod)) {
                push @errs, "$subject is not $what";
            }
        }
    }

    if (@errs) {
        return [200, "OK", 0, {
            'func.errors' => \@errs,
            "cmdline.result" => join("\n", @errs),
            "cmdline.exit_code" => 1,
        }];
    } else {
        return [200, "OK", 1, {
            "cmdline.result" => "All modules".
                ($with_recursive_prereqs ? " with their recursive prereqs" :
                     $with_prereqs ? " with their prereqs" : "")." are $what",
        }];
    }
}

1;
# ABSTRACT: Check that a module (with its prereqs) are all core/PP

__END__

=pod

=encoding UTF-8

=head1 NAME

App::lcpan::Cmd::core_or_pp - Check that a module (with its prereqs) are all core/PP

=head1 VERSION

This document describes version 0.051 of App::lcpan::Cmd::core_or_pp (from Perl distribution App-lcpan-CmdBundle-core_or_pp), released on 2021-02-13.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<core-or-pp>.

=head1 FUNCTIONS


=head2 handle_cmd

Usage:

 handle_cmd(%args) -> [status, msg, payload, meta]

Check that a module (with its prereqs) are all coreE<sol>PP.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<core> => I<bool>

=item * B<core_or_pp> => I<bool>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. E<sol>pathE<sol>toE<sol>cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

If C<index_name> is a filename without any path, e.g. C<index.db> then index will
be located in the top-level of C<cpan>. If C<index_name> contains a path, e.g.
C<./index.db> or C</home/ujang/lcpan.db> then the index will be located solely
using the C<index_name>.

=item * B<modules>* => I<array[perl::modname]>

=item * B<pp> => I<bool>

=item * B<use_bootstrap> => I<bool> (default: 1)

Whether to use bootstrap database from App-lcpan-Bootstrap.

If you are indexing your private CPAN-like repository, you want to turn this
off.

=item * B<with_prereqs> => I<bool>

=item * B<with_recursive_prereqs> => I<bool>


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

Please visit the project's homepage at L<https://metacpan.org/release/App-lcpan-CmdBundle-core_or_pp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-lcpan-CmdBundle-core_or_pp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-lcpan-CmdBundle-core_or_pp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

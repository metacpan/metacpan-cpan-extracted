package App::lcpan::Cmd::core_or_pp;

our $DATE = '2017-01-20'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

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

    my $mods = {};
    if ($with_prereqs || $with_recursive_prereqs) {
        my $res = App::lcpan::deps(
            %args,
            (level => -1) x !!$with_recursive_prereqs,
        );
        return $res unless $res->[0] == 200;
        for my $e (@{ $res->[2] }) {
            $e->{module} =~ s/^\s+//;
            $mods->{$e->{module}} = $e->{version};
        }
        $mods->{$_} //= 0 for @{ $args{modules} };
    } else {
        $mods->{$_} = 0 for @{ $args{modules} };
    }

    my $what;
    my @errs;
  MOD:
    for my $mod (sort keys %$mods) {
        next if $mod eq 'perl'; # XXX check perl version
        my $v = $mods->{version};
        my $subject = "$mod".($v ? " (version $v)" : "");
        $log->tracef("Checking %s ...", $subject);
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

This document describes version 0.03 of App::lcpan::Cmd::core_or_pp (from Perl distribution App-lcpan-CmdBundle-core_or_pp), released on 2017-01-20.

=head1 DESCRIPTION

This module handles the L<lcpan> subcommand C<core-or-pp>.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

Check that a module (with its prereqs) are all core/PP.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<core> => I<bool>

=item * B<core_or_pp> => I<bool>

=item * B<cpan> => I<dirname>

Location of your local CPAN mirror, e.g. /path/to/cpan.

Defaults to C<~/cpan>.

=item * B<index_name> => I<filename> (default: "index.db")

Filename of index.

=item * B<modules>* => I<array[perl::modname]>

=item * B<pp> => I<bool>

=item * B<with_prereqs> => I<bool>

=item * B<with_recursive_prereqs> => I<bool>

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

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

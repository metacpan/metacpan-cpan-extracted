package App::PDRUtils::DistIniCmd::list_prereqs;

our $DATE = '2016-12-28'; # DATE
our $VERSION = '0.09'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG '$log';

use App::PDRUtils::Cmd;
use App::PDRUtils::DistIniCmd;

our %SPEC;

$SPEC{handle_cmd} = {
    v => 1.1,
    summary => 'List prereqs from `[Prereqs/*]` sections',
    description => <<'_',

This command list prerequisites found in `[Prereqs/*]` sections in your
`dist.ini`.

_
    args => {
        %App::PDRUtils::DistIniCmd::common_args,
        module => {
            summary => 'Module name',
            schema => ['perl::modname*'],
            tags => ['category:filtering'],
        },
        phase => {
            schema => ['str*', in=>[qw/configure build test runtime develop/]],
            tags => ['category:filtering'],
        },
        rel => {
            schema => ['str*', in=>[qw/requires recommends suggests conflicts/]],
            tags => ['category:filtering'],
        },
        detail => {
            schema => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub handle_cmd {
    my %fargs = @_;

    my $iod = $fargs{parsed_dist_ini};
    my $hoh = $iod->dump;

    my @res;
    for my $sect (sort keys %$hoh) {
        next unless $sect =~ m!\A
                               Prereqs
                               (?:\s*/\s*(.+))?
                               \z!x;
        my $plugin_name = $1;
        my ($phase, $rel);
        if ($plugin_name &&
                $plugin_name =~ /\A(Configure|Build|Test|Runtime|Develop)
                                 (Requires|Recommends|Suggests|Conflicts)\z/x) {
            $phase = $1;
            $rel   = $2;
        }

        my $prereqs = $hoh->{$sect};
        for (keys %$prereqs) {
            if (/^-phase$/) {
                $phase = delete $prereqs->{$_};
            }
            if (/^-(relationship|type)$/) {
                $rel = delete $prereqs->{$_};
            }
        }

        $phase //= "runtime";
        $rel   //= "requires";

        if (defined $fargs{phase}) {
            next unless lc($fargs{phase}) eq lc($phase);
        }
        if (defined $fargs{rel}) {
            next unless lc($fargs{rel}) eq lc($rel);
        }

        for my $mod (sort keys %$prereqs) {
            my $version = $prereqs->{$mod};
            if (defined $fargs{module}) {
                next unless $fargs{module} eq $mod;
            }
            push @res, {
                module  => $mod,
                version => $version,
                phase   => lc $phase,
                rel     => lc $rel,
            };
        }
    }

    if ($fargs{detail}) {
        return [304, "Not modified", $iod, {
            'func.result' => \@res,
            'table.fields' => [qw/module version phase rel/],
        }];
    } else {
        @res = map { $_->{module} } @res;
        return [304, "Not modified", $iod, {
            'func.result' => \@res,
        }];
    }
}

1;
# ABSTRACT: List prereqs from `[Prereqs/*]` sections

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PDRUtils::DistIniCmd::list_prereqs - List prereqs from `[Prereqs/*]` sections

=head1 VERSION

This document describes version 0.09 of App::PDRUtils::DistIniCmd::list_prereqs (from Perl distribution App-PDRUtils), released on 2016-12-28.

=head1 FUNCTIONS


=head2 handle_cmd(%args) -> [status, msg, result, meta]

List prereqs from `[Prereqs/*]` sections.

This command list prerequisites found in C<[Prereqs/*]> sections in your
C<dist.ini>.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>

=item * B<module> => I<perl::modname>

Module name.

=item * B<parsed_dist_ini>* => I<obj>

=item * B<phase> => I<str>

=item * B<rel> => I<str>

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

Please visit the project's homepage at L<https://metacpan.org/release/App-PDRUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PDRUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PDRUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

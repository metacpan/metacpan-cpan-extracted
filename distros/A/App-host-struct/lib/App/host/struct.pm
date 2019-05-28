package App::host::struct;

our $DATE = '2019-05-24'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use IPC::System::Options 'system', -log=>1;
use List::Util qw(uniqstr);

our %SPEC;

$SPEC{host_struct} = {
    v => 1.1,
    summary => 'host alternative that returns data structure',
    args => {
        action => {
            schema  => ['str*', in=>[
                'resolve',
                'resolve-ns-address',
                'resolve-mx-address',
            ]],
            default => 'resolve',
        },
        type => {
            schema => 'str*',
            cmdline_aliases => {t=>{}},
        },
        name => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
        server => {
            schema => 'str*',
            pos => 1,
        },
    },
    examples => [
    ],
    description => <<'_',

Early release.

_
};
sub host_struct {
    my %args = @_;

    my $action = $args{action} // 'resolve-mx-address';
    my $type = $args{type} //
        ($action =~ /^resolve-(\w+)-address$/ ? $1 : 'a');

    if ($action =~ /^resolve/) {
        return [412, "For action=resolve-$1-address, type must be $1"]
            if $action =~ /^resolve-(\w+)-address$/ && $type ne $1;

        my ($out, $err);
        system(
            {capture_stdout => \$out, capture_stderr => \$err},
            "host", "-t", $type, $args{name},
            (defined $args{server} ? ($args{server}) : ()),
        );
        log_warn "host: $err" if $err;

        my @res;
        if ($type eq 'a') {
            push @res, $1 while $out =~ / has address (.+)$/gm;
        } elsif ($type eq 'ns') {
            push @res, $1 while $out =~ / name server (.+)\.$/gm;
        } elsif ($type eq 'mx') {
            push @res, $1 while $out =~ / is handled by \d+ (.+)\.$/gm;
        } else {
            return [412, "Don't know yet how to parse type=$type"];
        }

        if ($action =~ /-address$/) {
            my @a;
            for my $n (@res) {
                system(
                    {capture_stdout => \$out, capture_stderr => \$err},
                    "host", "-t", "a", $n,
                );
                log_warn "host: $err" if $err;
                push @a, $1 while $out =~ / has address (.+)$/gm;
            }
            @res = @a;
        }

        return [200, "OK", [sort {$a cmp $b} (uniqstr @res)]];
    } else {
        return [400, "Unknown action '$action'"];
    }
}

1;
# ABSTRACT: host alternative that returns data structure

__END__

=pod

=encoding UTF-8

=head1 NAME

App::host::struct - host alternative that returns data structure

=head1 VERSION

This document describes version 0.001 of App::host::struct (from Perl distribution App-host-struct), released on 2019-05-24.

=head1 SYNOPSIS

See the included script L<host-struct>.

=head1 FUNCTIONS


=head2 host_struct

Usage:

 host_struct(%args) -> [status, msg, payload, meta]

host alternative that returns data structure.

Early release.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "resolve")

=item * B<name>* => I<str>

=item * B<server> => I<str>

=item * B<type> => I<str>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-host-struct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-host-struct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-host-struct>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Net::DNS>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

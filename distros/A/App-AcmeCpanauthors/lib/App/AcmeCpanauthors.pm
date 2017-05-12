package App::AcmeCpanauthors;

our $DATE = '2016-10-01'; # DATE
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _should_skip {
    local $_ = shift;
    # exclude known modules that do not contain list of CPAN authors
    return 1 if /\A(Utils\::.+|Utils|Factory|Register)\z/;
    0;
}

sub _list_installed {
    require Module::List;
    my $mods = Module::List::list_modules(
        "Acme::CPANAuthors::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
        });
    my @res;
    for my $ca0 (sort keys %$mods) {
        my $ca = $ca0;
        $ca =~ s/\AAcme::CPANAuthors:://;
        next if _should_skip($ca);
        push @res, {
            name => $ca,
        };
     }
    \@res;
}

$SPEC{acme_cpanauthors} = {
    v => 1.1,
    summary => 'Unofficial CLI for Acme::CPANAuthors',
    args => {
        action => {
            schema  => ['str*', in=>[
                'list_cpan', 'list_installed',
                'list_ids',
            ]],
            req => 1,
            cmdline_aliases => {
                list_cpan => {
                    summary => 'Shortcut for --action list_cpan',
                    is_flag => 1,
                    code    => sub { $_[0]{action} = 'list_cpan' },
                },
                L => {
                    summary => 'Shortcut for --action list_cpan',
                    is_flag => 1,
                    code    => sub { $_[0]{action} = 'list_cpan' },
                },
                list_installed => {
                    summary => 'Shortcut for --action list_installed',
                    is_flag => 1,
                    code    => sub { $_[0]{action} = 'list_installed' },
                },
                list_ids => {
                    summary => 'Shortcut for --action list_ids',
                    is_flag => 1,
                    code    => sub { $_[0]{action} = 'list_ids' },
                },
            },
        },
        module => {
            summary => 'Acme::CPANAuthors::* module name, without Acme::CPANAuthors:: prefix',
            schema => ['str*'],
            pos => 0,
            completion => sub {
                require Complete::Module;
                my %args = @_;
                my $res = Complete::Module::complete_module(
                    word => $args{word},
                    find_pod => 0,
                    find_prefix => 0,
                    ns_prefix => 'Acme::CPANAuthors',
                );
                $res->{words} = [grep {!_should_skip($_)} @{$res->{words}}];
            },
        },
        lcpan => {
            schema => 'bool',
            summary => 'Use local CPAN mirror first when available (for -L)',
        },
        detail => {
            summary => 'Display more information when listing modules/result',
            schema  => 'bool',
            cmdline_aliases => {l=>{}},
        },
    },
    examples => [
        {
            argv => [qw/--list-installed/],
            summary => 'List installed Acme::CPANAuthors::* modules',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/--list-cpan/],
            summary => 'List available Acme::CPANAuthors::* modules on CPAN',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/-L --lcpan/],
            summary => 'Like previous example, but use local CPAN mirror first',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/--list-ids Indonesian/],
            summary => "List PAUSE ID's of Indonesian authors",
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub acme_cpanauthors {
    my %args = @_;

    my $action = $args{action};
    my $detail = $args{detail};
    my $module = $args{module};

    if ($action eq 'list_installed') {

        my @res;
        for (@{ _list_installed() }) {
            if ($detail) {
                push @res, $_;
            } else {
                push @res, $_->{name};
            }
        }
        [200, "OK", \@res,
         {('cmdline.default_format' => 'text') x !!$detail}];

    } elsif ($action eq 'list_cpan') {

        my @methods = $args{lcpan} ?
            ('lcpan', 'metacpan') : ('metacpan', 'lcpan');

      METHOD:
        for my $method (@methods) {
            if ($method eq 'lcpan') {
                unless (eval { require App::lcpan::Call; 1 }) {
                    warn "App::lcpan::Call is not installed, skipped listing ".
                        "modules from local CPAN mirror\n";
                    next METHOD;
                }
                my $res = App::lcpan::Call::call_lcpan_script(
                    argv => [
                        qw/mods --namespace Acme::CPANAuthors/,
                        ("-l") x !!$detail,
                    ],
                );
                return $res if $res->[0] != 200;
                if ($detail) {
                    return [200, "OK",
                            [grep {!_should_skip($_->{module})}
                                 map {$_->{module} =~ s/\AAcme::CPANAuthors:://; $_}
                                     grep {$_->{module} =~ /Acme::CPANAuthors::/} sort @{$res->[2]}]];
                } else {
                    return [200, "OK",
                            [grep {!_should_skip($_)}
                                 map {s/\AAcme::CPANAuthors:://; $_}
                                     grep {/Acme::CPANAuthors::/} sort @{$res->[2]}]];
                }
            } elsif ($method eq 'metacpan') {
                unless (eval { require MetaCPAN::Client; 1 }) {
                    warn "MetaCPAN::Client is not installed, skipped listing ".
                        "modules from MetaCPAN\n";
                    next METHOD;
                }
                my $mcpan = MetaCPAN::Client->new;
                my $rs = $mcpan->module({
                        'module.name'=>'Acme::CPANAuthors::*',
                    });
                my @res;
                while (my $row = $rs->next) {
                    my $mod = $row->module->[0]{name};
                    say "D: mod=$mod" if $ENV{DEBUG};
                    $mod =~ s/\AAcme::CPANAuthors:://;
                    next if _should_skip($mod);
                    push @res, $mod unless grep {$mod eq $_} @res;
                }
                warn "Empty result from MetaCPAN\n" unless @res;
                return [200, "OK", [sort @res]];
            }
        }
        return [412, "Can't find a way to list CPAN mirrors"];

    } elsif ($action eq 'list_ids') {

        return [400, "Please specify module"] unless $module;

        require Acme::CPANAuthors;
        my $authors = Acme::CPANAuthors->new($module);
        [200, "OK", [$authors->id]];

    } else {

        [400, "Unknown action '$action'"];

    }
}

1;
# ABSTRACT: Unofficial CLI for Acme::CPANAuthors

__END__

=pod

=encoding UTF-8

=head1 NAME

App::AcmeCpanauthors - Unofficial CLI for Acme::CPANAuthors

=head1 VERSION

This document describes version 0.002 of App::AcmeCpanauthors (from Perl distribution App-AcmeCpanauthors), released on 2016-10-01.

=head1 SYNOPSIS

See the included script L<acme-cpanauthors>.

=head1 FUNCTIONS


=head2 acme_cpanauthors(%args) -> [status, msg, result, meta]

Unofficial CLI for Acme::CPANAuthors.

Examples:

=over

=item * List installed Acme::CPANAuthors::* modules:

 acme_cpanauthors( action => "list_installed");

=item * List available Acme::CPANAuthors::* modules on CPAN:

 acme_cpanauthors( action => "list_cpan");

=item * Like previous example, but use local CPAN mirror first:

 acme_cpanauthors( action => "list_cpan", lcpan => 1);

=item * List PAUSE ID's of Indonesian authors:

 acme_cpanauthors( module => "Indonesian", action => "list_ids");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action>* => I<str>

=item * B<detail> => I<bool>

Display more information when listing modules/result.

=item * B<lcpan> => I<bool>

Use local CPAN mirror first when available (for -L).

=item * B<module> => I<str>

Acme::CPANAuthors::* module name, without Acme::CPANAuthors:: prefix.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 ENVIRONMENT

=head2 DEBUG => bool

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-AcmeCpanauthors>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-AcmeCpanauthors>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-AcmeCpanauthors>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Acme::CPANAuthors> and C<Acme::CPANAuthors::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

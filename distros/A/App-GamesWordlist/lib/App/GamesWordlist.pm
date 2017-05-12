package App::GamesWordlist;

our $DATE = '2016-02-14'; # DATE
our $VERSION = '0.16'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _list_installed {
    require Module::List;
    my $mods = Module::List::list_modules(
        "Games::Word::Wordlist::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
        });
    my $modsp = Module::List::list_modules(
        "Games::Word::Phraselist::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
        });
    my $res = {}; # key=name, val=full module name
    for my $fullname (keys %$mods, keys(%$modsp)) {
        (my $shortname = $fullname) =~ s/^Games::Word::\w+list:://;
        if ($res->{$shortname}) {
            ($shortname = $fullname) =~ s/^Games::Word:://;
        }
        $res->{$shortname} = $fullname;
    }
    $res;
}

$SPEC{wordlist} = {
    v => 1.1,
    summary => 'Grep words from Games::Word::{Wordlist,Phraselist}::*',
    args => {
        arg => {
            schema => ['array*' => of => 'str*'],
            pos => 0,
            greedy => 1,
        },
        ignore_case => {
            schema  => 'bool',
            default => 1,
        },
        len => {
            schema  => 'int*',
        },
        min_len => {
            schema  => 'int*',
        },
        max_len => {
            schema  => 'int*',
        },
        wordlist => {
            schema => ['array*' => of => 'str*'],
            summary => 'Select one or more wordlist modules',
            cmdline_aliases => {w=>{}},
            element_completion => sub {
                require Complete::Util;

                my %args = @_;
                Complete::Util::complete_array_elem(
                    word  => $args{word},
                    array => [sort keys %{ _list_installed() }],
                    ci    => 1,
                );
            },
        },
        or => {
            summary => 'Use OR logic instead of the default AND',
            schema  => 'bool',
        },
        action => {
            schema  => ['str*', in=>[
                'list_cpan', 'list_installed', 'install', 'uninstall',
                'grep',
            ]],
            default => 'grep',
            cmdline_aliases => {
                l => {
                    summary=>'List installed Games::Word::Wordlist::* modules',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                L => {
                    summary=>'List Games::Word::Wordlist::* modules on CPAN',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_cpan' },
                },
                I => {
                    summary=>'Install Games::Word::Wordlist::* module',
                    code => sub { my $args=shift; $args->{action} = 'install' },
                },
                U => {
                    summary=>'Uninstall Games::Word::Wordlist::* module',
                    code => sub { my $args=shift; $args->{action} = 'uninstall' },
                },
            },
        },
        lcpan => {
            schema => 'bool',
            summary => 'Use local CPAN mirror first when available',
        },
        detail => {
            summary => 'Display more information when listing modules',
            schema  => 'bool',
        },
    },
    examples => [
        {
            argv => [],
            summary => 'By default print all words from all wordlists',
            test => 0,
            'x.doc.show_result' => 0, # too large & no need
        },
        {
            argv => [qw/foo bar/],
            summary => 'Print all words matching /foo/ and /bar/',
            test => 0,
            'x.doc.show_result' => 0, # no need
        },
        {
            argv => [qw/--or foo bar/],
            summary => 'Print all words matching /foo/ or /bar/',
            test => 0,
            'x.doc.show_result' => 0, # no need
        },
        {
            argv => [qw/-w KBBI foo/],
            summary => 'Select a specific wordlist (multiple -w allowed)',
            test => 0,
            'x.doc.show_result' => 0, # no need
        },
        {
            argv => [qw|/fof[aeiou]/|],
            summary => 'Filter by regex',
            test => 0,
            'x.doc.show_result' => 0, # no need
        },
    ],
    'cmdline.default_format' => 'text-simple',
};
sub wordlist {
    my %args = @_;

    my $action = $args{action} // 'grep';
    my $list_installed = _list_installed();
    my $ci = $args{ignore_case} // 1;
    my $or = $args{or};
    my $arg = $args{arg} // [];

    if ($action eq 'grep') {

        # convert /.../ in arg to regex
        for (@$arg) {
            if (m!\A/(.*)/\z!) {
                $_ = $ci ? qr/$1/i : qr/$1/;
            } else {
                $_ = lc($_) if $ci;
            }
        }

        my @res;
        my $wordlists = $args{wordlist};
        if (!$wordlists || !@$wordlists) {
            $wordlists = [sort keys %$list_installed];
        }
        for my $wl (@$wordlists) {
            my $mod = $list_installed->{$wl} or
                return [400, "Unknown wordlist '$wl', see 'wordlist -l' ".
                            "for list of installed wordlists"];
            (my $modpm = $mod . ".pm") =~ s!::!/!g;
            require $modpm;
            my $obj = $mod->new;
            $obj->each_word(
                sub {
                    my $word = shift;

                    return if defined($args{len}) &&
                        length($word) != $args{len};
                    return if defined($args{min_len}) &&
                        length($word) < $args{min_len};
                    return if defined($args{max_len}) &&
                        length($word) > $args{max_len};

                    my $cmpword = $ci ? lc($word) : $word;
                    for (@$arg) {
                        my $match =
                            ref($_) eq 'Regexp' ? $cmpword =~ $_ :
                                index($cmpword, $_) >= 0;
                        if ($or) {
                            # succeed early when --or
                            if ($match) {
                                push @res, $word;
                                return;
                            }
                        } else {
                            # fail early when and (the default)
                            if (!$match) {
                                return;
                            }
                        }
                    }
                    if (!$or || !@$arg) {
                        push @res, $word;
                    }
                }
            );
        }
        [200, "OK", \@res];

    } elsif ($action eq 'list_installed') {

        my @res;
        for (sort keys %$list_installed) {
            if ($args{detail}) {
                push @res, {
                    name   => $_,
                    module => $list_installed->{$_},
                };
            } else {
                push @res, $_;
            }
        }
        [200, "OK", \@res,
         {('cmdline.default_format' => 'text') x !!$args{detail}}];

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
                    argv => [qw/mods --namespace Games::Word::Wordlist
                                --namespace Games::Word::Phraselist/],
                );
                return $res unless $res->[0] == 200;
                return [200, "OK", [grep {/(Word|Phrase)list::/} sort @{$res->[2]}]];
            } elsif ($method eq 'metacpan') {
                unless (eval { require MetaCPAN::Client; 1 }) {
                    warn "MetaCPAN::Client is not installed, skipped listing ".
                        "modules from MetaCPAN\n";
                    next METHOD;
                }
                my $mcpan = MetaCPAN::Client->new;
                my $rs = $mcpan->module({
                    either => [
                        {'module.name'=>'Games::Word::Wordlist::*'},
                        {'module.name'=>'Games::Word::Phraselist::*'},
                    ]});
                my @res;
                while (my $row = $rs->next) {
                    my $mod = $row->module->[0]{name};
                    push @res, $mod unless grep {$mod eq $_} @res;
                }
                return [200, "OK", [sort @res]];
            }
        }
        return [412, "Can't find a way to list CPAN mirrors"];

    } elsif ($action eq 'install') {

        [501, "Not yet implemented"];

    } elsif ($action eq 'uninstall') {

        [501, "Not yet implemented"];

    } else {

        [400, "Unknown action '$action'"];

    }
}

1;
# ABSTRACT: Grep words from Games::Word::{Wordlist,Phraselist}::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::GamesWordlist - Grep words from Games::Word::{Wordlist,Phraselist}::*

=head1 VERSION

This document describes version 0.16 of App::GamesWordlist (from Perl distribution App-GamesWordlist), released on 2016-02-14.

=head1 SYNOPSIS

See the included script L<games-wordlist>.

=head1 FUNCTIONS


=head2 wordlist(%args) -> [status, msg, result, meta]

Grep words from Games::Word::{Wordlist,Phraselist}::*.

Examples:

=over

=item * By default print all words from all wordlists:

 wordlist();

=item * Print all words matching /foo/ and /bar/:

 wordlist( arg => ["foo", "bar"]);

=item * Print all words matching /foo/ or /bar/:

 wordlist( arg => ["foo", "bar"], or => 1);

=item * Select a specific wordlist (multiple -w allowed):

 wordlist( arg => ["foo"], wordlist => ["KBBI"]);

=item * Filter by regex:

 wordlist( arg => ["/fof[aeiou]/"]);

=back

This function is not exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "grep")

=item * B<arg> => I<array[str]>

=item * B<detail> => I<bool>

Display more information when listing modules.

=item * B<ignore_case> => I<bool> (default: 1)

=item * B<lcpan> => I<bool>

Use local CPAN mirror first when available.

=item * B<len> => I<int>

=item * B<max_len> => I<int>

=item * B<min_len> => I<int>

=item * B<or> => I<bool>

Use OR logic instead of the default AND.

=item * B<wordlist> => I<array[str]>

Select one or more wordlist modules.

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

Please visit the project's homepage at L<https://metacpan.org/release/App-GamesWordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-GamesWordlist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-GamesWordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::wordlist> which greps C<WordList::*> modules instead.

L<Games::Word::Wordlist>

L<Games::Word::Phraselist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

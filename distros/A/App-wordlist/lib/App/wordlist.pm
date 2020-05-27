package App::wordlist;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-24'; # DATE
our $DIST = 'App-wordlist'; # DIST
our $VERSION = '0.274'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use List::Util qw(shuffle);

our %SPEC;

our %arg_wordlists = (
    wordlists => {
        'x.name.is_plural' => 1,
        schema => ['array*' => {
            of => 'str*', # for the moment we need to use 'str' instead of 'perl::modname' due to Perinci::Sub::GetArgs::Argv limitation
            'x.perl.coerce_rules'=>[ ['From_str_or_array::expand_perl_modname_wildcard'=>{ns_prefix=>"WordList"}] ],
        }],
        summary => 'Select one or more wordlist modules',
        cmdline_aliases => {w=>{}},
        element_completion => sub {
            require Complete::Util;

            my %args = @_;
            Complete::Util::complete_array_elem(
                word  => $args{word},
                array => [map {$_->{name}} @{ _list_installed() }],
                ci    => 1,
            );
        },
    },
);

sub _length_in_graphemes {
    my $length = () = $_[0] =~ m/\X/g;
    return $length;
}

sub _list_installed {
    require Module::List;
    my $mods = Module::List::list_modules(
        "WordList::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
            return_path   => 1,
        });
    my @res;
    for my $wl0 (sort keys %$mods) {
        (my $wl = $wl0) =~ s/\AWordList:://;

        my $lang = '';
        if ($wl =~ /^(\w\w)::/) {
            $lang = $1;
        }

        push @res, {
            name => $wl,
            lang => $lang,
            path => $mods->{$wl0}{module_path},
        };
     }
    \@res;
}

$SPEC{wordlist} = {
    v => 1.1,
    summary => 'Grep words from WordList::*',
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
        num => {
            summary => 'Return (at most) this number of words (0 = unlimited)',
            schema  => ['int*', min=>0, max=>9999],
            default => 0,
            cmdline_aliases => {n=>{}},
        },
        random => {
            summary => 'Pick random words',
            description => <<'_',

If set to true, then streaming will be turned off. All words will be gathered
first, then words will be chosen randomly from the gathered list.

_
            schema  => 'bool*',
            cmdline_aliases => {r=>{}},
        },

        %arg_wordlists,
        or => {
            summary => 'Match any word in query instead of the default "all"',
            schema  => 'bool',
        },
        action => {
            schema  => ['str*', in=>[
                'list_cpan', 'list_installed',
                'grep', 'stat',
            ]],
            default => 'grep',
            cmdline_aliases => {
                l => {
                    summary=>'List installed WordList::* modules',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                L => {
                    summary=>'List WordList::* modules on CPAN',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_cpan' },
                },
                s => {
                    summary=>'Show statistics contained in the wordlist modules',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'stat' },
                },
            },
        },
        lcpan => {
            schema => 'bool',
            summary => 'Use local CPAN mirror first when available (for -L)',
        },
        detail => {
            summary => 'Display more information when listing modules/result',
            description => <<'_',

When listing installed modules (`-l`), this means also returning a wordlist's
language.

When returning grep result, this means also returning wordlist name.

_
            schema  => 'bool',
        },
        langs => {
            'x.name.is_plural' => 1,
            summary => 'Only include wordlists of certain language(s)',
            description => <<'_',

By convention, language code is the first subnamespace of a wordlist module,
e.g. WordList::EN::* for English, WordList::FR::* for French, and so on.
Wordlist modules which do not follow this convention (e.g. WordList::Password::*
or WordList::PersonName::*) are not included.

_
            schema => ['array*', of => ['str*', match => '\A\w\w\z']],
            element_completion => sub {
                my %args = @_;
                my @langs;
                for my $rec (@{ _list_installed() }) {
                    next unless length $rec->{lang};
                    push @langs, $rec->{lang}
                        unless grep {$_ eq $rec->{name}} @langs;
                }
                require Complete::Util;
                Complete::Util::complete_array_elem(
                    word => $args{word}, array => \@langs);
            },
        },
        color => {
            summary => 'When to highlight search string/matching pattern with color',
            schema => ['str*', in=>['never', 'always', 'auto']],
            default => 'auto',
        },
    },
    examples => [
        {
            argv => [],
            summary => 'By default print all words from all wordlists',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/foo bar/],
            summary => 'Print all words matching /foo/ and /bar/',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/--or foo bar/],
            summary => 'Print all words matching /foo/ or /bar/',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/--detail foo/],
            summary => 'Print wordlist name for each matching words',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/-w ID::KBBI foo/],
            summary => 'Select a specific wordlist (multiple -w allowed)',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/-w ID::** foo/],
            summary => 'Select all ID::* wordlists (wildcard will be expanded)',
            test => 0,
            'x.doc.show_result' => 0,
        },

        {
            argv => [qw/--lang FR foo/],
            summary => 'Select French wordlists (multiple --lang allowed)',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw|/fof[aeiou]/|],
            summary => 'Filter by regex',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/-l/],
            summary => 'List installed wordlist modules',
            test => 0,
            'x.doc.show_result' => 0,
        },
        {
            argv => [qw/-L/],
            summary => 'List wordlist modules available on CPAN',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
    'cmdline.default_format' => 'text-simple',
};
sub wordlist {
    require Encode;
    require WordListUtil::CLI;

    my %args = @_;

    my $action = $args{action} // 'grep';
    my $list_installed = _list_installed();
    my $ci = $args{ignore_case} // 1;
    my $or = $args{or};
    my $arg = $args{arg} // [];
    my $detail = $args{detail};
    my $num = $args{num} // 0;
    my $random = $args{random};
    my $color = $args{color} // 'auto';

    my $use_color = ($color eq 'always' ? 1 : $color eq 'never' ? 0 : undef)
        // $ENV{COLOR} // (-t STDOUT);

    if ($action eq 'grep' || $action eq 'stat') {
        # convert /.../ in arg to regex
        for (@$arg) {
            $_ = Encode::decode('UTF-8', $_);
            if (m!\A/(.*)/\z!) {
                $_ = $ci ? qr/$1/i : qr/$1/;
            } else {
                $_ = lc($_) if $ci;
            }
        }

        my @res;
        my $wordlists;
        if ($args{wordlists}) {
            $wordlists = $args{wordlists};
        } else {
            $wordlists = [];
            for my $rec (@$list_installed) {
                if ($args{langs} && @{ $args{langs} }) {
                    next unless grep { $rec->{lang} eq uc($_) } @{$args{langs}};
                }
                push @$wordlists, $rec->{name};
            }
        }

        $wordlists = [shuffle @$wordlists] if $random;
        log_trace "Wordlist(s) to use: %s", $wordlists;

        if ($action eq 'stat') {
            no strict 'refs';
            return [200] unless @$wordlists;
            my %all_stats;
            for my $wl (@$wordlists) {
                my $mod = "WordList::$wl"; $mod =~ s/=.*//;
                (my $modpm = "$mod.pm") =~ s!::!/!g;
                require $modpm;
                if (@$wordlists == 1) {
                    return [200, "OK", \%{"$mod\::STATS"}];
                } else {
                    $all_stats{$wl} = \%{"$mod\::STATS"};
                }
            }
            return [200, "OK", \%all_stats];
        }

        # optimize random picking when there's only one wordlist to pick from
        if ($random && @$wordlists == 1 && $num > 0 && $num <= 100) {
            my $wl_obj = WordListUtil::CLI::instantiate_wordlist($wordlists->[0]);
            return [200, "OK", [$wl_obj->pick($num)]];
        }

        my $n = 0;

        my $code_format_word = sub {
            my ($wl, $word, $highlight_str, $ci) = @_;
            #use DD; dd \@_;
            if (defined $highlight_str) {
                if (ref $highlight_str eq 'Regexp') {
                    $word =~ s/($highlight_str)/\e[1;31m$1\e[0m/g;
                } else {
                    if ($ci) {
                        $word =~ s/(\Q$highlight_str\E)/\e[1;31m$1\e[0m/gi;
                    } else {
                        $word =~ s/(\Q$highlight_str\E)/\e[1;31m$1\e[0m/g;
                    }
                }
            }
            $detail ? [$wl, $word] : $word;
        };

        my $i_wordlist = 0;
        my $nth_word;
        my $wl_obj;
        my $code_return_word = sub {
          REDO:
            return if $i_wordlist >= @$wordlists;
            my $wl = $wordlists->[$i_wordlist];
            unless ($wl_obj) {
                log_trace "Instantiating wordlist $wl ...";
                $wl_obj = WordListUtil::CLI::instantiate_wordlist($wl, 'ignore');
                unless ($wl_obj) {
                    $i_wordlist++;
                    goto REDO;
                }
                $nth_word = 0;
            }
            my $word = $nth_word++ ? $wl_obj->next_word : $wl_obj->first_word;
            unless (defined $word) {
                undef $wl_obj;
                $i_wordlist++;
                goto REDO;
            }

            goto REDO if !$random && $num > 0 && $n >= $num;
            goto REDO if defined($args{len}) &&
                _length_in_graphemes($word) != $args{len};
            goto REDO if defined($args{min_len}) &&
                _length_in_graphemes($word) < $args{min_len};
            goto REDO if defined($args{max_len}) &&
                _length_in_graphemes($word) > $args{max_len};

            my $cmpword = $ci ? lc($word) : $word;
            my $match_arg;
            for (@$arg) {
                my $match =
                    ref($_) eq 'Regexp' ? $cmpword =~ $_ :
                    index($cmpword, $_) >= 0;
                if ($or) {
                    # succeed early when --or
                    if ($match) {
                        $n++;
                        return $code_format_word->(
                            $wl, $word, $use_color ? $_ : undef, $ci);
                    }
                } else {
                    # fail early when and (the default)
                    if (!$match) {
                        goto REDO;
                    }
                }
                $match_arg = $_;
            }
            if (!$or || !@$arg) {
                $n++;
                return $code_format_word->(
                    $wl, $word, $use_color ? $match_arg : undef, $ci);
            }
        };
        my $res = [200, "OK", $code_return_word, {stream=>1}];

      RANDOMIZE: {
            last unless $random;
            require Array::Pick::Scan;

            my @words;
            if ($num > 0) {
                @words = Array::Pick::Scan::random_item($res->[2], $num);
            } else {
                while (defined(my $word = $res->[2]->())) { push @words, $word }
                @words = shuffle @words;
            }
            $res = [200, "OK", \@words];
        }

      RETURN_RES:
        $res;

    } elsif ($action eq 'list_installed') {

        my @res;
        for (@$list_installed) {
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
                    argv => [qw/mods --namespace WordList/],
                );
                return $res if $res->[0] != 200;
                return [200, "OK",
                        [map {my $w = $_; $w =~ s/\AWordList:://; $w }
                             grep {/WordList::/} sort @{$res->[2]}]];
            } elsif ($method eq 'metacpan') {
                unless (eval { require MetaCPAN::Client; 1 }) {
                    warn "MetaCPAN::Client is not installed, skipped listing ".
                        "modules from MetaCPAN\n";
                    next METHOD;
                }
                my $mcpan = MetaCPAN::Client->new;
                my $rs = $mcpan->module({
                        'module.name'=>'WordList::*',
                    });
                my @res;
                while (my $row = $rs->next) {
                    my $mod = $row->module->[0]{name};
                    say "D: mod=$mod" if $ENV{DEBUG};
                    $mod =~ s/\AWordList:://;
                    push @res, $mod unless grep {$mod eq $_} @res;
                }
                warn "Empty result from MetaCPAN\n" unless @res;
                return [200, "OK", \@res];
            }
        }
        return [412, "Can't find a way to list CPAN mirrors"];

    } else {

        [400, "Unknown action '$action'"];

    }
}

1;
# ABSTRACT: Grep words from WordList::*

__END__

=pod

=encoding UTF-8

=head1 NAME

App::wordlist - Grep words from WordList::*

=head1 VERSION

This document describes version 0.274 of App::wordlist (from Perl distribution App-wordlist), released on 2020-05-24.

=head1 SYNOPSIS

See the included script L<wordlist>.

=head1 FUNCTIONS


=head2 wordlist

Usage:

 wordlist(%args) -> [status, msg, payload, meta]

Grep words from WordList::*.

Examples:

=over

=item * By default print all words from all wordlists:

 wordlist();

=item * Print all words matching E<sol>fooE<sol> and E<sol>barE<sol>:

 wordlist( arg => ["foo", "bar"]);

=item * Print all words matching E<sol>fooE<sol> or E<sol>barE<sol>:

 wordlist( arg => ["foo", "bar"], or => 1);

=item * Print wordlist name for each matching words:

 wordlist( arg => ["foo"], detail => 1);

=item * Select a specific wordlist (multiple -w allowed):

 wordlist( arg => ["foo"], wordlists => ["ID::KBBI"]);

=item * Select all ID::* wordlists (wildcard will be expanded):

 wordlist( arg => ["foo"], wordlists => ["ID::**"]);

=item * Select French wordlists (multiple --lang allowed):

 wordlist( arg => ["foo"], langs => ["FR"]);

=item * Filter by regex:

 wordlist( arg => ["/fof[aeiou]/"]);

=item * List installed wordlist modules:

 wordlist( action => "list_installed");

=item * List wordlist modules available on CPAN:

 wordlist( action => "list_cpan");

=back

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "grep")

=item * B<arg> => I<array[str]>

=item * B<color> => I<str> (default: "auto")

When to highlight search stringE<sol>matching pattern with color.

=item * B<detail> => I<bool>

Display more information when listing modulesE<sol>result.

When listing installed modules (C<-l>), this means also returning a wordlist's
language.

When returning grep result, this means also returning wordlist name.

=item * B<ignore_case> => I<bool> (default: 1)

=item * B<langs> => I<array[str]>

Only include wordlists of certain language(s).

By convention, language code is the first subnamespace of a wordlist module,
e.g. WordList::EN::* for English, WordList::FR::* for French, and so on.
Wordlist modules which do not follow this convention (e.g. WordList::Password::*
or WordList::PersonName::*) are not included.

=item * B<lcpan> => I<bool>

Use local CPAN mirror first when available (for -L).

=item * B<len> => I<int>

=item * B<max_len> => I<int>

=item * B<min_len> => I<int>

=item * B<num> => I<int> (default: 0)

Return (at most) this number of words (0 = unlimited).

=item * B<or> => I<bool>

Match any word in query instead of the default "all".

=item * B<random> => I<bool>

Pick random words.

If set to true, then streaming will be turned off. All words will be gathered
first, then words will be chosen randomly from the gathered list.

=item * B<wordlists> => I<array[str]>

Select one or more wordlist modules.


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

=head2 DEBUG => bool

=head2 COLOR => bool

Set color on/off when --color=auto (the default).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-wordlist>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-wordlist>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-wordlist>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::GamesWordlist> (L<games-wordlist>) which greps from
C<Games::Word::Wordlist::*> instead.

L<WordList> and C<WordList::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

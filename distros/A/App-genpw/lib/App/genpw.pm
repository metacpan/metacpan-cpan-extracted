package App::genpw;

use 5.010001;
use strict;
use warnings;
use Log::ger;

# TODO: random shuffling/picking of words from wordlist is not cryptographically
# secure yet
use Random::Any 'rand', -warn => 1;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-16'; # DATE
our $DIST = 'App-genpw'; # DIST
our $VERSION = '0.013'; # VERSION

our %SPEC;

my $symbols            = [split //, q(~`!@#$%^&*()_-+={}[]|\\:;"'<>,.?/)];                          # %s
my $letters            = ["A".."Z","a".."z"];                                                       # %l
my $digits             = ["0".."9"];                                                                # %d
my $hexdigits          = ["0".."9","a".."f"];                                                       # %h
my $hexdigits_upper    = ["0".."9","A".."F"];                                                       # %h
my $letterdigits       = [@$letters, @$digits];                                                     # %a
my $letterdigitsymbols = [@$letterdigits, @$symbols];                                               # %x
my $base64characters   = ["A".."Z","a".."z","0".."9","+","/"];                                      # %m
my $base58characters   = [split //, q(ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789)]; # %b
my $base56characters   = [split //, q(ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789)];   # %B

our %arg_action = (
    action => {
        schema => ['str*', in=>[qw/gen list-patterns/]],
        default => 'gen',
        cmdline_aliases => {
            list_patterns => {summary=>'Shortcut for --action=list-patterns', is_flag=>1, code=>sub { $_[0]{action} = 'list-patterns' }},
        },
    },
);

our %arg_patterns = (
    patterns => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'pattern',
        summary => 'Pattern(s) to use',
        schema => ['array*', of=>'str*', min_len=>1],
        description => <<'MARKDOWN',

CONVERSION (`%P`). A pattern is string that is roughly similar to a printf
pattern:

    %P

where `P` is certain letter signifying a conversion. This will be replaced with
some other string according to the conversion. An example is the `%h` conversion
which will be replaced with hexdigit.

LENGTH (`%NP`). A non-negative integer (`N`) can be specified before the
conversion to signify desired length, for example, `%4w` will return a random
word of length 4.

MINIMUM AND MAXIMUM LENGTH (`%M$NP`). If two non-negative integers separated by
`$` is specified before the conversion, this specify desired minimum and maximum
length. For example, `%4$10h` will be replaced with between 4 and 10 hexdigits.

ARGUMENT AND FILTERS (`%(arg)P`, `%(arg)(filter1)(...)P`). Finally, an argument
followed by zero or more filters can be specified (before the lengths) and
before the conversion. For example, `%(wordlist:ID::KBBI)w` will be replaced by
a random word from the wordlist <pm:WordList::ID::KBBI>. Another example,
`%()(Str::uc)4$10h` will be replaced by between 4-10 uppercase hexdigits, and
`%(arraydata:Sample::DeNiro)(Str::underscore_non_latin_alphanums)(Str::lc)(Str::ucfirst)w`
will be replaced with a random movie title of Robert De Niro, where symbols are
replaced with underscore then the string will be converted into lowercase and
the first character uppercased, e.g. `Dear_america_letters_home_from_vietnam`.

Anything else will be left as-is.

Available conversions:

    %l   Random Latin letter (A-Z, a-z)
    %d   Random digit (0-9)
    %h   Random hexdigit (0-9a-f in lowercase [default] or 0-9A-F in uppercase).
         Known arguments:
         - "u" (to use the uppercase instead of the default lowercase digits)
    %a   Random letter/digit (Alphanum) (A-Z, a-z, 0-9; combination of %l and %d)
    %s   Random ASCII symbol, e.g. "-" (dash), "_" (underscore), etc.
    %x   Random letter/digit/ASCII symbol (combination of %a and %s)
    %m   Base64 character (A-Z, a-z, 0-9, +, /)
    %b   Base58 character (A-Z, a-z, 0-9 minus IOl0)
    %B   Base56 character (A-Z, a-z, 0-9 minus IOol01)
    %%   A literal percent sign
    %w   Random word. Known arguments:
         - "stdin:" (for getting the words from stdin, the default)
         - "wordlist:NAME" (for getting the words from a <pm:WordList> module)
         - "arraydata:NAME" (for getting the words from an <pm:ArrayData> module, the
           Role::TinyCommons::Collection::PickItems::RandomPos will be applied).

Filters are modules in the `Data::Sah::Filter::perl::` namespace.

MARKDOWN
        cmdline_aliases => {p=>{}},
    },
);

my %filters;
my %perconv_wl_objs; # WordList objects instantiated by per-conversion wordlist specification
my %perconv_ad_objs; # ArrayData objects instantiated by per-conversion wordlist specification
sub _fill_conversion {
    my ($matches, $words, $wl) = @_;

    my $n = $matches->{N};
    my $m = $matches->{M};
    my $len = defined($n) && defined($m) ? $n+int(rand()*($m-$n+1)) :
        defined($n) ? $n : 1;

    my $res;
    my $do_filter = sub {
        return unless $matches->{FILTERS};
        my @filters;
        while ($matches->{FILTERS} =~ /\(([^)]+)\)/g) { push @filters, $1 }
        require Data::Sah::Filter;
        for my $filter (@filters) {
            unless ($filters{$filter}) {
                $filters{$filter} = Data::Sah::Filter::gen_filter(filter_names => [$filter]);
            }
            $res = $filters{$filter}->($res);
        }
    };

    if ($matches->{CONV} eq '%') {
        $res = join("", map {'%'} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'd') {
        $res = join("", map {$digits->[rand(@$digits)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'h') {
        if (defined($matches->{ARG}) && $matches->{ARG} eq 'u') {
            $res = join("", map {$hexdigits_upper->[rand(@$hexdigits_upper)]} 1..$len);
        } else {
            $res = join("", map {$hexdigits->[rand(@$hexdigits)]} 1..$len);
        }
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'l') {
        $res = join("", map {$letters->[rand(@$letters)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'a') {
        $res = join("", map {$letterdigits->[rand(@$letterdigits)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 's') {
        $res = join("", map {$symbols->[rand(@$symbols)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'x') {
        $res = join("", map {$letterdigitsymbols->[rand(@$letterdigitsymbols)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'm') {
        $res = join("", map {$base64characters->[rand(@$base64characters)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'b') {
        $res = join("", map {$base58characters->[rand(@$base58characters)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'B') {
        $res = join("", map {$base56characters->[rand(@$base56characters)]} 1..$len);
        $do_filter->(); return $res;
    } elsif ($matches->{CONV} eq 'w') {
       my $word;
        my $iter = 0;
        while (1) {
            if ($words) {
                @$words or die "Ran out of words (please use a longer wordlist or set a lower -n";
                $word = shift @$words;
            } elsif ($wl) {
                ($word) = $wl->pick(1, "allow duplicates");
            } elsif (defined($matches->{ARG}) && length $matches->{ARG}) {
                if ($matches->{ARG} =~ /\Awordlist:(.+)/) {
                    my $perconv_wl = $1;
                    unless ($perconv_wl_objs{$perconv_wl}) {
                        log_trace "Instantiating WordList '$perconv_wl' ...";
                        require Module::Load::Util;
                        $perconv_wl_objs{$perconv_wl} = Module::Load::Util::instantiate_class_with_optional_args({ns_prefix=>'WordList'}, $perconv_wl);
                    }
                    ($word) = $perconv_wl_objs{$perconv_wl}->pick(1, "allow_duplicates");
                } elsif ($matches->{ARG} =~ /\Aarraydata:(.+)/) {
                    my $perconv_ad = $1;
                    unless ($perconv_ad_objs{$perconv_ad}) {
                        log_trace "Instantiating ArrayData '$perconv_ad' ...";
                        require Module::Load::Util;
                        $perconv_ad_objs{$perconv_ad} = Module::Load::Util::instantiate_class_with_optional_args({ns_prefix=>'ArrayData'}, $perconv_ad)->apply_roles("PickItems::RandomPos");
                    }
                    ($word) = $perconv_ad_objs{$perconv_ad}->pick_item;
                } else {
                    die "Unknown argument in '$matches->{all}' conversion: $matches->{ARG}";
                }
            } else {
                die "No supply of words for conversion '$matches->{all}'";
            }

            # repeat picking if word does not fulfill requirement (e.g. length)
            next if defined $n && length $word < $n;
            next if defined $m && length $word > $m;
            do { undef $word; last } if $iter++ > 1000;
            last;
        }
        die "Couldn't find suitable random words for conversion '$matches->{all}'"
            unless defined $word;
       $res = $word;
       $do_filter->(); return $res;
   }
}

sub _set_case {
    my ($str, $case) = @_;
    if ($case eq 'upper') {
        return uc($str);
    } elsif ($case eq 'lower') {
        return lc($str);
    } elsif ($case eq 'title') {
        return ucfirst(lc($str));
    } elsif ($case eq 'random') {
        return join("", map { rand() < 0.5 ? uc($_) : lc($_) } split(//, $str));
    } else {
        return $str;
    }
}

our $re = qr/(?<all>
                 %
                 (?:
                     \((?<ARG>[^)]*)\)
                     (?<FILTERS>(?:\([^)]+\))*)?
                 )?
                 (?:(?<N>\d+)(?:\$(?<M>\d+))?)?
                 (?<CONV>[abBdhlmswx%]))
            /x;

sub _fill_pattern {
    my ($pattern, $words, $wl) = @_;

    $pattern =~ s/$re/_fill_conversion({%+}, $words, $wl)/eg;

    $pattern;
}

sub _pattern_has_stdin_w_conversion {
    my ($pattern) = @_;
    my $res;
    $pattern =~ s/$re/if ($+{CONV} eq 'w' && (!defined($+{ARG}) || $+{ARG} eq '' || $+{ARG} eq 'stdin:')) { $res = 1 }/eg;
    $res;
}

$SPEC{genpw} = {
    v => 1.1,
    summary => '(Gen)erate random password/strings, with (p)atterns and (w)ordlists',
    description => <<'MARKDOWN',

This is yet another utility to generate random password. Features:

* Allow specifying pattern(s), e.g. '%8a%s' means 8 random alphanumeric
  characters followed by a symbol.
* Use words from wordlists.
* Use strong random source when available, otherwise fallback to Perl's builtin
  `rand()`.

Examples:

By default generate base56 password 12-20 characters long (-p %12$20B):

    % genpw
    Uk7Zim6pZeMTZQUyaM

Generate 5 passwords instead of 1:

    % genpw 5
    igYiRhUb5t9d9f3J
    b7D44pnxZHJGQzDy2eg
    RXDtqjMvp2hNAdQ
    Xz3DmAL94akqtZ5xb
    7TfANv9yxAaMGXm

Generate random digits between 10 and 12 characters long:

    % genpw -p '%10$12d'
    55597085674

Generate password in the form of a random word + 4 random digits. Words will be
fed from STDIN:

    % genpw -p '%w%4d' < /usr/share/dict/words
    shafted0412

Like the above, but words will be fetched from `WordList::*` modules. You need
to install the <prog:genpw-wordlist> CLI. By default, will use wordlist from
<pm:WordList::EN::Enable>:

    % genpw -p '%(wordlist:EN::Enable)w%4d'

    % genpw-wordlist -p '%w%4d'
    sedimentologists8542

Generate a random GUID:

    % genpw -p '%8h-%4h-%4h-%4h-%12h'
    ff26d142-37a8-ecdf-c7f6-8b6ae7b27695

Like the above, but in uppercase:

    % genpw -p '%(u)8h-%(u)4h-%(u)4h-%(u)4h-%(u)12h'
    CA333840-6132-33A1-9C31-F2FF20EDB3EA

    % genpw -p '%()(Str::uc)8h-%()(Str::uc)4h-%()(Str::uc)4h-%()(Str::uc)4h-%()(Str::uc)12h'
    CA333840-6132-33A1-9C31-F2FF20EDB3EA

    % genpw -p '%8h-%4h-%4h-%4h-%12h' -U
    22E13D9E-1187-CD95-1D05-2B92A09E740D

Use configuration file to avoid typing the pattern every time, put this in
`~/genpw.conf`:

    [profile=guid]
    patterns = "%8h-%4h-%4h-%4h-%12h"

then:

    % genpw -P guid
    008869fa-177e-3a46-24d6-0900a00e56d5

Keywords: generate, pattern, wordlist

MARKDOWN
    args => {
        %arg_action,
        num => {
            schema => ['int*', min=>1],
            default => 1,
            cmdline_aliases => {n=>{}},
            pos => 0,
        },
        %arg_patterns,
        min_len => {
            summary => 'If no pattern is supplied, will generate random '.
                'alphanum characters with this minimum length',
            schema => 'posint*',
        },
        max_len => {
            summary => 'If no pattern is supplied, will generate random '.
                'alphanum characters with this maximum length',
            schema => 'posint*',
        },
        len => {
            summary => 'If no pattern is supplied, will generate random '.
                'alphanum characters with this exact length',
            schema => 'posint*',
            cmdline_aliases => {l=>{}},
        },
        case => {
            summary => 'Force casing',
            schema => ['str*', in=>['default','random','lower','upper','title']],
            default => 'default',
            description => <<'MARKDOWN',

`default` means to not change case. `random` changes casing some letters
randomly to lower-/uppercase. `lower` forces lower case. `upper` forces
UPPER CASE. `title` forces Title case.

MARKDOWN
            cmdline_aliases => {
                U => {is_flag=>1, summary=>'Shortcut for --case=upper', code=>sub {$_[0]{case} = 'upper'}},
                L => {is_flag=>1, summary=>'Shortcut for --case=lower', code=>sub {$_[0]{case} = 'lower'}},
            },
        },
    },
    examples => [
    ],
    links => [
        {url=>'prog:genpw-base56'},
        {url=>'prog:genpw-base64'},
        {url=>'prog:genpw-ind'},
        {url=>'prog:genpw-wordlist'},
    ],
};
sub genpw {
    my %args = @_;

    my $action = $args{action} // 'gen';
    my $num = $args{num} // 1;
    my $min_len = $args{min_len} // $args{len} // 12;
    my $max_len = $args{max_len} // $args{len} // 20;
    my $patterns = $args{patterns} // ["%$min_len\$${max_len}B"];
    my $case = $args{case} // 'default';

    if ($action eq 'list-patterns') {
        return [200, "OK", $patterns];
    }

  GET_WORDS_FROM_STDIN:
    {
        last if defined $args{_words} || defined $args{_wl};
        my $has_w;
        for (@$patterns) {
            if (_pattern_has_stdin_w_conversion($_)) { $has_w++; last }
        }
        last unless $has_w;
        require List::Util;
        $args{_words} = [List::Util::shuffle(<STDIN>)];
        chomp for @{ $args{_words} };
    }

    my @passwords;
    for my $i (1..$num) {
            my $password =
                _fill_pattern($patterns->[rand @$patterns], $args{_words}, $args{_wl});
            $password = _set_case($password, $case);
        push @passwords, $password;
    }

    [200, "OK", \@passwords];
}

1;
# ABSTRACT: (Gen)erate random password/strings, with (p)atterns and (w)ordlists

__END__

=pod

=encoding UTF-8

=head1 NAME

App::genpw - (Gen)erate random password/strings, with (p)atterns and (w)ordlists

=head1 VERSION

This document describes version 0.013 of App::genpw (from Perl distribution App-genpw), released on 2024-01-16.

=head1 SYNOPSIS

See the included script L<genpw>.

=head1 FUNCTIONS


=head2 genpw

Usage:

 genpw(%args) -> [$status_code, $reason, $payload, \%result_meta]

(Gen)erate random passwordE<sol>strings, with (p)atterns and (w)ordlists.

This is yet another utility to generate random password. Features:

=over

=item * Allow specifying pattern(s), e.g. '%8a%s' means 8 random alphanumeric
characters followed by a symbol.

=item * Use words from wordlists.

=item * Use strong random source when available, otherwise fallback to Perl's builtin
C<rand()>.

=back

Examples:

By default generate base56 password 12-20 characters long (-p %12$20B):

 % genpw
 Uk7Zim6pZeMTZQUyaM

Generate 5 passwords instead of 1:

 % genpw 5
 igYiRhUb5t9d9f3J
 b7D44pnxZHJGQzDy2eg
 RXDtqjMvp2hNAdQ
 Xz3DmAL94akqtZ5xb
 7TfANv9yxAaMGXm

Generate random digits between 10 and 12 characters long:

 % genpw -p '%10$12d'
 55597085674

Generate password in the form of a random word + 4 random digits. Words will be
fed from STDIN:

 % genpw -p '%w%4d' < /usr/share/dict/words
 shafted0412

Like the above, but words will be fetched from C<WordList::*> modules. You need
to install the L<genpw-wordlist> CLI. By default, will use wordlist from
L<WordList::EN::Enable>:

 % genpw -p '%(wordlist:EN::Enable)w%4d'
 
 % genpw-wordlist -p '%w%4d'
 sedimentologists8542

Generate a random GUID:

 % genpw -p '%8h-%4h-%4h-%4h-%12h'
 ff26d142-37a8-ecdf-c7f6-8b6ae7b27695

Like the above, but in uppercase:

 % genpw -p '%(u)8h-%(u)4h-%(u)4h-%(u)4h-%(u)12h'
 CA333840-6132-33A1-9C31-F2FF20EDB3EA
 
 % genpw -p '%()(Str::uc)8h-%()(Str::uc)4h-%()(Str::uc)4h-%()(Str::uc)4h-%()(Str::uc)12h'
 CA333840-6132-33A1-9C31-F2FF20EDB3EA
 
 % genpw -p '%8h-%4h-%4h-%4h-%12h' -U
 22E13D9E-1187-CD95-1D05-2B92A09E740D

Use configuration file to avoid typing the pattern every time, put this in
C<~/genpw.conf>:

 [profile=guid]
 patterns = "%8h-%4h-%4h-%4h-%12h"

then:

 % genpw -P guid
 008869fa-177e-3a46-24d6-0900a00e56d5

Keywords: generate, pattern, wordlist

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "gen")

(No description)

=item * B<case> => I<str> (default: "default")

Force casing.

C<default> means to not change case. C<random> changes casing some letters
randomly to lower-/uppercase. C<lower> forces lower case. C<upper> forces
UPPER CASE. C<title> forces Title case.

=item * B<len> => I<posint>

If no pattern is supplied, will generate random alphanum characters with this exact length.

=item * B<max_len> => I<posint>

If no pattern is supplied, will generate random alphanum characters with this maximum length.

=item * B<min_len> => I<posint>

If no pattern is supplied, will generate random alphanum characters with this minimum length.

=item * B<num> => I<int> (default: 1)

(No description)

=item * B<patterns> => I<array[str]>

Pattern(s) to use.

CONVERSION (C<%P>). A pattern is string that is roughly similar to a printf
pattern:

 %P

where C<P> is certain letter signifying a conversion. This will be replaced with
some other string according to the conversion. An example is the C<%h> conversion
which will be replaced with hexdigit.

LENGTH (C<%NP>). A non-negative integer (C<N>) can be specified before the
conversion to signify desired length, for example, C<%4w> will return a random
word of length 4.

MINIMUM AND MAXIMUM LENGTH (C<%M$NP>). If two non-negative integers separated by
C<$> is specified before the conversion, this specify desired minimum and maximum
length. For example, C<%4$10h> will be replaced with between 4 and 10 hexdigits.

ARGUMENT AND FILTERS (C<%(arg)P>, C<%(arg)(filter1)(...)P>). Finally, an argument
followed by zero or more filters can be specified (before the lengths) and
before the conversion. For example, C<%(wordlist:ID::KBBI)w> will be replaced by
a random word from the wordlist L<WordList::ID::KBBI>. Another example,
C<%()(Str::uc)4$10h> will be replaced by between 4-10 uppercase hexdigits, and
C<%(arraydata:Sample::DeNiro)(Str::underscore_non_latin_alphanums)(Str::lc)(Str::ucfirst)w>
will be replaced with a random movie title of Robert De Niro, where symbols are
replaced with underscore then the string will be converted into lowercase and
the first character uppercased, e.g. C<Dear_america_letters_home_from_vietnam>.

Anything else will be left as-is.

Available conversions:

 %l   Random Latin letter (A-Z, a-z)
 %d   Random digit (0-9)
 %h   Random hexdigit (0-9a-f in lowercase [default] or 0-9A-F in uppercase).
      Known arguments:
      - "u" (to use the uppercase instead of the default lowercase digits)
 %a   Random letter/digit (Alphanum) (A-Z, a-z, 0-9; combination of %l and %d)
 %s   Random ASCII symbol, e.g. "-" (dash), "_" (underscore), etc.
 %x   Random letter/digit/ASCII symbol (combination of %a and %s)
 %m   Base64 character (A-Z, a-z, 0-9, +, /)
 %b   Base58 character (A-Z, a-z, 0-9 minus IOl0)
 %B   Base56 character (A-Z, a-z, 0-9 minus IOol01)
 %%   A literal percent sign
 %w   Random word. Known arguments:
      - "stdin:" (for getting the words from stdin, the default)
      - "wordlist:NAME" (for getting the words from a L<WordList> module)
      - "arraydata:NAME" (for getting the words from an L<ArrayData> module, the
        Role::TinyCommons::Collection::PickItems::RandomPos will be applied).

Filters are modules in the C<Data::Sah::Filter::perl::> namespace.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-genpw>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-genpw>.

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

This software is copyright (c) 2024, 2020, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-genpw>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

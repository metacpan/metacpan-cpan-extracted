package Complete::Getopt::Long;

our $DATE = '2019-06-26'; # DATE
our $VERSION = '0.471'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_cli_arg
               );

our %SPEC;

sub _default_completion {
    require Complete::Env;
    require Complete::File;
    require Complete::Util;

    my %args = @_;
    my $word = $args{word} // '';

    my $fres;
    #$log->tracef('[comp][compgl] entering default completion routine');

    # try completing '$...' with shell variables
    if ($word =~ /\A\$/) {
        #$log->tracef('[comp][compgl] completing shell variable');
        {
            my $compres = Complete::Env::complete_env(
                word=>$word);
            last unless @$compres;
            $fres = {words=>$compres, esc_mode=>'shellvar'};
            goto RETURN_RES;
        }
        # if empty, fallback to searching file
    }

    # try completing '~foo' with user dir (appending / if user's home exists)
    if ($word =~ m!\A~([^/]*)\z!) {
        #$log->tracef("[comp][compgl] completing userdir, user=%s", $1);
        {
            eval { require Unix::Passwd::File };
            last if $@;
            my $res = Unix::Passwd::File::list_users(detail=>1);
            last unless $res->[0] == 200;
            my $compres = Complete::Util::complete_array_elem(
                array=>[map {"~" . $_->{user} . ((-d $_->{home}) ? "/":"")}
                            @{ $res->[2] }],
                word=>$word,
            );
            last unless @$compres;
            $fres = {words=>$compres, path_sep=>'/'};
            goto RETURN_RES;
        }
        # if empty, fallback to searching file
    }

    # try completing '~/blah' or '~foo/blah' as if completing file, but do not
    # expand ~foo (this is supported by complete_file(), so we just give it off
    # to the routine)
    if ($word =~ m!\A(~[^/]*)/!) {
        #$log->tracef("[comp][compgl] completing file, path=<%s>", $word);
        $fres = {words=>Complete::File::complete_file(word=>$word),
                 path_sep=>'/'};
        goto RETURN_RES;
    }

    # try completing something that contains wildcard with glob. for
    # convenience, we add '*' at the end so that when user type [AB] it is
    # treated like [AB]*.
    require String::Wildcard::Bash;
    if (String::Wildcard::Bash::contains_wildcard($word)) {
        #$log->tracef("[comp][compgl] completing with wildcard glob, glob=<%s>", "$word*");
        {
            my $compres = [glob("$word*")];
            last unless @$compres;
            for (@$compres) {
                $_ .= "/" if (-d $_);
            }
            $fres = {words=>$compres, path_sep=>'/'};
            goto RETURN_RES;
        }
        # if empty, fallback to searching file
    }
    #$log->tracef("[comp][compgl] completing with file, file=<%s>", $word);
    $fres = {words=>Complete::File::complete_file(word=>$word),
             path_sep=>'/'};
  RETURN_RES:
    #$log->tracef("[comp][compgl] leaving default completion routine, result=%s", $fres);
    $fres;
}

# return the key/element if $opt matches exactly a key/element in $opts (which
# can be an array/hash) OR expands unambiguously to exactly one key/element in
# $opts, otherwise return undef. e.g. _expand1('--fo', [qw/--foo --bar --baz
# --fee --feet/]) and _expand('--fee', ...) will respectively return '--foo' and
# '--fee' because it expands/is unambiguous in the list, but _expand1('--ba',
# ...) or _expand1('--qux', ...) will both return undef because '--ba' expands
# ambiguously (--bar/--baz) while '--qux' cannot be expanded.
sub _expand1 {
    my ($opt, $opts) = @_;
    my @candidates;
    my $is_hash = ref($opts) eq 'HASH';
    for ($is_hash ? (sort {length($a)<=>length($b)} keys %$opts) : @$opts) {
        next unless index($_, $opt) == 0;
        push @candidates, $is_hash ? $opts->{$_} : $_;
        last if $opt eq $_;
    }
    return @candidates == 1 ? $candidates[0] : undef;
}

# mark an option (and all its aliases) as seen
sub _mark_seen {
    my ($seen_opts, $opt, $opts) = @_;
    my $opthash = $opts->{$opt};
    return unless $opthash;
    my $ospec = $opthash->{ospec};
    for (keys %$opts) {
        my $v = $opts->{$_};
        $seen_opts->{$_}++ if $v->{ospec} eq $ospec;
    }
}

$SPEC{complete_cli_arg} = {
    v => 1.1,
    summary => 'Complete command-line argument using '.
        'Getopt::Long specification',
    description => <<'_',

This routine can complete option names, where the option names are retrieved
from <pm:Getopt::Long> specification. If you provide completion routine in
`completion`, you can also complete _option values_ and _arguments_.

Note that this routine does not use <pm:Getopt::Long> (it does its own parsing)
and currently is not affected by Getopt::Long's configuration. Its behavior
mimics Getopt::Long under these configuration: `no_ignore_case`, `bundling` (or
`no_bundling` if the `bundling` option is turned off). Which I think is the
sensible default. This routine also does not currently support `auto_help` and
`auto_version`, so you'll need to add those options specifically if you want to
recognize `--help/-?` and `--version`, respectively.

_
    args => {
        getopt_spec => {
            summary => 'Getopt::Long specification',
            schema  => 'hash*',
            req     => 1,
        },
        completion => {
            summary     =>
                'Completion routine to complete option value/argument',
            schema      => 'code*',
            description => <<'_',

Completion code will receive a hash of arguments (`%args`) containing these
keys:

* `type` (str, what is being completed, either `optval`, or `arg`)
* `word` (str, word to be completed)
* `cword` (int, position of words in the words array, starts from 0)
* `opt` (str, option name, e.g. `--str`; undef if we're completing argument)
* `ospec` (str, Getopt::Long option spec, e.g. `str|S=s`; undef when completing
  argument)
* `argpos` (int, argument position, zero-based; undef if type='optval')
* `nth` (int, the number of times this option has seen before, starts from 0
  that means this is the first time this option has been seen; undef when
  type='arg')
* `seen_opts` (hash, all the options seen in `words`)
* `parsed_opts` (hash, options parsed the standard/raw way)

as well as all keys from `extras` (but these won't override the above keys).

and is expected to return a completion answer structure as described in
`Complete` which is either a hash or an array. The simplest form of answer is
just to return an array of strings. The various `complete_*` function like those
in <pm:Complete::Util> or the other `Complete::*` modules are suitable to use
here.

Completion routine can also return undef to express declination, in which case
the default completion routine will then be consulted. The default routine
completes from shell environment variables (`$FOO`), Unix usernames (`~foo`),
and files/directories.

Example:

    use Complete::Unix qw(complete_user);
    use Complete::Util qw(complete_array_elem);
    complete_cli_arg(
        getopt_spec => {
            'help|h'   => sub{...},
            'format=s' => \$format,
            'user=s'   => \$user,
        },
        completion  => sub {
            my %args  = @_;
            my $word  = $args{word};
            my $ospec = $args{ospec};
            if ($ospec && $ospec eq 'format=s') {
                complete_array_elem(array=>[qw/json text xml yaml/], word=>$word);
            } else {
                complete_user(word=>$word);
            }
        },
    );

_
        },
        words => {
            summary     => 'Command line arguments, like @ARGV',
            description => <<'_',

See function `parse_cmdline` in <pm:Complete::Bash> on how to produce this (if
you're using bash).

_
            schema      => 'array*',
            req         => 1,
        },
        cword => {
            summary     =>
                "Index in words of the word we're trying to complete",
            description => <<'_',

See function `parse_cmdline` in <pm:Complete::Bash> on how to produce this (if
you're using bash).

_
            schema      => 'int*',
            req         => 1,
        },
        extras => {
            summary => 'Add extra arguments to completion routine',
            schema  => 'hash',
            description => <<'_',

The keys from this `extras` hash will be merged into the final `%args` passed to
completion routines. Note that standard keys like `type`, `word`, and so on as
described in the function description will not be overwritten by this.

_
        },
        bundling => {
            schema  => 'bool*',
            default => 1,
            'summary.alt.bool.not' => 'Turn off bundling',
            description => <<'_',

If you turn off bundling, completion of short-letter options won't support
bundling (e.g. `-b<tab>` won't add more single-letter options), but single-dash
multiletter options can be recognized. Currently only those specified with a
single dash will be completed. For example if you have `-foo=s` in your option
specification, `-f<tab>` can complete it.

This can be used to complete old-style programs, e.g. emacs which has options
like `-nw`, `-nbc` etc (but also have double-dash options like
`--no-window-system` or `--no-blinking-cursor`).

_
        },
    },
    result_naked => 1,
    result => {
        schema => ['any*' => of => ['hash*', 'array*']],
        description => <<'_',

You can use `format_completion` function in <pm:Complete::Bash> module to format
the result of this function for bash.

_
    },
};
sub complete_cli_arg {
    require Complete::Util;
    require Getopt::Long::Util;

    my %args = @_;

    my $fname = __PACKAGE__ . "::complete_cli_arg"; # XXX use __SUB__
    my $fres;

    $args{words} or die "Please specify words";
    my @words = @{ $args{words} };
    defined(my $cword = $args{cword}) or die "Please specify cword";
    my $gospec = $args{getopt_spec} or die "Please specify getopt_spec";
    my $comp = $args{completion};
    my $extras = $args{extras} // {};
    my $bundling = $args{bundling} // 1;
    my %parsed_opts;

    #$log->tracef('[comp][compgl] entering %s(), words=%s, cword=%d, word=<%s>',
    #             $fname, \@words, $cword, $words[$cword]);

    # parse all options first & supply default completion routine
    my %opts;
    for my $ospec (keys %$gospec) {
        my $res = Getopt::Long::Util::parse_getopt_long_opt_spec($ospec)
            or die "Can't parse option spec '$ospec'";
        next if $res->{is_arg};
        $res->{min_vals} //= $res->{type} ? 1 : 0;
        $res->{max_vals} //= $res->{type} || $res->{opttype} ? 1:0;
        for my $o0 (@{ $res->{opts} }) {
            my @ary = $res->{is_neg} && length($o0) > 1 ?
                ([$o0, 0], ["no$o0",1], ["no-$o0",1]) : ([$o0,0]);
            for my $elem (@ary) {
                my $o = $elem->[0];
                my $is_neg = $elem->[1];
                my $k = length($o)==1 ||
                    (!$bundling && $res->{dash_prefix} eq '-') ?
                        "-$o" : "--$o";
                $opts{$k} = {
                    name => $k,
                    ospec => $ospec, # key to getopt specification
                    parsed => $res,
                    is_neg => $is_neg,
                };
            }
        }
    }
    my @optnames = sort keys %opts;

    my $code_get_summary = sub {
        # currently we only extract summaries from Rinci metadata and
        # Perinci::CmdLine object
        return unless $extras;
        my $ggls_res = $extras->{ggls_res};
        return unless $ggls_res;
        my $cmdline = $extras->{cmdline};
        return unless $cmdline;
        my $r = $extras->{r};
        return unless $r;

        my $optname = shift;
        my $ospec  = $opts{$optname}{ospec};
        return unless $ospec; # shouldn't happen
        my $specmeta = $ggls_res->[3]{'func.specmeta'};
        my $ospecmeta = $specmeta->{$ospec};

        if ($ospecmeta->{is_alias}) {
            my $real_ospecmeta = $specmeta->{ $ospecmeta->{alias_for} };
            my $real_opt = $real_ospecmeta->{parsed}{opts}[0];
            $real_opt = length($real_opt) == 1 ? "-$real_opt" : "--$real_opt";
            return "Alias for $real_opt";
        }

        if (defined(my $coptname = $ospecmeta->{common_opt})) {
            # it's a common Perinci::CmdLine option
            my $coptspec = $cmdline->{common_opts}{$coptname};
            #use DD; dd $coptspec;
            return unless $coptspec;

            my $summ;
            # XXX translate
            if ($opts{$optname}{is_neg}) {
                $summ = $coptspec->{"summary.alt.bool.not"};
                return $summ if defined $summ;
                my $pos_opt = $ospecmeta->{pos_opts}[0];
                $pos_opt = length($pos_opt) == 1 ? "-$pos_opt" : "--$pos_opt";
                return "The opposite of $pos_opt";
            } else {
                $summ = $coptspec->{"summary.alt.bool.yes"};
                return $summ if defined $summ;
                $summ = $coptspec->{"summary"};
                return $summ if defined $summ;
            }
        } else {
            # it's option from function argument
            my $arg = $ospecmeta->{arg};
            my $argspec = $extras->{r}{meta}{args}{$arg};
            #use DD; dd $argspec;

            my $summ;
            # XXX translate
            #use DD; dd {optname=>$optname, ospecmeta=>$ospecmeta};
            if ($ospecmeta->{is_neg}) {
                $summ = $argspec->{"summary.alt.bool.not"};
                return $summ if defined $summ;
                my $pos_opt = $ospecmeta->{pos_opts}[0];
                $pos_opt = length($pos_opt) == 1 ? "-$pos_opt" : "--$pos_opt";
                return "The opposite of $pos_opt";
            } else {
                $summ = $argspec->{"summary.alt.bool.yes"};
                return $summ if defined $summ;
                $summ = $argspec->{"summary"};
                return $summ if defined $summ;
            }
        }

        return;
    };

    my %seen_opts;

    # for each word (each element in this array), we try to find out whether
    # it's supposed to complete option name, or option value, or argument, or
    # separator (or more than one of them). plus some other information.
    #
    # each element is a hash. if hash contains 'optname' key then it expects an
    # option name. if hash contains 'optval' key then it expects an option
    # value.
    #
    # 'short_only' means that the word is not to be completed with long option
    # name, only (bundle of) one-letter option names.

    my @expects;

    my $i = -1;
    my $argpos = 0;

  WORD:
    while (1) {
        last WORD if ++$i >= @words;
        my $word = $words[$i];
        #say "D:i=$i, word=$word, ~~\@words=",~~@words;

        if ($word eq '--' && $i != $cword) {
            $expects[$i] = {separator=>1};
            while (1) {
                $i++;
                last WORD if $i >= @words;
                $expects[$i] = {arg=>1, argpos=>$argpos++};
            }
        }

        if ($word =~ /\A-/) {

            # check if it is a (bundle) of short option names
          SHORT_OPTS:
            {
                # it's not a known short option
                last unless $opts{"-".substr($word,1,1)};

                # not a bundle, regard as only a single short option name
                last unless $bundling;

                # expand bundle
                my $j = $i;
                my $rest = substr($word, 1);
                my @inswords;
                my $encounter_equal_sign;
              EXPAND:
                while (1) {
                    $rest =~ s/(.)// or last;
                    my $opt = "-$1";
                    my $opthash = $opts{$opt};
                    unless ($opthash) {
                        # we encounter an unknown option, doubt that this is a
                        # bundle of short option name, it could be someone
                        # typing --long as -long
                        @inswords = ();
                        $expects[$i]{short_only} = 0;
                        $rest = $word;
                        last EXPAND;
                    }
                    if ($opthash->{parsed}{max_vals}) {
                        # stop after an option that requires value
                        _mark_seen(\%seen_opts, $opt, \%opts);

                        if ($i == $j) {
                            $words[$i] = $opt;
                        } else {
                            push @inswords, $opt;
                            $j++;
                        }

                        my $expand;
                        if (length $rest) {
                            $expand++;
                            # complete -Sfoo^ is completing option value
                            $expects[$j > $i ? $j+1 : $j+2]{do_complete_optname} = 0;
                            $expects[$j > $i ? $j+1 : $j+2]{optval} = $opt;
                        } else {
                            # complete -S^ as [-S] to add space
                            $expects[$j > $i ? $j-1 : $j]{optname} = $opt;
                            $expects[$j > $i ? $j-1 : $j]{comp_result} = [
                                substr($word, 0, length($word)-length($rest))];
                        }

                        if ($rest =~ s/\A=//) {
                            $encounter_equal_sign++;
                        }

                        if ($expand) {
                            push @inswords, "=", $rest;
                            $j+=2;
                        }
                        last EXPAND;
                    }
                    # continue splitting
                    _mark_seen(\%seen_opts, $opt, \%opts);
                    if ($i == $j) {
                        $words[$i] = $opt;
                    } else {
                        push @inswords, $opt;
                    }
                    $j++;
                }

                #use DD; print "D:inswords: "; dd \@inswords;

                my $prefix = $encounter_equal_sign ? '' :
                    substr($word, 0, length($word)-length($rest));
                splice @words, $i+1, 0, @inswords;
                for (0..@inswords) {
                    $expects[$i+$_]{prefix} = $prefix;
                    $expects[$i+$_]{word}   = $rest;
                }
                $cword += @inswords;
                $i += @inswords;
                $word = $words[$i];
                $expects[$i]{short_only} //= 1;
            } # SHORT_OPTS

            # split --foo=val -> --foo, =, val
          SPLIT_EQUAL:
            {
                if ($word =~ /\A(--?[^=]+)(=)(.*)/) {
                    splice @words, $i, 1, $1, $2, $3;
                    $word = $1;
                    $cword += 2 if $cword >= $i;
                }
            }

            my $opt = $word;
            my $opthash = _expand1($opt, \%opts);

            if ($opthash) {
                $opt = $opthash->{name};
                $expects[$i]{optname} = $opt;
                my $nth = $seen_opts{$opt} // 0;
                $expects[$i]{nth} = $nth;
                _mark_seen(\%seen_opts, $opt, \%opts);

                my $min_vals = $opthash->{parsed}{min_vals};
                my $max_vals = $opthash->{parsed}{max_vals};
                #say "D:min_vals=$min_vals, max_vals=$max_vals";

                # detect = after --opt
                if ($i+1 < @words && $words[$i+1] eq '=') {
                    $i++;
                    $expects[$i] = {separator=>1, optval=>$opt, word=>'', nth=>$nth};
                    # force a value due to =
                    if (!$max_vals) { $min_vals = $max_vals = 1 }
                }

                for (1 .. $min_vals) {
                    $i++;
                    last WORD if $i >= @words;
                    $expects[$i]{optval} = $opt;
                    $expects[$i]{nth} = $nth;
                    push @{ $parsed_opts{$opt} }, $words[$i];
                }
                for (1 .. $max_vals-$min_vals) {
                    last if $i+$_ >= @words;
                    last if $words[$i+$_] =~ /\A-/; # a new option
                    $expects[$i+$_]{optval} = $opt; # but can also be optname
                    $expects[$i]{nth} = $nth;
                    push @{ $parsed_opts{$opt} }, $words[$i+$_];
                }
            } else {
                # an unknown option, assume it doesn't require argument, unless
                # it's --opt= or --opt=foo
                $opt = undef;
                $expects[$i]{optname} = $opt;

                # detect = after --opt
                if ($i+1 < @words && $words[$i+1] eq '=') {
                    $i++;
                    $expects[$i] = {separator=>1, optval=>undef, word=>''};
                    if ($i+1 < @words) {
                        $i++;
                        $expects[$i]{optval} = $opt;
                    }
                }
            }
        } else {
            $expects[$i]{optname} = '';
            $expects[$i]{arg} = 1;
            $expects[$i]{argpos} = $argpos++;
        }
    }

    my $exp = $expects[$cword];
    my $word = $exp->{word} // $words[$cword];

    #use DD; print "D:words: "; dd \@words;
    #say "D:cword: $cword";
    #use DD; print "D:expects: "; dd \@expects;
    #use DD; print "D:seen_opts: "; dd \%seen_opts;
    #use DD; print "D:parsed_opts: "; dd \%parsed_opts;
    #use DD; print "D:exp: "; dd $exp;
    #use DD; say "D:word:<$word>";

    my @answers;

    # complete option names
    {
        last if $word =~ /\A[^-]/;
        last unless exists $exp->{optname};
        last if defined($exp->{do_complete_optname}) &&
            !$exp->{do_complete_optname};
        if ($exp->{comp_result}) {
            push @answers, $exp->{comp_result};
            last;
        }
        #say "D:completing option names";
        my $opt = $exp->{optname};
        my @o;
        my @osumms;
        my $o_has_summaries;
        for my $optname (@optnames) {
            my $repeatable = 0;
            next if $exp->{short_only} && $optname =~ /\A--/;
            if ($seen_opts{$optname}) {
                my $opthash = $opts{$optname};
                my $ospecval = $gospec->{$opthash->{ospec}};
                my $parsed = $opthash->{parsed};
                if (ref($ospecval) eq 'ARRAY') {
                    $repeatable = 1;
                } elsif ($parsed->{desttype} || $parsed->{is_inc}) {
                    $repeatable = 1;
                }
            }
            # skip options that have been specified and not repeatable
            #use DD; dd {'$_'=>$_, seen=>$seen_opts{$_}, repeatable=>$repeatable, opt=>$opt};
            next if $seen_opts{$optname} && !$repeatable && (
                # long option has been specified
                (!$opt || $opt ne $optname) ||
                     # short option (in a bundle) has been specified
                    (defined($exp->{prefix}) &&
                         index($exp->{prefix}, substr($opt, 1, 1)) >= 0));
            if (defined $exp->{prefix}) {
                my $o = $optname; $o =~ s/\A-//;
                push @o, "$exp->{prefix}$o";
            } else {
                push @o, $optname;
            }
            my $summ = $code_get_summary->($optname) // '';
            if (length $summ) {
                $o_has_summaries = 1;
                push @osumms, $summ;
            } else {
                push @osumms, '';
            }
        }
        #use DD; dd \@o;
        #use DD; dd \@osumms;
        my $compres = Complete::Util::complete_array_elem(
            array => \@o, word => $word,
            (summaries => \@osumms) x !!$o_has_summaries,
        );
        #$log->tracef('[comp][compgl] adding result from option names, '.
        #                 'matching options=%s', $compres);
        push @answers, $compres;
        if (!exists($exp->{optval}) && !exists($exp->{arg})) {
            $fres = {words=>$compres, esc_mode=>'option'};
            goto RETURN_RES;
        }
    }

    # complete option value
    {
        last unless exists($exp->{optval});
        #say "D:completing option value";
        my $opt = $exp->{optval};
        my $opthash; $opthash = $opts{$opt} if $opt;
        my %compargs = (
            %$extras,
            type=>'optval', words=>\@words, cword=>$args{cword},
            word=>$word, opt=>$opt, ospec=>$opthash->{ospec},
            argpos=>undef, nth=>$exp->{nth}, seen_opts=>\%seen_opts,
            parsed_opts=>\%parsed_opts,
        );
        my $compres;
        if ($comp) {
            #$log->tracef("[comp][compgl] invoking routine supplied from 'completion' argument to complete option value, option=<%s>", $opt);
            $compres = $comp->(%compargs);
            Complete::Util::modify_answer(answer=>$compres, prefix=>$exp->{prefix})
                if defined $exp->{prefix};
            #$log->tracef('[comp][compgl] adding result from routine: %s', $compres);
        }
        if (!$compres || !$comp) {
            $compres = _default_completion(%compargs);
            Complete::Util::modify_answer(answer=>$compres, prefix=>$exp->{prefix})
                if defined $exp->{prefix};
            #$log->tracef('[comp][compgl] adding result from default '.
            #                 'completion routine');
        }
        push @answers, $compres;
    }

    # complete argument
    {
        last unless exists($exp->{arg});
        my %compargs = (
            %$extras,
            type=>'arg', words=>\@words, cword=>$args{cword},
            word=>$word, opt=>undef, ospec=>undef,
            argpos=>$exp->{argpos}, seen_opts=>\%seen_opts,
            parsed_opts=>\%parsed_opts,
        );
        #$log->tracef('[comp][compgl] invoking \'completion\' routine '.
        #                 'to complete argument');
        my $compres; $compres = $comp->(%compargs) if $comp;
        if (!defined $compres) {
            $compres = _default_completion(%compargs);
            #$log->tracef('[comp][compgl] adding result from default '.
            #                 'completion routine: %s', $compres);
        }
        push @answers, $compres;
    }

    #$log->tracef("[comp][compgl] combining result from %d source(s)", ~~@answers);
    $fres = Complete::Util::combine_answers(@answers) // [];

  RETURN_RES:
    #$log->tracef("[comp][compgl] leaving %s(), result=%s", $fname, $fres);
    $fres;
}

1;
# ABSTRACT: Complete command-line argument using Getopt::Long specification

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Getopt::Long - Complete command-line argument using Getopt::Long specification

=head1 VERSION

This document describes version 0.471 of Complete::Getopt::Long (from Perl distribution Complete-Getopt-Long), released on 2019-06-26.

=head1 SYNOPSIS

See L<Getopt::Long::Complete> for an easy way to use this module.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_cli_arg

Usage:

 complete_cli_arg(%args) -> hash|array

Complete command-line argument using Getopt::Long specification.

This routine can complete option names, where the option names are retrieved
from L<Getopt::Long> specification. If you provide completion routine in
C<completion>, you can also complete I<option values> and I<arguments>.

Note that this routine does not use L<Getopt::Long> (it does its own parsing)
and currently is not affected by Getopt::Long's configuration. Its behavior
mimics Getopt::Long under these configuration: C<no_ignore_case>, C<bundling> (or
C<no_bundling> if the C<bundling> option is turned off). Which I think is the
sensible default. This routine also does not currently support C<auto_help> and
C<auto_version>, so you'll need to add those options specifically if you want to
recognize C<--help/-?> and C<--version>, respectively.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<bundling> => I<bool> (default: 1)

If you turn off bundling, completion of short-letter options won't support
bundling (e.g. C<< -bE<lt>tabE<gt> >> won't add more single-letter options), but single-dash
multiletter options can be recognized. Currently only those specified with a
single dash will be completed. For example if you have C<-foo=s> in your option
specification, C<< -fE<lt>tabE<gt> >> can complete it.

This can be used to complete old-style programs, e.g. emacs which has options
like C<-nw>, C<-nbc> etc (but also have double-dash options like
C<--no-window-system> or C<--no-blinking-cursor>).

=item * B<completion> => I<code>

Completion routine to complete option value/argument.

Completion code will receive a hash of arguments (C<%args>) containing these
keys:

=over

=item * C<type> (str, what is being completed, either C<optval>, or C<arg>)

=item * C<word> (str, word to be completed)

=item * C<cword> (int, position of words in the words array, starts from 0)

=item * C<opt> (str, option name, e.g. C<--str>; undef if we're completing argument)

=item * C<ospec> (str, Getopt::Long option spec, e.g. C<str|S=s>; undef when completing
argument)

=item * C<argpos> (int, argument position, zero-based; undef if type='optval')

=item * C<nth> (int, the number of times this option has seen before, starts from 0
that means this is the first time this option has been seen; undef when
type='arg')

=item * C<seen_opts> (hash, all the options seen in C<words>)

=item * C<parsed_opts> (hash, options parsed the standard/raw way)

=back

as well as all keys from C<extras> (but these won't override the above keys).

and is expected to return a completion answer structure as described in
C<Complete> which is either a hash or an array. The simplest form of answer is
just to return an array of strings. The various C<complete_*> function like those
in L<Complete::Util> or the other C<Complete::*> modules are suitable to use
here.

Completion routine can also return undef to express declination, in which case
the default completion routine will then be consulted. The default routine
completes from shell environment variables (C<$FOO>), Unix usernames (C<~foo>),
and files/directories.

Example:

 use Complete::Unix qw(complete_user);
 use Complete::Util qw(complete_array_elem);
 complete_cli_arg(
     getopt_spec => {
         'help|h'   => sub{...},
         'format=s' => \$format,
         'user=s'   => \$user,
     },
     completion  => sub {
         my %args  = @_;
         my $word  = $args{word};
         my $ospec = $args{ospec};
         if ($ospec && $ospec eq 'format=s') {
             complete_array_elem(array=>[qw/json text xml yaml/], word=>$word);
         } else {
             complete_user(word=>$word);
         }
     },
 );

=item * B<cword>* => I<int>

Index in words of the word we're trying to complete.

See function C<parse_cmdline> in L<Complete::Bash> on how to produce this (if
you're using bash).

=item * B<extras> => I<hash>

Add extra arguments to completion routine.

The keys from this C<extras> hash will be merged into the final C<%args> passed to
completion routines. Note that standard keys like C<type>, C<word>, and so on as
described in the function description will not be overwritten by this.

=item * B<getopt_spec>* => I<hash>

Getopt::Long specification.

=item * B<words>* => I<array>

Command line arguments, like @ARGV.

See function C<parse_cmdline> in L<Complete::Bash> on how to produce this (if
you're using bash).

=back

Return value:  (hash|array)


You can use C<format_completion> function in L<Complete::Bash> module to format
the result of this function for bash.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Getopt-Long>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Getopt-Long>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Getopt-Long>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long::Complete>

L<Complete>

L<Complete::Bash>

Other modules related to bash shell tab completion: L<Bash::Completion>,
L<Getopt::Complete>.

L<Perinci::CmdLine> - an alternative way to easily create command-line
applications with completion feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

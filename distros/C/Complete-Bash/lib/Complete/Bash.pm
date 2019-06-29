package Complete::Bash;

our $DATE = '2019-06-28'; # DATE
our $VERSION = '0.324'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       point
                       parse_cmdline
                       join_wordbreak_words
                       format_completion
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines for bash shell',
};

sub _expand_tilde {
    my ($user, $slash) = @_;
    my @ent;
    if (length $user) {
        @ent = getpwnam($user);
    } else {
        @ent = getpwuid($>);
        $user = $ent[0];
    }
    return $ent[7] . $slash if @ent;
    "~$user$slash"; # return as-is when failed
}

sub _add_unquoted {
    no warnings 'uninitialized';

    my ($word, $is_cur_word, $after_ws) = @_;

    #say "D:add_unquoted word=$word is_cur_word=$is_cur_word after_ws=$after_ws";

    $word =~ s!^(~)(\w*)(/|\z) |  # 1) tilde  2) username  3) optional slash
               \\(.)           |  # 4) escaped char
               \$(\w+)            # 5) variable name
              !
                  $1 ? (not($after_ws) || $is_cur_word ? "$1$2$3" : _expand_tilde($2, $3)) :
                      $4 ? $4 :
                          ($is_cur_word ? "\$$5" : $ENV{$5})
                              !egx;
    $word;
}

sub _add_double_quoted {
    no warnings 'uninitialized';

    my ($word, $is_cur_word) = @_;

    $word =~ s!\\(.)           |  # 1) escaped char
               \$(\w+)            # 2) variable name
              !
                  $1 ? $1 :
                      ($is_cur_word ? "\$$2" : $ENV{$2})
                          !egx;
    $word;
}

sub _add_single_quoted {
    my $word = shift;
    $word =~ s/\\(.)/$1/g;
    $word;
}

$SPEC{point} = {
    v => 1.1,
    summary => 'Return line with point marked by a marker',
    description => <<'_',

This is a utility function useful for testing/debugging. `parse_cmdline()`
expects a command-line and a cursor position (`$line`, `$point`). This routine
expects `$line` with a marker character (by default it's the caret, `^`) and
return (`$line`, `$point`) to feed to `parse_cmdline()`.

Example:

    point("^foo") # => ("foo", 0)
    point("fo^o") # => ("foo", 2)

_
    args_as => 'array',
    args => {
        cmdline => {
            summary => 'Command-line which contains a marker character',
            schema => 'str*',
            pos => 0,
        },
        marker => {
            summary => 'Marker character',
            schema => ['str*', len=>1],
            default => '^',
            pos => 1,
        },
    },
    result_naked => 1,
};
sub point {
    my ($line, $marker) = @_;
    $marker //= '^';

    my $point = index($line, $marker);
    die "BUG: No marker '$marker' in line <$line>" unless $point >= 0;
    $line =~ s/\Q$marker\E//;
    ($line, $point);
}

$SPEC{parse_cmdline} = {
    v => 1.1,
    summary => 'Parse shell command-line for processing by completion routines',
    description => <<'_',

This function basically converts `COMP_LINE` (str) and `COMP_POINT` (int) into
something like (but not exactly the same as) `COMP_WORDS` (array) and
`COMP_CWORD` (int) that bash supplies to shell functions.

The differences with bash are (these differences are mostly for parsing
convenience for programs that use this routine; this comparison is made against
bash versions 4.2-4.3):

1) quotes and backslashes are stripped (bash's `COMP_WORDS` contains all the
   quotes and backslashes);

2) quoted phrase that contains spaces, or phrase that contains escaped spaces is
   parsed as a single word. For example:

    command "First argument" Second\ argument

   bash would split it as (represented as Perl):

    ["command", "\"First", "argument\"", "Second\\", "argument"]

   which is not very convenient. We parse it into:

    ["command", "First argument", "Second argument"]

3) variables are substituted with their values from environment variables except
   for the current word (`COMP_WORDS[COMP_CWORD]`) (bash does not perform
   variable substitution for `COMP_WORDS`). However, note that special shell
   variables that are not environment variables like `$0`, `$_`, `$IFS` will not
   be replaced correctly because bash does not export those variables for us.

4) tildes (`~`) are expanded with user's home directory except for the current
   word (bash does not perform tilde expansion for `COMP_WORDS`);

Caveats:

* Like bash, we group non-whitespace word-breaking characters into its own word.
  By default `COMP_WORDBREAKS` is:

    "'@><=;|&(:

  So if raw command-line is:

    command --foo=bar http://example.com:80 mail@example.org Foo::Bar

  then the parse result will be:

    ["command", "--foo", "=", "bar", "http", ":", "//example.com", ":", "80", "Foo", "::", "Bar"]

  which is annoying sometimes. But we follow bash here so we can more easily
  accept input from a joined `COMP_WORDS` if we write completion bash functions,
  e.g. (in the example, `foo` is a Perl script):

    _foo ()
    {
        local words=(${COMP_CWORDS[@]})
        # add things to words, etc
        local point=... # calculate the new point
        COMPREPLY=( `COMP_LINE="foo ${words[@]}" COMP_POINT=$point foo` )
    }

  To avoid these word-breaking characters to be split/grouped, we can escape
  them with backslash or quote them, e.g.:

    command "http://example.com:80" Foo\:\:Bar

  which bash will parse as:

    ["command", "\"http://example.com:80\"", "Foo\\:\\:Bar"]

  and we parse as:

    ["command", "http://example.com:80", "Foo::Bar"]

* Due to the way bash parses the command line (see above), the two below are
  equivalent:

    % cmd --foo=bar
    % cmd --foo = bar

Because they both expand to `['--foo', '=', 'bar']`. But obviously
<pm:Getopt::Long> does not regard the two as equivalent.

_
    args_as => 'array',
    args => {
        cmdline => {
            summary => 'Command-line, defaults to COMP_LINE environment',
            schema => 'str*',
            pos => 0,
        },
        point => {
            summary => 'Point/position to complete in command-line, '.
                'defaults to COMP_POINT',
            schema => 'int*',
            pos => 1,
        },
        opts => {
            summary => 'Options',
            schema => 'hash*',
            description => <<'_',

Optional. Known options:

* `truncate_current_word` (bool). If set to 1, will truncate current word to the
  position of cursor, for example (`^` marks the position of cursor):
  `--vers^oo` to `--vers` instead of `--versoo`. This is more convenient when
  doing tab completion.

_
            schema => 'hash*',
            pos => 2,
        },
    },
    result => {
        schema => ['array*', len=>2],
        description => <<'_',

Return a 2-element array: `[$words, $cword]`. `$words` is array of str,
equivalent to `COMP_WORDS` provided by bash to shell functions. `$cword` is an
integer, roughly equivalent to `COMP_CWORD` provided by bash to shell functions.
The word to be completed is at `$words->[$cword]`.

Note that COMP_LINE includes the command name. If you want the command-line
arguments only (like in `@ARGV`), you need to strip the first element from
`$words` and reduce `$cword` by 1.


_
    },
    result_naked => 1,
    links => [
    ],
};
sub parse_cmdline {
    no warnings 'uninitialized';
    my ($line, $point, $opts) = @_;

    $line  //= $ENV{COMP_LINE};
    $point //= $ENV{COMP_POINT} // 0;

    die "$0: COMP_LINE not set, make sure this script is run under ".
        "bash completion (e.g. through complete -C)\n" unless defined $line;

    log_trace "[compbash] line=<$line> point=<$point>"
        if $ENV{COMPLETE_BASH_TRACE};

    my @words;
    my $cword;
    my $pos = 0;
    my $pos_min_ws = 0;
    my $after_ws = 1; # XXX what does this variable mean?
    my $chunk;
    my $add_blank;
    my $is_cur_word;
    $line =~ s!(                                                         # 1) everything
                  (")((?: \\\\|\\"|[^"])*)(?:"|\z)(\s*)               |  #  2) open "  3) content  4) space after
                  (')((?: \\\\|\\'|[^'])*)(?:'|\z)(\s*)               |  #  5) open '  6) content  7) space after
                  ((?: \\\\|\\"|\\'|\\=|\\\s|[^"'@><=|&\(:\s])+)(\s*) |  #  8) unquoted word  9) space after
                  ([\@><=|&\(:]+) |                                      #  10) non-whitespace word-breaking characters
                  \s+
              )!
                  $pos += length($1);
                  #say "D: \$1=<$1> \$2=<$3> \$3=<$3> \$4=<$4> \$5=<$5> \$6=<$6> \$7=<$7> \$8=<$8> \$9=<$9> \$10=<$10>";
                  #say "D:<$1> pos=$pos, point=$point, cword=$cword, after_ws=$after_ws";

                  if ($2 || $5 || defined($8)) {
                      # double-quoted/single-quoted/unquoted chunk

                      if (not(defined $cword)) {
                          $pos_min_ws = $pos - length($2 ? $4 : $5 ? $7 : $9);
                          #say "D:pos_min_ws=$pos_min_ws";
                          if ($point <= $pos_min_ws) {
                              $cword = @words - ($after_ws ? 0 : 1);
                          } elsif ($point < $pos) {
                              $cword = @words + 1 - ($after_ws ? 0 : 1);
                              $add_blank = 1;
                          }
                      }

                      if ($after_ws) {
                          $is_cur_word = defined($cword) && $cword==@words;
                      } else {
                          $is_cur_word = defined($cword) && $cword==@words-1;
                      }
                      #say "D:is_cur_word=$is_cur_word";
                      $chunk =
                          $2 ? _add_double_quoted($3, $is_cur_word) :
                              $5 ? _add_single_quoted($6) :
                              _add_unquoted($8, $is_cur_word, $after_ws);
                      if ($opts && $opts->{truncate_current_word} &&
                              $is_cur_word && $pos > $point) {
                          $chunk = substr(
                              $chunk, 0, length($chunk)-($pos_min_ws-$point));
                          #say "D:truncating current word to <$chunk>";
                      }
                      if ($after_ws) {
                          push @words, $chunk;
                      } else {
                          $words[-1] .= $chunk;
                      }
                      if ($add_blank) {
                          push @words, '';
                          $add_blank = 0;
                      }
                      $after_ws = ($2 ? $4 : $5 ? $7 : $9) ? 1:0;

                  } elsif ($10) {
                      # non-whitespace word-breaking characters
                      push @words, $10;
                      $after_ws = 1;
                  } else {
                      # whitespace
                      $after_ws = 1;
                  }
    !egx;

    $cword //= @words;
    $words[$cword] //= '';

    log_trace "[compbash] words=%s, cword=%s", \@words, $cword
        if $ENV{COMPLETE_BASH_TRACE};

    [\@words, $cword];
}

$SPEC{join_wordbreak_words} = {
    v => 1.1,
    summary => 'Post-process parse_cmdline() result by joining some words',
    description => <<'_',

`parse_cmdline()`, like bash, splits some characters that are considered as
word-breaking characters:

    "'@><=;|&(:

So if command-line is:

    command -MData::Dump bob@example.org

then they will be parsed as:

    ["command", "-MData", "::", "Dump", "bob", '@', "example.org"]

Normally in Perl applications, we want `:`, `@` to be part of word. So this
routine will convert the above into:

    ["command", "-MData::Dump", 'bob@example.org']

_
};
sub join_wordbreak_words {
    my ($words, $cword) = @_;
    my $new_words = [];
    my $i = -1;
    while (++$i < @$words) {
        my $w = $words->[$i];
        if ($w =~ /\A[\@=:]+\z/) {
            if (@$new_words and $#$new_words != $cword) {
                $new_words->[-1] .= $w;
                $cword-- if $cword >= $i || $cword >= @$new_words;
            } else {
                push @$new_words, $w;
            }
            if ($i+1 < @$words) {
                $i++;
                $new_words->[-1] .= $words->[$i];
                $cword-- if $cword >= $i || $cword >= @$new_words;
            }
        } else {
            push @$new_words, $w;
        }
    }
    [$new_words, $cword];
}

sub _terminal_width {
    # XXX need to cache?
    if (eval { require Term::Size; 1 }) {
        my ($cols, undef) = Term::Size::chars();
        $cols;
    } else {
        $ENV{COLUMNS} // 80;
    }
}

# given terminal width & number of columns, calculate column width
sub _column_width {
    my ($terminal_width, $num_columns) = @_;
    if (defined $num_columns && $num_columns > 0) {
        int( ($terminal_width - ($num_columns-1)*2) / $num_columns ) - 1;
    } else {
        undef;
    }
}

# given terminal width & column width, calculate number of columns
sub _num_columns {
    my ($terminal_width, $column_width) = @_;
    my $n = int( ($terminal_width+2) / ($column_width+2) );
    $n >= 1 ? $n : 1;
}

$SPEC{format_completion} = {
    v => 1.1,
    summary => 'Format completion for output (for shell)',
    description => <<'_',

Bash accepts completion reply in the form of one entry per line to STDOUT. Some
characters will need to be escaped. This function helps you do the formatting,
with some options.

This function accepts completion answer structure as described in the `Complete`
POD. Aside from `words`, this function also recognizes these keys:

* `as` (str): Either `string` (the default) or `array` (to return array of lines
  instead of the lines joined together). Returning array is useful if you are
  doing completion inside `Term::ReadLine`, for example, where the library
  expects an array.

* `esc_mode` (str): Escaping mode for entries. Either `default` (most
  nonalphanumeric characters will be escaped), `shellvar` (like `default`, but
  dollar sign `$` will not be escaped, convenient when completing environment
  variables for example), `filename` (currently equals to `default`), `option`
  (currently equals to `default`), or `none` (no escaping will be done).

* `path_sep` (str): If set, will enable "path mode", useful for
  completing/drilling-down path. Below is the description of "path mode".

  In shell, when completing filename (e.g. `foo`) and there is only a single
  possible completion (e.g. `foo` or `foo.txt`), the shell will display the
  completion in the buffer and automatically add a space so the user can move to
  the next argument. This is also true when completing other values like
  variables or program names.

  However, when completing directory (e.g. `/et` or `Downloads`) and there is
  solely a single completion possible and it is a directory (e.g. `/etc` or
  `Downloads`), the shell automatically adds the path separator character
  instead (`/etc/` or `Downloads/`). The user can press Tab again to complete
  for files/directories inside that directory, and so on. This is obviously more
  convenient compared to when shell adds a space instead.

  The `path_sep` option, when set, will employ a trick to mimic this behaviour.
  The trick is, if you have a completion array of `['foo/']`, it will be changed
  to `['foo/', 'foo/ ']` (the second element is the first element with added
  space at the end) to prevent bash from adding a space automatically.

  Path mode is not restricted to completing filesystem paths. Anything path-like
  can use it. For example when you are completing Java or Perl module name (e.g.
  `com.company.product.whatever` or `File::Spec::Unix`) you can use this mode
  (with `path_sep` appropriately set to, e.g. `.` or `::`).

_
    args_as => 'array',
    args => {
        completion => {
            summary => 'Completion answer structure',
            description => <<'_',

Either an array or hash. See function description for more details.

_
            schema=>['any*' => of => ['hash*', 'array*']],
            req=>1,
            pos=>0,
        },
        opts => {
            summary => 'Specify options',
            schema=>'hash*',
            pos=>1,
            description => <<'_',

Known options:

* word

  A workaround. String. For now, see source code for more details.

* show_summaries

  Whether to show item's summaries. Boolean, default is from
  COMPLETE_BASH_SHOW_SUMMARIES environment variable or 1.

  An answer item contain summary, which is a short description about the item,
  e.g.:

      [{word=>"-a"    , summary=>"Show hidden files"},
       {word=>"-l"    , summary=>"Show details"},
       {word=>"--sort", summary=>"Specify sort order"}],

  When summaries are not shown, user will just be seeing something like:

      -a
      -l
      --sort

  But when summaries are shown, user will see:

      -a         -- Show hidden files
      -l         -- Show details
      --sort     -- Specify sort order

  which is quite helpful.

_

        },
    },
    result => {
        summary => 'Formatted string (or array, if `as` is set to `array`)',
        schema => ['any*' => of => ['str*', 'array*']],
    },
    result_naked => 1,
};
sub format_completion {
    my ($hcomp, $opts) = @_;

    $opts //= {};

    $hcomp = {words=>$hcomp} unless ref($hcomp) eq 'HASH';
    my $words    = $hcomp->{words};
    my $as       = $hcomp->{as} // 'string';
    # 'escmode' key is deprecated (Complete 0.11-) and will be removed later
    my $esc_mode = $hcomp->{esc_mode} // $hcomp->{escmode} // 'default';
    my $path_sep = $hcomp->{path_sep};

    my @res;
    my @summaries;
    my $has_summary;

  FORMAT_MESSAGE:
    # display a message instead of list of words. we send " " (ASCII space)
    # which bash does not display, so we can display a line of message while the
    # user does not get the message as the completion. I've also tried \000 to
    # \037 instead of space (\040) but nothing works better.
    if (defined $hcomp->{message}) {
        my $msg = $hcomp->{message};
        if ($msg =~ /\A /) {
            $msg =~ s/\A +//;
            $msg = " (empty message)" unless length $msg;
        }
        @res = (sprintf("%-"._terminal_width()."s", $msg), " ");
        goto RETURN_RES;
    }

  WORKAROUND_PREVENT_BASH_FROM_INSERTING_SPACE:
    if (defined($path_sep) && @$words == 1) {
        my $re = qr/\Q$path_sep\E\z/;
        my $word;
        if (ref($words->[0]) eq 'HASH') {
            $words = [$words->[0], {word=>"$words->[0] "}] if
                $words->[0]{word} =~ $re;
        } else {
            $words = [$words->[0], "$words->[0] "]
                if $words->[0] =~ $re;
        }
    }

  WORKAROUND_WITH_WORDBREAKS:
    # this is a workaround. since bash breaks words using characters in
    # $COMP_WORDBREAKS, which by default is "'@><=;|&(: this presents a problem
    # we often encounter: if we want to provide with a list of strings
    # containing say ':', most often Perl modules/packages, if user types e.g.
    # "Text::AN" and we provide completion ["Text::ANSI"] then bash will change
    # the word at cursor to become "Text::Text::ANSI" since it sees the current
    # word as "AN" and not "Text::AN". the workaround is to chop /^Text::/ from
    # completion answers. btw, we actually chop /^text::/i to handle
    # case-insensitive matching, although this does not have the ability to
    # replace the current word (e.g. if we type 'text::an' then bash can only
    # replace the current word 'an' with 'ANSI).
    if (defined($opts->{word})) {
        if ($opts->{word} =~ s/(.+[\@><=;|&\(:])//) {
            my $prefix = $1;
            for (@$words) {
                if (ref($_) eq 'HASH') {
                    $_->{word} =~ s/\A\Q$prefix\E//i;
                } else {
                    s/\A\Q$prefix\E//i;
                }
            }
        }
    }

  ESCAPE_WORDS:
    for my $entry (@$words) {
        my $word    = ref($entry) eq 'HASH' ? $entry->{word}    : $entry;
        my $summary = (ref($entry) eq 'HASH' ? $entry->{summary} : undef) // '';
        if ($esc_mode eq 'shellvar') {
            # don't escape $
            $word =~ s!([^A-Za-z0-9,+._/\$~-])!\\$1!g;
        } elsif ($esc_mode eq 'none') {
            # no escaping
        } else {
            # default
            $word =~ s!([^A-Za-z0-9,+._/:~-])!\\$1!g;
        }
        push @res, $word;
        push @summaries, $summary;
        $has_summary = 1 if length $summary;
    }

    my $summary_align = $ENV{COMPLETE_BASH_SUMMARY_ALIGN} // 'left';
    my $max_columns = $ENV{COMPLETE_BASH_MAX_COLUMNS} // 0;
    my $terminal_width = _terminal_width();
    my $column_width = _column_width($terminal_width, $max_columns);

    #warn "terminal_width=$terminal_width, column_width=".($column_width // 'undef')."\n";

  SORT: {
        # we pre-sort because we want to draw summary lines every N row
        last unless $summary_align eq 'right';
        my @orders = sort {
            # XXX how does bash sort completion entries, exactly? this is still
            # not right. bash puts -\? between --debug and --format.
            my $e1 = lc $res[$a]; $e1 =~ s/[^A-Za-z0-9]+//;
            my $e2 = lc $res[$b]; $e2 =~ s/[^A-Za-z0-9]+//;
            $e1 cmp $e2;
        } 0..$#res;
        @res = map { $res[$_] } @orders;
        @summaries = map { $summaries[$_] } @orders;
    }

  INSERT_SUMMARIES: {
        last if @res <= 1;
        last unless $has_summary;
        last unless $opts->{show_summaries} //
            $ENV{COMPLETE_BASH_SHOW_SUMMARIES} // 1;
        my $max_entry_width   = 8;
        my $max_summ_width = 0;
        for (0..$#res) {
            $max_entry_width = length $res[$_]
                if $max_entry_width < length $res[$_];
            $max_summ_width = length $summaries[$_]
                if $max_summ_width < length $summaries[$_];
        }
        #warn "max_entry_width=$max_entry_width, max_summ_width=$max_summ_width\n";
        if ($summary_align eq 'right') {
            # if we are aligning summary to the right, we want to fill column
            # width width
            if ($max_columns <= 0) {
                $max_columns = _num_columns(
                    $terminal_width, ($max_entry_width + 2 + $max_summ_width));
            }
            $column_width = _column_width($terminal_width, $max_columns);
            my $new_max_summ_width = $column_width - 2 - $max_entry_width;
            $max_summ_width = $new_max_summ_width
                if $max_summ_width < $new_max_summ_width;
            #warn "max_columns=$max_columns, column_width=$column_width, max_summ_width=$max_summ_width\n";
        }

        my $line_every = $ENV{COMPLETE_BASH_SUMMARY_LINE_EVERY} // 4;
        for (0..$#res) {
            my $summary = $summaries[$_];
            if ($max_columns == 1 &&
                    $summary_align eq 'right' && ($_+1) % $line_every == 0) {
                $summary = ("_" x ($max_summ_width - length $summary)) .
                    $summary;
            }
            if (length $summary) {
                $res[$_] = sprintf(
                    "%-${max_entry_width}s |%".
                        ($summary_align eq 'right' ? $max_summ_width : '')."s",
                    $res[$_], $summary);
            }
        }
    } # INSERT_SUMMARIES

  MAX_COLUMNS: {
        last unless $max_columns > 0;
        my $max_entry_width = 0;
        for (@res) {
            $max_entry_width = length if $max_entry_width < length;
        }
        last if $max_entry_width >= $column_width;
        for (@res) {
            $_ .= " " x ($column_width - length) if $column_width > length;
        }
    }

  RETURN_RES:
    if ($as eq 'array') {
        return \@res;
    } else {
        return join("", map {($_, "\n")} @res);
    }
}

1;
# ABSTRACT: Completion routines for bash shell

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Bash - Completion routines for bash shell

=head1 VERSION

This document describes version 0.324 of Complete::Bash (from Perl distribution Complete-Bash), released on 2019-06-28.

=head1 DESCRIPTION

This module provides routines related to tab completion in bash shell.

=head2 About programmable completion in bash

Bash allows completion to come from various sources. The simplest is from a list
of words (C<-W>):

 % complete -W "one two three four" somecmd
 % somecmd t<Tab>
 two  three

Another source is from a bash function (C<-F>). The function will receive input
in two variables: C<COMP_WORDS> (array, command-line chopped into words) and
C<COMP_CWORD> (integer, index to the array of words indicating the cursor
position). It must set an array variable C<COMPREPLY> that contains the list of
possible completion:

 % _foo()
 {
   local cur
   COMPREPLY=()
   cur=${COMP_WORDS[COMP_CWORD]}
   COMPREPLY=($( compgen -W '--help --verbose --version' -- $cur ) )
 }
 % complete -F _foo foo
 % foo <Tab>
 --help  --verbose  --version

And yet another source is an external command (C<-C>) including, from a Perl
script. The command receives two environment variables: C<COMP_LINE> (string,
raw command-line) and C<COMP_POINT> (integer, cursor location). Program must
split C<COMP_LINE> into words, find the word to be completed, complete that, and
return the list of words one per-line to STDOUT. An example:

 % cat foo-complete
 #!/usr/bin/perl
 use Complete::Bash qw(parse_cmdline format_completion);
 use Complete::Util qw(complete_array_elem);
 my ($words, $cword) = @{ parse_cmdline() };
 my $res = complete_array_elem(array=>[qw/--help --verbose --version/], word=>$words->[$cword]);
 print format_completion($res);

 % complete -C foo-complete foo
 % foo --v<Tab>
 --verbose --version

=head2 About the routines in this module

First of all, C<parse_cmdline()> is the function to parse raw command-line (such
as what you get from bash in C<COMP_LINE> environment variable) into words. This
makes it easy for the other functions to generate completion answer. See the
documentation for that function for more details.

C<format_completion()> is what you use to format completion answer structure for
bash.

=head1 FUNCTIONS


=head2 format_completion

Usage:

 format_completion($completion, $opts) -> str|array

Format completion for output (for shell).

Bash accepts completion reply in the form of one entry per line to STDOUT. Some
characters will need to be escaped. This function helps you do the formatting,
with some options.

This function accepts completion answer structure as described in the C<Complete>
POD. Aside from C<words>, this function also recognizes these keys:

=over

=item * C<as> (str): Either C<string> (the default) or C<array> (to return array of lines
instead of the lines joined together). Returning array is useful if you are
doing completion inside C<Term::ReadLine>, for example, where the library
expects an array.

=item * C<esc_mode> (str): Escaping mode for entries. Either C<default> (most
nonalphanumeric characters will be escaped), C<shellvar> (like C<default>, but
dollar sign C<$> will not be escaped, convenient when completing environment
variables for example), C<filename> (currently equals to C<default>), C<option>
(currently equals to C<default>), or C<none> (no escaping will be done).

=item * C<path_sep> (str): If set, will enable "path mode", useful for
completing/drilling-down path. Below is the description of "path mode".

In shell, when completing filename (e.g. C<foo>) and there is only a single
possible completion (e.g. C<foo> or C<foo.txt>), the shell will display the
completion in the buffer and automatically add a space so the user can move to
the next argument. This is also true when completing other values like
variables or program names.

However, when completing directory (e.g. C</et> or C<Downloads>) and there is
solely a single completion possible and it is a directory (e.g. C</etc> or
C<Downloads>), the shell automatically adds the path separator character
instead (C</etc/> or C<Downloads/>). The user can press Tab again to complete
for files/directories inside that directory, and so on. This is obviously more
convenient compared to when shell adds a space instead.

The C<path_sep> option, when set, will employ a trick to mimic this behaviour.
The trick is, if you have a completion array of C<['foo/']>, it will be changed
to C<['foo/', 'foo/ ']> (the second element is the first element with added
space at the end) to prevent bash from adding a space automatically.

Path mode is not restricted to completing filesystem paths. Anything path-like
can use it. For example when you are completing Java or Perl module name (e.g.
C<com.company.product.whatever> or C<File::Spec::Unix>) you can use this mode
(with C<path_sep> appropriately set to, e.g. C<.> or C<::>).

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$completion>* => I<hash|array>

Completion answer structure.

Either an array or hash. See function description for more details.

=item * B<$opts> => I<hash>

Specify options.

Known options:

=over

=item * word

A workaround. String. For now, see source code for more details.

=item * show_summaries

Whether to show item's summaries. Boolean, default is from
COMPLETE_BASH_SHOW_SUMMARIES environment variable or 1.

An answer item contain summary, which is a short description about the item,
e.g.:

  [{word=>"-a"    , summary=>"Show hidden files"},
   {word=>"-l"    , summary=>"Show details"},
   {word=>"--sort", summary=>"Specify sort order"}],

When summaries are not shown, user will just be seeing something like:

  -a
  -l
  --sort

But when summaries are shown, user will see:

  -a         -- Show hidden files
  -l         -- Show details
  --sort     -- Specify sort order

which is quite helpful.

=back

=back

Return value: Formatted string (or array, if `as` is set to `array`) (str|array)



=head2 join_wordbreak_words

Usage:

 join_wordbreak_words() -> [status, msg, payload, meta]

Post-process parse_cmdline() result by joining some words.

C<parse_cmdline()>, like bash, splits some characters that are considered as
word-breaking characters:

 "'@><=;|&(:

So if command-line is:

 command -MData::Dump bob@example.org

then they will be parsed as:

 ["command", "-MData", "::", "Dump", "bob", '@', "example.org"]

Normally in Perl applications, we want C<:>, C<@> to be part of word. So this
routine will convert the above into:

 ["command", "-MData::Dump", 'bob@example.org']

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 parse_cmdline

Usage:

 parse_cmdline($cmdline, $point, $opts) -> array

Parse shell command-line for processing by completion routines.

This function basically converts C<COMP_LINE> (str) and C<COMP_POINT> (int) into
something like (but not exactly the same as) C<COMP_WORDS> (array) and
C<COMP_CWORD> (int) that bash supplies to shell functions.

The differences with bash are (these differences are mostly for parsing
convenience for programs that use this routine; this comparison is made against
bash versions 4.2-4.3):

1) quotes and backslashes are stripped (bash's C<COMP_WORDS> contains all the
   quotes and backslashes);

2) quoted phrase that contains spaces, or phrase that contains escaped spaces is
   parsed as a single word. For example:

 command "First argument" Second\ argument

   bash would split it as (represented as Perl):

 ["command", "\"First", "argument\"", "Second\\", "argument"]

   which is not very convenient. We parse it into:

 ["command", "First argument", "Second argument"]

3) variables are substituted with their values from environment variables except
   for the current word (C<COMP_WORDS[COMP_CWORD]>) (bash does not perform
   variable substitution for C<COMP_WORDS>). However, note that special shell
   variables that are not environment variables like C<$0>, C<$_>, C<$IFS> will not
   be replaced correctly because bash does not export those variables for us.

4) tildes (C<~>) are expanded with user's home directory except for the current
   word (bash does not perform tilde expansion for C<COMP_WORDS>);

Caveats:

=over

=item * Like bash, we group non-whitespace word-breaking characters into its own word.
By default C<COMP_WORDBREAKS> is:

"'@><=;|&(:

So if raw command-line is:

command --foo=bar http://example.com:80 mail@example.org Foo::Bar

then the parse result will be:

["command", "--foo", "=", "bar", "http", ":", "//example.com", ":", "80", "Foo", "::", "Bar"]

which is annoying sometimes. But we follow bash here so we can more easily
accept input from a joined C<COMP_WORDS> if we write completion bash functions,
e.g. (in the example, C<foo> is a Perl script):

I<foo ()
{
    local words=(${COMP>CWORDS[@]})
    # add things to words, etc
    local point=... # calculate the new point
    COMPREPLY=( C<COMP_LINE="foo ${words[@]}" COMP_POINT=$point foo> )
}

To avoid these word-breaking characters to be split/grouped, we can escape
them with backslash or quote them, e.g.:

command "http://example.com:80" Foo\:\:Bar

which bash will parse as:

["command", "\"http://example.com:80\"", "Foo\:\:Bar"]

and we parse as:

["command", "http://example.com:80", "Foo::Bar"]

=item * Due to the way bash parses the command line (see above), the two below are
equivalent:

% cmd --foo=bar
% cmd --foo = bar

=back

Because they both expand to C<['--foo', '=', 'bar']>. But obviously
L<Getopt::Long> does not regard the two as equivalent.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$cmdline> => I<str>

Command-line, defaults to COMP_LINE environment.

=item * B<$opts> => I<hash>

Options.

Optional. Known options:

=over

=item * C<truncate_current_word> (bool). If set to 1, will truncate current word to the
position of cursor, for example (C<^> marks the position of cursor):
C<--vers^oo> to C<--vers> instead of C<--versoo>. This is more convenient when
doing tab completion.

=back

=item * B<$point> => I<int>

Point/position to complete in command-line, defaults to COMP_POINT.

=back

Return value:  (array)


Return a 2-element array: C<[$words, $cword]>. C<$words> is array of str,
equivalent to C<COMP_WORDS> provided by bash to shell functions. C<$cword> is an
integer, roughly equivalent to C<COMP_CWORD> provided by bash to shell functions.
The word to be completed is at C<< $words-E<gt>[$cword] >>.

Note that COMP_LINE includes the command name. If you want the command-line
arguments only (like in C<@ARGV>), you need to strip the first element from
C<$words> and reduce C<$cword> by 1.



=head2 point

Usage:

 point($cmdline, $marker) -> any

Return line with point marked by a marker.

This is a utility function useful for testing/debugging. C<parse_cmdline()>
expects a command-line and a cursor position (C<$line>, C<$point>). This routine
expects C<$line> with a marker character (by default it's the caret, C<^>) and
return (C<$line>, C<$point>) to feed to C<parse_cmdline()>.

Example:

 point("^foo") # => ("foo", 0)
 point("fo^o") # => ("foo", 2)

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$cmdline> => I<str>

Command-line which contains a marker character.

=item * B<$marker> => I<str> (default: "^")

Marker character.

=back

Return value:  (any)

=head1 ENVIRONMENT

=head2 COMPLETE_BASH_MAX_COLUMNS

Uint.

Bash will show completion entries in one or several columns, depending on the
terminal width and the length of the entries (much like a standard non-long
`ls`). If you prefer completion entries to be shown in a single column no matter
how wide your terminal is, or how short the entries are, you can set the value
of this variable to 1. If you prefer a maximum of two columns, set to 2, and so
on. L</format_completion> will pad the entries with sufficient spaces to limit
the number of columns.

=head2 COMPLETE_BASH_SHOW_SUMMARIES

Bool. Will set the default for C<show_summaries> option in
L</format_completion>.

=head2 COMPLETE_BASH_SUMMARY_ALIGN

String. Either C<left> (the default) or C<right>.

The C<left> align looks something like this:

 --bar      Summary about the bar option
 --baz      Summary about the baz option
 --foo      Summary about the foo option
 --schapen  Summary about the schapen option

The C<right> align will make the completion answer look like what you see in the
B<fish> shell:

 --bar                        Summary about the bar option
 --baz                        Summary about the baz option
 --foo                        Summary about the foo option
 --schapen                Summary about the schapen option

To help match the option and its corresponding summary visually, by default a
line of underscores is drawn for every 5 lines (configurable via
L</COMPLETE_BASH_SUMMARY_LINE_EVERY>.

 --bar                        Summary about the bar option
 --baz                        Summary about the baz option
 --foo                        Summary about the foo option
 --foobar   _______________Summary about the foobar option
 --lam                        Summary about the lam option
 --qux
 --quux                                    Alias for --qux
 --schapen  ______________Summary about the schapen option

=head2 COMPLETE_BASH_SUMMARY_LINE_EVERY

Uint. Default: 4.

Relevant only when L</COMPLETE_BASH_SUMMARY_ALIGN> is set to C<right> (see its
documentation for more detail).

=head2 COMPLETE_BASH_TRACE

Bool. If set to true, will produce more log statements to L<Log::ger>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Bash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Bash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Bash>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>, the convention that this module follows.

Some higher-level modules that use this module (so you don't have to use this
module directly): L<Getopt::Long::Complete> (via L<Complete::Getopt::Long>),
L<Getopt::Long::Subcommand>, L<Perinci::CmdLine> (via
L<Perinci::Sub::Complete>).

Other modules related to bash shell tab completion: L<Bash::Completion>,
L<Getopt::Complete>, L<Term::Bash::Completion::Generator>.

Programmable Completion section in Bash manual:
L<https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018, 2016, 2015, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

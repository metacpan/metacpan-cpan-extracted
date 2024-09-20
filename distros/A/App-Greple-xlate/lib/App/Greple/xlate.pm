package App::Greple::xlate;

our $VERSION = "0.3401";

=encoding utf-8

=head1 NAME

App::Greple::xlate - translation support module for greple

=head1 SYNOPSIS

    greple -Mxlate -e ENGINE --xlate pattern target-file

    greple -Mxlate::deepl --xlate pattern target-file

=head1 VERSION

Version 0.3401

=head1 DESCRIPTION

B<Greple> B<xlate> module find desired text blocks and replace them by
the translated text.  Currently DeepL (F<deepl.pm>) and ChatGPT
(F<gpt3.pm>) module are implemented as a back-end engine.
Experimental support for gpt-4 and gpt-4o are also included.

If you want to translate normal text blocks in a document written in
the Perl's pod style, use B<greple> command with C<xlate::deepl> and
C<perl> module like this:

    greple -Mxlate::deepl -Mperl --pod --re '^(\w.*\n)+' --all foo.pm

In this command, pattern string C<^(\w.*\n)+> means consecutive lines
starting with alpha-numeric letter.  This command show the area to be
translated highlighted.  Option B<--all> is used to produce entire
text.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Then add C<--xlate> option to translate the selected area.  Then, it
will find the desired sections and replace them by the B<deepl>
command output.

By default, original and translated text is printed in the "conflict
marker" format compatible with L<git(1)>.  Using C<ifdef> format, you
can get desired part by L<unifdef(1)> command easily.  Output format
can be specified by B<--xlate-format> option.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/format-conflict.png">
</p>

If you want to translate entire text, use B<--match-all> option.  This
is a short-cut to specify the pattern C<(?s).+> which matches entire
text.

Conflict marker format data can be viewed in side-by-side style by
C<sdif> command with C<-V> option.  Since it makes no sense to compare
on a per-string basis, the C<--no-cdif> option is recommended.  If you
do not need to color the text, specify C<--no-textcolor> (or
C<--no-tc>).

    sdif -V --no-tc --no-cdif data_shishin.deepl-EN-US.cm

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/sdif-cm-view.png">
</p>

=head1 NORMALIZATION

Processing is done in specified units, but in the case of a sequence
of multiple lines of non-empty text, they are converted together into
a single line.  This operation is performed as follows:

=over 2

=item *

Remove white space at the beginning and end of each line.

=item *

If a line ends with a full-width punctuation character, concatenate
with next line.

=item *

If a line ends with a full-width character and the next line begins
with a full-width character, concatenate the lines.

=item *

If either the end or the beginning of a line is not a full-width
character, concatenate them by inserting a space character.

=back

Cache data is managed based on the normalized text, so even if
modifications are made that do not affect the normalization results,
the cached translation data will still be effective.

This normalization process is performed only for the first (0th) and
even-numbered pattern.  Thus, if two patterns are specified as
follows, the text matching the first pattern will be processed after
normalization, and no normalization process will be performed on the
text matching the second pattern.

    greple -Mxlate -E normalized -E not-normalized

Therefore, use the first pattern for text that is to be processed by
combining multiple lines into a single line, and use the second
pattern for pre-formatted text.  If there is no text to match in the
first pattern, then a pattern that does not match anything, such as
C<(?!)>.

=head1 MASKING

Occasionally, there are parts of text that you do not want translated.
For example, tags in markdown files. DeepL suggests that in such
cases, the part of the text to be excluded be converted to XML tags,
translated, and then restored after the translation is complete.  To
support this, it is possible to specify the parts to be masked from
translation.

    --xlate-setopt maskfile=MASKPATTERN

This will interpret each line of the file `MASKPATTERN` as a regular
expression, translate strings matching it, and revert after
processing.  Lines beginning with C<#> are ignored.

This interface is experimental and subject to change in the future.

=head1 OPTIONS

=over 7

=item B<--xlate>

=item B<--xlate-color>

=item B<--xlate-fold>

=item B<--xlate-fold-width>=I<n> (Default: 70)

Invoke the translation process for each matched area.

Without this option, B<greple> behaves as a normal search command.  So
you can check which part of the file will be subject of the
translation before invoking actual work.

Command result goes to standard out, so redirect to file if necessary,
or consider to use L<App::Greple::update> module.

Option B<--xlate> calls B<--xlate-color> option with B<--color=never>
option.

With B<--xlate-fold> option, converted text is folded by the specified
width.  Default width is 70 and can be set by B<--xlate-fold-width>
option.  Four columns are reserved for run-in operation, so each line
could hold 74 characters at most.

=item B<--xlate-engine>=I<engine>

Specifies the translation engine to be used. If you specify the engine
module directly, such as C<-Mxlate::deepl>, you do not need to use
this option.

At this time, the following engines are available

=over 2

=item * B<deepl>: DeepL API

=item * B<gpt3>: gpt-3.5-turbo

=item * B<gpt4>: gpt-4-turbo

=item * B<gpt4o>: gpt-4o-mini

B<gpt-4o>'s interface is unstable and cannot be guaranteed to work
correctly at the moment.

=back

=item B<--xlate-labor>

=item B<--xlabor>

Instead of calling translation engine, you are expected to work for.
After preparing text to be translated, they are copied to the
clipboard.  You are expected to paste them to the form, copy the
result to the clipboard, and hit return.

=item B<--xlate-to> (Default: C<EN-US>)

Specify the target language.  You can get available languages by
C<deepl languages> command when using B<DeepL> engine.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Specify the output format for original and translated text.

The following formats other than C<xtxt> assume that the part to be
translated is a collection of lines.  In fact, it is possible to
translate only a portion of a line, and specifying a format other than
C<xtxt> will not produce meaningful results.

=over 4

=item B<conflict>, B<cm>

Original and converted text are printed in L<git(1)> conflict marker
format.

    <<<<<<< ORIGINAL
    original text
    =======
    translated Japanese text
    >>>>>>> JA

You can recover the original file by next L<sed(1)> command.

    sed -e '/^<<<<<<< /d' -e '/^=======$/,/^>>>>>>> /d'

=item B<ifdef>

Original and converted text are printed in L<cpp(1)> C<#ifdef>
format.

    #ifdef ORIGINAL
    original text
    #endif
    #ifdef JA
    translated Japanese text
    #endif

You can retrieve only Japanese text by the B<unifdef> command:

    unifdef -UORIGINAL -DJA foo.ja.pm

=item B<space>

Original and converted text are printed separated by single blank
line.

=item B<xtxt>

If the format is C<xtxt> (translated text) or unkown, only translated
text is printed.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Specify the maximum length of text to be sent to the API at once.
Default value is set as for free DeepL account service: 128K for the
API (B<--xlate>) and 5000 for the clipboard interface
(B<--xlate-labor>).  You may be able to change these value if you are
using Pro service.

=item B<--xlate-maxline>=I<n> (Default: 0)

Specify the maximum lines of text to be sent to the API at once.

Set this value to 1 if you want to translate one line at a time.  This
option takes precedence over the C<--xlate-maxlen> option.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

See the tranlsation result in real time in the STDERR output.

=item B<--match-all>

Set the whole text of the file as a target area.

=back

=head1 CACHE OPTIONS

B<xlate> module can store cached text of translation for each file and
read it before execution to eliminate the overhead of asking to
server.  With the default cache strategy C<auto>, it maintains cache
data only when the cache file exists for target file.

=over 7

=item --cache-clear

The B<--cache-clear> option can be used to initiate cache management
or to refresh all existing cache data. Once executed with this option,
a new cache file will be created if one does not exist and then
automatically maintained afterward.

=item --xlate-cache=I<strategy>

=over 4

=item C<auto> (Default)

Maintain the cache file if it exists.

=item C<create>

Create empty cache file and exit.

=item C<always>, C<yes>, C<1>

Maintain cache anyway as far as the target is normal file.

=item C<clear>

Clear the cache data first.

=item C<never>, C<no>, C<0>

Never use cache file even if it exists.

=item C<accumulate>

By default behavior, unused data is removed from the cache file.  If
you don't want to remove them and keep in the file, use C<accumulate>.

=back

=back

=head1 COMMAND LINE INTERFACE

You can easily use this module from the command line by using the
C<xlate> command included in the distribution. See the C<xlate> help
information for usage.

The C<xlate> command works in concert with the Docker environment, so
even if you do not have anything installed on hand, you can use it as
long as Docker is available.  Use C<-D> or C<-C> option.

Also, since makefiles for various document styles are provided,
translation into other languages is possible without special
specification.  Use C<-M> option.

You can also combine the Docker and make options so that you can run
make in a Docker environment.

Running like C<xlate -GC> will launch a shell with the current working
git repository mounted.

Read Japanese article in L</SEE ALSO> section for detail.

    xlate [ options ] -t lang file [ greple options ]
	-h   help
	-v   show version
	-d   debug
	-n   dry-run
	-a   use API
	-c   just check translation area
	-r   refresh cache
	-s   silent mode
	-e # translation engine (default "deepl")
	-p # pattern to determine translation area
	-w # wrap line by # width
	-o # output format (default "xtxt", or "cm", "ifdef")
	-f # from lang (ignored)
	-t # to lang (required, no default)
	-m # max length per API call
	-l # show library files (XLATE.mk, xlate.el)
        --   terminate option parsing
    Make options
	-M   run make
	-n   dry-run
    Docker options
	-G   mount git top-level directory
	-B   run in non-interactive (batch) mode
	-R   mount read-only
	-E * specify environment variable to be inherited
	-I * specify altanative docker image (default: tecolicom/xlate:version)
	-D * run xlate on the container with the rest parameters
	-C * run following command on the container, or run shell

    Control Files:
	*.LANG    translation languates
	*.FORMAT  translation foramt (xtxt, cm, ifdef)
	*.ENGINE  translation engine (deepl or gpt3)


=head1 EMACS

Load the F<xlate.el> file included in the repository to use C<xlate>
command from Emacs editor.  C<xlate-region> function translate the
given region.  Default language is C<EN-US> and you can specify
language invoking it with prefix argument.

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Set your authentication key for DeepL service.

=item OPENAI_API_KEY

OpenAI authentication key.

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head2 TOOLS

You have to install command line tools for DeepL and ChatGPT.

L<https://github.com/DeepLcom/deepl-python>

L<https://github.com/tecolicom/App-gpty>

=head1 SEE ALSO

L<App::Greple::xlate>

L<App::Greple::xlate::deepl>

L<App::Greple::xlate::gpt3>

L<https://hub.docker.com/r/tecolicom/xlate>

=over 7

=item L<https://github.com/DeepLcom/deepl-python>

DeepL Python library and CLI command.

=item L<https://github.com/openai/openai-python>

OpenAI Python Library

=item L<https://github.com/tecolicom/App-gpty>

OpenAI command line interface

=item L<App::Greple>

See the B<greple> manual for the detail about target text pattern.
Use B<--inside>, B<--outside>, B<--include>, B<--exclude> options to
limit the matching area.

=item L<App::Greple::update>

You can use C<-Mupdate> module to modify files by the result of
B<greple> command.

=item L<App::sdif>

Use B<sdif> to show conflict marker format side by side with B<-V>
option.

=back

=head2 ARTICLES

=over 2

=item * L<https://qiita.com/kaz-utashiro/items/1c1a51a4591922e18250>

Greple module to translate and replace only the necessary parts with DeepL API (in Japanese)

=item * L<https://qiita.com/kaz-utashiro/items/a5e19736416ca183ecf6>

Generating documents in 15 languages with DeepL API module (in Japanese)

=item * L<https://qiita.com/kaz-utashiro/items/1b9e155d6ae0620ab4dd>

Automatic translation Docker environment with DeepL API (in Japanese)

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use utf8;

use Data::Dumper;

use Text::ANSI::Fold ':constants';
use App::cdif::Command;
use Hash::Util qw(lock_keys);
use Unicode::EastAsianWidth;

use Exporter 'import';
our @EXPORT_OK = qw($VERSION &opt);
our @EXPORT_TAGS = ( all => [ qw($VERSION) ] );

our %opt = (
    debug    => \(our $debug = 0),
    engine   => \(our $xlate_engine),
    progress => \(our $show_progress = 1),
    format   => \(our $output_format = 'conflict'),
    collapse => \(our $collapse_spaces = 1),
    from     => \(our $lang_from = 'ORIGINAL'),
    to       => \(our $lang_to = 'EN-US'),
    fold     => \(our $fold_line = 0),
    width    => \(our $fold_width = 70),
    auth_key => \(our $auth_key),
    method   => \(our $cache_method //= $ENV{GREPLE_XLATE_CACHE} || 'auto'),
    dryrun   => \(our $dryrun = 0),
    maxlen   => \(our $max_length = 0),
    maxline  => \(our $max_line = 0),
    prompt   => \(our $prompt),
    mask     => \(our $mask),
    maskfile => \(our $maskfile),
    glossary => \(our $glossary),
);
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

my $current_file;

our %formatter = (
    xtxt => undef,
    none => undef,
    conflict => sub {
	join '',
	    "<<<<<<< $lang_from\n",
	    $_[0],
	    "=======\n",
	    $_[1],
	    ">>>>>>> $lang_to\n";
    },
    cm => 'conflict',
    ifdef => sub {
	join '',
	    "#ifdef $lang_from\n",
	    $_[0],
	    "#endif\n",
	    "#ifdef $lang_to\n",
	    $_[1],
	    "#endif\n";
    },
    space   => sub { join "\n", @_ },
    discard => sub { '' },
);

# aliases
for (keys %formatter) {
    next if ! $formatter{$_} or ref $formatter{$_};
    $formatter{$_} = $formatter{$formatter{$_}} // die;
}

my %cache;

use App::Greple::xlate::Mask;
my $maskobj;

sub setup {
    return if state $once_called++;
    if (defined $cache_method) {
	if ($cache_method eq '') {
	    $cache_method = 'auto';
	}
	if ($cache_method =~ /^(no|never)/i) {
	    $cache_method = '';
	}
    }
    if ($xlate_engine) {
	my $mod = __PACKAGE__ . "::$xlate_engine";
	if (eval "require $mod") {
	    $mod->import;
	} else {
	    die "Engine $xlate_engine is not available.\n";
	}
	no strict 'refs';
	${"$mod\::lang_from"} = $lang_from;
	${"$mod\::lang_to"} = $lang_to;
	*XLATE = \&{"$mod\::xlate"};
	if (not defined &XLATE) {
	    die "No \"xlate\" function in $mod.\n";
	}
    }
    if (my $pat = opt('mask')) {
	$maskobj = App::Greple::xlate::Mask->new(pattern => $pat);
    }
    if (my $patfile = opt('maskfile')) {
	$maskobj = App::Greple::xlate::Mask->new(file => $patfile);
    }
}

sub normalize {
    local $_ = shift;
    my $paragraph = shift;
    if (not $paragraph) {
	return
	s{^.+}{
	    ${^MATCH}
		=~ s/\A\s+|\s+\z//gr
	}pmger;
    }
    s{^.+(?:\n.+)*}{
	${^MATCH}
	# remove leading/trailing spaces
	    =~ s/\A\s+|\s+\z//gr
	# remove newline after Japanese Punct char
	    =~ s/(?<=\p{InFullwidth})(?<=\pP)\n//gr
	# join Japanese lines without space
	    =~ s/(?<=\p{InFullwidth})\n(?=\p{InFullwidth})//gr
	# join ASCII lines with single space
	    =~ s/\s+/ /gr
    }pmger;
}

sub postgrep {
    my $grep = shift;
    my @miss;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    my($s, $e, $i) = @$m;
	    my $key = normalize $grep->cut(@$m), $i % 2 == 0;
	    if (not exists $cache{$key}) {
		$cache{$key} = undef;
		push @miss, $key;
	    }
	}
    }
    cache_update(@miss) if @miss;
}

sub _progress {
    my $opt = ref $_[0] ? shift : {};
    opt('progress') or return;
    if (my $label = $opt->{label}) { print STDERR "[xlate.pm] $label:\n" }
    for (my @s = @_) {
	my $i =()= /^/mg;
	my @m = ($i == 1 ? '╶' : '│') x $i ;
	@m[0,-1] = qw(┌ └) if $i > 1;
	s/^/sprintf "%7s ", shift(@m)/mge;
	s/(?<!\n)\z/\n/;
	print STDERR $_;
    }
}

sub cache_update {
    binmode STDERR, ':encoding(utf8)';

    my @from = @_;
    _progress({label => "From"}, @from);
    return @from if $dryrun;

    $maskobj->mask(@from) if $maskobj;
    my @chop = grep { $from[$_] =~ s/(?<!\n)\z/\n/ } keys @from;
    my @to = &XLATE(@from);
    chop @to[@chop];
    $maskobj->unmask(@to) if $maskobj;

    _progress({label => "To"}, @to);
    die "Unmatched response:\n@to" if @from != @to;
    @cache{@_} = @to;
}

sub fold_lines {
    state $fold = Text::ANSI::Fold->new(
	width     => $fold_width,
	boundary  => 'word',
	linebreak => LINEBREAK_ALL,
	runin     => 4,
	runout    => 4,
    );
    local $_ = shift;
    s/(.+)/join "\n", $fold->text($1)->chops/ge;
    $_;
}

sub strip {
    my($text, $paragraph) = @_;
    goto &paragraph_strip if $paragraph;
    my @text = $text =~ /.*\n|.+\z/g;
    my @space = map {
	[ s/\A(\s+)// ? $1 : '', s/(\h+)$//  ? $1 : ''  ]
    } @text;
    $_[0] = join '', @text;
    sub { # unstrip
	for (@_) {
	    my @text = /.*\n|.+\z/g;
	    if (@space == @text + 1) {
		push @text, '';
	    }
	    die "UNMATCH:\n".Dumper(\@text, \@space) if @text != @space;
	    for my $i (keys @text) {
		my($head, $tail) = @{$space[$i]};
		$text[$i] =~ s/\A/$head/ if length $head > 0;
		$text[$i] =~ s/\Z/$tail/ if length $tail > 0;
	    }
	    $_ = join '', @text;
	}
    };
}
sub paragraph_strip {
    local *_ = \$_[0];
    my $head = s/\A(\s+)// ? $1 : '' ;
    my $tail = s/(\h+)$//  ? $1 : '' ;
    sub {
	for (@_) {
	    s/\A/$head/ if length $head > 0;
	    s/\Z/$tail/ if length $tail > 0;
	}
    };
}
sub xlate {
    my $param = { @_ };
    my($index, $text) = @{$param}{qw(index match)};
    my $paragraph = $index % 2 == 0;
    my $unstrip = strip($text, $paragraph);
    my $key = normalize($text, $paragraph);
    my $s = $cache{$key} // "!!! TRANSLATION ERROR !!!\n";
    $unstrip->($text, $s);
    $s = fold_lines $s if $fold_line;
    if (state $formatter = $formatter{$output_format}) {
	return $formatter->($text, $s);
    } else {
	return $s;
    }
}
sub callback { goto &xlate }

sub cache_file {
    my $file = sprintf("%s.xlate-%s-%s.json",
		       $current_file, $xlate_engine, $lang_to);
    if ($cache_method eq 'auto') {
	-f $file ? $file : undef;
    } else {
	if ($cache_method and -f $current_file) {
	    $file;
	} else {
	    undef;
	}
    }
}

sub begin {
    setup if not (state $done++);
    my %args = @_;
    $current_file = delete $args{&::FILELABEL} or die;
    s/\z/\n/ if /.\z/;
    if (not defined $xlate_engine) {
	die "Select translation engine.\n";
    }
    if (my $file = cache_file) {
	my @opt;
	if ($cache_method =~ /create|clear/i) {
	    push @opt, clear => 1;
	}
	if ($cache_method =~ /accumulate/i) {
	    push @opt, accumulate => 1;
	}
	require App::Greple::xlate::Cache;
	tie %cache, 'App::Greple::xlate::Cache', $file, @opt;
	die "skip $current_file" if $cache_method eq 'create';
    }
}

sub end {
#    if (my $obj = tied %cache) {
#	$obj->update;
#    }
}

sub set {
    while (my($key, $val) = splice @_, 0, 2) {
	next if $key eq &::FILELABEL;
	die "$key: Invalid option.\n" if not exists $opt{$key};
	opt($key) = $val;
    }
}

1;

__DATA__

builtin xlate-debug!       $debug
builtin xlate-progress!    $show_progress
builtin xlate-format=s     $output_format
builtin xlate-fold-line!   $fold_line
builtin xlate-fold-width=i $fold_width
builtin xlate-from=s       $lang_from
builtin xlate-to=s         $lang_to
builtin xlate-cache:s      $cache_method
builtin xlate-engine=s     $xlate_engine
builtin xlate-dryrun       $dryrun
builtin xlate-maxlen=i     $max_length
builtin xlate-maxline=i    $max_line
builtin xlate-prompt=s     $prompt
builtin xlate-glossary=s   $glossary

builtin deepl-auth-key=s   $App::Greple::xlate::deepl::auth_key
builtin deepl-method=s     $App::Greple::xlate::deepl::method

option default --need=1 --no-regioncolor --cm=/544E,/454E,/533E,/353E

option --xlate-setopt --prologue &__PACKAGE__::set($<shift>)

option --xlate-color \
	--postgrep &__PACKAGE__::postgrep \
	--callback &__PACKAGE__::callback \
	--begin    &__PACKAGE__::begin \
	--end      &__PACKAGE__::end
option --xlate --xlate-color --color=never
option --xlate-fold --xlate --xlate-fold-line
option --xlate-labor --xlate --deepl-method=clipboard
option --xlabor --xlate-labor

option --cache-clear --xlate-cache=clear

option --match-all       --re '\A(?s).+\z'
option --match-entire    --match-all
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

#  LocalWords:  deepl ifdef unifdef Greple greple perl DeepL ChatGPT
#  LocalWords:  gpt html img src xlabor

package App::Greple::xlate;

our $VERSION = "2.00";

=encoding utf-8

=head1 NAME

App::Greple::xlate - translation support module for greple

=head1 SYNOPSIS

    greple -Mxlate --xlate-engine gpt5 --xlate pattern target-file

    greple -Mxlate --xlate-engine deepl --xlate pattern target-file

=head1 VERSION

Version 2.00

=head1 DESCRIPTION

B<Greple> B<xlate> module find desired text blocks and replace them by
the translated text.  The primary engine is GPT-5.5 (F<llm/gpt5.pm>),
which calls the L<llm|https://llm.datasette.io/> command; DeepL
(F<deepl.pm>) and legacy B<gpty>-based engines are also included.

Translations are cached per file, so re-running a command costs
nothing for unchanged text.  When a document is edited, only the
changed paragraphs are sent to the API again; a context-aware engine
also receives the surrounding translations, the raw source text
around the change, and the previous version of the edited paragraph,
so the new translation keeps the established wording (see
B<--xlate-context-window>).  Sensitive strings can be concealed
before transmission (see L</ANONYMIZATION AND TEMPLATES>).

If you want to translate normal text blocks in a document written in
the Perl's pod style, use B<greple> command with C<--xlate-engine gpt5>
and C<perl> module like this:

    greple -Mxlate --xlate-engine gpt5 -Mperl --pod --re '^([\w\pP].*\n)+' --all foo.pm

In this command, pattern string C<^([\w\pP].*\n)+> means consecutive
lines starting with alpha-numeric and punctuation letter.  This
command show the area to be translated highlighted.  Option B<--all>
is used to produce entire text.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/select-area.png">
</p>

Then add C<--xlate> option to translate the selected area.  Then, it
will find the desired sections and replace them by the translation
engine's output.

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
L<sdif|App::sdif> command with C<-V> option.  Since it makes no sense
to compare on a per-string basis, the C<--no-cdif> option is
recommended.  If you do not need to color the text, specify
C<--no-textcolor> (or C<--no-tc>).

    sdif -V --no-filename --no-tc --no-cdif data_shishin.deepl-EN-US.cm

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
first pattern, use a pattern that does not match anything, such as
C<(?!)>.

=head1 MASKING

Occasionally, there are parts of text that you do not want translated.
For example, tags in markdown files. DeepL suggests that in such
cases, the part of the text to be excluded be converted to XML tags,
translated, and then restored after the translation is complete.  To
support this, it is possible to specify the parts to be masked from
translation.

    --xlate-setopt maskfile=MASKPATTERN

This will interpret each line of the file C<MASKPATTERN> as a regular
expression, translate strings matching it, and revert after
processing.  Lines beginning with C<#> are ignored.

Complex pattern can be written on multiple lines with backslash
escaped newline.

How the text is transformed by masking can be seen by B<--xlate-mask>
option.

Masking protects markup from being translated.  To conceal sensitive
strings from the translation service itself, see L</ANONYMIZATION AND
TEMPLATES>; both can be used together.

This interface is experimental and subject to change in the future.

=head1 ANONYMIZATION AND TEMPLATES

Sensitive strings can be concealed before they are sent to the
translation API and restored in the output.  Three sources of
anonymization rules are available: a dictionary file
(B<--xlate-anonymize>), inline marks in the document itself
(B<--xlate-anonymize-mark>), and YAML front matter values
(B<--xlate-frontmatter>).  Each string is replaced by a category tag
such as C<< <person id=1 /> >> during transmission.  The concealment
target is API transmission only: local cache files store restored
plain text.  Use B<--xlate-dryrun> to inspect exactly what would be
transmitted.

For form documents (quarterly reports and the like), define the
actors up front and reference them in the body:

    ---
    報告者: 山田太郎
    発注会社: アクメ株式会社
    ---
    本件について {{ 報告者 }} が調査を行った。

Translate the template once per language with C<--xlate-template>
(and C<--xlate-frontmatter> when the values are kept in the file),
then render each case with B<pandoc-embedz> standalone mode --
values under C<global:> in an external config never reach the
translation API at all:

    greple -Mxlate --xlate --xlate-engine=gpt5 --xlate-to=EN-US \
           --xlate-template= --xlate-format=xtxt \
           --match-paragraph --all --need=0 \
           report-template.md > report-template.EN.md
    pandoc-embedz --standalone report-template.EN.md \
                  -c case-123.yaml -o report-123.EN.md < /dev/null

For inline marks, providing a macro definition config makes the same
translated template render either the real names or a redacted
version:

    # macros.yaml           # macros-redacted.yaml
    preamble: |             preamble: |
      {% macro person(name) %}{{ name }}{% endmacro %}
                              {% macro person(name) %}(関係者){% endmacro %}

Exclude embedz blocks from translation when a document contains them:

    --exclude '^```embedz\n(?s:.*?)^```\n'

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

Specifies the translation engine to be used.

At this time, the following engines are available

=over 2

=item * B<gpt5>: gpt-5.5 (via the C<llm> command)

=item * B<deepl>: DeepL API (via the C<deepl> command)

=item * B<gpt3>: gpt-3.5-turbo (legacy, via the C<gpty> command)

=item * B<gpt4o>: gpt-4o-mini (legacy, via the C<gpty> command)

=back

Engine modules are searched in backend namespaces first (C<llm>, then
C<gpty>), then directly under C<App::Greple::xlate>.  So C<gpt5> loads
C<App::Greple::xlate::llm::gpt5> which calls the C<llm> command, while
C<gpt4o> falls back to C<App::Greple::xlate::gpty::gpt4o>.  Use
C<--xlate-setopt backend=gpty> to force a specific backend.

=item B<--xlate-labor>

=item B<--xlabor>

Instead of calling translation engine, you are expected to work for.
After preparing text to be translated, they are copied to the
clipboard.  You are expected to paste them to the form, copy the
result to the clipboard, and hit return.

=item B<--xlate-to> (Default: C<EN-US>)

Specify the target language.  LLM engines accept any language name
or code the model understands; it is interpolated into the
translation prompt.  You can get available languages by C<deepl
languages> command when using B<DeepL> engine.

=item B<--xlate-from> (Default: C<ORIGINAL>)

Label used for the original text in C<conflict>, C<colon> and
C<ifdef> output formats.  With the B<DeepL> engine a non-default
value is also passed as the source language.

=item B<--xlate-format>=I<format> (Default: C<conflict>)

Specify the output format for original and translated text.

The following formats other than C<xtxt> assume that the part to be
translated is a collection of lines.  In fact, it is possible to
translate only a portion of a line, but specifying a format other than
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

=item B<colon>, I<:::::::>

The original and translated text are output in a markdown's custom
container style.

    ::::::: ORIGINAL
    original text
    :::::::
    ::::::: JA
    translated Japanese text
    :::::::

Above text will be translated to the following in HTML.

    <div class="ORIGINAL">
    original text
    </div>
    <div class="JA">
    translated Japanese text
    </div>

Number of colon is 7 by default.  If you specify colon sequence like
C<:::::>, it is used instead of 7 colons.

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

=item B<space+>

Original and converted text are printed separated by single blank
line.  For C<space+>, it also outputs a newline after the converted
text.

=item B<xtxt>

If the format is C<xtxt> (translated text) or unkown, only translated
text is printed.

=back

=item B<--xlate-maxlen>=I<chars> (Default: 0)

Specify the maximum length of text to be sent to the API at once.
The default value 0 means the engine's own limit: for the free DeepL
account service that is 128K for the API (B<--xlate>) and 5000 for
the clipboard interface (B<--xlate-labor>).  You may be able to
change these value if you are using Pro service.

=item B<--xlate-maxline>=I<n> (Default: 0)

Specify the maximum lines of text to be sent to the API at once.

Set this value to 1 if you want to translate one line at a time.  This
option takes precedence over the C<--xlate-maxlen> option.

=item B<--xlate-prompt>=I<text>

Specify a custom prompt to be sent to the translation engine.  This
option is available for the LLM engines (C<gpt3>, C<gpt4o>, C<gpt5>)
but not for DeepL.  You can customize the translation behavior by
providing specific instructions to the AI model.  If the prompt
contains C<%s>, it will be replaced with the target language name.

=item B<--xlate-context>=I<text>

Specify additional context information to be sent to the translation
engine.  This option can be used multiple times to provide multiple
context strings.  The context information helps the translation engine
understand the background and produce more accurate translations.

=item B<--xlate-context-window>=I<n>

(Context-aware engines only, e.g. C<gpt5> on the llm backend)
Number of surrounding translated blocks passed as reference context
when re-translating changed blocks (default 2).  The context also
includes the raw source text around the changed region (headings,
list structure, captions) and, when available, the previous version
of the changed text recovered from the cache, so that unchanged
wording is preserved.  Set to 0 to disable context-aware translation
entirely.
Note that each changed region is translated in its own API call and
the context can add up to about 8000 characters to the system
prompt, so context-aware translation trades some extra cost for
consistency.

=item B<--xlate-cache-seed>=I<file>

Initialize a new document's cache from another document's cache
file.  Useful for periodic reports: seed the new issue's cache with
the previous issue's, so unchanged paragraphs are not re-translated
and edited paragraphs keep the previous issue's wording.  The seed
is used only when the target cache is empty; otherwise it is
ignored with a warning.  With the default C<--xlate-cache=auto>, specifying a seed also
implies creating the new document's cache file.

=item B<--xlate-anonymize>=I<file>

Anonymize sensitive strings before they are sent to the translation
API, and restore them in the output.  The dictionary file gives one
entry per item: in JSON (canonical, machine-generatable)

    [ { "category": "person",  "text": "山田太郎" },
      { "category": "company", "regex": "アクメ(株式会社)?" } ]

or in a simple line format (C<category pattern>, C</.../> for regex).
Each item is replaced by a category tag such as C<< <person id=1 /> >>;
the same string always gets the same tag, so the model can keep track
of who is who.  Unknown JSON fields are ignored, so generators (e.g. a
local LLM extracting entities) may add their own annotations.
Category C<lit> is reserved.  Local cache files still store restored
plain text: the concealment target is API transmission only.

A dictionary can be generated by an external tool -- for example a
local model extracting sensitive entities:

    llm -m <local-model> \
        -s 'Extract sensitive entities as a JSON array of objects
            with "category" and "text" fields.' \
        < report.md > report.anon.json
    greple -Mxlate --xlate-anonymize=report.anon.json ...

A UTF-8 BOM in the file is tolerated.  Values in the front matter
line format may carry a trailing comment only on their own line, not
after the value.

=item B<--xlate-anonymize-mark>[=I<regex>]

Collect anonymization entries from inline marks in the document
itself.  Mark the first occurrence like C<{{ person("山田太郎") }}>
and every occurrence of the string document-wide is anonymized.  The
mark itself stays in the source and in the translation, so a document
can also be processed by a Jinja2-style macro processor (define the
C<person> macro to print or redact the name).  A custom I<regex> must
contain C<< (?<category>...) >> and C<< (?<text>...) >> named captures.

Note that with an optional-value option like this, a following
file argument would be taken as the value: write
C<--xlate-anonymize-mark=> (with a trailing C<=>) when using the
default notation.

Alternative notations can be configured, for example
C<< --xlate-anonymize-mark='@@(?<category>[a-z][a-z0-9_]*):(?<text>[^\n]+?)@@' >>
for C<@@person:NAME@@>-style marks, or an HTML-comment form that stays
invisible in rendered Markdown.  Mark rules are collected per
document: a string marked in one input file is not concealed in
another file of the same run (unlike front matter values, which
accumulate across files).

=item B<--xlate-template>[=I<regex>]

Treat template expressions (default: Jinja2 C<{{ ... }}>,
C<{% ... %}>, C<{# ... #}>) as opaque placeholders: instruct the
model to copy them unchanged and verify, per block, that the response
contains exactly the same expressions, each the same number of times.
Their order may change, since translation legitimately reorders them
to follow the target language word order.  A broken expression
aborts the run; the cache is checkpointed and frozen, so nothing paid
for is lost.

Note that with an optional-value option like this, a following
file argument would be taken as the value: write
C<--xlate-template=> (with a trailing C<=>) when using the
default notation.

=item B<--xlate-frontmatter>

Treat a leading C<---> ... C<---> block as YAML front matter: exclude
it from translation and from the phase-2 context slices, and add its
flat C<key: value> values to the anonymization rules (category
C<var>) as a safety net.  With multiple input files the collected
values accumulate (erring on the side of concealment).

Always leave a blank line after the closing C<--->.  With a
paragraph-style match pattern, front matter that runs directly into
the body text forms one straddling block that the exclusion cannot
suppress (a warning is printed in that case); the values are still
anonymized, but the front matter itself would be sent for
translation.

=item B<--xlate-glossary>=I<glossary>

Specify a glossary ID to be used for translation.  This option is only
available when using the DeepL engine.  The glossary ID should be obtained
from your DeepL account and ensures consistent translation of specific terms.

=item B<--xlate-dryrun>

Do not call the translation API; instead show, through the progress
display, each payload exactly as it would be transmitted (after
anonymization and masking).  Useful for checking what leaves the
machine and for estimating the cost of a run.

=item B<-->[B<no->]B<xlate-progress> (Default: True)

See the translation result in real time in the STDERR output.  The
C<From> payload is shown as transmitted, after anonymization and
masking.

=item B<--xlate-stripe>

Use L<App::Greple::stripe> module to show the matched part by zebra
striping fashion.  This is useful when the matched parts are connected
back-to-back.

The color palette is switched according to the background color of the
terminal.  If you want to specify explicitly, you can use
B<--xlate-stripe-light> or B<--xlate-stripe-dark>.

=item B<--xlate-mask>

Perform masking function and display the converted text as is without
restoration.

=item B<--match-all>

Set the whole text of the file as a target area.

=item B<--lineify-cm>

=item B<--lineify-colon>

In the case of the C<cm> and C<colon> formats, the output is split and
formatted line by line.  Therefore, if only a portion of a line is to
be translated, the expected result cannot be obtained.  These filters
fix output that is corrupted by translating part of a line into normal
line-by-line output.

In the current implementation, if multiple parts of a line are
translated, they are output as independent lines.

=back

=head1 CACHE OPTIONS

B<xlate> module can store cached text of translation for each file and
read it before execution to eliminate the overhead of asking to
server.  With the default cache strategy C<auto>, it maintains cache
data only when the cache file exists for target file.

Use B<--xlate-cache=clear> to initiate cache management or to clean up
all existing cache data.  Once executed with this option, a new cache
file will be created if one does not exist and then automatically
maintained afterward.

=over 7

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

=item B<--xlate-update>

This option forces to update cache file even if it is not necessary.

=back

=head1 COMMAND LINE INTERFACE

You can easily use this module from the command line by using the
C<xlate> command included in the distribution.  See the C<xlate> man
page for usage.

The C<xlate> command supports GNU-style long options such as
C<--to-lang>, C<--from-lang>, C<--engine>, and C<--file>.  Use
C<xlate -h> to see all available options.

The C<xlate> command works in concert with the Docker environment, so
even if you do not have anything installed on hand, you can use it as
long as Docker is available.  Use C<-D> or C<-C> option.

Docker operations are handled by L<App::dozo>, which can also be
used as a standalone command.  The C<dozo> command supports the
C<.dozorc> configuration file for persistent container settings.

Also, since makefiles for various document styles are provided,
translation into other languages is possible without special
specification.  Use C<-M> option.

You can also combine the Docker and C<make> options so that you can
run C<make> in a Docker environment.

Running like C<xlate -C> will launch a shell with the current working
git repository mounted.

Read Japanese article in L</SEE ALSO> section for detail.

=head1 EMACS

Load the F<xlate.el> file included in the repository to use C<xlate>
command from Emacs editor.  C<xlate-region> function translate the
given region.  Default language is C<EN-US> and you can specify
language invoking it with prefix argument.

=for html <p>
<img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/App-Greple-xlate/main/images/emacs.png">
</p>

=head1 ENVIRONMENT

=over 7

=item DEEPL_AUTH_KEY

Set your authentication key for DeepL service.

=item OPENAI_API_KEY

OpenAI authentication key, used by the legacy B<gpty> engines.  The
C<llm>-based B<gpt5> engine reads this variable too, but keys stored
with C<llm keys set openai> also work.

=item GREPLE_XLATE_CACHE

Set the default cache strategy (see L</CACHE OPTIONS>).

=back

=head1 INSTALL

=head2 CPANMINUS

    $ cpanm App::Greple::xlate

=head2 TOOLS

Install the command line tool for the engine you use: C<llm> for the
B<gpt5> engine, C<deepl> for DeepL, C<gpty> for the legacy GPT
engines.

L<https://llm.datasette.io/>

L<https://github.com/DeepLcom/deepl-python>

L<https://github.com/tecolicom/App-gpty>

=head1 SEE ALSO

=head2 MODULES

L<App::Greple::xlate::llm>,
L<App::Greple::xlate::deepl>

L<App::dozo> - Generic Docker runner used by xlate for container operations

=head2 RELATED MODULES

=over 2

=item * L<App::Greple>

See the B<greple> manual for the detail about target text pattern.
Use B<--inside>, B<--outside>, B<--include>, B<--exclude> options to
limit the matching area.

=item * L<App::Greple::update>

You can use C<-Mupdate> module to modify files by the result of
B<greple> command.

=item * L<App::sdif>

Use B<sdif> to show conflict marker format side by side with B<-V>
option.

=item * L<App::Greple::stripe>

Greple B<stripe> module use by B<--xlate-stripe> option.

=back

=head2 RESOURCES

=over 2

=item * L<https://hub.docker.com/r/tecolicom/xlate>

Docker container image.

=item * L<https://github.com/tecolicom/getoptlong>

The C<getoptlong.sh> library used for option parsing in the C<xlate>
script and L<App::dozo>.

=item * L<https://llm.datasette.io/>

The C<llm> command used by the B<gpt5> engine to access LLM models.

=item * L<https://github.com/DeepLcom/deepl-python>

DeepL Python library and CLI command.

=item * L<https://github.com/openai/openai-python>

OpenAI Python Library

=item * L<https://github.com/tecolicom/App-gpty>

OpenAI command line interface

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

Copyright © 2023-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.26;
use warnings;
use utf8;

use Data::Dumper;

use Text::ANSI::Fold ':constants';
use Command::Run;
use Hash::Util qw(lock_keys);
use Unicode::EastAsianWidth;
use List::Util qw(max);

use Exporter 'import';
our @EXPORT_OK = qw($VERSION &opt %opt);
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
    update   => \(our $force_update = 0),
    dryrun   => \(our $dryrun = 0),
    maxlen   => \(our $max_length = 0),
    maxline  => \(our $max_line = 0),
    prompt   => \(our $prompt),
    mask     => \(our $mask),
    maskfile => \(our $maskfile),
    glossary => \(our $glossary),
    backend  => \(our $engine_backend = ''),
    cache_seed => \(our $cache_seed),
    context_window => \(our $context_window = 2),
    anonymize => \(our $anonymize_file),
    anonymize_mark => \(our $anonymize_mark),
    template => \(our $template_option),
    frontmatter => \(our $use_frontmatter = 0),
    contexts => (\our @contexts),
);
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

our $current_file;
my $current_text;              # whole document, set in begin()
my $frontmatter_len = 0;       # body starts after this offset
our $call_context;             # per-call context for context-aware engines
our $engine_supports_context;  # engine declares $XLATE_CONTEXT
my $colon_count = 7;

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
    colon => sub {
        my $colon = ':' x $colon_count;
        join '',
            "$colon $lang_from\n",
            $_[0],
            "$colon\n",
            "$colon $lang_to\n",
            $_[1],
            "$colon\n";
    },
    ifdef => sub {
        join '',
            "#ifdef $lang_from\n",
            $_[0],
            "#endif\n",
            "#ifdef $lang_to\n",
            $_[1],
            "#endif\n";
    },
    space    => sub { join("\n", @_) },
    'space+' => sub { join("\n", @_) . "\n" },
    discard  => sub { '' },
);

# aliases
for (keys %formatter) {
    next if ! $formatter{$_} or ref $formatter{$_};
    $formatter{$_} = $formatter{$formatter{$_}} // die;
}

my %cache;

use App::Greple::xlate::Mask;
my $maskobj;
my $anonobj;

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
        # Resolve the engine module.  Backend-based engines live under a
        # backend namespace (e.g. llm::gpt5, gpty::gpt5); others live
        # directly under App::Greple::xlate (e.g. deepl, null).  Try
        # backend namespaces FIRST, in order of preference, so that
        # --xlate-engine=gpt5 binds to llm::gpt5 even if a stale
        # top-level App::Greple::xlate::gpt5 lingers in @INC from an
        # older install.  Use --xlate-setopt backend=NAME to force a
        # specific backend (e.g. backend=gpty for comparison with the
        # old gpty engine).
        my @backend = length($engine_backend // '') ? $engine_backend : qw(llm gpty);
        my $mod;
        for my $cand ((map __PACKAGE__ . "::$_\::$xlate_engine", @backend),
                      __PACKAGE__ . "::$xlate_engine") {
            if (eval "require $cand; 1") { $mod = $cand; last }
            # Fall through only when the candidate itself is missing;
            # a syntax error or a missing dependency inside an existing
            # module must be reported, not silently skipped.
            (my $path = $cand) =~ s{::}{/}g;
            die $@ unless $@ =~ /^Can't locate \Q$path.pm\E /;
        }
        $mod or die "Engine $xlate_engine is not available.\n";
        $mod->import;
        no strict 'refs';
        ${"$mod\::lang_from"} = $lang_from;
        ${"$mod\::lang_to"} = $lang_to;
        *XLATE = \&{"$mod\::xlate"};
        $engine_supports_context = ${"$mod\::XLATE_CONTEXT"};
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
    if (defined $anonymize_file or defined $anonymize_mark) {
        $anonobj = App::Greple::xlate::Mask->new(STABLE => 1);
        $anonobj->add_escape_rule;
        $anonobj->load_anonymize_file($anonymize_file)
            if defined $anonymize_file;
    }
}

use App::Greple::xlate::Text;

sub postgrep {
    my $grep = shift;
    my @blocks;
    my %pending;
    for my $r ($grep->result) {
        my($b, @match) = @$r;
        for my $m (@match) {
            my($s, $e, $i) = @$m;
            my $key = App::Greple::xlate::Text
                ->new($grep->cut(@$m), paragraph => ($i % 2 == 0))
                ->normalized;
            my $hit = !$pending{$key} && exists $cache{$key};
            if (not $hit and not $pending{$key}++) {
                $cache{$key} = undef;
            }
            push @blocks, { key => $key, s => $s, e => $e, hit => $hit };
        }
    }
    my @regions;
    my $i = 0;
    while ($i < @blocks) {
        if ($blocks[$i]{hit}) { $i++; next }
        my $j = $i;
        $j++ while $j < @blocks and not $blocks[$j]{hit};
        push @regions, [ $i, $j - 1 ];
        $i = $j;
    }
    return if not @regions;
    my $with_context = $engine_supports_context
        && $context_window > 0
        && grep { $_->{hit} } @blocks;
    if ($with_context) {
        my %queued;
        for my $region (@regions) {
            my @texts = grep { not $queued{$_}++ }
                        map $blocks[$_]{key}, $region->[0] .. $region->[1];
            next unless @texts;
            cache_update({
                texts   => \@texts,
                context => region_context(\@blocks, @$region),
            });
        }
    } else {
        my %seen;
        my @texts = grep { not $seen{$_}++ }
                    map $blocks[$_]{key},
                    map { $_->[0] .. $_->[1] } @regions;
        cache_update({ texts => \@texts, context => undef });
    }
}

our $CONTEXT_SOURCE_MAX = 2000;   # per-side raw source slice limit

our $TEMPLATE_DEFAULT = q[\{\{.*?\}\}|\{%.*?%\}|\{#.*?#\}];

sub template_regex {
    return undef unless defined $template_option;
    length($template_option) ? $template_option : $TEMPLATE_DEFAULT;
}

##
## Build the per-region context (surrounding source slices, neighbor
## pairs, previous-version pairs).
##
sub region_context {
    my($blocks, $from, $to) = @_;
    my(@before, @after);
    for (my $k = $from - 1; $k >= 0 and @before < $context_window; $k--) {
        next unless $blocks->[$k]{hit};
        my $v = $cache{$blocks->[$k]{key}};
        push @before, [ $blocks->[$k]{key}, $v ] if defined $v;
    }
    for (my $k = $to + 1; $k < @$blocks and @after < $context_window; $k++) {
        next unless $blocks->[$k]{hit};
        my $v = $cache{$blocks->[$k]{key}};
        push @after, [ $blocks->[$k]{key}, $v ] if defined $v;
    }
    my @old;
    if (my $tied = tied %cache) {
        my %is_hit = map { $_->{key} => 1 } grep { $_->{hit} } @$blocks;
        my($lo, $hi);
        for (my $k = $from - 1; $k >= 0; $k--) {
            next unless $blocks->[$k]{hit};
            my $pos = $tied->old_position($blocks->[$k]{key});
            if (defined $pos) { $lo = $pos + 1; last }
        }
        for (my $k = $to + 1; $k < @$blocks; $k++) {
            next unless $blocks->[$k]{hit};
            my $pos = $tied->old_position($blocks->[$k]{key});
            if (defined $pos) { $hi = $pos - 1; last }
        }
        $lo //= 0;
        $hi //= $tied->old_size - 1;
        @old = grep { not $is_hit{$_->[0]} }
               $tied->old_entries_slice($lo, $hi);
    }
    return {
        source_before => source_slice_before($blocks->[$from]{s}),
        source_after  => source_slice_after($blocks->[$to]{e}),
        hits_before   => \@before,
        hits_after    => \@after,
        old_pairs     => \@old,
    };
}

sub source_slice_before {
    my $end = shift;
    return '' unless defined $current_text and $end > $frontmatter_len;
    my $start = $end - $CONTEXT_SOURCE_MAX;
    $start = $frontmatter_len if $start < $frontmatter_len;
    my $s = substr($current_text, $start, $end - $start);
    $s =~ s/\A[^\n]*\n// if $start > $frontmatter_len;   # round up to a line start
    $s;
}

sub source_slice_after {
    my $start = shift;
    return '' unless defined $current_text
        and $start < length($current_text);
    my $s = substr($current_text, $start, $CONTEXT_SOURCE_MAX);
    if ($start + $CONTEXT_SOURCE_MAX < length($current_text)) {
        $s =~ s/(?<=\n)[^\n]*\z//;         # drop trailing partial line
    }
    $s;
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
        s/( +)$/"␣" x length($1)/mge;
        print STDERR $_;
    }
}

sub clone_context {
    my $ctx = shift;
    return {
        source_before => $ctx->{source_before},
        source_after  => $ctx->{source_after},
        hits_before   => [ map [ @$_ ], @{$ctx->{hits_before} // []} ],
        hits_after    => [ map [ @$_ ], @{$ctx->{hits_after}  // []} ],
        old_pairs     => [ map [ @$_ ], @{$ctx->{old_pairs}   // []} ],
    };
}

sub cache_update {
    binmode STDERR, ':encoding(utf8)';

    my $region = ref $_[0] eq 'HASH' ? shift : { texts => [ @_ ] };
    my @from = @{$region->{texts}};
    my @pristine = @from;
    my $context = $region->{context};

    if ($context) {
        my $refs = @{$context->{hits_before} // []}
                 + @{$context->{hits_after} // []};
        my $olds = @{$context->{old_pairs} // []};
        _progress({label => "Context"},
                  sprintf("%d reference pair(s), %d previous pair(s)",
                          $refs, $olds));
    }
    if ($dryrun) {
        my @preview = @from;
        if ($anonobj) {
            $anonobj->mask(@preview);
            $anonobj->reset;
        }
        if ($maskobj) {
            $maskobj->mask(@preview);
            $maskobj->reset;
        }
        _progress({label => "From"}, @preview);
        return @from;
    }
    my @result = eval {
        my $masked_context = $context;
        if ($anonobj) {
            $anonobj->mask(@from);
            if ($context) {
                $masked_context = clone_context($context);
                $anonobj->mask_reference(
                    $masked_context->{source_before},
                    $masked_context->{source_after});
                for my $pairs (@{$masked_context}{qw(hits_before hits_after old_pairs)}) {
                    $anonobj->mask_reference(@$_) for @$pairs;
                }
            }
        }
        $maskobj->mask(@from) if $maskobj;
        # Show the payload as it will be transmitted, consistent with
        # the dryrun preview and the --xlate-mask display.
        _progress({label => "From"}, @from);
        warn Dumper $masked_context if $context and opt('debug');
        my @chop = grep { $from[$_] =~ s/(?<!\n)\z/\n/ } keys @from;
        my @to = do {
            local $call_context = $masked_context;
            map { s/ +$//mgr } &XLATE(@from);
        };
        chop @to[@chop];
        $maskobj->unmask(@to)->reset if $maskobj;
        if ($anonobj) {
            $anonobj->unmask(@to);
            $anonobj->reset;
        }

        _progress({label => "To"}, @to);
        if (defined(my $tre = template_regex())) {
            for my $i (0 .. $#pristine) {
                # Translation may legitimately reorder expressions to
                # follow the target language word order; require the
                # same multiset, not the same sequence.
                my @want = sort $pristine[$i] =~ /($tre)/g;
                my @got  = sort +($to[$i] // '') =~ /($tre)/g;
                if (@want != @got
                    or grep { $want[$_] ne $got[$_] } 0 .. $#want) {
                    die sprintf("Template expressions broken in response:\n" .
                                "  expected: %s\n  got: %s\n",
                                join(' ', @want), join(' ', @got));
                }
            }
        }
        die "Unmatched response:\n@to" if @from != @to;
        @cache{@{$region->{texts}}} = @to;
        if (my $obj = tied %cache) {
            $obj->checkpoint;
        }
        @to;
    };
    if ($@) {
        # Preserve everything already paid for (including old pairs)
        # and freeze the cache so global destruction cannot purge it.
        if (my $obj = tied %cache) {
            $obj->checkpoint;
            $obj->readonly = 1;
        }
        die $@;
    }
    @result;
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

sub xlate {
    my $param = { @_ };
    my($index, $text) = $param->@{qw(index match)};
    my $obj = App::Greple::xlate::Text->new($text,
                                            paragraph => ($index % 2 == 0));
    my $s = $cache{$obj->normalized} // "!!! TRANSLATION ERROR !!!\n";
    $obj->unstrip($s);
    $s = fold_lines $s if $fold_line;
    if (state $formatter = $formatter{$output_format}) {
        return $formatter->($text, $s);
    } else {
        return $s;
    }
}
sub callback { goto &xlate }

sub mask_string {
    my($s) = +{ @_ }->{match};
    if ($anonobj) {
        $anonobj->mask($s);
    }
    if ($maskobj) {
        $maskobj->mask($s);
    }
    $s;
}

sub cache_file {
    my $file = sprintf("%s.xlate-%s-%s.json",
                       $current_file, $xlate_engine, $lang_to);
    if ($cache_method eq 'auto') {
        # Seeding targets a document whose cache does not exist yet,
        # so a seed implies cache creation even in auto mode.
        (-f $file or defined $cache_seed) ? $file : undef;
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
    $current_text = $_;
    $frontmatter_len = 0;
    if ($use_frontmatter
        and $current_text =~ /\A(---\n(?s:.*?)^---\n)/m) {
        my $fm = $1;
        $frontmatter_len = length $fm;
        # A paragraph-style match pattern joins the front matter with
        # the first body paragraph unless a blank line separates them,
        # and a straddling match defeats the --exclude region.
        if (substr($current_text, $frontmatter_len, 1) ne "\n") {
            warn "$current_file: no blank line after front matter; " .
                 "it may be caught by paragraph matching.\n";
        }
        my @values;
        for my $line (split /\n/, $fm) {
            next if $line =~ /^---/;
            my($k, $v) = $line =~ /^([^\s:#][^:]*):\s*(.+?)\s*$/ or next;
            $v =~ s/\A(["'])(.*)\1\z/$2/s;   # strip surrounding quotes
            push @values, $v;
        }
        if (@values) {
            if (not $anonobj) {
                $anonobj = App::Greple::xlate::Mask->new(STABLE => 1);
                $anonobj->add_escape_rule;
            }
            $anonobj->add_rule(var => quotemeta($_)) for @values;
        }
    }
    if ($anonobj and defined $anonymize_mark) {
        my $regex = length($anonymize_mark)
            ? $anonymize_mark : $App::Greple::xlate::Mask::DEFAULT_MARK;
        $anonobj->file_rules(
            App::Greple::xlate::Mask::extract_marks($current_text, $regex));
    }
    if (not defined $xlate_engine) {
        die "Select translation engine.\n";
    }
    if ($output_format =~ /^(:+)$/) {
        $colon_count = length($1);
        $output_format = 'colon';
    }
    if (my $file = cache_file) {
        my @opt;
        if ($cache_method =~ /create|clear/i) {
            push @opt, clear => 1;
        }
        if ($cache_method =~ /accumulate/i) {
            push @opt, accumulate => 1;
        }
        if ($force_update) {
            push @opt, force_update => 1;
        }
        if (defined $cache_seed) {
            push @opt, seed => $cache_seed;
        }
        if ($dryrun) {
            push @opt, readonly => 1;
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
builtin xlate-update!      $force_update
builtin xlate-engine=s     $xlate_engine
builtin xlate-dryrun       $dryrun
builtin xlate-maxlen=i     $max_length
builtin xlate-maxline=i    $max_line
builtin xlate-prompt=s     $prompt
builtin xlate-glossary=s   $glossary
builtin xlate-context=s    @contexts
builtin xlate-context-window=i $context_window
builtin xlate-anonymize=s      $anonymize_file
builtin xlate-anonymize-mark:s $anonymize_mark
builtin xlate-template:s   $template_option
builtin xlate-cache-seed=s $cache_seed

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

option --xlate-mask \
        --begin    &__PACKAGE__::begin \
        --callback &__PACKAGE__::mask_string

option --cache-clear --xlate-cache=clear

option --xlate-frontmatter \
        --xlate-setopt frontmatter=1 \
        --exclude '\A---\n(?s:.*?)^---\n'

option --match-all       --re '\A(?s).+\z'
option --match-entire    --match-all
option --match-paragraph --re '^(.+\n)+'
option --match-podtext   -Mperl --pod --re '^(\w.*\n)(\S.*\n)*'

option --ifdef-color --re '^#ifdef(?s:.*?)^#endif.*\n'

option --xlate-stripe --xlate-stripe-auto
option --xlate-stripe-light -Mstripe
option --xlate-stripe-dark  -Mstripe::config=darkmode
option --xlate-stripe-auto \
        -Mtermcolor::bg(light=-Mstripe,dark=-Mstripe::config=darkmode)

option --lineify-cm \
        -Mxlate::Filter --of &lineify_cm

option --lineify-colon \
        -Mxlate::Filter --of &lineify_colon

#  LocalWords:  deepl ifdef unifdef Greple greple perl DeepL ChatGPT
#  LocalWords:  gpt html img src xlabor

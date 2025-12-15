package App::xlate;

our $VERSION = "0.9922";

1;
=encoding utf-8

=head1 NAME

xlate - TRANSlate CLI front-end for App::Greple::xlate module

=head1 SYNOPSIS

xlate [ options ] -t LANG FILE [ greple options ]

  Translation options:
    -h, --help        help
        --version     show version
    -d, --debug       debug mode (currently enables trace)
        --trace       trace mode
    -n, --dryrun      dry-run
    -a, --api         use API
    -c, --check       just check translation area
    -r, --refresh     refresh cache
    -u, --update      force update cache
    -s, --silent      silent mode
    -t, --to-lang=#   target language (required, no default)
    -b, --from-lang=# base language (informational)
    -e, --engine=#    translation engine (*deepl, gpt5, ...)
    -p, --pattern=#   pattern string to determine translation area
    -f, --file=#      pattern file to determine translation area
    -o, --format=#    output format (*xtxt, cm, ifdef, space, space+, colon)
    -x, --maskfile=#  file containing mask patterns
    -g, --glossary=#  glossary file
    -w, --wrap=#      wrap line by # width
    -m, --maxlen=#    max length per API call
    -l, --library=#   show library files (XLATE.mk, xlate.el)
    --                end of option
    N.B. default is marked as *

  Make options:
    -M, --make        run make
    -n, --dryrun      dry-run

  Docker options:
    -D, --docker *    run xlate on the container with the same parameters
    -C, --command *   execute following command on the container, or run shell
    -L, --live *      use the live container
    N.B. These options terminate option handling

    -W, --mount-cwd    mount current working directory
    -H, --mount-home   mount home directory
    -V, --volume=#     specify mount directory
    -U, --unmount      do not mount
    -R, --mount-ro     mount read-only
    -B, --batch        run container in batch mode
    -N, --name=#       specify the name of live container
    -K, --kill         kill and remove live container
    -E, --env=#        specify an environment variable to be inherited
    -I, --image=#      docker image or version (default: tecolicom/xlate:version)
    -P, --port=#       port mapping
    -O, --other=#      additional docker option

  Control Files:
    *.LANG    translation languages
    *.FORMAT  translation format (xtxt, cm, ifdef, colon, space)
    *.ENGINE  translation engine (deepl, gpt5, ...)

=head1 VERSION

    Version 0.9922

=cut
=head1 DESCRIPTION

B<XLATE> is a versatile command-line tool designed as a user-friendly
frontend for the B<greple> C<-Mxlate> module, simplifying the process
of multilingual automatic translation using various API services.  It
streamlines the interaction with the underlying module, making it
easier for users to handle diverse translation needs across multiple
file formats and languages.

A key feature of B<xlate> is its seamless integration with Docker
environments, allowing users to quickly set up and use the tool
without complex environment configurations.  This Docker support
ensures consistency across different systems and simplifies
deployment, benefiting both individual users and teams working on
translation projects.

B<xlate> supports various document formats, including C<.docx>,
C<.pptx>, and C<.md> files, and offers multiple output formats to suit
different requirements.  By combining Docker capabilities with
built-in make functionality, B<xlate> enables powerful automation of
translation workflows.  This combination facilitates efficient batch
processing of multiple files, streamlined project management, and easy
integration into continuous integration/continuous deployment (CI/CD)
pipelines, significantly enhancing productivity in large-scale
localization efforts.

=head2 Basic Usage

To translate a file, use the following command:

    xlate -t <target_language> <file>

For example, to translate a file from English to Japanese:

    xlate -t JA example.txt

=head2 Translation Engines

xlate supports multiple translation engines.  Use the -e option to
specify the engine:

    xlate -e deepl -t JA example.txt

Available engines: deepl, gpt5, ...

=head2 Output Formats

Various output formats are supported. Use the -o option to specify the format:

    xlate -o cm -t JA example.txt

Available formats: xtxt, cm, ifdef, space, space+, colon

=head2 Docker Support

B<xlate> offers seamless integration with Docker through the B<dozo>
command.  Use C<-D> to run xlate in a container, or C<-C> to run
arbitrary commands.

    xlate -D -t JA file.txt      # run xlate in container
    xlate -C make                # run make in container
    xlate -DM -t 'EN FR' *.docx  # combine with make

Docker options (C<-I>, C<-E>, C<-W>, C<-H>, C<-V>, C<-U>, C<-R>,
C<-B>, C<-N>, C<-K>, C<-L>, C<-P>, C<-O>) are passed to B<dozo>.  For details
on live containers, container naming, and configuration, see L<dozo>.

B<Note:> The generic Docker runner functionality (C<-C>, C<-L> options)
has been moved to the standalone L<dozo> command. For running arbitrary
commands or managing live containers, use B<dozo> directly. These options
in xlate are maintained for backward compatibility but may be deprecated
in future versions.

=head2 Make Support

xlate utilizes GNU Make for automating and managing translation tasks.
This feature is particularly useful for handling translations of
multiple files or translations to different languages.

To use the make feature:

    xlate -M [options] [target]

xlate provides a specialized Makefile (F<XLATE.mk>) that defines
translation tasks and rules.  This file is located in the xlate
library directory and is automatically used when the -M option is
specified.

Example usage:

    xlate -M -t 'EN FR DE' document.docx

This command will use make to translate document.docx to English,
French, and German, following the rules defined in XLATE.mk.

The C<-n> option can be used with C<-M> for a dry-run, showing what
actions would be taken without actually performing the translations:

    xlate -M -n -t 'EN FR DE' document.docx

Users can customize the translation process using parameter files:

=over 4

=item F<*.LANG>:

Specifies target languages for a specific file

=item F<*.FORMAT>:

Defines output formats for a specific file

=item F<*.ENGINE>:

Selects the translation engine for a specific file

=back

For more detailed information on the make functionality and available
rules, refer to the F<XLATE.mk> file in the xlate library directory.

=head1 OPTIONS

=over 7

=item B<-h>, B<--help>

Show help message.

=item B<--version>

Show version information.

=item B<-d>, B<--debug>

Enable debug mode. Currently this enables trace mode.

=item B<--trace>

Enable trace mode (set -x).

=item B<-n>, B<--dryrun>

Perform a dry-run without making any changes.

=item B<-a>, B<--api>

Use API for translation.

=item B<-c>, B<--check>

Check translation area without performing translation.

=item B<-r>, B<--refresh>

Refresh the translation cache.

=item B<-u>, B<--update>

Force update of the translation cache.

=item B<-s>, B<--silent>

Run in silent mode.

=item B<-t> I<lang>, B<--to-lang>=I<lang>

Specify the target language (required).

=item B<-b> I<lang>, B<--from-lang>=I<lang>

Specify the base language (optional).

=item B<-e> I<engine>, B<--engine>=I<engine>

Specify the translation engine to use.

=item B<-p> I<pattern>, B<--pattern>=I<pattern>

Specify a pattern to determine the translation area.
See L<App::Greple::xlate/NORMALIZATION>.

=item B<-f> I<file>, B<--file>=I<file>

Specify a file containing patterns to determine the translation area.
See L<App::Greple::xlate/NORMALIZATION>.

=item B<-o> I<format>, B<--format>=I<format>

Specify the output format.

=item B<-x> I<file>, B<--maskfile>=I<file>

Specify a file containing mask patterns.
See L<App::Greple::xlate/MASKING>.

=item B<-g> I<file>, B<--glossary>=I<file>

Specify a glossary file.

=item B<-w> I<width>, B<--wrap>=I<width>

Wrap lines at the specified width.

=item B<-m> I<length>, B<--maxlen>=I<length>

Specify the maximum length per API call.

=item B<-l> I<file>, B<--library>=I<file>

Show library files (XLATE.mk, xlate.el).

=back

=head2 MAKE OPTIONS

=over 7

=item B<-M>, B<--make>

Run make.

=item B<-n>, B<--dryrun>

Dry-run.

=back

=head2 DOCKER OPTIONS

=over 7

=item B<-D>, B<--docker>

Run B<xlate> on the Docker container with the rest of the parameters.
Once this option appears, subsequent options are not interpreted by
xlate, so it should always be the last of the xlate options.

=back

The following options are specific to L<dozo> and are passed through
when invoking Docker features. These options are maintained for backward
compatibility but may be removed in future versions. For direct container
management, use the L<dozo> command instead.

=over 7

=item B<-C> [ I<command> ], B<--command>

Execute command on the Docker container, or run shell if no command.

=item B<-L> [ I<command> ], B<--live>

Use live (persistent) container.  See L<dozo> for details.

=item B<-W>, B<--mount-cwd>

Mount current working directory.

=item B<-H>, B<--mount-home>

Mount home directory.

=item B<-U>, B<--unmount>

Do not mount any directory.

=item B<-R>, B<--mount-ro>

Mount read-only.

=item B<-V> I<from>:I<to>, B<--volume>=I<from>:I<to>

Additional volume mount.  Repeatable.

=item B<-E> I<name>[=I<value>], B<--env>=I<name>[=I<value>]

Environment variable to inherit.  Repeatable.

=item B<-I> I<image>, B<--image>=I<image>

Docker image.  Prefix with colon (C<:version>) for default image version.

=item B<-B>, B<--batch>

Batch mode (non-interactive).

=item B<-N> I<name>, B<--name>=I<name>

Container name for live container.

=item B<-K>, B<--kill>

Kill and remove the live container.

=item B<-P> I<port>, B<--port>=I<port>

Port mapping (e.g., C<8080:80>).  Repeatable.

=item B<-O> I<option>, B<--other>=I<option>

Additional docker option.  Repeatable.

=back

=head1 ENVIRONMENT

=over 4

=item DEEPL_AUTH_KEY

DeepL API key.

=item OPENAI_API_KEY

OpenAI API key.

=item ANTHROPIC_API_KEY

Anthropic API key.

=item LLM_PERPLEXITY_KEY

Perplexity API key.

=back

=head1 FILES

=over 4

=item F<*.LANG>

Specifies translation languages.

=item F<*.FORMAT>

Specifies translation format.

=item F<*.ENGINE>

Specifies translation engine.

=back

=head1 EXAMPLES

1. Translate a Word document to English:

   xlate -DMa -t EN-US example.docx

2. Translate to multiple languages and formats:

   xlate -M -o 'xtxt ifdef' -t 'EN-US KO ZH' example.docx

3. Run a command in Docker container:

   xlate -C sdif -V --nocdif example.EN-US.cm

4. Translate without using API (via clipboard):

   xlate -t JA README.md

=head1 SEE ALSO

L<App::Greple::xlate>

L<dozo> - Generic Docker runner used by xlate for container operations

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

[![Actions Status](https://github.com/kaz-utashiro/App-xlate/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/App-xlate/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-xlate.svg)](https://metacpan.org/release/App-xlate)
# NAME

    xlate - TRANSlate CLI front-end for App::Greple::xlate module

# SYNOPSIS

    xlate [ options ] -t LANG FILE [ greple options ]
        -h   help
        -v   show version
        -d   debug
        -n   dry-run
        -a   use API
        -c   just check translation area
        -r   refresh cache
        -u   force update cache
        -s   silent mode
        -t # target language (required, no default)
        -b # base language (informational)
        -e # translation engine (*deepl, gpt3, gpt4, gpt4o)
        -p # pattern string to determine translation area
        -f # pattern file to determine translation area
        -o # output format (*xtxt, cm, ifdef, space, space+, colon)
        -x # file containing mask patterns
        -w # wrap line by # width
        -m # max length per API call
        -l # show library files (XLATE.mk, xlate.el)
        --   end of option
        N.B. default is marked as *

    Make options
        -M   run make
        -n   dry-run

    Docker options
        -D * run xlate on the container with the same parameters
        -C * execute following command on the container, or run shell
        -L * use the live container
        N.B. These options terminate option handling

        -W   mount current working directory
        -H   mount home directory
        -V # specify mount directory
        -U   do not mount
        -R   mount read-only
        -B   run container in batch mode
        -N   specify the name of live container
        -K   kill and remove live container
        -E # specify an environment variable to be inherited
        -I # docker image or version (default: tecolicom/xlate:version)

    Control Files:
        *.LANG    translation languates
        *.FORMAT  translation foramt (xtxt, cm, ifdef, colon, space)
        *.ENGINE  translation engine (deepl, gpt3, gpt4, gpt4o)

# VERSION

    Version 0.9909

# DESCRIPTION

**XLATE** is a versatile command-line tool designed as a user-friendly
frontend for the **greple** `-Mxlate` module, simplifying the process
of multilingual automatic translation using various API services.  It
streamlines the interaction with the underlying module, making it
easier for users to handle diverse translation needs across multiple
file formats and languages.

A key feature of **xlate** is its seamless integration with Docker
environments, allowing users to quickly set up and use the tool
without complex environment configurations.  This Docker support
ensures consistency across different systems and simplifies
deployment, benefiting both individual users and teams working on
translation projects.

**xlate** supports various document formats, including `.docx`,
`.pptx`, and `.md` files, and offers multiple output formats to suit
different requirements.  By combining Docker capabilities with
built-in make functionality, **xlate** enables powerful automation of
translation workflows.  This combination facilitates efficient batch
processing of multiple files, streamlined project management, and easy
integration into continuous integration/continuous deployment (CI/CD)
pipelines, significantly enhancing productivity in large-scale
localization efforts.

## Basic Usage

To translate a file, use the following command:

    xlate -t <target_language> <file>

For example, to translate a file from English to Japanese:

    xlate -t JA example.txt

## Translation Engines

xlate supports multiple translation engines.  Use the -e option to
specify the engine:

    xlate -e deepl -t JA example.txt

Available engines: deepl, gpt3, gpt4, gpt4o

## Output Formats

Various output formats are supported. Use the -o option to specify the format:

    xlate -o cm -t JA example.txt

Available formats: xtxt, cm, ifdef, space, space+, colon

## Docker Support

**xlate** offers seamless integration with Docker, providing a powerful
and flexible environment for translation tasks.  This approach
combines the strengths of xlate's translation capabilities with
Docker's containerization benefits.

### Key Concepts

- **Git Friendly**

    If you are working in a git environment, the git top directory is
    automatically mounted, which works seamlessly with git commands.
    Otherwise the current directory is mounted.

- **Containerized Environment**

    By running xlate in a Docker container, you ensure a consistent and
    isolated environment for all translation tasks.  This eliminates
    issues related to system dependencies or conflicting software
    versions.

- **Integration with Make**

    The Docker functionality can be combined with xlate's **make** feature,
    allowing for complex, multi-file translation projects to be managed
    efficiently within a containerized environment. For example:

        xlate -DM -t 'EN FR DE' project_files/*.docx

    This command runs **xlate** in a Docker container, utilizing make to
    process multiple files with specified target languages.

- **Environment Variable Handling**

    With the ability to pass specific environment variables into the
    container (`-E`), you can easily manage API keys and other
    configuration settings without modifying the container itself.

## Make Support

xlate utilizes GNU Make for automating and managing translation tasks.
This feature is particularly useful for handling translations of
multiple files or to different languages.

To use the make feature:

    xlate -M [options] [target]

xlate provides a specialized Makefile (`XLATE.mk`) that defines
translation tasks and rules.  This file is located in the xlate
library directory and is automatically used when the -M option is
specified.

Example usage:

    xlate -M -t 'EN FR DE' document.docx

This command will use make to translate document.docx to English,
French, and German, following the rules defined in XLATE.mk.

The `-n` option can be used with `-M` for a dry-run, showing what
actions would be taken without actually performing the translations:

    xlate -M -n -t 'EN FR DE' document.docx

Users can customize the translation process using parameter files:

- `*.LANG`:

    Specifies target languages for a specific file

- `*.FORMAT`:

    Defines output formats for a specific file

- `*.ENGINE`:

    Selects the translation engine for a specific file

For more detailed information on the make functionality and available
rules, refer to the `XLATE.mk` file in the xlate library directory.

## XLATERC File

The `.xlaterc` file allows you to set default options for the
`xlate` command.  This file is searched in the Git top directory and
the current directory.  If found, its contents are applied before any
command-line options.

Each line in the `.xlaterc` file should contain a valid `xlate`
command option.  Lines starting with `#` are treated as comments and
ignored.

For example, if the following line is set in `.xlaterc`, `xlate`
will use the specified container image when docker is run.

    -I tecolicom/texlive-groff-ja:v1.35

# OPTIONS

- **-h**

    Show help message.

- **-v**

    Show version information.

- **-d**

    Enable debug mode.

- **-n**

    Perform a dry-run without making any changes.

- **-a**

    Use API for translation.

- **-c**

    Check translation area without performing translation.

- **-r**

    Refresh the translation cache.

- **-u**

    Force update of the translation cache.

- **-s**

    Run in silent mode.

- **-t** _lang_

    Specify the target language (required).

- **-b** _lang_

    Specify the base language (optional).

- **-e** _engine_

    Specify the translation engine to use.

- **-p** _pattern_

    Specify a pattern to determine the translation area.
    See ["NORMALIZATION" in App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate#NORMALIZATION).

- **-f** _file_

    Specify a file containing pattern to determine the translation area.
    See ["NORMALIZATION" in App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate#NORMALIZATION).

- **-o** _format_

    Specify the output format.

- **-x** _file_

    Specify a file containing mask patterns.

- **-w** _width_

    Wrap lines at the specified width.

- **-m** _length_

    Specify the maximum length per API call.

- **-l** _file_

    Show library files (XLATE.mk, xlate.el).

## MAKE OPTIONS

- **-M**

    Run make.

- **-n**

    Dry run.

## DOCKER OPTIONS

Docker feature is invoked by the `-D`, `-C` or `-L` option.
Once any of these options appear, subsequent options are not
interpreted, so it should always be the last of Docker related
options.

- **-D** _options_

    Run **xlate** scirpt on the Docker container with the rest of the
    parameters.

- **-C** \[ _command_ \]

    Execute the following command on the Docker container, or run a shell
    if no command is provided.

- **-L** \[ _command_ \]

    When executed without arguments, option `-L` attaches to a running
    container (performs `docker attach`).  If the container does not
    exist, a new container is created, and if there is a stopped
    container, it is restarted before attaching.

    If executed with command arguments, the command is executed on the
    running container (performs `docker exec`).  If the container does
    not exist, it creates a new container executing the given command.
    Therefore, the next time it attaches, it connects to the container
    that executes that command.

    Target container is distinguished by name.  The default container name
    is `xlate`.  The last portion of the Docker image to run is given as
    the name of the container.  If a directory to mount is specified, the
    name of that directory is added after dot (`.`).  For example, if you
    run `ubuntu:latest` image with mounting home directory (`-H`), the
    container name will be `ubuntu.yourname`.

When running in a docker environment, the [git(1)](http://man.he.net/man1/git) top directory is
mounted if you are in a directory under git, otherwise current
directory is mounted.  Working directory will still be moved to the
current location within that tree.

- **-W**

    Mount current working directory.

- **-H**

    Mount user's home directory.  The environment variable `HOME` is set
    to the mount point.

- **-U**

    Do not mount any directory.

- **-R**

    Mount directory as read-only.

- **-V** _from_:_to_

    Specify the additional directory to be mounted.
    Repeatable.

- **-E** _name_\[=_value_\]

    Specify environment variable to be inherited in Docker.
    Repeatable.

- **-I** _image_

    Specify Docker image name.  If it begins with a colon (`:`), it is
    treated as a version of the default image.

- **-B**

    Run the container in batch mode.  Specifically, run `docker` command
    without the `--interactive` and `--tty` options.

- **-N**

    Specifies the name of the live container explicitly.  Once you have
    created a container named `xlate`, you can connect to it with just
    the `-A` option.

- **-K**

    Kill and remove the existing live container.  If a container with the
    specified name (default is `xlate`) exists, it will be stopped and
    removed.

# ENVIRONMENT

- DEEPL\_AUTH\_KEY

    DeepL API key.

- OPENAI\_API\_KEY

    OpenAI API key.

- ANTHROPIC\_API\_KEY

    Anthropic API key.

- LLM\_PERPLEXITY\_KEY

    Perplexity API key.

# FILES

- `*.LANG`

    Specifies translation languages.

- `*.FORMAT`

    Specifies translation format.

- `*.ENGINE`

    Specifies translation engine.

# EXAMPLES

1\. Translate a Word document to English:

    xlate -DMa -t EN-US example.docx

2\. Translate to multiple languages and formats:

    xlate -M -o 'xtxt ifdef' -t 'EN-US KO ZH' example.docx

3\. Run a command in Docker container:

    xlate -C sdif -V --nocdif example.EN-US.cm

4\. Translate without using API (via clipboard):

    xlate -t JA README.md

# SEE ALSO

[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2023-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

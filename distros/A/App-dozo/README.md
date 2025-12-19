[![Actions Status](https://github.com/tecolicom/App-dozo/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/App-dozo/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-dozo.svg)](https://metacpan.org/release/App-dozo)
<div>
    <p align="center"><img src="https://raw.githubusercontent.com/tecolicom/App-dozo/main/images/dozo-logo.png" width="400"></p>
</div>

# NAME

dozo - Dôzo, Docker with Zero Overhead

# SYNOPSIS

dozo -I IMAGE \[ options \] \[ command ... \]

    -h, --help         show help
        --version      show version
    -d, --debug        debug mode (show full command)
    -x, --trace        trace mode (set -x)
    -q, --quiet        quiet mode
    -n, --dryrun       dry-run mode

    -I, --image=#      Docker image (required unless -D)
    -D, --default      use default image (DOZO_DEFAULT_IMAGE or tecolicom/xlate)
    -E, --env=#        environment variable to inherit (repeatable)
    -W, --mount-cwd    mount current working directory
    -H, --mount-home   mount home directory
    -U, --unmount      do not mount any directory
        --mount-mode=# mount mode (rw or ro, default: rw)
    -R, --mount-ro     mount read-only (shortcut for --mount-mode=ro)
    -V, --volume=#     additional volume to mount (repeatable)
    -B, --batch        batch mode (non-interactive)
    -L, --live         use live (persistent) container
    -N, --name=#       live container name
    -K, --kill         kill and remove existing container
    -P, --port=#       port mapping (repeatable)
    -O, --other=#      additional docker options (repeatable)

# VERSION

Version 0.9927

# USAGE

When executed without arguments, Dôzo starts an interactive shell
inside the container.  When arguments are given, they are executed as
a command.

    dozo -I alpine                  # start shell
    dozo -I alpine ls -la           # run command

By setting `-D` or your favorite image with `-I` in `~/.dozorc`,
you can simply run Dôzo without specifying an image.  Since the git
top directory is automatically mounted, git commands work as expected
from anywhere in the tree.

    $ dozo                          # start shell
    $ dozo git log -p               # run git log -p

With `-L` option, you can use a persistent container.  Tools
installed in the container will remain available for subsequent use.

    $ dozo -L                       # start shell and create container
    # apt update && apt install -y cowsay
    # exit
    $ dozo -L /usr/games/cowsay Dôzo
     ______
    < Dôzo >
     ------
            \   ^__^
             \  (oo)\_______
                (__)\       )\/\
                    ||----w |
                    ||     ||

# INSTALLATION

Using [cpanminus](https://metacpan.org/pod/App::cpanminus):

    cpanm -n App::dozo

To install the latest version from GitHub:

    cpanm -n https://github.com/tecolicom/App-dozo.git

Alternatively, you can simply place `dozo` and `getoptlong.sh` in
your PATH.

**Dôzo** requires Bash 4.3 or later.

# DESCRIPTION

**Dôzo** is a generic Docker runner that simplifies running commands in
Docker containers.  The name comes from the Japanese word "dôzo"
(どうぞ) meaning "please" or "go ahead", and also stands for "**D**ocker
with **Z**ero **O**verhead".  The command name is `dozo` for ease of
typing.

It automatically configures the tedious Docker options such as volume
mounts, environment variables, working directories, and interactive
terminal settings, so you can focus on the command you want to run.

**Dôzo** is distributed as a standalone module and can be used as a
general-purpose Docker runner. It was originally developed as part of
[App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate) and is used by [xlate](https://metacpan.org/pod/xlate) for Docker operations.

**Dôzo** uses [getoptlong.sh](https://github.com/tecolicom/getoptlong)
for option parsing.

## Key Features

- **Git Friendly**

    If you are working in a git environment, the git top directory is
    automatically mounted. Otherwise the current directory is mounted.

- **Live Container**

    Use `-L` to create or attach to a persistent container that survives
    between invocations. Container names are automatically generated from
    the image name and mount directory.

- **Environment Inheritance**

    Common environment variables are automatically inherited: `LANG`,
    `TZ`, proxy settings, terminal settings, and API keys for AI/LLM
    services (DeepL, OpenAI, Anthropic, Perplexity).

- **Flexible Mounting**

    Various mount options: current directory (`-W`), home directory
    (`-H`), additional volumes (`-V`), read-only mode (`-R`), or no
    mount (`-U`).

- **X11 Support**

    When `DISPLAY` is set, the host IP is automatically detected and
    passed to the container, enabling GUI applications.

- **Configuration File**

    Use `.dozorc` to set default options. Searched in current directory,
    git top directory, and home directory.

- **Standalone Operation**

    **Dôzo** can operate independently of [xlate](https://metacpan.org/pod/xlate). The distribution includes
    `getoptlong.sh` as a submodule in the `share/getoptlong` directory.
    If the module is installed via CPAN, it searches for `getoptlong.sh`
    via `File::Share::dist_dir('App-dozo')`. Otherwise, it searches for
    `getoptlong.sh` in the standard `PATH`.

# OPTIONS

- **-h**, **--help**

    Show help message.

- **-d**, **--debug**

    Enable debug mode. Shows the full docker command line that will be executed.

- **-x**, **--trace**

    Enable trace mode (set -x).

- **-q**, **--quiet**

    Quiet mode.

- **-n**, **--dryrun**

    Dry-run mode. Show docker commands without executing them.
    Useful for testing and debugging.

- **-I** _image_, **--image**=_image_

    Specify Docker image. Required unless `-D` is given, but you can put
    it in `.dozorc` so you don't have to type it every time.

- **-D**, **--default**

    Use the default Docker image. If `DOZO_DEFAULT_IMAGE` environment
    variable is set, use that image. Otherwise, use
    `tecolicom/xlate:VERSION` where VERSION is the current Dôzo version.
    See ["DEFAULT IMAGE"](#default-image) section for details about the default image.

- **-E** _name_\[=_value_\], **--env**=_name_\[=_value_\]

    Specify environment variable to inherit. Repeatable.

- **-W**, **--mount-cwd**

    Mount current working directory.

- **-H**, **--mount-home**

    Mount home directory.

- **-V** _path_, **-V** _from_:_to_, **--volume**=_from_:_to_

    Specify additional directory to mount. If only _path_ is given
    (without `:`), it is mounted to the same path in the container.
    Repeatable.

- **-U**, **--unmount**

    Do not mount any directory.

- **--mount-mode**=_mode_

    Set mount mode. _mode_ is either `rw` (read-write, default) or `ro`
    (read-only).

- **-R**, **--mount-ro**

    Mount directory as read-only. Shortcut for `--mount-mode=ro`.

- **-B**, **--batch**

    Run in batch mode (non-interactive).

- **-N** _name_, **--name**=_name_

    Specify container name explicitly.

- **-K**, **--kill**

    Kill and remove existing container.

- **-L**, **--live**

    Use live (persistent) container.

- **-P** _port_, **--port**=_port_

    Specify port mapping (e.g., `8080:80`). Repeatable.

- **-O** _option_, **--other**=_option_

    Specify additional docker options. Repeatable.

    Note: Spaces and commas in option values are treated as delimiters and
    will split the value into multiple elements.

# LIVE CONTAINER

The `-L` option enables live (persistent) container mode. Unlike
normal mode where containers are removed after execution (`--rm`),
live containers persist between invocations, allowing you to maintain
state and reduce startup overhead.

## Container Lifecycle

When `-L` is specified, **Dôzo** behaves as follows:

- 1. **Container does not exist**

    Create a new persistent container (without `--rm` flag).

- 2. **Container exists and is running**

    If a command is given, execute it using `docker exec`. Otherwise,
    attach to the container using `docker attach`.

- 3. **Container exists but is paused**

    Unpause the container with `docker unpause`, then proceed as above.

- 4. **Container exists but is exited**

    Start the container with `docker start`, then proceed as above.

## Container Naming

Container names are automatically generated in the format:

    <image_name>.<mount_directory>

For example, if you run:

    dozo -I tecolicom/xlate -L

from `/home/user/project`, the container name would be
`xlate.project`.

You can override the auto-generated name using the `-N` option:

    dozo -I tecolicom/xlate -L -N mycontainer

## Managing Live Containers

- **Attach to existing container**

        dozo -I myimage -L

    If no command is given, attaches to the container's main process.

- **Execute command in existing container**

        dozo -I myimage -L ls -la

    Runs the command in the existing container using `docker exec`.

- **Kill and recreate container**

        dozo -I myimage -KL

    The `-K` option removes the existing container before `-L` creates
    a new one. Useful when you need a fresh container state.

- **Kill container only**

        dozo -I myimage -K

    Without `-L`, the container is removed and the command exits.

## Interactive Mode

In live container mode, interactive mode (`-i` and `-t` flags for
Docker) is automatically enabled when:

- Standard input is a terminal (TTY)
- The `-B` (batch) option is not specified

This allows seamless interactive use when attaching to containers or
running interactive commands.

# CONFIGURATION FILE

`.dozorc` files are loaded from the following locations in order:

- 1. Home directory `.dozorc`
- 2. Git top directory `.dozorc` (if different)
- 3. Current directory `.dozorc`
- 4. Command line arguments

For single-value options (like `-I`, `-N`), later values override
earlier ones. For repeatable options (like `-E`, `-V`, `-P`, `-O`),
all values are accumulated in order.

You can use any command line option in the configuration file:

    # Example .dozorc
    -I tecolicom/xlate:latest
    -E CUSTOM_VAR=value
    -V /data:/data

Lines starting with `#` are treated as comments.

# DOCKER-IN-DOCKER

To use Docker commands inside the container, mount the host's Docker
socket:

    # .dozorc for Docker-in-Docker
    -I docker
    -V /var/run/docker.sock

This allows you to run Docker commands from within the container using
the host's Docker daemon:

    $ dozo docker run --rm alpine uname -a

Or run it as a one-liner without `.dozorc`:

    $ dozo -I docker -V /var/run/docker.sock docker run --rm alpine uname -a

# DEFAULT IMAGE

The `tecolicom/xlate` image is specifically designed for document
translation and text processing tasks, providing a comprehensive
environment with the following features:

## Translation and AI Tools

- **DeepL CLI** - Command-line interface for DeepL translation API
- **gpty** - GPT command-line tool for AI-powered text processing
- **llm** - Unified LLM interface with plugins for multiple providers:
Gemini, Claude 3, Perplexity, and OpenRouter

## Text Processing Tools

- **greple** with xlate module - Pattern-based text extraction and
translation
- **sdif** - Side-by-side diff viewer with word-level highlighting
- **ansicolumn**, **ansifold**, **ansiexpand** - ANSI-aware text
formatting tools
- **optex textconv** - Document format converter (PDF, Office, etc.)

## Greple Extensions

Multiple [App::Greple](https://metacpan.org/pod/App%3A%3AGreple) extension modules are pre-installed:

- **msdoc** - Microsoft Office document support
- **xp** - Extended pattern syntax
- **subst** - Text substitution with dictionary
- **frame** - Frame-style output formatting

## Git Integration

The image includes a pre-configured git environment optimized for
document comparison and review. Since **Dôzo** automatically mounts
the git top directory by default, git commands work seamlessly with
full repository context:

- **Side-by-side diff** - `git diff`, `git log`, and `git show`
use **sdif** for word-level side-by-side comparison
- **Colorful blame** - `git blame` uses **greple** for enhanced
label coloring
- **Office document diff** - Compare Word (.docx), Excel (.xlsx),
and PowerPoint (.pptx) files directly with git
- **PDF diff** - View PDF metadata changes
- **JSON diff** - Normalized JSON comparison using **jq**

## Additional Utilities

- **MeCab** - Japanese morphological analyzer with IPA dictionary
- **poppler-utils** - PDF processing tools (pdftotext, etc.)
- **jq**, **yq** - JSON and YAML processors

## Environment

- Based on Ubuntu with Japanese locale (ja\_JP.UTF-8)
- Perl and Python3 runtime environments
- Common API keys are automatically inherited from host
(DEEPL\_AUTH\_KEY, OPENAI\_API\_KEY, ANTHROPIC\_API\_KEY, etc.)

# ENVIRONMENT

## Configuration Variables

- `DOZO_DEFAULT_IMAGE`

    Specifies the default Docker image used when `-D` (`--default`) option
    is given. If not set, `tecolicom/xlate:VERSION` is used where VERSION
    is the current Dôzo version.

## Inherited Variables

The following environment variables are inherited by default:

    LANG TZ
    HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    TERM_PROGRAM TERM_BGCOLOR COLORTERM
    DEEPL_AUTH_KEY OPENAI_API_KEY ANTHROPIC_API_KEY LLM_PERPLEXITY_KEY

## Container Variables

The following environment variables are set inside the container:

- `DOZO_RUNNING_ON_DOCKER=1`

    Indicates the command is running inside a container started by Dôzo.

- `XLATE_RUNNING_ON_DOCKER=1`

    For compatibility with xlate. Used to prevent recursive Docker
    invocation when xlate is run inside the container.

# SEE ALSO

[xlate](https://metacpan.org/pod/xlate), [App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)

[getoptlong.sh](https://github.com/tecolicom/getoptlong)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2025 Kazumasa Utashiro.

This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)

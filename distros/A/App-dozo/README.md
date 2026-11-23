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
        --bundle       print a self-contained dozo
    -d, --debug        debug mode (show full command)
    -x, --trace        trace mode (set -x)
    -q, --quiet        quiet mode
    -n, --dryrun       dry-run mode

    -I, --image=#      Docker image (required unless -D)
    -D, --default      use default image
    -A, --auto-pull    pull newer image before running
    -F, --with=#       add features to the image (repeatable)
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
    -S, --status       show live containers and derived images

# VERSION

Version 1.03

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

A self-contained single file, which needs no other part of the
distribution, is attached to each release on GitHub; download it and
place it in your PATH:

    curl -fsSLo ~/.local/bin/dozo \
        https://github.com/tecolicom/App-dozo/releases/download/VERSION/dozo
    chmod +x ~/.local/bin/dozo

The same file is made by `dozo --bundle` from an installed **Dôzo**,
also inside the default image once it carries a **Dôzo** with this
option:

    docker run --rm tecolicom/xlate dozo --bundle > dozo

**Dôzo** requires Bash 4.4 or later, as does the `getoptlong.sh`
script it uses.

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
    When the current directory is under the git top directory, the
    corresponding subdirectory in the container is used as the working
    directory.

- **Live Container**

    Use `-L` to create or attach to a persistent container that survives
    between invocations. Container names are automatically generated from
    the image name and mount directory.

- **Environment Inheritance**

    Common environment variables are automatically inherited: `LANG`,
    `TZ`, proxy settings, terminal settings, and API keys for AI/LLM
    services (DeepL, OpenAI, Anthropic, Perplexity).

- **Flexible Mounting**

    The directory is mounted on `/work` in the container, and it is used
    as the working directory. Various mount options are available: current
    directory (`-W`), home directory (`-H`), additional volumes (`-V`),
    read-only mode (`-R`), or no mount (`-U`).

- **X11 Support**

    When `DISPLAY` is set, the address of the interface used for the
    default route is detected and passed to the container as `DISPLAY`,
    enabling GUI applications.

- **Configuration File**

    Use `.dozorc` to set default options. Loaded from the home directory,
    the git top directory, and the current directory, in that order, so
    that a closer file takes precedence.

- **Standalone Operation**

    **Dôzo** can operate independently of [xlate](https://metacpan.org/pod/xlate). The `getoptlong.sh`
    script is provided by the [Getopt::Long::Bash](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash) CPAN distribution,
    which is installed as a dependency. Alternatively, you can place
    `getoptlong.sh` in your `PATH` manually.

# OPTIONS

Repeatable options (**-E**, **-V**, **-P**, **-O** and **--with**) can be
given more than once, and a single value is also split into multiple
elements at commas; spaces around a comma are ignored.  Thus
`-P 8000,9000` gives two port mappings.  **-P** and **-O** are split
at spaces and tabs as well, so **-O** with the value `--memory 2g`
gives two docker options.  The others keep spaces in a value: **-E**
with the value `MSG=hello world` defines one variable.  Use
**--no-**_option_ (e.g. **--no-with**) to discard the values given so
far, including those in `.dozorc`.

- **-h**, **--help**

    Show help message.

- **--version**

    Show version number.

- **--bundle**

    Print a self-contained **Dôzo**, which includes what it needs from
    the distribution, and exit without running Docker.  The result is a
    single file that runs where only Bash 4.4 or later and Docker are
    available:

        dozo --bundle > ~/.local/bin/dozo-single

    A file made this way prints itself again.

- **-d**, **--debug**

    Enable debug mode. Shows the full docker command line that will be executed.

- **-x**, **--trace**

    Enable trace mode (set -x).

- **-q**, **--quiet**

    Quiet mode. Suppress the informational line printed to standard error
    before the container is started:

        docker run image=alpine env=13 command=echo hi

    It summarizes the image name, the number of environment variables to be
    inherited, the container name (with **-L**) and the command to be
    executed. This line is shown regardless of **-n**; use **-d** to see the
    whole docker command line instead.

- **-n**, **--dryrun**

    Dry-run mode. Show docker commands without executing them.
    Useful for testing and debugging.

- **-I** _image_, **--image**=_image_

    Specify Docker image. Required unless `-D` is given, but you can put
    it in `.dozorc` so you don't have to type it every time.

- **-D**, **--default**

    Use the default Docker image. If `DOZO_DEFAULT_IMAGE` environment
    variable is set, use that image. Otherwise, use `tecolicom/xlate`,
    that is, its `latest` tag. See ["DEFAULT IMAGE"](#default-image) section for details
    about the default image.

- **-A**, **--auto-pull**

    Run `docker pull` before running the command, so that a newer image
    is downloaded when the registry has one.  Nothing is downloaded
    without this option once the image is on the machine.  When the pull
    fails, as it does when offline, a warning is shown and the command
    runs on the local image.

    An existing live container stays as it is, on the image it was created
    from; use `-KL` to recreate it.

- **-E** _name_\[=_value_\], **--env**=_name_\[=_value_\]

    Specify environment variable to pass to the container. If _value_ is
    omitted, the value is inherited from the host environment. Repeatable.

- **-W**, **--mount-cwd**

    Mount current working directory.

- **-H**, **--mount-home**

    Mount home directory. The `HOME` environment variable in the
    container is set to the mount point (`/work`).

- **-U**, **--unmount**

    Do not mount any directory.

- **--mount-mode**=_mode_

    Set mount mode of the automatically mounted directory. _mode_ is
    either `rw` (read-write, default) or `ro` (read-only). This does not
    affect volumes given by **-V**; append `:ro` to them instead.

- **-R**, **--mount-ro**

    Mount directory as read-only. Shortcut for `--mount-mode=ro`.

- **-V** _path_, **-V** _from_:_to_, **--volume**=_from_:_to_

    Specify additional directory to mount. If only _path_ is given
    (without `:`), it is mounted to the same path in the container; a
    relative path is resolved against the current directory. Repeatable.

- **-B**, **--batch**

    Run in batch mode (non-interactive): the container gets no terminal
    and does not wait for input from one.  Input from a pipe or a file is
    still passed to the command, as in `git diff | dozo -B cdif`.

- **-L**, **--live**

    Use live (persistent) container.

- **-N** _name_, **--name**=_name_

    Specify container name explicitly.

- **-K**, **--kill**

    Kill and remove existing container.

- **-P** _port_, **-P** _host_:_container_, **--port**=_host_:_container_

    Specify port mapping. If only _port_ is given (without `:`), it is
    mapped to the same port in the container (e.g., `-P 8000` becomes
    `8000:8000`, and `-P 8000/udp` becomes `8000:8000/udp`).
    Repeatable.

- **-O** _option_, **--other**=_option_

    Specify additional docker options. Repeatable.

- **-F** _name_\[/_arg_\]\[,...\], **--with**=_name_\[/_arg_\]\[,...\]

    Run the image with the named features added.  A feature is a piece of
    Dockerfile kept in `~/.config/dozo/features/` (or under
    `XDG_CONFIG_HOME`), and the image made from the base image with the
    features applied in order is used instead of the base image.  A name
    may be followed by `/` and an argument for the feature.  Names are
    separated by comma, and the option is repeatable: values given in
    `.dozorc` and on the command line accumulate (`.dozorc` first).
    See ["FEATURES"](#features) section for details.

- **-S**, **--status**

    Show the status, and change nothing: what **-L** would do here and
    why (the mounted directory, the image and where it is given, the
    container it would use or make, the image of **--with**), the live
    containers and the derived images made by **dozo**, and the commands
    to remove those which are no longer used.  Nothing is pulled, built,
    started or removed.  It takes no command.  Give it with other options
    to see what they would do: `dozo -I alpine -S`, `dozo --with locale
    \-S`, `dozo -KL -S`.  See ["Show the status"](#show-the-status).

# INTERACTIVE MODE

The container is started with Docker's `--interactive` option, and
`--tty` is added as well when the standard input is a terminal (TTY).
With the **-B** (batch) option, neither is given when the standard
input is a terminal, so that nothing waits for keyboard input; when
the standard input is a pipe or a file, `--interactive` is still
given so that the input reaches the command.  The same rule is
applied to `docker exec` in live container mode.

This allows seamless interactive use when attaching to containers or
running interactive commands.

# LIVE CONTAINER

The `-L` option enables live (persistent) container mode. Unlike
normal mode where containers are removed after execution (`--rm`),
live containers persist between invocations, allowing you to maintain
state and reduce startup overhead.

## Container Lifecycle

When `-L` is specified, **Dôzo** behaves as follows:

- 1. **Container does not exist**

    Create a new persistent container (without `--rm` flag).  Without a
    command, the container is started with the image's default command
    (usually a shell) and you are connected to it.  With a command, the
    container is started in the background with the default command,
    and then the command is executed in it as in case 2.  So you can
    build up an environment from the first invocation, even in batch
    mode:

        dozo -L -B apt-get install -y foo
        dozo -L -B pip install bar

    If the image has an entrypoint, the command is given to it as
    arguments, and the container stops when it finishes.

- 2. **Container exists and is running**

    If a command is given, execute it using `docker exec`. Otherwise,
    attach to the container using `docker attach`.

- 3. **Container exists but is paused**

    Unpause the container with `docker unpause`, then proceed as above.

- 4. **Container exists but is not started**

    If the container is in the `created` or `exited` state, start it
    with `docker start`, then proceed as above.

## Container Naming

Container names are automatically generated in the format:

    <image_name>.<mount_directory>

For example, if you run:

    dozo -I tecolicom/xlate -L

from `/home/user/project`, the container name would be
`xlate.project`.

The name is made from the last part of the image name only, without
the tag, the owner or the registry: `alpine` and `alpine:3.18`, or
`tecolicom/xlate` and `other/xlate`, give the same name, and an
existing container is used for both.  When the image of the existing
container differs from the one given by **-I**, **dozo** tells so; use
**-K** to recreate the container, or **-N** to give another name.

You can override the auto-generated name using the `-N` option:

    dozo -I tecolicom/xlate -L -N mycontainer

The name also has only the last part of the mounted directory, so
`/a/project` and `/b/project` give the same name.  A live container
has the label `dozo.mount` with the full physical path of the
mounted directory (a directory reached through a symlink is the same
directory), `dozo.image` with the image given by **-I**, and
`dozo.version` with the version of **dozo** that made it.  If the
container found by a name made from **-I** is of another
directory, **dozo** stops instead of running the command on the files
of that directory; give another name with **-N**.  A name given by
**-N** is not checked, and nor is a container made by an older
**dozo**, which has no label.

## Managing Live Containers

- **Use the container of this directory**

        dozo -I myimage -L          # start working
        dozo -L                     # later: connect to the same container
        dozo -L make test           # run a command in it
        dozo -KL                    # make it again from the same image
        dozo -K                     # remove it

    When neither **-I**, **-D** nor **-N** is on the command line, **-L**
    and **-K** use the container made for the mounted directory, found by
    its `dozo.mount` label.  In a git repository this is the top
    directory, so the same container is used from any subdirectory.  If
    there are several of them (made from different images), **dozo** lists
    them; choose one with **-I** or **-N**.  **-KL** makes the container
    again from the image in its `dozo.image` label.

    An image set in `.dozorc` (by **-I** or **-D**) is a default: it is
    used only when there is no container for the directory.  So with
    **-D** in `~/.dozorc`, **dozo -L** connects to the container started
    by **dozo -I myimage -L** in this directory, and to the one of the
    default image elsewhere.  **-I** or **-D** on the command line always
    chooses the container of that image.

- **Attach to existing container**

        dozo -I myimage -L

    If no command is given, attaches to the container's main process.

- **Execute command in existing container**

        dozo -I myimage -L ls -la

    Runs the command in the existing container using `docker exec`.
    Environment variables are passed just as for a new container, and when
    the current directory is under the mounted directory, the
    corresponding subdirectory is used as the working directory.

- **Kill and recreate container**

        dozo -I myimage -KL

    The `-K` option removes the existing container before `-L` creates
    a new one. Useful when you need a fresh container state.

- **Kill container only**

        dozo -I myimage -K

    Without `-L`, the container is removed and the command exits.

- **Show the status**

        dozo -S

    Shows what **dozo -L** would do in this directory, and lists the live
    containers and the derived images (see ["Derived Images"](#derived-images)):

        /home/me/project:
          image      tecolicom/xlate (/home/me/.dozorc)
          container  xlate.project, exited (found by label)
          --with     locale: dozo/xlate:locale-3580643729 (exists)

        live containers:
          NAME           STATUS  IMAGE            DIRECTORY   NOTE
        * xlate.project  exited  tecolicom/xlate  ~/project   with dozo/xlate:locale-3580643729
          xlate.old      exited  tecolicom/xlate  ~/old       no label, gone

        derived images:
          IMAGE                         BASE             WITH    STATE     CREATED
        * dozo/xlate:locale-3580643729  tecolicom/xlate  locale  current   2 hours ago
          dozo/brew:locale-2017098170   homebrew/brew    locale  outdated  3 days ago

        to clean up:
          docker rm xlate.old
          docker image rm dozo/brew:locale-2017098170

    `*` marks what this directory uses.  The containers are those made
    by **dozo** (also those made before the `dozo.mount` label, shown with
    `no label`), and not those run without **-L**.  A container whose
    directory does not exist any more (`gone`) is to clean up; one whose
    image has been updated since it was made can be made again with
    **-KL**.  Where **-L** would stop with an error (several containers for
    the directory, a container of another directory), the status tells it
    as a `note` instead.  **dozo** removes nothing: copy the commands
    under `to clean up` to remove them.

# FEATURES

A _feature_ is a named piece of Dockerfile that is added to any
image.  It is a way to bring your usual setup (locale, dot files,
environment variables, ...) to an image made by someone else:

    dozo -I homebrew/brew --with locale,home make test

Features are not bundled with **dozo**; you write your own.

## Feature Directory

Features are looked up in
`${XDG_CONFIG_HOME:-$HOME/.config}/dozo/features/`.  A name which
contains `/` or starts with `.` is rejected, and a missing feature
is an error.  A feature takes one of two forms.

- **File**

    `features/NAME` is a fragment of Dockerfile (`RUN`, `ENV`, `USER`,
    and so on).

- **Directory**

    `features/NAME/Dockerfile` is the fragment, and the directory itself
    is the build context, so `COPY` can copy files in it.  Files made by
    Finder and editors (`.DS_Store`, `*~`, `.*.sw?`, `#*#`, `.#*`)
    do not cause a rebuild, but they are still in the context, and so is
    `Dockerfile` itself; `COPY . ...` copies them too.  To keep them
    out of the image, list them in `.dockerignore`:

        Dockerfile
        .dockerignore
        .DS_Store
        *~
        .*.sw?

**dozo** gives these values as Dockerfile `ARG`:

- `DOZO_USER`

    The user of the base image (`root` if the image sets none).

- `DOZO_HOME`

    The home directory of that user.

- `DOZO_ARG`

    The argument given as _name_`/`_arg_ (empty without it).

A feature may switch to `USER root`.  At the end of each feature,
**dozo** restores the original user of the base image (nothing is done
if the image sets none).

## Arguments

A feature can take an argument, given after the first `/` of the
name: `--with locale/ja_JP` passes `ja_JP` to the feature
`locale` as `DOZO_ARG`.  Everything after the first `/` is the
argument, so it may contain `/` itself (`zone/Asia/Tokyo`), and
spaces when quoted, but not a comma, which separates features.
`locale/` is the same as `locale`.  The argument is given by
`docker build --build-arg`, and is available as `$DOZO_ARG` in the
feature.

Different arguments make different images, and each of them is
reused.  **dozo** does not split the argument; to take several values,
pick a separator and split it with `IFS` in the feature (see
`features/locale` below):

    dozo -I homebrew/brew --with locale/ja_JP+en_US make test

## Examples

`features/locale`, which makes UTF-8 locales on Debian and Ubuntu
based images: `--with locale` makes `ja_JP.UTF-8`, and
`--with locale/ja_JP+en_US` makes `ja_JP.UTF-8` and
`en_US.UTF-8`.  **dozo** gives `LANG` of the host to the container,
so making the locale is enough.  It does nothing when the image has
the locales already, or has neither `locale-gen` nor `apt-get`
(such as alpine), so it can be given always in `~/.dozorc`:

    --with locale

It is included in the distribution, in `share/features/locale`.
**dozo** does not look there: copy it to the feature directory.  For
an installed distribution (with [File::ShareDir](https://metacpan.org/pod/File%3A%3AShareDir)):

    mkdir -p ~/.config/dozo/features
    cp "$(perl -MFile::ShareDir=dist_dir -E 'say dist_dir "App-dozo"')"/features/locale \
       ~/.config/dozo/features/

The comments in the file tell how it works.

`features/home/Dockerfile`, with other files in `features/home/`:

    COPY --chown=$DOZO_USER . $DOZO_HOME/
    RUN exec >> $DOZO_HOME/.inputrc \
        && echo Control-n: history-search-forward \
        && echo Control-p: history-search-backward

## Derived Images

Each feature makes one image on top of the previous one, tagged
`dozo/`_base_`:`_name_`-`_cksum_.  The checksum is made from
the parent image, the content of the feature (for a directory, the
names and contents of all files in it) and its argument.  An image
which already exists is reused and nothing is built, so the second and
later runs only add one image check per stage (a few tens of
milliseconds).  When a feature or the base image (for example updated
by **-A**) changes, the image is made again from that feature on, and
earlier images are reused.  Put heavy features first.

A base image which is not found locally is pulled automatically.
Build output goes to the standard error, and is not shown with
**-q**.  If a build fails, the command is not run.  With **-n**, the
`docker build` and `docker run` commands are shown but nothing is
built.

With **-L**, a new container is made from the derived image, but an
existing container is not changed.  **dozo** warns about it when its
image differs; use **-K** to recreate it:

    dozo -I homebrew/brew --with locale -KL

Derived images are not removed automatically.  They have the labels
`dozo.base` (the base image) and `dozo.with` (the features applied
so far).  **dozo -S** lists them with their state: `current` (used
by **--with** now), `outdated` (the feature or the base image has
changed since), `feature gone` or `base gone`, and shows the
commands to remove those not current and not used by a container (see
["Show the status"](#show-the-status)).  To list and remove all of them:

    docker image ls --filter label=dozo.base
    docker image rm $(docker image ls -q --filter label=dozo.base)

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

Lines starting with `#` are treated as comments.  A `#` in the middle
of a line does **not** start a comment, and a trailing comment is not
supported.

Each line is split into arguments in the same way as the shell does, so
quotation marks have to be balanced.  A line which cannot be parsed is
an error, and **Dôzo** stops after showing the file name, the line
number and the line itself.

Write nothing but options in the configuration file.  Its contents are
placed before the command line arguments, and option parsing stops at
the first argument which is not an option.  Everything after it,
including options given on the command line, is passed to the container
as the command to execute.  This is the rule which lets you write
`dozo -I alpine ls -la` without `-la` being taken as an option of
**Dôzo**, but it also means that a stray word in `.dozorc` disables
option parsing altogether.  With a trailing comment like this:

    -I alpine  # use alpine

`dozo -n ls` does not show the docker command line but runs
`# use alpine -n ls` in the container.

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
    is given. If not set, `tecolicom/xlate` is used, which resolves to its
    `latest` tag.

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

Copyright © 2025-2026 Kazumasa Utashiro.

This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)

package App::dozo;

our $VERSION = "1.03";

1;
=encoding utf-8

=for html <p align="center"><img src="https://raw.githubusercontent.com/tecolicom/App-dozo/main/images/dozo-logo.png" width="400"></p>

=head1 NAME

dozo - Dôzo, Docker with Zero Overhead

=head1 SYNOPSIS

dozo -I IMAGE [ options ] [ command ... ]

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

=head1 VERSION

Version 1.03

=head1 USAGE

When executed without arguments, Dôzo starts an interactive shell
inside the container.  When arguments are given, they are executed as
a command.

    dozo -I alpine                  # start shell
    dozo -I alpine ls -la           # run command

By setting C<-D> or your favorite image with C<-I> in F<~/.dozorc>,
you can simply run Dôzo without specifying an image.  Since the git
top directory is automatically mounted, git commands work as expected
from anywhere in the tree.

    $ dozo                          # start shell
    $ dozo git log -p               # run git log -p

With C<-L> option, you can use a persistent container.  Tools
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

=cut
=head1 INSTALLATION

Using L<cpanminus|https://metacpan.org/pod/App::cpanminus>:

    cpanm -n App::dozo

To install the latest version from GitHub:

    cpanm -n https://github.com/tecolicom/App-dozo.git

Alternatively, you can simply place C<dozo> and C<getoptlong.sh> in
your PATH.

A self-contained single file, which needs no other part of the
distribution, is attached to each release on GitHub; download it and
place it in your PATH:

    curl -fsSLo ~/.local/bin/dozo \
        https://github.com/tecolicom/App-dozo/releases/download/VERSION/dozo
    chmod +x ~/.local/bin/dozo

The same file is made by C<dozo --bundle> from an installed B<Dôzo>,
also inside the default image once it carries a B<Dôzo> with this
option:

    docker run --rm tecolicom/xlate dozo --bundle > dozo

B<Dôzo> requires Bash 4.4 or later, as does the C<getoptlong.sh>
script it uses.

=head1 DESCRIPTION

B<Dôzo> is a generic Docker runner that simplifies running commands in
Docker containers.  The name comes from the Japanese word "dôzo"
(どうぞ) meaning "please" or "go ahead", and also stands for "B<D>ocker
with B<Z>ero B<O>verhead".  The command name is C<dozo> for ease of
typing.

It automatically configures the tedious Docker options such as volume
mounts, environment variables, working directories, and interactive
terminal settings, so you can focus on the command you want to run.

B<Dôzo> is distributed as a standalone module and can be used as a
general-purpose Docker runner. It was originally developed as part of
L<App::Greple::xlate> and is used by L<xlate> for Docker operations.

B<Dôzo> uses L<getoptlong.sh|https://github.com/tecolicom/getoptlong>
for option parsing.

=head2 Key Features

=over 4

=item B<Git Friendly>

If you are working in a git environment, the git top directory is
automatically mounted. Otherwise the current directory is mounted.
When the current directory is under the git top directory, the
corresponding subdirectory in the container is used as the working
directory.

=item B<Live Container>

Use C<-L> to create or attach to a persistent container that survives
between invocations. Container names are automatically generated from
the image name and mount directory.

=item B<Environment Inheritance>

Common environment variables are automatically inherited: C<LANG>,
C<TZ>, proxy settings, terminal settings, and API keys for AI/LLM
services (DeepL, OpenAI, Anthropic, Perplexity).

=item B<Flexible Mounting>

The directory is mounted on F</work> in the container, and it is used
as the working directory. Various mount options are available: current
directory (C<-W>), home directory (C<-H>), additional volumes (C<-V>),
read-only mode (C<-R>), or no mount (C<-U>).

=item B<X11 Support>

When C<DISPLAY> is set, the address of the interface used for the
default route is detected and passed to the container as C<DISPLAY>,
enabling GUI applications.

=item B<Configuration File>

Use C<.dozorc> to set default options. Loaded from the home directory,
the git top directory, and the current directory, in that order, so
that a closer file takes precedence.

=item B<Standalone Operation>

B<Dôzo> can operate independently of L<xlate>. The C<getoptlong.sh>
script is provided by the L<Getopt::Long::Bash> CPAN distribution,
which is installed as a dependency. Alternatively, you can place
C<getoptlong.sh> in your C<PATH> manually.

=back

=head1 OPTIONS

Repeatable options (B<-E>, B<-V>, B<-P>, B<-O> and B<--with>) can be
given more than once, and a single value is also split into multiple
elements at commas; spaces around a comma are ignored.  Thus
C<-P 8000,9000> gives two port mappings.  B<-P> and B<-O> are split
at spaces and tabs as well, so B<-O> with the value C<--memory 2g>
gives two docker options.  The others keep spaces in a value: B<-E>
with the value C<MSG=hello world> defines one variable.  Use
B<--no->I<option> (e.g. B<--no-with>) to discard the values given so
far, including those in F<.dozorc>.

=over 7

=item B<-h>, B<--help>

Show help message.

=item B<--version>

Show version number.

=item B<--bundle>

Print a self-contained B<Dôzo>, which includes what it needs from
the distribution, and exit without running Docker.  The result is a
single file that runs where only Bash 4.4 or later and Docker are
available:

    dozo --bundle > ~/.local/bin/dozo-single

A file made this way prints itself again.

=item B<-d>, B<--debug>

Enable debug mode. Shows the full docker command line that will be executed.

=item B<-x>, B<--trace>

Enable trace mode (set -x).

=item B<-q>, B<--quiet>

Quiet mode. Suppress the informational line printed to standard error
before the container is started:

    docker run image=alpine env=13 command=echo hi

It summarizes the image name, the number of environment variables to be
inherited, the container name (with B<-L>) and the command to be
executed. This line is shown regardless of B<-n>; use B<-d> to see the
whole docker command line instead.

=item B<-n>, B<--dryrun>

Dry-run mode. Show docker commands without executing them.
Useful for testing and debugging.

=item B<-I> I<image>, B<--image>=I<image>

Specify Docker image. Required unless C<-D> is given, but you can put
it in F<.dozorc> so you don't have to type it every time.

=item B<-D>, B<--default>

Use the default Docker image. If C<DOZO_DEFAULT_IMAGE> environment
variable is set, use that image. Otherwise, use C<tecolicom/xlate>,
that is, its C<latest> tag. See L</DEFAULT IMAGE> section for details
about the default image.

=item B<-A>, B<--auto-pull>

Run C<docker pull> before running the command, so that a newer image
is downloaded when the registry has one.  Nothing is downloaded
without this option once the image is on the machine.  When the pull
fails, as it does when offline, a warning is shown and the command
runs on the local image.

An existing live container stays as it is, on the image it was created
from; use C<-KL> to recreate it.

=item B<-E> I<name>[=I<value>], B<--env>=I<name>[=I<value>]

Specify environment variable to pass to the container. If I<value> is
omitted, the value is inherited from the host environment. Repeatable.

=item B<-W>, B<--mount-cwd>

Mount current working directory.

=item B<-H>, B<--mount-home>

Mount home directory. The C<HOME> environment variable in the
container is set to the mount point (F</work>).

=item B<-U>, B<--unmount>

Do not mount any directory.

=item B<--mount-mode>=I<mode>

Set mount mode of the automatically mounted directory. I<mode> is
either C<rw> (read-write, default) or C<ro> (read-only). This does not
affect volumes given by B<-V>; append C<:ro> to them instead.

=item B<-R>, B<--mount-ro>

Mount directory as read-only. Shortcut for C<--mount-mode=ro>.

=item B<-V> I<path>, B<-V> I<from>:I<to>, B<--volume>=I<from>:I<to>

Specify additional directory to mount. If only I<path> is given
(without C<:>), it is mounted to the same path in the container; a
relative path is resolved against the current directory. Repeatable.

=item B<-B>, B<--batch>

Run in batch mode (non-interactive): the container gets no terminal
and does not wait for input from one.  Input from a pipe or a file is
still passed to the command, as in C<git diff | dozo -B cdif>.

=item B<-L>, B<--live>

Use live (persistent) container.

=item B<-N> I<name>, B<--name>=I<name>

Specify container name explicitly.

=item B<-K>, B<--kill>

Kill and remove existing container.

=item B<-P> I<port>, B<-P> I<host>:I<container>, B<--port>=I<host>:I<container>

Specify port mapping. If only I<port> is given (without C<:>), it is
mapped to the same port in the container (e.g., C<-P 8000> becomes
C<8000:8000>, and C<-P 8000/udp> becomes C<8000:8000/udp>).
Repeatable.

=item B<-O> I<option>, B<--other>=I<option>

Specify additional docker options. Repeatable.

=item B<-F> I<name>[/I<arg>][,...], B<--with>=I<name>[/I<arg>][,...]

Run the image with the named features added.  A feature is a piece of
Dockerfile kept in F<~/.config/dozo/features/> (or under
C<XDG_CONFIG_HOME>), and the image made from the base image with the
features applied in order is used instead of the base image.  A name
may be followed by C</> and an argument for the feature.  Names are
separated by comma, and the option is repeatable: values given in
F<.dozorc> and on the command line accumulate (F<.dozorc> first).
See L</FEATURES> section for details.

=item B<-S>, B<--status>

Show the status, and change nothing: what B<-L> would do here and
why (the mounted directory, the image and where it is given, the
container it would use or make, the image of B<--with>), the live
containers and the derived images made by B<dozo>, and the commands
to remove those which are no longer used.  Nothing is pulled, built,
started or removed.  It takes no command.  Give it with other options
to see what they would do: C<dozo -I alpine -S>, C<dozo --with locale
-S>, C<dozo -KL -S>.  See L</Show the status>.

=back

=head1 INTERACTIVE MODE

The container is started with Docker's C<--interactive> option, and
C<--tty> is added as well when the standard input is a terminal (TTY).
With the B<-B> (batch) option, neither is given when the standard
input is a terminal, so that nothing waits for keyboard input; when
the standard input is a pipe or a file, C<--interactive> is still
given so that the input reaches the command.  The same rule is
applied to C<docker exec> in live container mode.

This allows seamless interactive use when attaching to containers or
running interactive commands.

=head1 LIVE CONTAINER

The C<-L> option enables live (persistent) container mode. Unlike
normal mode where containers are removed after execution (C<--rm>),
live containers persist between invocations, allowing you to maintain
state and reduce startup overhead.

=head2 Container Lifecycle

When C<-L> is specified, B<Dôzo> behaves as follows:

=over 4

=item 1. B<Container does not exist>

Create a new persistent container (without C<--rm> flag).  Without a
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

=item 2. B<Container exists and is running>

If a command is given, execute it using C<docker exec>. Otherwise,
attach to the container using C<docker attach>.

=item 3. B<Container exists but is paused>

Unpause the container with C<docker unpause>, then proceed as above.

=item 4. B<Container exists but is not started>

If the container is in the C<created> or C<exited> state, start it
with C<docker start>, then proceed as above.

=back

=head2 Container Naming

Container names are automatically generated in the format:

    <image_name>.<mount_directory>

For example, if you run:

    dozo -I tecolicom/xlate -L

from C</home/user/project>, the container name would be
C<xlate.project>.

The name is made from the last part of the image name only, without
the tag, the owner or the registry: C<alpine> and C<alpine:3.18>, or
C<tecolicom/xlate> and C<other/xlate>, give the same name, and an
existing container is used for both.  When the image of the existing
container differs from the one given by B<-I>, B<dozo> tells so; use
B<-K> to recreate the container, or B<-N> to give another name.

You can override the auto-generated name using the C<-N> option:

    dozo -I tecolicom/xlate -L -N mycontainer

The name also has only the last part of the mounted directory, so
F</a/project> and F</b/project> give the same name.  A live container
has the label C<dozo.mount> with the full physical path of the
mounted directory (a directory reached through a symlink is the same
directory), C<dozo.image> with the image given by B<-I>, and
C<dozo.version> with the version of B<dozo> that made it.  If the
container found by a name made from B<-I> is of another
directory, B<dozo> stops instead of running the command on the files
of that directory; give another name with B<-N>.  A name given by
B<-N> is not checked, and nor is a container made by an older
B<dozo>, which has no label.

=head2 Managing Live Containers

=over 4

=item B<Use the container of this directory>

    dozo -I myimage -L          # start working
    dozo -L                     # later: connect to the same container
    dozo -L make test           # run a command in it
    dozo -KL                    # make it again from the same image
    dozo -K                     # remove it

When neither B<-I>, B<-D> nor B<-N> is on the command line, B<-L>
and B<-K> use the container made for the mounted directory, found by
its C<dozo.mount> label.  In a git repository this is the top
directory, so the same container is used from any subdirectory.  If
there are several of them (made from different images), B<dozo> lists
them; choose one with B<-I> or B<-N>.  B<-KL> makes the container
again from the image in its C<dozo.image> label.

An image set in F<.dozorc> (by B<-I> or B<-D>) is a default: it is
used only when there is no container for the directory.  So with
B<-D> in F<~/.dozorc>, B<dozo -L> connects to the container started
by B<dozo -I myimage -L> in this directory, and to the one of the
default image elsewhere.  B<-I> or B<-D> on the command line always
chooses the container of that image.

=item B<Attach to existing container>

    dozo -I myimage -L

If no command is given, attaches to the container's main process.

=item B<Execute command in existing container>

    dozo -I myimage -L ls -la

Runs the command in the existing container using C<docker exec>.
Environment variables are passed just as for a new container, and when
the current directory is under the mounted directory, the
corresponding subdirectory is used as the working directory.

=item B<Kill and recreate container>

    dozo -I myimage -KL

The C<-K> option removes the existing container before C<-L> creates
a new one. Useful when you need a fresh container state.

=item B<Kill container only>

    dozo -I myimage -K

Without C<-L>, the container is removed and the command exits.

=item B<Show the status>

    dozo -S

Shows what B<dozo -L> would do in this directory, and lists the live
containers and the derived images (see L</Derived Images>):

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

C<*> marks what this directory uses.  The containers are those made
by B<dozo> (also those made before the C<dozo.mount> label, shown with
C<no label>), and not those run without B<-L>.  A container whose
directory does not exist any more (C<gone>) is to clean up; one whose
image has been updated since it was made can be made again with
B<-KL>.  Where B<-L> would stop with an error (several containers for
the directory, a container of another directory), the status tells it
as a C<note> instead.  B<dozo> removes nothing: copy the commands
under C<to clean up> to remove them.

=back

=head1 FEATURES

A I<feature> is a named piece of Dockerfile that is added to any
image.  It is a way to bring your usual setup (locale, dot files,
environment variables, ...) to an image made by someone else:

    dozo -I homebrew/brew --with locale,home make test

Features are not bundled with B<dozo>; you write your own.

=head2 Feature Directory

Features are looked up in
F<${XDG_CONFIG_HOME:-$HOME/.config}/dozo/features/>.  A name which
contains C</> or starts with C<.> is rejected, and a missing feature
is an error.  A feature takes one of two forms.

=over 4

=item B<File>

F<features/NAME> is a fragment of Dockerfile (C<RUN>, C<ENV>, C<USER>,
and so on).

=item B<Directory>

F<features/NAME/Dockerfile> is the fragment, and the directory itself
is the build context, so C<COPY> can copy files in it.  Files made by
Finder and editors (F<.DS_Store>, F<*~>, F<.*.sw?>, F<#*#>, F<.#*>)
do not cause a rebuild, but they are still in the context, and so is
F<Dockerfile> itself; C<COPY . ...> copies them too.  To keep them
out of the image, list them in F<.dockerignore>:

    Dockerfile
    .dockerignore
    .DS_Store
    *~
    .*.sw?

=back

B<dozo> gives these values as Dockerfile C<ARG>:

=over 4

=item C<DOZO_USER>

The user of the base image (C<root> if the image sets none).

=item C<DOZO_HOME>

The home directory of that user.

=item C<DOZO_ARG>

The argument given as I<name>C</>I<arg> (empty without it).

=back

A feature may switch to C<USER root>.  At the end of each feature,
B<dozo> restores the original user of the base image (nothing is done
if the image sets none).

=head2 Arguments

A feature can take an argument, given after the first C</> of the
name: C<--with locale/ja_JP> passes C<ja_JP> to the feature
F<locale> as C<DOZO_ARG>.  Everything after the first C</> is the
argument, so it may contain C</> itself (C<zone/Asia/Tokyo>), and
spaces when quoted, but not a comma, which separates features.
C<locale/> is the same as C<locale>.  The argument is given by
C<docker build --build-arg>, and is available as C<$DOZO_ARG> in the
feature.

Different arguments make different images, and each of them is
reused.  B<dozo> does not split the argument; to take several values,
pick a separator and split it with C<IFS> in the feature (see
F<features/locale> below):

    dozo -I homebrew/brew --with locale/ja_JP+en_US make test

=head2 Examples

F<features/locale>, which makes UTF-8 locales on Debian and Ubuntu
based images: C<--with locale> makes C<ja_JP.UTF-8>, and
C<--with locale/ja_JP+en_US> makes C<ja_JP.UTF-8> and
C<en_US.UTF-8>.  B<dozo> gives C<LANG> of the host to the container,
so making the locale is enough.  It does nothing when the image has
the locales already, or has neither C<locale-gen> nor C<apt-get>
(such as alpine), so it can be given always in F<~/.dozorc>:

    --with locale

It is included in the distribution, in F<share/features/locale>.
B<dozo> does not look there: copy it to the feature directory.  For
an installed distribution (with L<File::ShareDir>):

    mkdir -p ~/.config/dozo/features
    cp "$(perl -MFile::ShareDir=dist_dir -E 'say dist_dir "App-dozo"')"/features/locale \
       ~/.config/dozo/features/

The comments in the file tell how it works.

F<features/home/Dockerfile>, with other files in F<features/home/>:

    COPY --chown=$DOZO_USER . $DOZO_HOME/
    RUN exec >> $DOZO_HOME/.inputrc \
        && echo Control-n: history-search-forward \
        && echo Control-p: history-search-backward

=head2 Derived Images

Each feature makes one image on top of the previous one, tagged
C<dozo/>I<base>C<:>I<name>C<->I<cksum>.  The checksum is made from
the parent image, the content of the feature (for a directory, the
names and contents of all files in it) and its argument.  An image
which already exists is reused and nothing is built, so the second and
later runs only add one image check per stage (a few tens of
milliseconds).  When a feature or the base image (for example updated
by B<-A>) changes, the image is made again from that feature on, and
earlier images are reused.  Put heavy features first.

A base image which is not found locally is pulled automatically.
Build output goes to the standard error, and is not shown with
B<-q>.  If a build fails, the command is not run.  With B<-n>, the
C<docker build> and C<docker run> commands are shown but nothing is
built.

With B<-L>, a new container is made from the derived image, but an
existing container is not changed.  B<dozo> warns about it when its
image differs; use B<-K> to recreate it:

    dozo -I homebrew/brew --with locale -KL

Derived images are not removed automatically.  They have the labels
C<dozo.base> (the base image) and C<dozo.with> (the features applied
so far).  B<dozo -S> lists them with their state: C<current> (used
by B<--with> now), C<outdated> (the feature or the base image has
changed since), C<feature gone> or C<base gone>, and shows the
commands to remove those not current and not used by a container (see
L</Show the status>).  To list and remove all of them:

    docker image ls --filter label=dozo.base
    docker image rm $(docker image ls -q --filter label=dozo.base)

=head1 CONFIGURATION FILE

C<.dozorc> files are loaded from the following locations in order:

=over 4

=item 1. Home directory C<.dozorc>

=item 2. Git top directory C<.dozorc> (if different)

=item 3. Current directory C<.dozorc>

=item 4. Command line arguments

=back

For single-value options (like C<-I>, C<-N>), later values override
earlier ones. For repeatable options (like C<-E>, C<-V>, C<-P>, C<-O>),
all values are accumulated in order.

You can use any command line option in the configuration file:

    # Example .dozorc
    -I tecolicom/xlate:latest
    -E CUSTOM_VAR=value
    -V /data:/data

Lines starting with C<#> are treated as comments.  A C<#> in the middle
of a line does B<not> start a comment, and a trailing comment is not
supported.

Each line is split into arguments in the same way as the shell does, so
quotation marks have to be balanced.  A line which cannot be parsed is
an error, and B<Dôzo> stops after showing the file name, the line
number and the line itself.

Write nothing but options in the configuration file.  Its contents are
placed before the command line arguments, and option parsing stops at
the first argument which is not an option.  Everything after it,
including options given on the command line, is passed to the container
as the command to execute.  This is the rule which lets you write
C<dozo -I alpine ls -la> without C<-la> being taken as an option of
B<Dôzo>, but it also means that a stray word in F<.dozorc> disables
option parsing altogether.  With a trailing comment like this:

    -I alpine  # use alpine

C<dozo -n ls> does not show the docker command line but runs
C<# use alpine -n ls> in the container.

=head1 DOCKER-IN-DOCKER

To use Docker commands inside the container, mount the host's Docker
socket:

    # .dozorc for Docker-in-Docker
    -I docker
    -V /var/run/docker.sock

This allows you to run Docker commands from within the container using
the host's Docker daemon:

    $ dozo docker run --rm alpine uname -a

Or run it as a one-liner without C<.dozorc>:

    $ dozo -I docker -V /var/run/docker.sock docker run --rm alpine uname -a

=head1 DEFAULT IMAGE

The C<tecolicom/xlate> image is specifically designed for document
translation and text processing tasks, providing a comprehensive
environment with the following features:

=head2 Translation and AI Tools

=over 4

=item * B<DeepL CLI> - Command-line interface for DeepL translation API

=item * B<gpty> - GPT command-line tool for AI-powered text processing

=item * B<llm> - Unified LLM interface with plugins for multiple providers:
Gemini, Claude 3, Perplexity, and OpenRouter

=back

=head2 Text Processing Tools

=over 4

=item * B<greple> with xlate module - Pattern-based text extraction and
translation

=item * B<sdif> - Side-by-side diff viewer with word-level highlighting

=item * B<ansicolumn>, B<ansifold>, B<ansiexpand> - ANSI-aware text
formatting tools

=item * B<optex textconv> - Document format converter (PDF, Office, etc.)

=back

=head2 Greple Extensions

Multiple L<App::Greple> extension modules are pre-installed:

=over 4

=item * B<msdoc> - Microsoft Office document support

=item * B<xp> - Extended pattern syntax

=item * B<subst> - Text substitution with dictionary

=item * B<frame> - Frame-style output formatting

=back

=head2 Git Integration

The image includes a pre-configured git environment optimized for
document comparison and review. Since B<Dôzo> automatically mounts
the git top directory by default, git commands work seamlessly with
full repository context:

=over 4

=item * B<Side-by-side diff> - C<git diff>, C<git log>, and C<git show>
use B<sdif> for word-level side-by-side comparison

=item * B<Colorful blame> - C<git blame> uses B<greple> for enhanced
label coloring

=item * B<Office document diff> - Compare Word (.docx), Excel (.xlsx),
and PowerPoint (.pptx) files directly with git

=item * B<PDF diff> - View PDF metadata changes

=item * B<JSON diff> - Normalized JSON comparison using B<jq>

=back

=head2 Additional Utilities

=over 4

=item * B<MeCab> - Japanese morphological analyzer with IPA dictionary

=item * B<poppler-utils> - PDF processing tools (pdftotext, etc.)

=item * B<jq>, B<yq> - JSON and YAML processors

=back

=head2 Environment

=over 4

=item * Based on Ubuntu with Japanese locale (ja_JP.UTF-8)

=item * Perl and Python3 runtime environments

=item * Common API keys are automatically inherited from host
(DEEPL_AUTH_KEY, OPENAI_API_KEY, ANTHROPIC_API_KEY, etc.)

=back

=head1 ENVIRONMENT

=head2 Configuration Variables

=over 4

=item C<DOZO_DEFAULT_IMAGE>

Specifies the default Docker image used when C<-D> (C<--default>) option
is given. If not set, C<tecolicom/xlate> is used, which resolves to its
C<latest> tag.

=back

=head2 Inherited Variables

The following environment variables are inherited by default:

    LANG TZ
    HTTP_PROXY HTTPS_PROXY http_proxy https_proxy
    TERM_PROGRAM TERM_BGCOLOR COLORTERM
    DEEPL_AUTH_KEY OPENAI_API_KEY ANTHROPIC_API_KEY LLM_PERPLEXITY_KEY

=head2 Container Variables

The following environment variables are set inside the container:

=over 4

=item C<DOZO_RUNNING_ON_DOCKER=1>

Indicates the command is running inside a container started by Dôzo.

=item C<XLATE_RUNNING_ON_DOCKER=1>

For compatibility with xlate. Used to prevent recursive Docker
invocation when xlate is run inside the container.

=back

=head1 SEE ALSO

L<xlate>, L<App::Greple::xlate>

L<getoptlong.sh|https://github.com/tecolicom/getoptlong>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright © 2025-2026 Kazumasa Utashiro.

This software is released under the MIT License.
L<https://opensource.org/licenses/MIT>

=cut

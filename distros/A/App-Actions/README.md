## Name

App::Actions - run GitHub Actions workflows locally

## Version

0.002.1

## Synopsis

Run every job of a workflow (this is what `action-run run` does):

```perl
    use App::Actions;

    my $actions = App::Actions->new(
            workflow_file => "$ENV{HOME}/src/CGI-Info/.github/workflows/perl-ci.yml",
            project_dir   => "$ENV{HOME}/src/CGI-Info",
    );

    exit $actions->run();    # 0 = passed, 1 = a job failed, 2 = could not run
```

Run one job, with a secret, and show the Docker commands:

```perl
    my $actions = App::Actions->new(
            workflow_file => '.github/workflows/ci.yml',
            jobs          => [ 'test' ],
            secrets       => { CODECOV_TOKEN => $ENV{CODECOV_TOKEN} },
            verbose       => 1,
    );
    exit $actions->run;
```

See what would run, without running it:

```perl
    App::Actions->new(workflow_file => '.github/workflows/ci.yml')->list_jobs;
    exit App::Actions->new(workflow_file => '.github/workflows/ci.yml', dry_run => 1)->run;
```

Check Docker and download the images first, for a CI job:

```perl
    use JSON::PP;

    my $result = App::Actions->new(workflow_file => '.github/workflows/ci.yml')->preflight(json => 1);
    print JSON::PP->new->canonical->encode($result->{summary}), "\n";
    exit $result->{exit};
```

Run the jobs of a matrix four at a time, and keep their logs:

```perl
    App::Actions->new(workflow_file => '.github/workflows/ci.yml', parallel => 4)->run;
    # logs: see "action-run logs"
```

Set an option for every run on this computer, without changing the code
(see ["new"](#new) for where the file may live; the environment wins over it):

```
    # ~/.conf/local.yaml
    ---
    App__Actions:
      keep_images: 0

    # or, for one command:  App__Actions__keep_images=0 action-run ci.yml .
```

Collect the warnings and errors instead of printing them, or turn them off:

```perl
    my @messages;
    my $exit = App::Actions->new(workflow_file => 'ci.yml', logger => \@messages)->run;
    print "$_->{level}: $_->{message}\n" for @messages;

    App::Actions->new(workflow_file => 'ci.yml', logger => 'NULL')->run;
```

## Description

**In short:** this module runs a GitHub Actions workflow on your own
computer, in Docker containers, so you can test and debug it without
pushing to GitHub.  Most people use it through the `action-run` command;
see [action-run](https://metacpan.org/pod/action-run).

How it works, in brief:

- 1. It reads the workflow file ([App::Actions::Workflow](https://metacpan.org/pod/App%3A%3AActions%3A%3AWorkflow)) and expands
each job's matrix.
- 2. It checks that Docker works and can see your project (as
`action-run check` does).
- 3. It downloads the images the jobs need, several at a time.
- 4. For each job, it makes a private Docker network, starts the job's
service containers (for example a database), and starts one long-lived
container for the job, with your project mounted in it.
- 5. It runs each step in that container with `docker exec`.  Files and
installed modules stay between steps, as on GitHub.
- 6. It removes the job's containers and network, and reports the
result.

The rest of this section gives the details.

App::Actions runs a GitHub Actions workflow on a local machine using Docker
containers, allowing troublesome issues to be more easily debugged.
It understands the parts of a workflow that are useful for local
testing: jobs, matrix expansion, container images, service containers,
environment files, working directories, shells, and `if` conditions.

Each job gets a private Docker network, its own service containers, and a
long-lived job container.  Steps are executed in that container with
`docker exec`, so files and installed modules persist between steps.  A
service must stay up: one that stops, or that a restart policy keeps bringing
back, stops the run with the state and restart count the daemon reports and
the last lines the container printed.  A container the daemon refuses to start
is reported the same way: its message is quoted and the image, entrypoint or
published port it names is called out, because there is nothing of the
container's own to quote.  When a job finishes, its containers and network are
removed; the images the run pulled are kept, as the next run's cache, unless
`keep_images` is set to a false value.  The `GITHUB_ENV`, `GITHUB_PATH`,
`GITHUB_OUTPUT`, `GITHUB_STATE`, and `GITHUB_STEP_SUMMARY` files written by
steps are honoured.  If an image has no `sudo` and the container is running
as root, a small `sudo` shim is placed on `PATH` so that steps such as
`sudo apt update` work locally.

The host may run UNIX or Windows; only the containers are Linux.  Command
output is captured without `fork` or a piped `open`, and paths, volumes and
permissions are handled in a platform-neutral way, so the same code and test
suite run on both.  Step scripts, the `sudo` and `apt` shims, and
`event.json` are written with LF line endings, which is what the container's
shell expects.  Arguments are quoted for the Windows command line by
[App::Actions::Process](https://metacpan.org/pod/App%3A%3AActions%3A%3AProcess) itself, because Perl's own Windows quoting gives up
on any argument containing a double quote and the C runtime then splits it at
its spaces.

Run `action-run check` to diagnose the host before running a workflow.  It
reports the platform, the Docker client and daemon versions, whether the
daemon runs Linux containers, and whether Docker can bind-mount a temporary
directory and the project directory.  Each problem it finds is followed by the
step that fixes it, such as starting Docker Desktop, switching it to Linux
containers, or sharing the drive that holds the project.  See [action-run](https://metacpan.org/pod/action-run)
for the details.

Errors raised by this module, [App::Actions::Workflow](https://metacpan.org/pod/App%3A%3AActions%3A%3AWorkflow) and
[App::Actions::Action](https://metacpan.org/pod/App%3A%3AActions%3A%3AAction) come from the catalogue in [App::Actions::I18N](https://metacpan.org/pod/App%3A%3AActions%3A%3AI18N).
They are in English unless `ACTION_RUN_LANG` names another catalogue
(`fr`, `de` or `zh`).

## Methods

### New

Creates the object that runs one workflow.

#### Arguments

- `workflow_file` - required; the path of the workflow.
- `project_dir` - the repository the workflow runs against.  It may
be omitted when the workflow is inside a repository's `.github/workflows`
directory; the repository root is then used.
- Run options: `jobs`, `image`, `perl_image`, `platform`, `user`,
`env`, `secrets`, `dry_run`, `explain`, `verbose`, `quiet`, `keep`,
`keep_images`, `pull`, `no_pull`, `strict_actions`, `skip_check`,
`pull_concurrency`, `parallel`, `log_dir`, `cache_file`, `docker`, and
`docker_bin`.  Any other key is an error.
- `logger` - where warnings and errors go: a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction)
object, an array reference to collect them in, a hash reference of
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) options (for example `{ file => $path }`), or the
string `'NULL'` to throw them away.  By default they are printed to standard
error.

`parallel` says how many jobs of one matrix may run at the same time; it is
1 unless it is set, and `action-run` sets it to the number of processors
unless `--parallel` says otherwise.  `pull_concurrency` says how many images
may be pulled at the same time; it defaults to `ACTION_RUN_PULL_CONCURRENCY`
from the environment, and to four when that is not set or empty.  It must be
a positive integer.  `keep_images` defaults to true: the images a run pulls
stay behind as the next run's cache, and a false value removes the ones the
run itself pulled when it finishes.  The kept images are recorded by
[App::Actions::Cache](https://metacpan.org/pod/App%3A%3AActions%3A%3ACache), which is what `action-run cache` lists and
`action-run cache --prune` removes; the record lives in the user's cache
directory, and `cache_file` or `ACTION_RUN_CACHE_FILE` moves it.
`log_dir` says where the per-job logs of a parallel run are kept; it
defaults to `ACTION_RUN_LOG_DIR`, then to `action-run/logs` under that same
cache directory.  `action-run logs` reads that directory, with the sizes and
ages of the logs, `action-run logs --json` prints them, with the clock their
ages are measured from, as a versioned document, and
`action-run logs --prune` removes them.  `--older-than` filters that listing,
and with `--prune` removes only logs at least that old; a log is selected on
its own modification time, so newer logs in the same run stay.

`explain` is a dry run whose output is the containers rather than the Docker
commands: nothing is started and no daemon is contacted, and one block per
container says what it would be told to run, which is how a service that stops
on start-up can be diagnosed without running it.

Before any job starts, the environment is probed exactly as `action-run`
`check` does: the daemon must be reachable and run Linux containers, and the
project directory must be readable through a bind mount.  The probe uses the
image the first runnable job will use, so a working setup needs no extra pull.
It says nothing when it passes and prints the full report, with remedies, when
it does not, in which case no container is started.  `skip_check` starts the
workflow anyway, and is what `action-run --skip-check` sets.

The images the run needs are then prepared before the first container:
job images, service images and `docker://` action images, with matrix values
resolved.  A missing image is pulled at that point, so a mistyped image is
reported before any job has started rather than halfway through one.  Local
composite actions are read up front for the same reason, including actions
used inside other actions, so an image named within one is known before its
first step; only an image whose name the run alone can resolve is left until
it is used.  Presence is checked first, then the missing images are pulled
`pull_concurrency` at a time (four by default), so a wide matrix does not sit
through one download after another; a failure is still reported against the
image and the job, service or action that needed it, whichever pull finished
first.

`pull` refreshes the images even when they are present locally, and each
image is pulled once per run, however many jobs, services or steps use it: the
check a job makes of its own image reuses what the run has already fetched.

`docker` and `docker_bin` name the Docker command.  It may also be a wrapper
script; a wrapper written in Perl is run with the current Perl interpreter, so
it works on Windows too, where the operating system cannot start a shebang
script directly.  `docker` may instead be an object with the
[App::Actions::Docker](https://metacpan.org/pod/App%3A%3AActions%3A%3ADocker) interface, which is how the tests run without one.

**Configuration files and environment variables.**  After the arguments are
checked, [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) adds settings from two more places.  Both can
set any of the options above, and **both win over the arguments**:

- 1. Configuration files.  [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) looks for files named
`base.yaml` and then `local.yaml` (or `.json`, `.xml`, `.ini` and so
on) in the directory `CONFIG_DIR` names or, when it is not set, in
`~/.conf`, `~/config`, `~/conf` and `conf`.  The settings for this
module go in a section called `App__Actions`:

    ```
        # ~/.conf/local.yaml
        ---
        App__Actions:
          parallel: 2
          keep_images: 0
    ```

- 2. Environment variables named `App__Actions__` and then the option,
which win over everything else:

    ```
        App__Actions__parallel=2 App__Actions__quiet=1 action-run ci.yml .
    ```

So the order, from weakest to strongest, is: the arguments, then the
configuration files, then the environment variables.  Only top-level options
can be set this way; `App__Actions__env__NAME` does not add to `env`.  There
is no argument for naming a configuration file: `config_file` is refused as
an unknown option.

**Warnings and errors.**  What a run reports as a problem - a step that
failed, a job that could not run, a container that could not be removed -
goes to a [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) logger, at the `error` or `warn` level.  The
progress lines, the `[dry-run]` and Docker command echoes and the job
summary are the run's output, not diagnostics, and stay on standard output.
The default logger prints each message to standard error as a plain line, as
earlier versions did.  A `logger` in the configuration replaces it: in the
`App__Actions` section, or in a `UNIVERSAL` section of `universal.yaml`,
which [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) applies to every class that uses it.  A `logger`
argument replaces both.

```
    # ~/.conf/local.yaml: keep this module's messages in a file
    ---
    App__Actions:
      logger:
        file: /var/log/action-run.log
        level: warning
```

#### Returns

An `App::Actions` object.  Besides the options it holds `logger`, a
[Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction) object (a silent one for `'NULL'`), and any other
top-level keys found in the configuration files.  Only the options
listed above are passed on to [App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner), so the other keys
have no effect.

#### Side Effects

Reads and parses the workflow file.  Reads the configuration files described
above, if there are any, and the `App__Actions__*` environment variables.

#### Example

```perl
    # The repository root is found from the workflow's path.
    my $actions = App::Actions->new(
            workflow_file => 'project/.github/workflows/ci.yml',
            jobs          => [ 'test' ],
            dry_run       => 1,
    );
```

#### Api Specification

##### Input

```perl
    {
            workflow_file    => { type => 'string', min => 1 },
            project_dir      => { type => 'string', optional => 1 },
            jobs             => { type => 'arrayref', optional => 1 },
            env              => { type => 'hashref', optional => 1 },
            secrets          => { type => 'hashref', optional => 1 },
            docker           => { type => 'object', optional => 1 },
            image            => { type => 'string', optional => 1 },
            perl_image       => { type => 'string', optional => 1 },
            platform         => { type => 'string', optional => 1 },
            user             => { type => 'string', optional => 1 },
            log_dir          => { type => 'string', optional => 1 },
            cache_file       => { type => 'string', optional => 1 },
            docker_bin       => { type => 'string', optional => 1 },
            pull_concurrency => { type => 'string', optional => 1 },
            parallel         => { type => 'string', optional => 1 },
            dry_run          => { type => 'string', optional => 1 },
            explain          => { type => 'string', optional => 1 },
            verbose          => { type => 'string', optional => 1 },
            quiet            => { type => 'string', optional => 1 },
            keep             => { type => 'string', optional => 1 },
            keep_images      => { type => 'string', optional => 1 },
            pull             => { type => 'string', optional => 1 },
            no_pull          => { type => 'string', optional => 1 },
            strict_actions   => { type => 'string', optional => 1 },
            skip_check       => { type => 'string', optional => 1 },
            logger           => { type => [qw(object arrayref hashref string)], optional => 1 },
    }
```

##### Output

```perl
    { type => 'object', isa => 'App::Actions' }
```

#### Messages

```
    +-----------------------------------+------------------------------+-------------------------------+
    | Message                           | Meaning                      | Resolution                    |
    +-----------------------------------+------------------------------+-------------------------------+
    | workflow_file is required         | No workflow was named        | Pass workflow_file            |
    | Workflow file 'F' does not exist  | No file at the path          | Check the path                |
    | project_dir is required when the  | The repository root cannot   | Pass project_dir              |
    | workflow is not inside            | be inferred                  |                               |
    | .github/workflows                 |                              |                               |
    | Project directory 'D' does not    | No directory at the path     | Check the path                |
    | exist                             |                              |                               |
    | Invalid arguments to              | An unknown option, or one of | Use the documented options    |
    | App::Actions::new: REASON         | the wrong type               |                               |
    | Object::Configure: config_path    | A configuration file or      | Remove the ".." from that     |
    | contains path traversal           | variable names a path with   | setting                       |
    | sequences: PATH                   | ".." in it                   |                               |
    | Warning: Can't load configuration | A configuration file has a   | Fix the file; the run goes on |
    | from FILE: DETAIL (a warning)     | syntax error                 | without it                    |
    +-----------------------------------+------------------------------+-------------------------------+
```

The messages of ["load" in App::Actions::Workflow](https://metacpan.org/pod/App%3A%3AActions%3A%3AWorkflow#load) apply to the workflow file.

#### Pseudocode

```perl
    validate the arguments, refusing unknown options
    make the logger argument into a logger, or use the default (standard error)
    merge in the App__Actions section of the configuration files, then the
        App__Actions__* environment variables (both win; neither is validated)
    put back the logger made from the argument, or make the configured one
        into a logger ('NULL' is a silent one)
    refuse a missing workflow_file, then one that does not exist
    take project_dir as given, or the repository root that holds .github/workflows
    refuse a project directory that does not exist
    load the workflow
    return the object holding the paths, the workflow and the options
```

### Workflow, Workflow\_File, Project\_Dir

```perl
    my $workflow = $actions->workflow;         # the App::Actions::Workflow
    my $file     = $actions->workflow_file;    # its absolute path
    my $root     = $actions->project_dir;      # the absolute project directory
```

Read-only accessors.

#### Api Specification

##### Input

```
    {}
```

##### Output

```perl
    workflow:                   { type => 'object', isa => 'App::Actions::Workflow' }
    workflow_file, project_dir: { type => 'string' }
```

#### Messages

None.

#### Example

```
    printf "%s from %s\n", $actions->workflow->name, $actions->project_dir;
```

### Run

Runs the selected jobs.

#### Arguments

Any of the run options of ["new"](#new), which override the object's for this run
only.

#### Returns

0 for success, 1 when a job fails, and 2 for a usage, Docker, or other
infrastructure error.

#### Side Effects

Starts and removes Docker containers and networks, pulls images, writes the
image cache record and, for a parallel run, the job logs; prints the run's
progress unless `quiet`.

#### Example

```perl
    my $exit = $actions->run(jobs => [ 'lint' ], verbose => 1);
    exit $exit;
```

#### Api Specification

##### Input

The option rules of ["new"](#new), all optional, without `workflow_file` and
`project_dir`.

##### Output

```perl
    { type => 'integer', memberof => [ 0, 1, 2 ] }
```

#### Messages

```
    +--------------------------+-------------------------------+--------------------------------+
    | Message                  | Meaning                       | Resolution                     |
    +--------------------------+-------------------------------+--------------------------------+
    | Invalid arguments to     | An unknown or mistyped        | Use the options of new         |
    | App::Actions::run: R     | override                      |                                |
    +--------------------------+-------------------------------+--------------------------------+
```

Failures of the run itself are printed by [App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner) and
reported by the exit code rather than raised.

### Preflight

Makes the same checks as a run before its first job, then prepares the
images the selected jobs need, without starting anything.

#### Arguments

- `json` - optional; true to print nothing and return the document
`action-run preflight --json` prints.
- `schema_line` - optional; passed to the runner.
- Any run option of ["new"](#new), overriding the object's.

#### Returns

A hash of `exit` (0 or 2), `summary` and `error`.  `summary` is the report
[App::Actions::Check](https://metacpan.org/pod/App%3A%3AActions%3A%3ACheck) produces as data, with an `images` array added; each
entry is `{ image, source, status, error }`, and `status` is `pulled`,
`present`, `failed`, `skipped` or `deferred`.  A deferred entry could not
be named from the values available before the run, because a job has not
produced it yet; it carries `expression` instead of `image`, and the job
prepares it with its own values before it starts.  `summary` also carries
`schema_version`, which is
["preflight\_schema\_version" in App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner#preflight_schema_version); the schema and the
checked-in examples in `t/fixtures/` are validated in `t/schema.t`, which
also fails when a key, an enum value or a null variant the schema names
appears in none of them.  With `json => 1` nothing is
printed, so the caller's output can be a single document; `ready` is then a
JSON boolean and the summary is the document `action-run preflight --json`
prints, already validated against that schema, so a mismatch dies with an
[App::Actions::Schema::Invalid](https://metacpan.org/pod/App%3A%3AActions%3A%3ASchema%3A%3AInvalid)
exception naming the first key at fault rather than being returned; the
command gives that exit 70.

#### Side Effects

Contacts the Docker daemon, starts a probe container and pulls images.

#### Example

```perl
    my $result = $actions->preflight(json => 1);
    print JSON::PP->new->canonical->encode($result->{summary}), "\n";
    exit $result->{exit};
```

#### Api Specification

##### Input

The option rules of ["new"](#new), all optional, plus

```perl
    {
            json        => { type => 'string', optional => 1 },
            schema_line => { type => 'string', optional => 1 },
    }
```

##### Output

```perl
    { type => 'hashref' }    # { exit => 0|2, summary => {...}, error => string|undef }
```

#### Messages

```
    +--------------------------+-------------------------------+--------------------------------+
    | Message                  | Meaning                       | Resolution                     |
    +--------------------------+-------------------------------+--------------------------------+
    | Invalid arguments to     | An unknown or mistyped option | Use the options of new         |
    | App::Actions::preflight  |                               |                                |
    | the action-run preflight | The document drifted from its | A bug in this distribution;    |
    | --json document does not | schema (an                    | report it                      |
    | match ...                | App::Actions::Schema::Invalid)|                                |
    +--------------------------+-------------------------------+--------------------------------+
```

### Json\_Schema

Returns the JSON schema of one of the machine-readable documents.

#### Arguments

- `$name` - `check`, `preflight`, `cache` or `logs`.

#### Returns

The schema as a hash reference, which is what `action-run schema` prints.
The schemas live in [App::Actions::Check](https://metacpan.org/pod/App%3A%3AActions%3A%3ACheck), [App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner),
[App::Actions::Cache](https://metacpan.org/pod/App%3A%3AActions%3A%3ACache) and [App::Actions::Logs](https://metacpan.org/pod/App%3A%3AActions%3A%3ALogs), so the contract is
available from an installed distribution.

#### Example

```perl
    my $schema = App::Actions->json_schema('check');
    print $schema->{title}, "\n";    # action-run check --json
```

#### Api Specification

##### Input

```perl
    { name => { type => 'string', optional => 1 } }
```

##### Output

```perl
    { type => 'hashref' }
```

#### Messages

```
    +--------------------------+-------------------------------+--------------------------------+
    | Message                  | Meaning                       | Resolution                     |
    +--------------------------+-------------------------------+--------------------------------+
    | A document name is       | The name was undef or empty   | Pass check, preflight, cache   |
    | required                 |                               | or logs                        |
    | Unknown document 'N';    | No such document              | Use one of the names listed    |
    | expected check,          |                               |                                |
    | preflight, cache or logs |                               |                                |
    +--------------------------+-------------------------------+--------------------------------+
```

### List\_Jobs

Prints one line per expanded job: its id, a tab, and its display name.

#### Arguments

Any of the run options of ["new"](#new).  `dry_run` and `quiet` are always set,
because listing starts nothing and prints only the list.

#### Returns

0.

#### Side Effects

Prints to standard output.

#### Example

```perl
    $actions->list_jobs(jobs => [ 'test' ]);
    # test  test (perl=5.38)
    # test  test (perl=5.40)
```

#### Api Specification

##### Input

The option rules of ["new"](#new), all optional.

##### Output

```perl
    { type => 'integer', memberof => [ 0 ] }
```

#### Messages

```
    +--------------------------+-------------------------------+--------------------------------+
    | Message                  | Meaning                       | Resolution                     |
    +--------------------------+-------------------------------+--------------------------------+
    | Invalid arguments to     | An unknown or mistyped        | Use the options of new         |
    | App::Actions::list_jobs  | override                      |                                |
    +--------------------------+-------------------------------+--------------------------------+
```

## Testing

The suite runs against a fake Docker command, so it needs neither Docker nor
a daemon:

```
    prove -l t
```

One of its tests copies the suite into a temporary directory whose name
contains spaces and runs every test file there again, which is how paths with
spaces are covered on every platform.  The copy is made from `MANIFEST`, so it
holds exactly what the distribution ships and a test that reads a new file
finds it there as soon as that file is listed.  That doubles the running time;
set `SPACE_PATH=0` to skip it, or run just that check with
`prove -l t/space-path.t`.  It is skipped when `AUTOMATED_TESTING` is set
(continuous integration, CPAN testers) unless `SPACE_PATH` is set to a true
value.

`t/locales.t` covers the message catalogue: the country-to-language table
for GB, US, FR, DE and CN, and the error paths under the `en_US.UTF-8`,
`de_DE.UTF-8` and `ja_JP.UTF-8` POSIX locales.

The repository ships a pre-commit hook in `.githooks/` that runs the schema
checks and the live-knob check against the files a commit stages, so a version
bump applied to the schema or to the documents but not to both, or a live
test's knob added without its documentation or whitelist, is refused where it
happens rather than by CI afterwards.  Each check starts only when a staged
path can affect it.  It is off until a clone asks for it:

```
    git config core.hooksPath .githooks
```

A commit that touches nothing either check reads passes without a check being
run at all, and `git commit --no-verify` skips it for one commit.

The same checks can be run from the command line without attempting a commit:

```
    make check-staged    # against the index
    make check-worktree  # against the working tree, unstaged edits included
```

`check-worktree` always runs both checks, including files that are not tracked
yet, so a new fixture or live test is not skipped.  Both targets need the
`Makefile` that `perl Makefile.PL` writes.

The tests that need a real Docker daemon sit behind one switch,
`LIVE_TESTING`: `make test LIVE_TESTING=1` runs them all.  `t/real-docker.t`
runs one small workflow end to end with `action-run check` and the smoke
script, `t/real-docker-preflight.t` the preflight including an image that
cannot be pulled, and `t/self_test.t` the command a user runs -
`bin/action-run t/lib/self_test.yml .` - in a real container rather than the
fake one it uses by default.  One of them on its own is `LIVE_TESTING=1
prove -l t/real-docker.t`.

The _Live Docker_ workflow sets the switch and runs `t/self_test.t` on every
push, so the command a user runs is exercised on a daemon in CI rather than
only on a machine that has one.  The two daemon-specific files stay where a
particular daemon is the point: a local `LIVE_TESTING=1` run, and the
_Real Docker on Windows_ workflow.

The fake Docker executes step scripts with the host's shell, mapping the paths
`docker exec` was given back to the host, so a step's output and the files it
writes to `GITHUB_ENV` and `GITHUB_OUTPUT` are exercised without a daemon.
It runs the command of a `docker://` action the same way, so what a one-shot
container prints, and the status it exits with, are what the run sees.

The self test runs two workflows the distribution ships: the one above, which
proves the command surface, and `t/lib/self_test_cli.yml`, which runs
`action-run schema` and `action-run validate` inside a Perl image for every
check and preflight document and every cache and logs fixture, including the
unready, unreachable, uncounted, empty and prune examples, so the tool is
exercised where it is being tested rather than only from the checkout that
started it.  All four sets are discovered from `t/fixtures/check*.json`,
`t/fixtures/preflight*.json`, `t/fixtures/cache*.json` and
`t/fixtures/logs*.json` rather than listed by name, so a new one is validated
without editing the workflow.  That image gets
the tool's dependencies only when it does not have them, so the fake run
stays off the network.  It is named by digest rather than by the
`perl:5.38` tag, so the live job pulls the same image every time instead of
whatever that tag points at on the day it runs.  The test says which half it
ran: with `LIVE_TESTING=1` it reports that the workflow is in a real
container, and without it that the steps ran against the fake and the
container path was not exercised.

The live tests read two variables and both carry the `LIVE_TESTING`
prefix, so there is one name to remember: `LIVE_TESTING` turns them on and
`LIVE_TESTING_IMAGE` names the image they start, `alpine:3.20` by default.
`DOCKER` overrides the Docker command.  The daemon must run Linux containers.
`t/live-knobs.t` holds the tests, the documentation and the workflow to that
prefix, so a rename that misses one of them fails the ordinary suite.
The same ground is covered by `action-run-smoke`, which does not need `prove`
and reports the environment before it runs anything; use it when Docker, not
the code, is in doubt.  On Windows it is the check to run against Docker
Desktop, whose Linux engine `action-run-smoke` verifies before it starts a
container.

The opt-in _Real Docker on Windows_ workflow runs the same test on a Windows
host.  Dispatch it on a self-hosted Windows runner with Docker Desktop, or set
the `docker_host` input to a Linux daemon.  GitHub-hosted Windows runners
only run Windows containers, so the job stops there with an explanation.

## Limitations

Only Linux runners can be emulated.  Windows and macOS jobs are skipped.
Local composite and JavaScript actions are run; remote actions and local
`docker` actions cannot be run.  Checkout, setup-perl, cache, artifact, and
Codecov actions are treated as no-ops.  Use `strict_actions` to turn unknown
actions into failures instead of skips.  JavaScript actions need `node` in
the job image.  Job outputs, `needs.*.outputs`, and `timeout-minutes` are
not implemented.

Images are pulled concurrently only where `fork()` is reliable; on Windows
they are pulled one at a time, because Perl's emulation of `fork()` shares the
parent's handles with the child.

Design weaknesses that remain:

- [App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner) plans the run and hands the work to five
parts (images, containers, steps, parallel jobs and the report), each in its
own module under `App/Actions/Runner/`.  The parts are built from copies of
the runner's options rather than given the runner, so they can be tested
alone, but a change to an option after construction is not seen by them, and
the planner is still the largest of them.
- Errors raised through the catalogue are [App::Actions::Error](https://metacpan.org/pod/App%3A%3AActions%3A%3AError)
objects carrying the message key as a stable code, and `bin/action-run`
asks for the code rather than matching the text.  The errors of
[App::Actions::Check](https://metacpan.org/pod/App%3A%3AActions%3A%3ACheck), [App::Actions::Docker](https://metacpan.org/pod/App%3A%3AActions%3A%3ADocker), [App::Actions::Expression](https://metacpan.org/pod/App%3A%3AActions%3A%3AExpression),
[App::Actions::Process](https://metacpan.org/pod/App%3A%3AActions%3A%3AProcess), [App::Actions::Cache](https://metacpan.org/pod/App%3A%3AActions%3A%3ACache) and [App::Actions::Logs](https://metacpan.org/pod/App%3A%3AActions%3A%3ALogs) are
still strings.
- The option rules are one table, the runner's (see
["option\_rules" in App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner#option_rules)), but the options are still checked
twice: here, where the caller passes them, and in the runner, which is a
public class and so checks its own arguments.  The cost is a second pass
over a dozen keys per call.
- Unknown options are now an error.  A caller that passed an option
this module never forwarded (and which therefore had no effect) will now be
told so.
- The Check, Docker, Expression, Process and command-line messages
have not been moved into the catalogue yet; see
["LIMITATIONS" in App::Actions::I18N](https://metacpan.org/pod/App%3A%3AActions%3A%3AI18N#LIMITATIONS).
- Settings from configuration files and `App__Actions__*` environment
variables are merged in by [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) after ["new"](#new) has checked its
arguments, so they are not checked: `App__Actions__parallel=banana` is
accepted.  They also win over the arguments, which is the reverse of what
most programs do, and a caller cannot choose a configuration file.
- Not everything a run prints goes through the logger.  The progress
lines, the command echoes and the summary are output and stay on standard
output.  [App::Actions::I18N](https://metacpan.org/pod/App%3A%3AActions%3A%3AI18N) warns about a missing catalogue entry with
`carp`, because it has no object to hold a logger.  A pulling child of
[App::Actions::Process](https://metacpan.org/pod/App%3A%3AActions%3A%3AProcess) prints straight to the log file it was given, since
it is a separate process whose output is already captured.

## Common Pitfalls

- **Docker must be running, and able to see your project.**  Run
`action-run check` first if a run fails before any job starts.
- **Only Linux jobs run.**  Jobs with `runs-on: macos-*` or
`windows-*` are skipped, not failed.
- **Remote actions are not downloaded.**  `actions/checkout`,
setup-perl and a few others are treated as no-ops (your project is already
mounted).  Other remote actions are skipped with a warning; set
`strict_actions` to make them fail instead.
- **Secrets must be passed in.**  Nothing is read from GitHub.  Pass
`secrets => { NAME => value }` (or `--secret` on the command
line).  Missing secrets are empty, as on GitHub for a fork.
- **Images are kept.**  The images a run downloads stay, to make the
next run faster.  Set `keep_images => 0`, or use `action-run cache
--prune`, to remove them.
- **`run` returns a status; it does not die for a failed job.**
Check the number: 0, 1 or 2.
- **Unknown options are errors.**  A misspelt option name (`job` for
`jobs`) stops with `Invalid arguments to App::Actions::new`.
- **Run as yourself or root.**  With `user` set to another user, the
job's files (secrets included) must be readable by every user of the
computer, and a warning says so.
- **Only run workflows you trust.**  A workflow can mount any folder
of your computer into its containers, as it can on GitHub's own runners.
- **Parallel jobs write to log files, not the terminal.**  With
`parallel` above 1, read the output with `action-run logs`.
- **A configuration file or environment variable beats an argument.**
If `~/.conf/local.yaml` has an `App__Actions` section with `parallel: 8`,
then `parallel => 2` (and `action-run --parallel=2`) still runs eight
jobs at a time.  When an option seems to be ignored, look for an
`App__Actions` section in those files and for `App__Actions__*`
environment variables (`env | grep App__Actions`).
- **Values from those places are not checked.**  A misspelt or
nonsensical value there is not reported as an argument would be.
- **A UNIVERSAL logger takes the messages off the terminal.**
[Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) applies a `UNIVERSAL` section of `universal.yaml` to
every class that uses it, this one included.  If that section has a
`logger` that writes to a file or to syslog, a failed step is reported
there and not on standard error.  Give this module its own `logger` in an
`App__Actions` section, or pass `logger`, to choose where its messages go.

## Encoding

Workflow and action files are read as UTF-8.  Their names, commands and
values may contain any Unicode text, including non-ASCII characters and
emoji.  File and folder names are used as bytes, as your system stores
them.  Commands, environment variables and secrets are passed to Docker as
bytes (UTF-8 for text from the workflow).  What the containers print is
passed through to your terminal unchanged.  Messages from this module are
in English unless `ACTION_RUN_LANG` chooses French (`fr`), German
(`de`) or Chinese (`zh`); those are character strings, so the terminal
should use UTF-8.  Settings in configuration files and `App__Actions__*`
environment variables are used as [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction) reads them; keep
option values there in ASCII.

## See Also

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure), which ["new"](#new)
uses to read configuration files and environment variables
- [Config::Abstraction](https://metacpan.org/pod/Config%3A%3AAbstraction), which finds and reads those files
- [Test Dashboard](https://nigelhorne.github.io/App-Actions/coverage/)

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## Formal Specification

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.  It is for readers who want to check exactly what a routine
promises.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in `?` is an input, and a
name ending in `!` is an output.  `ΞState` means the routine changes
nothing, and `ΔState` means it can change the state.  The lines below the
rule are the conditions that are always true when the routine returns.

### New

```
    ┌─ New ─────────────────────────────────────────────
    │ ΞFileSystem
    │ workflowFile? : optional PATH
    │ projectDir?   : optional PATH
    │ options?      : OPTION ⇸ VALUE
    │ actions!      : Actions
    ├───────────────────────────────────────────────────
    │ dom options? ⊆ RUNNER_OPTIONS
    │ let settings == (args? ⊕ fileConfig(App__Actions)) ⊕ envConfig(App__Actions__)
    │     where args? == options? ∪ {workflow_file ↦ workflowFile?, project_dir ↦ projectDir?}
    │     -- dom fileConfig and dom envConfig are not checked against RUNNER_OPTIONS
    │ workflowFile? = ⊥ ⇒ raises WorkflowFileRequired
    │ abs(workflowFile?) ∉ regularFiles ⇒ raises WorkflowFileMissing
    │ projectDir? = ⊥ ∧ abs(workflowFile?) ∉ (PATH ⁀ "/.github/workflows/" ⁀ NAME)
    │     ⇒ raises ProjectDirRequired
    │ let root == (projectDir? ≠ ⊥ ⇒ abs(projectDir?))
    │             ∧ (projectDir? = ⊥ ⇒ repository(abs(workflowFile?)))
    │ root ∉ directories ⇒ raises ProjectDirMissing
    │ actions!.workflow = Workflow.Load(abs(workflowFile?))
    │ actions!.project_dir = root
    │ actions!.options = settings
    │ let logged == (logger? ≠ ⊥ ⇒ logger?)
    │             ∧ (logger? = ⊥ ∧ logger ∈ dom configured ⇒ configured(logger))
    │             ∧ (logger? = ⊥ ∧ logger ∉ dom configured ⇒ stderrLogger)
    │     where configured == fileConfig(App__Actions) ⊕ envConfig(App__Actions__)
    │     -- fileConfig includes the UNIVERSAL section of universal.yaml
    │ actions!.logger ∈ LogAbstraction
    │ logged = NULL ⇒ actions!.logger = silentLogger
    │ logged ≠ NULL ⇒ actions!.logger = toLogger(logged)
    └───────────────────────────────────────────────────

    The workflowFile? and projectDir? above are the values in settings, so a
    configuration file or environment variable can replace them too.
```

### Workflow, Workflow\_File, Project\_Dir

```
    ┌─ Accessor ────────────────────────────────────────
    │ ΞActions
    │ field? : {workflow, workflow_file, project_dir}
    │ value! : VALUE
    ├───────────────────────────────────────────────────
    │ value! = θActions.field?
    └───────────────────────────────────────────────────
```

### Run

```
    ┌─ Run ─────────────────────────────────────────────
    │ ΞActions
    │ overrides? : OPTION ⇸ VALUE
    │ exit!      : {0, 1, 2}
    ├───────────────────────────────────────────────────
    │ dom overrides? ⊆ RUNNER_OPTIONS
    │ exit! = Runner.Run(options ⊕ overrides?)
    └───────────────────────────────────────────────────
```

### Preflight

```
    ┌─ Preflight ───────────────────────────────────────
    │ ΞActions
    │ overrides? : OPTION ⇸ VALUE
    │ json?      : optional BOOLEAN
    │ result!    : Result
    ├───────────────────────────────────────────────────
    │ dom overrides? ⊆ RUNNER_OPTIONS
    │ result! = Runner.Preflight(options ⊕ overrides?, json?)
    │ result!.exit ∈ {0, 2}
    │ json? ⇒ valid(result!.summary, PreflightSchema)
    └───────────────────────────────────────────────────
```

### Json\_Schema

```
    DOCUMENT ::= check | preflight | cache | logs

    ┌─ JsonSchema ──────────────────────────────────────
    │ name?   : optional STRING
    │ schema! : KEY ⇸ VALUE
    ├───────────────────────────────────────────────────
    │ name? ∈ {⊥, ⟨⟩} ⇒ raises DocumentRequired
    │ name? ∉ DOCUMENT ⇒ raises DocumentUnknown(name?)
    │ name? ∈ DOCUMENT ⇒ schema! = owner(name?).json_schema
    └───────────────────────────────────────────────────
```

### List\_Jobs

```
    ┌─ ListJobs ────────────────────────────────────────
    │ ΞActions
    │ overrides? : OPTION ⇸ VALUE
    │ exit!      : {0}
    ├───────────────────────────────────────────────────
    │ output' = output ⁀ ⟨ j : selected(jobs ⊕ overrides?) • j.base_id ⁀ TAB ⁀ j.display_name ⟩
    │ exit! = 0
    └───────────────────────────────────────────────────
```

## State Diagram

An App::Actions object only holds options; each call to ["run"](#run),
["preflight"](#preflight) or ["list\_jobs"](#list_jobs) builds a new [App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner) and goes
through these states (the full detail of each is in [App::Actions::Runner](https://metacpan.org/pod/App%3A%3AActions%3A%3ARunner)
and its parts):

```
     new(%options)
          |   options checked; then App__Actions settings from configuration
          |   files and App__Actions__* environment variables merged over
          |   them (not checked); workflow loaded (errors are thrown here)
          v
    +-------------+
    |   READY     |<------------------------------------------------------+
    +-------------+                                                       |
       |       |  list_jobs: print "id<TAB>display name" per job; return 0 |
       |       +-------------------------------------------------------->-+
       |
       | run(%overrides) / preflight(%overrides)
       v
    +----------------+  daemon unreachable, not Linux containers,
    | CHECK DOCKER   |  project not mountable -> print report; status 2
    | (skip_check:   |---------------------------------------------------+
    |  skipped)      |                                                   |
    +----------------+                                                   |
       |                                                                 |
       v                                                                 |
    +----------------+  an image cannot be pulled -> status 2            |
    | PREPARE IMAGES |------------------------------------------------->-+
    | (pull missing, |                                                   |
    |  N at a time)  |  preflight stops here: return { exit, summary }   |
    +----------------+------------------------------------------------->-+
       |                                                                 |
       | for each selected job (matrix expanded; non-Linux skipped;      |
       | up to "parallel" at a time)                                     |
       v                                                                 |
    +----------------+  network, services, job container                 |
    | START JOB      |  (a service that stops -> job fails)              |
    +----------------+                                                   |
       |                                                                 |
       v                                                                 |
    +----------------+  each step: if: condition -> docker exec;         |
    | RUN STEPS      |  GITHUB_ENV / PATH / OUTPUT / STATE honoured;     |
    |                |  a failed step fails the job (later steps run     |
    |                |  only with if: failure() / always())              |
    +----------------+                                                   |
       |                                                                 |
       v                                                                 |
    +----------------+  containers and network removed (unless keep);    |
    | CLEAN UP JOB   |  images kept unless keep_images is false          |
    +----------------+                                                   |
       |                                                                 |
       v                                                                 |
    +----------------+  status 0 = every job passed, 1 = a job failed    |
    | REPORT         |------------------------------------------------->-+
    +----------------+                     returns the status
```

## License and Copyright

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the `LICENSE` file that comes with this distribution.
If you use it, please let me know.

# NAME

App::Project::Doctor - Unified pre-release health check for Perl CPAN distributions

# VERSION

0.02

# SYNOPSIS

    # Command line
    project-doctor [--check=Tests,CI] [--skip=Meta] [--fix] [PATH]

    # Programmatic
    use App::Project::Doctor;

    my $doctor = App::Project::Doctor->new(path => '/path/to/my-dist');
    my $report = $doctor->run;
    print $report->render_text;
    exit $report->exit_code;

# DESCRIPTION

Orchestrates a suite of diagnostic checks against a Perl CPAN distribution,
combining [App::Workflow::Lint](https://metacpan.org/pod/App%3A%3AWorkflow%3A%3ALint), [App::GHGen::Generator](https://metacpan.org/pod/App%3A%3AGHGen%3A%3AGenerator), [App::makefilepl2cpanfile](https://metacpan.org/pod/App%3A%3Amakefilepl2cpanfile)
into a single interactive pre-upload tool.

Each enabled `App::Project::Doctor::Check::*` plugin receives an
[App::Project::Doctor::Context](https://metacpan.org/pod/App%3A%3AProject%3A%3ADoctor%3A%3AContext) and returns a list of
[App::Project::Doctor::Finding](https://metacpan.org/pod/App%3A%3AProject%3A%3ADoctor%3A%3AFinding) objects which are collected into an
[App::Project::Doctor::Report](https://metacpan.org/pod/App%3A%3AProject%3A%3ADoctor%3A%3AReport).

# CONSTRUCTOR

## new( %args )

### API SPECIFICATION

#### Input

    path    : String    -- start path for root detection    default '.'
    checks  : ArrayRef  -- check name suffixes to run       default all
    skip    : ArrayRef  -- check names to exclude           default []
    verbose : Bool                                          default 0

#### Output

Blessed hashref of type `App::Project::Doctor`.

# ACCESSORS

`path`, `checks`, `skip`, `verbose` -- read-only.

# METHODS

## run

### API SPECIFICATION

#### Input

None.

#### Output

[App::Project::Doctor::Report](https://metacpan.org/pod/App%3A%3AProject%3A%3ADoctor%3A%3AReport).

### MESSAGES

    Code | Trigger                         | Resolution
    -----|----------------------------------|----------------------------------------
    DR01 | Cannot detect distribution root  | Run from within a distribution directory
    DR02 | A check class cannot be loaded   | Install the check's prerequisites

# CHECKS

In default execution order:

    Tests           t/ exists, .t files present, prove passes
    CI              At least one CI configuration present
    GitHubActions   Workflow YAML validates via App::Workflow::Lint
    Meta            META.yml/json parsed and complete
    Pod             All .pm files have valid POD
    Dependencies    Used modules declared as prerequisites
    License         LICENSE file present and consistent with META
    Security        strict/warnings everywhere; no hardcoded secrets
    CpanReadiness   Version format, Changes, MANIFEST, README

## run

Detects the distro root, instantiates all enabled checks, runs them in order,
and returns an [App::Project::Doctor::Report](https://metacpan.org/pod/App%3A%3AProject%3A%3ADoctor%3A%3AReport).

# LIMITATIONS

Checks run sequentially; no parallelism.

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# SEE ALSO

- [Configure an Object at Runtime](https://metacpan.org/pod/Object%3A%3AConfigure)
- [Test Dashboard](https://nigelhorne.github.io/App-Project-Doctor/coverage/)

# REPOSITORY

[https://github.com/nigelhorne/App-Project-Doctor](https://github.com/nigelhorne/App-Project-Doctor)

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-cgi-info at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Project-Doctor](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Project-Doctor).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc App::Project::Doctor

You can also look for information at:

- MetaCPAN

    [https://metacpan.org/dist/App-Project-Doctor](https://metacpan.org/dist/App-Project-Doctor)

- RT: CPAN's request tracker

    [https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Project-Doctor](https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Project-Doctor)

- CPAN Testers' Matrix

    [http://matrix.cpantesters.org/?dist=App-Project-Doctor](http://matrix.cpantesters.org/?dist=App-Project-Doctor)

- CPAN Testers Dependencies

    [http://deps.cpantesters.org/?module=App::Project::Doctor](http://deps.cpantesters.org/?module=App::Project::Doctor)

# FORMAL SPECIFICATION

## doctor

    Doctor == { path : Path, checks : [Name], skip : [Name], verbose : Bool }

    run : Doctor -> Report
    run d ==
      let root    = detect_root (path d)
          ctx     = Context { root, verbose = verbose d }
          enabled = sort_by_order (checks d \\ skip d)
      in  Report { concat [ check c ctx | c <- enabled ] }

    detect_root : Path -> Path | undefined
    detect_root p == nearest ancestor of p containing a ROOT_MARKER

# LICENSE

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

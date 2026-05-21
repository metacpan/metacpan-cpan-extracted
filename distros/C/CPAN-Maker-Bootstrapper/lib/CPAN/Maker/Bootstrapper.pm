package CPAN::Maker::Bootstrapper;

use strict;
use warnings;

use CLI::Simple qw(:roles);
use parent qw(CLI::Simple);

our $VERSION = '2.0.2';

use Role::Tiny::With;
with 'CPAN::Maker::Bootstrapper::Role::Init';

__PACKAGE__->use_log4perl( level => 'info' );

caller or exit __PACKAGE__->main;

1;

=pod

=encoding utf8

=head1 NAME

CPAN::Maker::Bootstrapper - Scaffold a new CPAN distribution in one command

=head1 SYNOPSIS

  # Create a configuration file (recommended first-time setup)
  cpan-maker-bootstrapper create-config > ~/.cpan-makerrc
  export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

  # Create a new plain Perl module project
  cpan-maker-bootstrapper --module  My::New::Module

  # Create a CLI module project (inherits from CLI::Simple)
  cpan-maker-bootstrapper --module My::New::CLI --stub cli

  # Use a custom stub
  cpan-maker-bootstrapper --module My::Module --stub /path/to/mystub.pm

  # Import files from another project
  cpan-maker-bootstrapper --module My::Module \
   -I /path/to/my-module/lib -I /path/to/my-module/bin \
   --installdir /tmp/My-Module

  # Install into a specific directory
  cpan-maker-bootstrapper --module My::Module --installdir ~/git

  # Override git identity
  cpan-maker-bootstrapper --module My::Module --username "Rob Lauer" --email rob@example.org

  # Run a code review on a module (set API key in environment)
  export LLM_API_KEY=$(cat ~/.ssh/anthropic-api-key)
  cpan-maker-bootstrapper code-review lib/My/Module.pm    

=head1 DESCRIPTION

L<https://github.com/rlauer6/CPAN-Maker-Bootstrapper/actions/workflows/build.yml>

L<CPAN::Maker::Bootstrapper> scaffolds a new CPAN distribution directory
ready to build immediately. It installs a project Makefile, a
C<buildspec.yml> pre-populated from your git config, stub source and test
files, and supporting makefiles - then runs C<make> to generate the initial
artifacts.

The result is a project that can produce a distributable tarball with a
single additional C<make> invocation, with no manual editing required for
a standard project layout.

L<CPAN::Maker::Bootstrapper> also provides AI-assisted development
tools via the Anthropic Claude API. These include iterative code
review with structured finding annotations, POD documentation review
with B<generation>, and AI-generated release notes. See L</LLM
Commands> and L</THE REVIEW WORKFLOW> for details regarding how to use
the AI tools for enhancing your code review process.

=head1 QUICK START

Install the bootstrapper and its dependencies:

 cpanm CPAN::Maker CPAN::Maker::Bootstrapper

I<Note: Before scaffolding your first project, consider running C<create-config>
to set up a personal configuration file - it pre-populates your git
identity, GitHub username, and preferred project directory so you never
have to pass them on the command line. See L</CONFIGURATION> for details.>

Scaffold a new project:

 cpan-maker-bootstrapper --module My::Module --installdir ~/git/My-Module

The bootstrapper creates the project directory, installs the build
system, generates stub source and test files, and runs C<make>
automatically. By the time it finishes you already have a working
distribution tarball in F<~/git/My-Module>.

 cd ~/git/My-Module

Review the generated files - particularly F<buildspec.yml> which
controls how the distribution is built, and F<requires> and
F<test-requires> which list your module's dependencies. Your git
identity is pre-populated from F<~/.gitconfig> but you may want to
adjust the description or resource URLs.

Edit the generated stub in F<lib/My/Module.pm.in>. This is your
primary source file - never edit the generated F<.pm> file directly
as it will be overwritten on the next C<make>.

As your project grows, add new modules to F<lib/> and scripts to
F<bin/> as F<.pm.in> and F<.pl.in> files respectively. The build
system discovers them automatically - no changes to the Makefile
required. Add new test files to F<t/> as F<.t> files.

When you are ready to build:

 make

This scans your source files for dependencies, regenerates F<requires>
and F<test-requires>, generates F<README.md> from your POD, and
produces a distributable tarball.

To verify your distribution installs cleanly:

 cpanm --local-lib=$HOME My-Module-*.tar.gz

To initialize version control and make your first commit:

 make git

See L</EXTENDING THE BUILD SYSTEM> for customizing the build,
dependency management details. See L</FAQ> for common
questions and recipes.

=head1 WHY YOU SHOULD CONSIDER USING YET ANOTHER BUILD TOOL

If you have ever reached for Jenkins, GitHub Actions, CircleCI, or a
sprawling shell script to automate your Perl builds, consider what
those tools actually require: a server or cloud account, a proprietary
YAML DSL, plugin ecosystems with their own release cycles, containers,
agents, and configuration files that only run in one specific
environment.

The C<CPAN::Maker> build system runs everywhere Perl runs - your
laptop, a remote EC2 instance, a colleague's workstation - with no
setup beyond C<cpanm CPAN::Maker::Bootstrapper>. C<git clone && make>
is always sufficient to build a fresh checkout.

=head2 The Stack

The build system is built on three tools that have been solving these
problems correctly for decades:

=over 4

=item * B<GNU make> - dependency tracking, incremental builds, the
target/prerequisite model is still the clearest expression of I<build
this from that>. A Makefile from 1990 still runs today.

=item * B<bash> - process orchestration, file manipulation,
conditionals, the Unix toolkit. Available on every system you will
ever deploy to.

=item * B<Perl> - text processing, CPAN ecosystem access, JSON, YAML,
HTTP - anything complex enough to warrant a real language, right there
in your build recipes without shelling out to another runtime.

=back

Together they give you a complete, auditable, version-controlled build
system that is trivially debuggable with C<make -n> and C<bash -x>,
self-documents via C<make help>, and needs no external services to run.

=head2 Best Practices Out of the Box

The installed build system encourages professional Perl development
habits from the start:

=over 4

=item * B<Source files are clearly separated> - generated C<.pm> and
C<.pl> files live alongside their C<.pm.in> and C<.pl.in> sources.
The build system always regenerates the C<.pm> from the C<.pm.in> on
change, making it clear which file you own. Never edit the generated
file directly - your changes will be overwritten on the next C<make>.

=item * B<Dependencies are tracked automatically> - C<scandeps-static.pl>
scans your source files on every build, keeping F<requires> and
F<test-requires> current. You stay in control via pinning, sticky
entries, and skip lists.

=item * B<Quality gates are built in> - C<perl -wc> syntax checking,
C<perltidy>, and C<perlcritic> run automatically on every build,
stopping bad code before it enters the distribution. Gates can be
selectively disabled via your configuration file or on the command
line (C<make LINT=off>) when you need a faster build during
development.

=item * B<The build system upgrades itself> - C<make update> refreshes
managed build files from the installed bootstrapper; C<make upgrade>
checks MetaCPAN and upgrades the bootstrapper itself.

=item * B<Extension without modification> - F<project.mk> is your
upgrade-safe extension point. Add custom targets, inter-module
dependencies, and project-specific variables there. The managed
F<Makefile> is never modified directly.

=back

=head2 Perl Quality Tools

The build system supports optional Perl quality gates controlled via
your configuration file. Set the following keys in the C<[cpan-maker]>
section:

 syntax-checking = on          # enables perl -wc on generated files
 perltidyrc = ~/.perltidyrc    # enables perltidy stage gate
 perlcriticrc = ~/.perlcriticrc # enables perlcritic stage gate

These can be overridden per-run from the command line:

 make SYNTAX_CHECKING=off      # disable syntax checking
 make PERLTIDYRC=""            # disable tidy gate
 make PERLCRITICRC=""          # disable critic gate

Add modules that cannot be syntax-checked outside their runtime
environment to C<PERLWC_SKIP> in F<project.mk>:

 PERLWC_SKIP = bin/startup.pl

Add inter-module build dependencies to F<project.mk> when modules
depend on each other at build time:

 lib/Foo/Bar.pm: lib/Foo.pm

To disable all linting at once:

 make LINT=off

Or use C<make quick> to disable both scanning and linting in one step.

=head2 A GNU Make Tutorial in Disguise

The F<.includes/> directory is also a practical demonstration of
advanced GNU make techniques that most developers never encounter -
working, production-tested examples you can learn from and adapt:

=over 4

=item * Pattern rules and sentinel files for incremental quality gates

=item * C<define>/C<endef> snippets - reusable shell and Perl code
blocks exported as make variables, eliminating duplication across
recipes

=item * C<$(shell ...)>, C<$(eval ...)>, C<$(call ...)>,
C<$(filter-out ...)>, C<$(addprefix ...)>, C<$(patsubst ...)> - the
full make function toolkit in real use

=item * C<?=>, C<:=>, C<+=>, and C<=> - all four assignment operators
with their distinct evaluation semantics put to work

=item * Order-only prerequisites, C<.DEFAULT_GOAL>, C<-include>, and
C<.SHELLFLAGS := -ec> - advanced directives that tame complex builds

=item * Trap-based temp file cleanup, C<mktemp>, and bash C<[[ ]]>>
conditionals inside make recipes

=item * Perl snippets exported into make via C<$(value ...)> and
C<export> - leveraging Perl's text processing power directly in the
build

=back

If GNU make is the cast-iron pan of build tools - virtually
indestructible, infinitely useful, and unfairly overlooked in favor of
shinier alternatives - then C<CPAN::Maker::Bootstrapper> is the recipe
book that shows you what it can really do.

=head1 IMPORTING FILES

The C<--import|-I> option allows you to bring existing Perl source
files into a new Bootstrapper project. This is the primary mechanism
for migrating an existing project or consuming a scaffold tarball
generated by C<cli-simple -scaffold>.

The C<--import> option may be specified multiple times to import from
several directories in a single operation:

  bootstrapper --module My::Script \
    --import /path/to/roles \
    --import /path/to/bin \
    --installdir .

=head2 What Gets Imported

The importer recursively scans the path provided by C<--import> and
brings in the following file types:

=over 4

=item * C<.pm> files - copied to F<lib/> as F<.pm.in> source files,
preserving the directory structure implied by the package name

=item * C<.pl> files - copied to F<bin/> as F<.pl.in> source files

=item * C<.t> files - copied to F<t/>

=item * Executable files - copied to F<bin/> as F<.in> files.

I<Note: Executable files are imported with their execute permission
removed. The build system sets permissions appropriately when
generating the final files from the C<.in> sources.>

=back

All imported files receive the C<.in> extension because they become
source inputs to the build system. The build generates the final
C<.pm>, C<.pl>, and script files from these sources, substituting
version tokens and running syntax checks along the way.

=head2 Module Name Requirement

When using C<--import> you must also specify C<--module> with the
primary module name of the distribution. The importer cannot infer
the module name from the imported files alone:

  bootstrapper --module My::Script --import /path/to/source --installdir .

=head2 The Build After Import

After creating the project source tree the importer runs C<make>
with linting disabled but syntax checking and dependency scanning
enabled:

  make LINT=off SYNTAX_CHECKING=on SCAN=on

This serves two purposes - it validates that the imported files are
syntactically correct Perl, and it runs C<scandeps-static.pl> against
the source to seed the F<requires> and F<test-requires> dependency
files.

The build will attempt to produce a distribution tarball. If the
build fails, C<make.log> and C<make.err> are written to your current
working directory for diagnosis.

=head2 Next Steps After a Successful Import

After a successful build you have a complete, buildable CPAN
distribution, although it may not reflect everything you need for your
project. Typical next steps:

=over 4

=item 1. Review and edit the generated F<buildspec.yml> - verify the
module name, author, and resource links are correct

=item 2. Manually import files missed by the importer

Your project may want to package additional files that are installed
into the distribution's share directory. Move them into an appropriate
directory or the root of the project and add them to the
F<buildspec.yml> file.

 extra_files:
   - ChangleLog <= include is distribution tarball, but not installed
   share:
     - config/some-file.ini  <= installs some-file.ini from your config/ directory
     - my-app.json <= install my-app.json from the root of your project

=item 3. Initialize a git repository with C<make git>

=item 4. Run C<make tidy> if you have C<perltidy> installed

=item 5. Run C<make> to produce the final distribution tarball

By default the repipes in the C<Makefile> will perform the following
actions:

=over 4

=item Perform a syntax check (C<perl -wc -I lib $@>) on your source files

=item Scan your source for dependencies

To turn this off:

 make SCAN=off

=item Run C<perltidy> on your source files

To turn this off:

 make PERLTIDYRC=""
 make LINT=off

=item Run C<perlcritic> on your source files

 make PERLCRITICRC=""
 make LINT=off

=back

To turn off everything except syntax checking:

 make quick

=item 6. Test installation: C<cpanm -n -v ./My-Script-1.0.0.tar.gz>

=back

=head2 Limitations

=over 4

=item * C<--import> cannot be used with C<--stub> - they are mutually
exclusive ways to create the initial source

=item * The importer uses the package declarations inside C<.pm> files
to determine where to place them under F<lib/>. If the importer cannot
match the filename with a package declaration inside the file, it will
warn and skip that file

=item * Imported files are not tidied automatically. If you have
C<perltidy> installed, run C<make tidy> after import to bring the
imported code into conformance with your C<.perltidyrc> before
committing

=item * If your imported modules have dependencies on each other, the
syntax check phase of the build may fail because Make processes files
independently and cannot guarantee build order. Add a F<project.mk>
to declare inter-module dependencies:

  lib/My/Script.pm: \
    lib/My/Script/Role/Frobnicate.pm \
    lib/My/Script/Role/List.pm

Make will then build your dependencies before attempting to syntax-check
the main module. See L</EXTENDING THE BUILD SYSTEM> for details on
F<project.mk>.

=back

=head2 Importing a CLI::Simple Scaffold Tarball

The C<import-scaffold> command is a convenience wrapper around
C<--import> specifically designed to consume tarballs generated by
C<cli-simple -scaffold>:

  bootstrapper import-scaffold my-script-roles.tar.gz \
    --module My::Script --installdir .

The tarball is extracted to a temporary directory and fed to the
importer automatically. See L<CLI::Simple> for details on generating
scaffold tarballs.


=head1 CONFIGURATION

C<cpan-maker-bootstrapper> can read your global F<.gitconfig> file or
a properly formatted C<.ini> file to populate some of the options used
when creating a distribution and using the AI commands. If you have a
GitHub user account add your username:

 git config --global user.github <your-username>

If you typically create projects in one directory, add the C<basedir>
option:

 git config --global cpan-maker.basedir $HOME/git

If you want to create a different configuration file it should have at
least the following entries:

 [user]
 	email = your-email@somedomain
 	name = First Last
        # use to construct GitHub resource URLs
 	github = github-user

 [cpan-maker]
 	basedir   = /home/myhome/git
        # indicates the resources section of Makefile.PL should contain github references
        resources = github
        llm-api-key-helper = cat ~/.ssh/anthropic-api-key

=over 4

=item C<llm-api-key-helper>

For LLM commands (code-review, pod-review), you can specify a
shell command that outputs your API key without exposing it in shell
history:

  llm-api-key-helper = cat ~/.ssh/anthropic-api-key

When set, this command is executed to retrieve the API key, avoiding
the need to pass it on the command line or set it in the environment
manually. This is the recommended secure approach.

See L<CPAN::Maker::ConfigReader> for a complete description of the
configuration file.

=item Use the C<--config> option to use your custom config.

=item Use C<create-config> to generate a starter configuration file:

 cpan-maker-bootstrapper create-config > ~/.cpan-makerrc

Then point C<cpan-maker-bootstrapper> at it by setting the
C<CPAN_MAKER_CONFIG> environment variable in your shell profile:

 export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

=back

=head2 Environment

=over 4

=item LLM_API_KEY

Your Anthropic Claude API key. Set this before running any LLM command
(code-review, pod-review, release-notes).

The key is removed from environment so it is not inherited by child
processes such as 'make'. This does not protect against memory
inspection of the current process - see L<LLM::API> for how the key is
actuall stored using a closure to prevent accidental serialization
via Dumper.

Avoid passing the key on the command line where it might be saved in
history and can be seen in process lists.

=item CPAN_MAKER_CONFIG

Path to a configuration file (in .ini format) containing user settings
such as name, email, GitHub username, and project base directory. If
not set, the bootstrapper will attempt to read settings from
~/.gitconfig.

=item SCAN

Controls whether dependency scanning is performed during C<make>. Set
to OFF or off to disable scanning. Default is ON.

=back

=head1 INSTALLED PROJECT FILES

The following files are installed into the project directory:

=over 4

=item * C<Makefile> - the complete build system. Derives all paths and
names from C<MODULE_NAME> or your stub file's package name. See L</THE
PROJECT MAKEFILE>.

=item * C<buildspec.yml> - generated from the template, pre-populated
with your module name, git identity, GitHub username, and project URLs.

=item * C<lib/E<lt>Module/PathE<gt>.pm.in> - stub module, populated from
either C<class-module.pm.tmpl> (default) or C<cli-module.pm.tmpl> (when
C<--stub cli> option is used). Contains package declaration, C<$VERSION>,
and a POD skeleton with your name and email from git config.

I<Note: All source files in C<lib/> and C<bin/> use the C<.pm.in> / C<.pl.in>
convention. These are the files you edit. The C<.pm> and C<.pl> files are
derived from them by the pattern rules in the Makefile, which substitute
C<E<64>PACKAGE_VERSIONE<64>> with the current value of C<VERSION>. Never edit the
generated C<.pm> or C<.pl> files directly - your changes will be
overwritten the next time C<make> runs!>

=item * C<t/00-E<lt>project-nameE<gt>.t> - minimal smoke test that calls
C<use_ok> on your module.

=item * F<.includes/> - the managed build system directory. Contains
all C<.mk> files installed and maintained by the bootstrapper. These
files are write-protected and should never be edited directly. Updated
by C<make update>.

 .includes/perl.mk         - pattern rules, syntax checking, tidy, critic
 .includes/git.mk          - make git target
 .includes/help.mk         - make help target
 .includes/version.mk      - make release/minor/major targets
 .includes/release-notes.mk - make release-notes target
 .includes/update.mk       - make update target
 .includes/upgrade.mk      - make upgrade/check-upgrade targets

=item * F<project.mk> - your extension point for custom make rules,
inter-module dependencies, and project-specific variables. Never
touched by C<make update>. See L</EXTENDING THE BUILD SYSTEM>.

=item * F<modulino.tmpl> - template used by C<make modulino> to
generate bash wrapper scripts for modulino-style modules.

=item * F<VERSION> - contains the current version string in
C<major.minor.patch> format. Managed by C<make release>, C<make minor>,
and C<make major>.

=item * F<ChangeLog> - empty placeholder, required by the distribution.

=item * .prompts/

The first time you attempt to run C<pod-review> or C<code-review> the
script will populate this directory with the default prompts.

=back

=head1 THE PROJECT MAKEFILE

The installed Makefile is self-configuring. It can derive everything
from C<MODULE_NAME> or the package name inside a custom stub file.

  MODULE_PATH  - lib/My/New/Module.pm (from MODULE_NAME)
  PROJECT_NAME - My-New-Module (from MODULE_NAME)
  TARBALL      - My-New-Module-1.0.0.tar.gz (from PROJECT_NAME + VERSION)

If C<MODULE_NAME> is not supplied on the command line, it is inferred
from the project directory name.

Key Makefile targets:

=over 4

=item C<make> / C<make all>

Builds the distribution tarball. Generates C<requires>,
C<test-requires>, and C<README.md> as prerequisites.

=item C<make requires> / C<make test-requires>

Scans source files with C<scandeps-static.pl> and writes the dependency
files specified in the C<buildspec.yml> file used by C<make-cpan-dist.pl>.

I<Note: By default, any change to your C<.pm.in> files will trigger a
rescan of your modules for new dependencies. This will add a
significant delay when you have many modules and a large number of
dependencies. You can avoid the scan by setting the environment
variable C<SCAN> to any value other than C<ON> (case insensitive).>

 make SCAN=OFF

=item C<make release> / C<make minor> / C<make major>

Bumps the patch, minor, or major version number in C<VERSION>.

=item C<make release-notes>

Generates a diff, file list, and tarball comparing the current version
to the previous git tag.

=item C<make clean>

Removes generated files. Does not affect C<buildspec.yml>, C<VERSION>,
or any C<*.in> source files.

=item C<make tidy>

Runs C<perltidy> on all C<.pm.in> and C<.pl.in> source files using
the profile specified by C<perltidyrc> in your config. Requires
C<perltidyrc> to be set.

=item C<make critic>

Runs C<perlcritic> on all source files using the profile specified by
C<perlcriticrc> in your config. Requires C<perlcriticrc> to be set.

=item C<make lint>

Runs both C<make tidy> and C<make critic>.

=item C<make git>

Initializes a git repository, stages all recommended project files
including F<.includes/*>, and makes an initial C<BigBang> commit.

=item C<make quick>

Builds the distribution tarball with dependency scanning and all
linting disabled. Useful during active development when you want fast
iterative builds without waiting for C<scandeps-static.pl> or quality
gates.

 make quick

Equivalent to:

 make SCAN=off LINT=off

=back

=head2 README.md

The F<Makefile> will automatically create a F<README.md> from your
Perl module's pod. The stock F<buildspec.yml> will include that
F<README.md> in the distribution's share directory. If you want the
F<README.md> to be included in the distribution but not installed,
edit the F<buildspec.yml> file.

B<Before>

  extra-files:
    - ChangeLog
    - share:
      - README.md

B<After>
  extra-files:
    - ChangeLog
    - README.md

If you want a different F<README.md> generated create a
F<README.md.in> file. That file will be filtered through
F<md-utils.pl> (from L<Markdown::Render>) to produce a C<.md> file.

=head1 USAGE

 cpan-maker-bootstrapper options command

=head2 Commands

=over 4

=item install (default)

Scaffolds a new project. This is the default command so:

 cpan-maker-bootstrapper -m My::Module

...is the same as:

 cpan-maker-bootstrapper -m My::Module install

=item create-config

Outputs a stub configuration file to STDOUT. Create and edit a new
config to customize the behavior of C<cpan-maker-bootstrapper>.

 cpan-maker-bootstrapper create-config > ~/.cpan-makerrc

Then set C<CPAN_MAKER_CONFIG> to point to it:

 export CPAN_MAKER_CONFIG=$HOME/.cpan-makerrc

=back

=head2 LLM Commands

The following commands require L<LLM::API> to be installed and a valid
Anthropic API key. Set it in the environment before running any LLM command:

 export LLM_API_KEY=$(cat ~/.ssh/anthropic-api-key)

The key is deleted from the environment immediately after being read and
is never passed to child processes. See L<CPAN::Maker::ConfigReader> for
the C<llm-api-key-helper> option which avoids exposing the key in shell
history entirely.

I<SECURITY NOTE: Never pass your API key on the command line where it
would be visible in shell history and process listings.>

=over 4

=item code-review

Submits a Perl module or script to the LLM for a code review. POD is
automatically stripped before submission so token costs reflect code
only. The review is written as a JSON file to the current directory.

 cpan-maker-bootstrapper code-review [options] lib/My/Module.pm

The review file is named:

 <module>-review-<timestamp>.code

A token usage summary is printed to stderr after the review completes.

If a review has been completed at least once the annotated review file
is automatically sent with your code to re-focus the review. You must
annotate the review file before resubmitting by running the
C<annotate> command and marking each finding with a valid
dispostion. See L</THE REVIEW WORKFLOW> for details.

Options specific to code-review:

 --prompt|-p PATH          path to a custom review prompt file
 --prompt-profile|-P NAME  additive prompt profile (repeatable)
 --context|-C PATH         context file to submit alongside the review (repeatable)

I<Note: The prompt profile list and the context file list is written
to the review output file. On subsequent runs these will be read from
the review. You do not need to provide them unless you want to update
their values.>

=item annotate

Applies disposition tags to findings in the latest review file and
displays the current annotation state. Must be run from a project
directory (one containing F<.includes/>).

 cpan-maker-bootstrapper annotate [options] lib/My/Module.pm

Without options, displays the current annotation state of the latest
review file. With C<-a> options, applies the specified dispositions
before displaying.

 cpan-maker-bootstrapper annotate lib/My/Module.pm
 cpan-maker-bootstrapper annotate -a 1:wrong -a 2:reject lib/My/Module.pm

Options:

 --annotate|-a N:DISPOSITION    apply disposition to finding N (repeatable)
 --auto-annotate|-A             annotate and immediately submit the next review
 --finalize-annotations|-F      create versioned release artifact

Valid dispositions are C<accept>, C<reject>, C<wrong>,
C<wrong-reconsider>, C<defer>, and C<confirmed> (case
insensitive). See L</THE REVIEW WORKFLOW> for a description of each.

=item pod-finding

 cpan-maker-bootstrapper pod-finding lib/CPAN/Maker/Bootstrapper.pm

Run this after a C<pod-review> command to display a table of findings.

=item pod-review

Submits a Perl module or script to the LLM for a documentation review.
The full file including code is submitted so the LLM can check
consistency between implementation and documentation. If no POD exists
the LLM generates complete POD documentation ready to paste after
C<__END__>.

 cpan-maker-bootstrapper pod-review lib/My/Module.pm

The review file is named:

 <module>-review-<timestamp>.pod

=item release-notes

Generates release notes for a given version using the LLM. Requires
the release artifacts produced by C<make release-notes>:

 release-<version>.diffs
 release-<version>.lst
 release-<version>.tar.gz

Usage:

 cpan-maker-bootstrapper release-notes <version>

The generated release notes are written to C<release-notes-E<lt>versionE<gt>.md>.
Binary files are automatically excluded. Use C<--max-diff-files> to
cap token consumption on large distributions (default: 50, 0 = unlimited).

=item code-finding

Generates a table with the complete details of a finding.

 cpan-maker-bootstrapper code-finding lib/My/Module.pm 1

=back

=head2 Options

=over 4

=item C<--annotate|-a> N:DISPOSITION

See L</annotate>

=item C<--auto-annotate|-A>

See L</annotate>

=item C<--basedir|-b> DIR

Base directory in which to create the projects. Defaults to the
current working directory when C<--installdir> and C<--basedir> are not
provided. The directory must exist or the script will throw an
exception.

I<Note: If C<--installdir> is provided it takes precedence and
C<--basedir> is ignored.>

default: pwd

=item C<--dry-run|-D>

Dry run mode will abort after displaying a pre-submission token and
cost estimation for the C<pod-review> and C<code-review> commands.

=item C<--config|-c> configuration file

The path to a C<.ini> file that contains configuration information
used to scaffold your project.

default: ~/.gitconfig

=item C<--color, --no-color>

Turns coloring of the annotation summary table on or off.

default: on

=item C<--context|-C> PATH

One or more files to submit with your code review file that provide
additional context for the LLM during the review.

=item C<--email|-e> EMAIL

Override the author email. Defaults to C<user.email> from your global
git config.

=item C<--finalize-annotations|-F>

See L</annotate>

=item C<--force|-f>

Overwrite an existing project. Without this flag, the command dies if a
C<Makefile> already exists in the target directory.

=item C<--github-user|-g> USER

Override the GitHub username used to construct repository URLs in
C<buildspec.yml>. Defaults to C<user.github> from your global git config.

=item C<--import|-I> path

A path that contains C<.pm> or C<.pl> files for importing into the
project. You can specify multiple paths. You cannot use C<--stub> and
C<--import> together.

Example:

 cpan-maker-bootstrapper --module Foo::Bar -I ~/foo-bar/lib -I ~/foo-bar/bin

When using the C<--import> option, you must use the C<--module> option
to specify the primary module name of the distribution. The importer
cannot infer the module name from the imported files alone.

I<Note: The F<Makefile> will automatically attempt to substitute the
token C<E<64>PACKAGE_VERSIONE<64>> inside your C<.pl.in> or C<.pm.in> files with
the current semantic version in the F<VERSION> file. If you want to
use that for versioning your scripts and modules add the token as
shown below:>

C<our $VERSION = 'E<64>PACKAGE_VERSIONE<64>;'>

=item C<--installdir|-i> DIR

Directory in which to create the project. Defaults to the
current working directory. The directory is created if it does not
exist.

Example:

  cpan-maker-bootstrapper --installdir ~/git/My-Module

The install directory should include the project name.

I<Note: C<--installdir> overrides C<--basedir>>.

=item C<--max-diff-files> LIMIT

The number of files inside the tarball that contains the changed files
for release notes creation that can be uploaded to the LLM. Set to 0
for no limit.

default: 50

=item C<--max-tokens|-t> TOKENS

Maximum number of tokens the LLM may return in a single response.
Higher values reduce the risk of truncated reviews on large files.

default: 4096 (set by L<LLM::API>)

=item C<--model|-M> MODEL

Specifies the model id to use for the C<pod-review> and C<code-review>
commands.

For C<pod-review> the default model is C<claude-haiku-4-5-20251001>.

For C<code-review> the default mode is C<claude-sonnet-4-6>.

The Haiku model tends to be better at summarizing documentation and
avoiding unnecessary analysis around edge cases that contribute to
noise.

I<Caution: Both models try hard to find issues to the point that you
will almost never get a clean run when asking for a POD review. When
your POD is complete, accurate and usable it's good enough. Avoid
shaving the yak!>

=item C<--module|-m> MODULE (required)

The Perl module name for the new project, e.g. C<My::New::Module>.
Used to derive the project directory name, source file path, and
tarball name. You can omit this option if you provide a stub file
(C<--stub path>) that contains a package name that is consistent with
the stub's path. For example, if my package is C<My::App> and the
module path contains C<My/App> then the script will assume your
module name is C<My::App>.

 cpan-maker-bootstrapper --stub $HOME/workdir/My/App.pm

=item C<--prompt|-p> PATH

Path to a text file that will be used to prompt the LLM for a code or pod review.

defaults:

 pod  => .prompts/pod-review.prompt
 code => .prompts/code-review.prompt

=item C<--prompt-profile|-P> NAME

The name of a prompt profile located in the F<.prompts> directory. One
or more profile names may be specified. You need only provide the name
(e.g. cli-tool).

See L</PROMPT PROFILES>

=item C<--resources|-r> github

Currently takes only a single value: 'github' that indicates that the
resources section of F<Makefile.PL> should be populated with GitHub
URL references. Future versions may support additional providers.

=item C<--stub|-s> TYPE|PATH

Controls the module stub used to generate the initial C<.pm.in> source
file. Three forms are accepted:

=over 4

=item * Omitted - uses the default plain class stub (C<class-module.pm.tmpl>).

=item * C<cli> - uses the CLI stub (C<cli-module.pm.tmpl>), which
inherits from L<CLI::Simple> and includes a skeleton C<main>, C<init>,
and a placeholder command.

=item * A file path - uses the specified file as the stub. The file
must exist or the command will die with an error. This allows you to
supply your own template or bootstrap a project around a module you
have already started writing. You can omit the C<--module> option if
you supply your own stub file. See the explanation for the
C<--module> option for details.

=back

When specifying a stub you cannot use the C<--import> option.

=item C<--username|-u> NAME

Override the author name used in the module stub and C<buildspec.yml>.
Defaults to C<user.name> from your global git config.

=back


=head1 THE REVIEW WORKFLOW

C<CPAN::Maker::Bootstrapper> allow you implement a structured
iterative code review workflow built around JSON review files and
developer-applied disposition annotations. The workflow converges over
several rounds, with each round potentially costing less as noise is
suppressed and findings are resolved.

=head2 Overview

Each review round consists of three steps:

=over 4

=item 1. Run a review

 cpan-maker-bootstrapper code-review \
   --prompt-profile cli-tool \
   lib/My/Module.pm

The review is written to a timestamped C<.code> file containing a JSON
object with C<findings>, C<confirmations>, and C<deferred> arrays.

=item 2. Annotate the findings

 cpan-maker-bootstrapper annotate lib/My/Module.pm

This displays the current annotation state. Apply dispositions with
C<-a> options:

 cpan-maker-bootstrapper annotate \
   -a 1:accept -a 2:wrong -a 3:reject -a 4:defer \
   lib/My/Module.pm

You can annotate incrementally across multiple invocations. Each call
shows the updated state so you always know what remains.

=item 3. Submit the next review

Once all findings are annotated and code updated if necessary, run the
next review. The bootstrapper automatically finds and submits the
latest annotated review file with your updated code:

 cpan-maker-bootstrapper code-review lib/My/Module.pm

Alternatively, use C<--auto-annotate|-A> with the C<annotate> command
to annotate and immediately resubmit in one step:

 cpan-maker-bootstrapper annotate -a 1:wrong -a 2:reject --auto-annotate \
   lib/My/Module.pm

The LLM will honor all dispositions from the prior round, confirm
fixes marked C<ACCEPT>, carry forward C<DEFER> items, and suppress
C<REJECT> and C<WRONG> findings. New findings appear without noise
from settled questions.

=back

=head2 Dry Run Mode

Before your prompt and code are submitted for review, the script will
output a table of showing you the estimated cosst based on token
counts. The input token count is derived by calling the "COUNT TOKEN"
endpoint API with the message to be submitted for review. The input
token count is therefore accurate, while the output token count is an
estimate.

To stop the script for actually submitting the message for review, use
the C<--dry-run> option. This will abort the process immediately prior
to submission.

=head2 Dispositions

Each finding in the annotations file must be given one of the following
dispositions before the next review can be submitted:

=over 4

=item ACCEPT

The finding is valid and has been fixed. On the next review the LLM
will confirm the fix is present. If the fix is not found the finding
will be re-raised.

=item REJECT

The finding has been reviewed and dismissed as inapplicable to this
codebase or context. It will not be raised again in subsequent reviews.

=item WRONG

The finding was based on faulty reasoning. The code is correct. The
finding will not be re-raised. Use this when the LLM has misread the
control flow, misunderstood the design intent, or applied an
inappropriate threat model.

=item WRONG-RECONSIDER

Applied automatically at finalization to all findings marked WRONG.
On the first review of the next version the LLM will re-examine the
specific function and code excerpt carefully. If the prior analysis
was still incorrect the finding reverts to WRONG. If the code has
changed and the finding is now valid it is raised as a new finding.
If the model understands specifically why its prior reasoning was
wrong it may mark the finding CONFIRMED.

=item DEFER

The finding is known and acknowledged but not yet addressed. It is
carried forward in the C<deferred> array of each subsequent review
without being treated as a new finding.

=item CONFIRMED

Used for logic confirmations rather than defects. Marks that both the
LLM and the developer agree the code is correct.

=back

=head2 Diminishing Returns and When to Stop

Run the C<annotate> command after each review submission to view the
findings. Each round tends to surface smaller and more obscure issues
as obvious findings are resolved. Stop when you see these signals:

=over 4

=item *

All new findings are LOW severity.

=item *

The LLM is re-raising findings already marked WRONG or REJECT,
possibly rephrased.

=item *

New findings describe edge cases that cannot occur in normal usage.

=back

When all findings have dispositions and no new substantive issues
appear, the code is ready to ship.

=head2 The Release Artifact

When you are satisfied with the review state, finalize it with
C<--finalize-annotations>:

 cpan-maker-bootstrapper annotate --finalize-annotations \
   -a 1:wrong -a 2:reject \
   lib/My/Module.pm

This applies any remaining dispositions, validates that all findings
are annotated, reads the version from the F<VERSION> file, and writes
the versioned release artifact:

 CPAN-Maker-Bootstrapper-1.1.0-REVIEW.json

This file serves as a code review certification for the release - a
machine-readable record of every finding examined, every logic
confirmation made, and every disposition applied before the version
was published. Commit it to the repository alongside your ChangeLog.

All findings marked WRONG are automatically converted to
WRONG-RECONSIDER in the release artifact, prompting careful
re-examination on the first review of the next version rather
than permanent suppression.

=head2 Cost Management

Typical review costs run $0.05-0.10 per run on a moderately sized
module with POD stripped depending on the model you choose. The
default model used for POD review is C<claude-haiku-4-5-20251001> and
C<claude-sonnet-4-6> for code review. Costs decrease over successive
rounds as the model spends fewer output tokens re-explaining
suppressed findings.

Use your own prompt profiles (C<--prompt-profile>) to suppress entire
classes of noise before they reach the annotation file. A well-tuned
profile for your application type is the highest-leverage cost
reduction available.

=head2 See Also

L</LLM Commands>, L</PROMPT PROFILES>, L<CPAN::Maker::ConfigReader>

=head1 PROMPT PROFILES

Prompt profiles are additive prompt fragments that customize the review
behavior for specific application types. They are appended to the base
review prompt before submission and are intended to focus the review on
relevant concerns while suppressing noise that does not apply to the
target context.

=head2 Using Profiles

Pass one or more profiles using the C<--prompt-profile> option:

  cpan-maker-bootstrapper code-review --prompt-profile cli-tool MyModule.pm

Multiple profiles may be combined:

  cpan-maker-bootstrapper code-review \
    --prompt-profile cli-tool \
    --prompt-profile security \
    MyModule.pm

Profiles are resolved from the F<.prompts/> directory in the current
project. A profile named C<cli-tool> resolves to
F<.prompts/cli-tool.prompt>. Add your own prompt profiles and commit
them to your project.

=head3 Built-in Profiles

The following profile is installed with the distribution:

=over 4

=item cli-tool

Appropriate for single-user developer CLI tools. Suppresses security
findings that assume a multi-user or hostile environment, TOCTOU race
condition findings that assume concurrent invocation, and concerns about
C<qx{}> or C<system()> calls where input originates from the user's own
configuration. Also assumes C<perlcritic> and C<perltidy> are enforced
in the development environment.

=back

=head3 Creating Custom Profiles

A profile is a plain text file in F<.prompts/> containing additional
prompt instructions, one per line. Lines beginning with C<#> are treated
as comments and stripped before submission. Profile instructions use the
same format as the base review prompt.

Example F<.prompts/security.prompt>:

  # security profile - add to any review where input handling matters
  - Treat all caller-supplied input as untrusted regardless of source.
  - Flag any use of eval, system, or exec that incorporates external data.
  - Flag missing taint checks on data used in file or system operations.

=head3 Planned Profiles

The following profiles are planned for future releases:

=over 4

=item library

Focuses on API contract correctness and caller assumptions. Appropriate
for CPAN distributions intended for use by unknown callers.

=item web-application

Treats external input as untrusted. Flags injection risks, authentication
gaps, and session handling concerns.

=item mod-perl-handler

Addresses Apache lifecycle concerns including global state, startup versus
request time initialization, and child process behavior.

=item lambda-function

Focuses on cold start performance, statelessness, and environment variable
handling appropriate for AWS Lambda deployments.

=back

Community contributions of additional profiles are welcome. See
L<https://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues>.

=head1 EXTENDING THE BUILD SYSTEM

The bootstrapper's F<Makefile> is intended to be immutable and work
across all of the projects that use C<CPAN::Maker::Bootstrapper>. Our
goal is to keep F<Makefile> working for you even when we make updates
to the bootstrapper.

However, you own F<Makefile> and are free to do with it as you
please. But we strongly advise that you read the sections below and
follow the I<recipe> as the saying goes, to use and update the build
system as it was intended.

The installed F<Makefile> is a managed file - it can be updated by
using the C<make> target C<update> when a new version of
C<CPAN::Maker::Bootstrapper> is released.

 make update

You are strongly advised not to modify the F<Makefile> - your changes
will be overwritten if you run C<make update>.

Instead, the recommended workflow, should you need to add new make
targets or control the order of the build based on dependencies is to
add those to F<project.mk>. All managed build system files live in
the F<.includes/> directory where they are write-protected and clearly
separated from your project files. The F<Makefile> includes them
automatically and conditionally includes F<project.mk> from the
project root:

 include .includes/perl.mk
 include .includes/help.mk
 include .includes/version.mk
 include .includes/release-notes.mk
 include .includes/git.mk
 include .includes/update.mk
 include .includes/upgrade.mk
 -include project.mk

F<project.mk> remains in the project root - it is your file, always
writable, and never touched by C<make update>. The leading C<-> on
its include means make will not complain if it does not exist yet.
This gives you a sanctioned, upgrade-safe extension point for
anything project-specific.

=head2 How the Makefile Works

The installed F<Makefile> is structured around a few key concepts:

=over 4

=item * B<Source files> live in F<lib/> as F<.pm.in> and in F<bin/> as
F<.pl.in>. The build generates the final F<.pm> and F<.pl> files from
these sources by substituting C<E<64>PACKAGE_VERSIONEE<64>> and other
tokens, running syntax checks, and optionally running perltidy and
perlcritic.

=item * B<Sentinel files> - F<.tdy> and F<.crit> files track whether
a source file has passed tidiness and critic checks. These are
regenerated only when the source changes.

=item * B<Dependency scanning> - C<scandeps-static.pl> scans your
source files and generates F<requires> and F<test-requires> files
which feed into F<Makefile.PL>. Controlled by C<SCAN=on|off>.

=item * B<The distribution tarball> is the final output of C<make>.
It is built by C<make-cpan-dist.pl> using F<buildspec.yml>.

=back

Key variables you can override on the make command line or in
F<project.mk>:

=over 4

=item C<SCAN=off> - skip dependency scanning

=item C<LINT=off> - skip perltidy and perlcritic

=item C<SYNTAX_CHECKING=off> - skip C<perl -wc> syntax checks

=item C<MIN_PERL_VERSION=5.016> - minimum Perl version for Makefile.PL

=item C<PERLTIDYRC=/path/to/rc> - path to perltidy configuration

=item C<PERLCRITICRC=/path/to/rc> - path to perlcritic configuration

=item C<SKIP_TESTS=1> - skips running tests when building distribution

=back


=head2 What belongs in project.mk

=over 4

=item Custom targets

Any target specific to your project - generating assets, running
linters, deploying, sending notifications:

 .PHONY: deploy
 deploy: all
     scp $(TARBALL) user@myserver:/opt/cpan

=item Inter-module dependencies

If your modules have build-time dependencies on each other, declare
them here rather than modifying the Makefile:

 lib/Foo/Bar.pm: lib/Foo.pm

=item Additional file generation

If your project generates code or configuration from templates beyond
what the standard Makefile handles:

 lib/Foo/Generated.pm.in: schema/foo.json
     perl bin/generate-module.pl $< > $@

=item Project-specific variables

 DEPLOY_HOST = myserver.example.com
 DEPLOY_PATH = /opt/cpan/incoming

=item Extending CLEANFILES

Add project-specific generated files to the cleanup target by
appending to C<CLEANFILES>:

 CLEANFILES += mygenerated.pm config/generated.yml

=back

=head2 What does NOT belong in project.mk

=over 4

=item * Modifications to existing targets like C<all>, C<clean>, C<requires>

=item * Changes to C<DEPS>, C<CLEANFILES>, or other core variables - these
are owned by the managed Makefile

=item * Anything that duplicates logic already in the managed Makefile

=back

=head2 Keeping the build system up to date

The following targets manage the lifecycle of the build system itself:

=over 4

=item C<make check-upgrade> / C<make upgrade-check>

Checks MetaCPAN to see if a newer version of
C<CPAN::Maker::Bootstrapper> is available.

=item C<make upgrade>

Checks MetaCPAN, installs the latest version via C<cpanm>, then
automatically runs C<make update> to refresh the managed project
files.

=item C<make update>

Copies the managed files from the currently installed bootstrapper
distribution into your project directory. After running, use
C<git diff> to review what changed and C<git checkout E<lt>fileE<gt>>
to revert any changes you don't want.

The following files are managed and may be updated:

 Makefile
 .includes/git.mk
 .includes/help.mk
 .includes/update.mk
 .includes/upgrade.mk
 .includes/version.mk
 .includes/perl.mk
 .includes/release-notes.mk
 modulino.tmpl

Your F<project.mk>, F<buildspec.yml>, F<requires>, F<VERSION>, source
files and tests are B<never> touched by C<make update>.

=item C<make cpanm>

Installs C<cpanminus> if it is not already available on your
C<PATH>. Required for C<make upgrade> to work:

 make cpanm && make upgrade

=back

=head2 What You Should Never Modify

The files in F<.includes/> - F<perl.mk>, F<git.mk>, F<help.mk> etc.
- are managed files that will be overwritten by C<make update>. Do
not modify them directly. If you need to override behavior they
provide, do so in F<project.mk> using Make's double-colon rule
pattern or by setting variables before the include.

The F<Makefile> itself is also managed and will be overwritten by
C<make update>. Your extension point is exclusively F<project.mk>.

=head2 Dependencies Management

The C<Makefile> will attempt to detect Perl module dependencies by
scanning .pm.in and .pl.in files and creating the F<requires> and
F<test-requires> files whenever you run C<make>. These files are used
by the F<make-cpan-dist.pl> utility to specify the dependencies in your
CPAN distribution file. You can prevent that by setting the environment
variable C<SCAN=OFF>. The default is C<SCAN=ON>.

To prevent an entry from being removed by a rescan, prefix the module
name with C<+>. These entries are sticky and survive all subsequent
scans even if the scanner no longer detects them.  To pin a specific
version, simply edit the version number in the F<requires> file. If
the scanner subsequently detects a different version, the Makefile
will preserve your pinned version. Note that pinned versions are
B<never> updated automatically - if you want to adopt a newer version
you must edit the file manually.

In your requires file:

  +Foo::Bar 1.0    # sticky - survives all rescans
  Baz::Qux  2.5   # version pinned - scanner won't override this version

I<Note: These two mechanisms are independent - C<+> controls whether an entry
survives rescans, while the version number controls what version is
required.>

=head1 MODULINOS

A modulino is a Perl module that doubles as a runnable script by
checking whether it was invoked directly or loaded as a library:

 package Foo::Bar;

 caller or __PACKAGE__->main;

 sub main {
   ...
   exit 0;
 }

Modulinos are useful for CLI scripts because they encourage
encapsulation, simplify unit testing, and keep logic organized
in named methods rather than inline code.

The C<Makefile> provides a C<modulino> target that generates a bash
wrapper script that invokes your module. By default it uses
C<MODULE_NAME>, producing a script named after the module:

 make modulino

For a project named C<Foo::Bar> this creates C<bin/foo-bar.in>.
C<make> then builds C<bin/foo-bar> from that source file via a
pattern rule, and the executable ends up in the distribution.

To create a modulino wrapper for a module other than the primary
project module, override C<MODULE_NAME>:

 make modulino MODULE_NAME=Foo::Bar::Buz

This creates C<bin/foo-bar-buz.in> invoking C<Foo::Bar::Buz>.

To give the wrapper a short or memorable name independent of the
module name, set C<ALIAS>:

 make modulino MODULE_NAME=Foo::Bar::Buz ALIAS=fbb

This creates C<bin/fbb.in> which still invokes C<Foo::Bar::Buz>.
C<ALIAS> accepts either a plain name (C<fbb>) or a module-style
name (C<Foo::Bar::Buz>) - colons are converted to hyphens and
the result is lowercased.

The generated wrapper scripts (without the C<.in> suffix) are
automatically added to F<.gitignore> since they are build artifacts.
The C<.in> source files are tracked by git.

=head1 PREREQUISITES

The following tool(s) must be on your C<PATH>:

=over 4

=item * C<git> - used to read global identity config

=item * C<make> - GNU make is required to build the project

=item * C<curl> - used by C<make upgrade> to query MetaCPAN

=back

=head1 CAVEATS

=over 4

=item F<.pm> and F<.pl> Generation

These files are generated from F<.pm.in> and F<.pl.in> files in the
Makefile by filtering them through a C<sed> command that replaces
certain tokens like C<E<64>PACKAGE_VERSIONE<64>> with values. The
generated files are read-only. Always edit the F<.in> file version.

Use C<E<64>PACKAGE_VERSIONE<64>> like this:

C<our $VERSION ='>C<E<64>PACKAGE_VERSIONE<64>>C<';>

=item The import feature cannot be used with C<--stub>

=item git

There is an assumption that users of this script are also C<git>
users. C<git> is required to run C<make git> which instatiates a git
project and makes an intial commit. It's also used to look into your
F<.gitconfig> file for your name and email address to populate the
certain element in the resources file used when building your CPAN
distribution.

=back

=head1 FAQ

=head2 My build is failing with a module not found error during syntax
checking

This is almost always a build-time dependency ordering issue. If
C<lib/Foo/Bar.pm> uses C<lib/Foo.pm>, make may attempt to build and
syntax-check C<Foo/Bar.pm> before C<Foo.pm> exists. Declare the
dependency in F<project.mk>:

 lib/Foo/Bar.pm: lib/Foo.pm

This tells make to build C<Foo.pm> first. See L</Inter-module
dependencies> for details.

If the module genuinely cannot be loaded outside its runtime
environment (an Apache handler, a mod_perl module, etc.), add it to
C<PERLWC_SKIP> in F<project.mk>:

 PERLWC_SKIP = lib/My/Apache/Handler.pm

=head2 How do I do a fast build during development?

 make quick

This disables dependency scanning and all linting (syntax checking,
perltidy, perlcritic) for the current build. Your F<requires> and
F<test-requires> files are not updated and no quality gates run.

Use C<make> without flags when you are ready to do a full build before
committing or releasing.

You can also disable individual features:

 make SCAN=off          # skip dependency scanning only
 make LINT=off          # skip all linting only
 make SYNTAX_CHECKING=off  # skip syntax checking only

=head2 How do I add a new module or script to the project?

Create the source file with the C<.pm.in> or C<.pl.in> extension in
the appropriate directory:

 lib/My/New/Module.pm.in
 bin/my-script.pl.in

The build system discovers them automatically via C<find-files> - no
changes to the Makefile are required. The next C<make> will include
them in the dependency scan and the distribution.

=head2 How do I include additional files in the distribution?

Edit F<buildspec.yml> and add entries to the C<extra-files> section:

 extra-files:
   - ChangeLog
   - README.md
   - share:
     - my-config-template.yml
     - my-data-file.json

Files listed under C<share:> are installed into the distribution's
share directory and can be accessed at runtime via
L<File::ShareDir>.

=head2 I want to pin a version or add a module the scanner missed

Edit F<requires> directly. Prefix the module name with C<+> to make
the entry sticky - it will survive all subsequent rescans even if the
scanner no longer detects it:

 +My::Required::Module 1.5

To pin a version without making the entry sticky, just set the version
number. The scanner will preserve your version if it detects a
different one on subsequent builds:

 Some::Module 2.0

These two mechanisms are independent - C<+> controls survivability,
the version number controls what version is required. See L</Dependencies>
for full details.

=head2 I want to exclude a module the scanner found

Create a F<requires.skip> file in the project root with one module
name per line:

 My::Own::Module
 Some::Transitive::Dep

The scanner will never add these to F<requires>. Use
F<test-requires.skip> for the same effect on test dependencies.

Note that on a clean first build neither skip file has any effect
since there is no prior F<requires> file to compare against. The skip
list takes effect from the second build onward.

=head2 I edited a .pm file and my changes disappeared

The C<.pm> files in F<lib/> are generated from the C<.pm.in> sources
and are write-protected. Always edit the C<.pm.in> file - the C<.pm>
is regenerated on every C<make> and your changes will be lost.

If you are unsure which file to edit:

 ls -l lib/My/Module.pm lib/My/Module.pm.in

The C<.pm.in> file is the one you own.

=head2 make update overwrote something I changed in a managed file

The managed files in F<.includes/> should never be edited directly -
that is what F<project.mk> is for. However if you did modify a managed
file and C<make update> overwrote it, git has you covered:

 git diff .includes/perl.mk
 git checkout .includes/perl.mk

This is why C<make git> and committing your F<.includes/> directory is
strongly recommended - git is your safety net for the entire build
system.

=head2 make says nothing to do but my source changed

The most common cause is that the generated C<.pm> file is newer than
the C<.pm.in> source. This can happen if you accidentally edited the
C<.pm> directly or if file timestamps got out of sync. Force a rebuild:

 touch lib/My/Module.pm.in

Or do a clean rebuild:

 make clean && make

=head2 How do I disable scanning temporarily?

 make SCAN=off

This skips the dependency scan entirely for that run - useful when
you have many modules and want a fast build during active development.
The default is C<SCAN=ON>.

=head2 How do I disable syntax checking temporarily?

 make SYNTAX_CHECKING=off

Similarly you can disable individual quality gates:

 make PERLTIDYRC="" PERLCRITICRC=""

=head2 How do I upgrade the build system?

 make upgrade

This checks MetaCPAN for a newer version of
C<CPAN::Maker::Bootstrapper>, installs it via C<cpanm>, and
automatically refreshes the managed files in F<.includes/> with
C<make update>. Review the changes with C<git diff> and revert
anything you don't want with C<git checkout>.

If C<cpanm> is not installed:

 make cpanm && make upgrade

=head2 I want to add a bash script to my distribution

Create the script in F<bin/> with a C<.sh.in> extension:

 bin/my-script.sh.in

The build system will process it through the standard token
substitution (replacing C<E<64>PACKAGE_VERSIONE<64>> and
C<E<64>MODULE_NAMEE<64>>), make it executable, and include it in the
distribution automatically.

If your script is more than a few lines of bash, consider writing it
as a I<modulino> instead - a Perl module that doubles as a runnable
script. Modulinos are easier to test, encourage encapsulation, and
give you the full power of Perl and CPAN. The build system has
first-class support for them:

 make modulino

This generates a bash wrapper in F<bin/> that invokes your module as
a script if it uses the modulino pattern:

 caller or __PACKAGE__->main;

See L</MODULINOS> for full details.

=head2 What is C<make release-notes> used for?

C<make release-notes> generates three artifacts comparing the current
working state of your repository against the previous git tag:

=over 4

=item * F<release-E<lt>versionE<gt>.diffs> - a unified diff of all
changed files

=item * F<release-E<lt>versionE<gt>.lst> - a list of added, modified,
and removed files

=item * F<release-E<lt>versionE<gt>.tar.gz> - a tarball containing
only the changed files

=back

These are primarily useful for generating release notes and changelogs,
and for submitting targeted patches. Run it after bumping the version
with C<make release>, C<make minor>, or C<make major> and before
publishing to CPAN:

 make minor
 make release-notes
 # review release-1.1.0.diffs
 make

The artifacts are all the clues needed for LLMs to produce accurate
and well written release notes for your project.

The release artifacts are cleaned up by C<make clean>.

=head2 Can I distribute the POD in my modules separately?

When you package your CPAN distribution you can strip the pod from
your modules or you can extract the pod and provide them as separate
C<.pod> files. There are two C<make> environment variables you can set
to control that behavior.

=over 4

=item C<make POD=extract>

C<extract> will strip POD from your module and create a C<.pod> file
containing the stripped POD that will be added to your distribution.

=item C<make POD=remove>

C<remove> will strip POD from your module. No POD will be included in
the distribution.

=back

=head2 The dependency resolver keeps adding a file I don't want to
list. How can I tell it to skip those files?

Add a F<requires.skip> file to exclude modules from the scanned
list. Sometimes the scanner may include modules that are optional or
modules you just don't want to include as requirements because they
are already included in a module you have already required.

Similarly, F<test-requires.skip> excludes modules from the test
dependency scan.

On a clean first run neither F<requires> nor F<test-requires> exists
yet, so the raw scanner output becomes the dependency file - meaning
skip list and pins have no effect until the second run.

=head2 Something still doesn't work - how do I report an issue?

First check the L</FAQ> sections above - your
issue may already be covered.

If you believe you have found a bug or want to request a feature,
please open an issue on GitHub:

 https://github.com/rlauer6/CPAN-Maker-Bootstrapper/issues

When reporting a bug please include:

=over 4

=item * The version of C<CPAN::Maker::Bootstrapper> (C<cpan-maker-bootstrapper --version>
or C<perl -MCPAN::Maker::Bootstrapper -e 'print $CPAN::Maker::Bootstrapper::VERSION'>)

=item * The output of C<make -n> or C<make --debug=v> if the issue is
build-related

=item * Your F<buildspec.yml> and F<project.mk> if relevant (redact
any sensitive information)

=item * The Perl and GNU make versions (C<perl --version>, C<make --version>)

=item * B<MAKE SURE YOUR SUBMISSION DOES NOT CONTAIN SECRETS!>

=back

Pull requests are welcome. The project follows the standard GitHub
fork-and-PR workflow.

=head1 SEE ALSO

L<CPAN::Maker> - the distribution builder driven by C<buildspec.yml>
(includes C<make-cpan-dist.pl>)

L<CLI::Simple> - the CLI framework used by the bootstrapper itself and
optionally by generated CLI module stubs

L<CPAN::Maker::ConfigReader> - the git config reader bundled with this
distribution, available for use in your own
tools.

L<LLM::API> - client interface to Anthropic's Claude API

L<Module::ScanDeps::Static> - the static dependency scanner used by
C<make requires> and C<make test-requires> to analyze your source files

=head1 DEPENDENCIES

  CLI::Simple::Constants
  CLI::Simple::Utils
  CPAN::Maker::ConfigReader
  Cwd
  English
  Email::Valid
  File::Basename
  File::Copy
  File::Find
  File::Path
  File::ShareDir
  File::Temp
  JSON::PP
  List::Util
  Module::Metadata;

=head2 Required for AI Commands

  Archive::Tar
  Pod::Extract (required for code-review command)
  Text::ASCIITable;

=head2 Recommend Packages

 Term::ANSIColor


=head1 VERSION

This documentation refers to version 1.1.1

=head1 AUTHOR

Rob Lauer - E<lt>rlauer@treasurersbriefcase.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

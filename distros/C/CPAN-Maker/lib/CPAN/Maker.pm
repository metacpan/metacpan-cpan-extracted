package CPAN::Maker;

use strict;
use warnings;

our $VERSION = '1.5.46';

1;

## no critic

__END__

=pod

=head1 NAME

CPAN::Maker - create a CPAN distribution

=head1 SYNOPSIS

 make-cpan-dist.pl options

 make-cpan-dist.pl -b buildspec.yml

=head1 DESCRIPTION

Utility that is part of a toolchain to create a CPAN distribution.

This utility should normally be called with the C<--buildspec> option
specifying a YAML file that describes the distribution to be
packaged. The toolchain can:

=over 5

=item * find Perl module dependencies in your modules and scripts

=item * create a C<Makefile.PL>

=item * package your artifacts from your project hierarchy into a CPAN distribution

=back

If the script is passed a YAML file (C<--buildspec>) then the script
will parse the build specification and call the bash script
C<make-cpan-dist> with all of the necessary flags to build a
tarball. If you do not provide a build specification this script will
only create the C<Makefile.PL> file for you.  It will be left to you
to modify the C<Makefile.PL> if necessary and then package the
artifacts into a CPAN distribution.

You can also call the bash script yourself, supplying all of the
necessary options.  When L<using the bash script|/"USING THE BASH
SCRIPT">, it will ultimately call this script to create the
C<Makefile.PL> and before creating your CPAN distribution.

=head1 OPTIONS

 -a, --author                author
 -A, --abstract              description of the module
 -B, --build-requires        build dependencies
 -b, --buildspec             read a buildspec and create command line
     --cleanup, --no-cleanup remove temp files, default: cleanup
     --create-buildspec      name of a buildspec file to create
 -d, --debug                 debug mode
     --dryrun                dryrun
     --exe-files             path to the executables list
     --extra-path            path to the extra files list
 -h, --help                  help
 -l, --log-level             ERROR, WARN, INFO, DEBUG, TRACE
 -m, --module                module name
 -M, --min-perl-version      minimum perl version to consider core, default: $PERL_VERSION
 -P, --pager, --no-pager     use a pager for help, default: use pager
     --pl-files              path to the PL_FILES list (see perldoc ExtUtils::MakeMaker)
     --postamble             name of the file containing the postamble instructions
 -p, --project-root          default: current working directory
     --recurse               whether to recurse directors when searching for files
 -r, --requires              dependency list
 -R, --require-versions      add version numbers to dependencies
     --no-require-versions   
     --scripts-path          path to the scripts listing
 -t, --test-requires         test dependencies
     --tests-path            path to the tests listing
 -s, --scandeps              use scandeps for dependency checking
 -V, --verbose               verbose output
 -v, --version               version
     --version-from          module name that provide version

This script is typically called with the C<--buildspec> option
specifying a YAML file that contains the options for building a CPAN
distribution.  Calling this script directly will only result in a
C<Makefile.PL> being written to STDOUT.

When invoked with a buildspec it will parse the YAML file and call
the bash script that actually creates the CPAN distribution.

=head1 ENVIRONMENT VARIABLES

=over 5

=item PRESERVE_MAKEFILE

Set this environment variable to a true value if you want
the script to preserve the F<Makefile.PL>. It will be copied to your
current working directory.

=item SKIP_TESTS

Set this environment variable a true value if you want
the script to preserve the F<Makefile.PL>. It will be copied to your

=item DEBUG

Set this environment variable to set the debug level to verbose. The
bash script will echo all commands run. This is useful for debugging
problems that might arise if you "go off script"

=back

 See https://github.com/rlauer6/make-cpan-dist.git for more documentation.

=head1 VERSION

1.5.46

=head1 USING THE BASH SCRIPT

Assuming you have a module named C<Foo::Bar> in a directory named
F<lib> and some tests in a directory named F<t>, you might try:

 make-cpan-dist -l lib -t t -m Foo::Bar \
  -a 'Rob Lauer <rlauer6@comcast.net>' -d 'the Foo::Bar module!'

I<NOTE: Running the Bash script in any directory of your project if it
is part of a F<git> repository will use the root of the repository as
your project home directory.  If you are not in a F<git> repository
AND do not supply the -H option (project home), then the current
directory will be considered the project home directory. This means
that options like -l will be relative to the current directory.>

=head2 Using F<buildspec.yml>

 make-cpan-dist.pl -b buildspec.yml

Calling this utility directly with the C<-b> option will parse the
buildspec and invoke the C<bash> script with all of the appropriate
options. This is the preferred way of using this toolchain. The format
of the YAML build file is described below.

I<IMPORTANT: All files specified in the F<buildspec.ym> file must be
specified as absolute paths or they should be relative to the
project's root directory, B<NOT THE CURRENT WORKING DIRECTORY!>>

=head1 OPTION DETAILS

=over 5

=item -A, --abstract

A short description of the module purpose.

=item -a, --author

When supplying the author on the command line, include the email
address in angle brackets as shown in the example.

Example: -a 'Rob Lauer <rlauer6@comcast.net>'

If this is a I<git> project then the bash script will attempt to get
your name and email from the git configuration.

=item -B, --build-requires

Name of the file that contains the dependencies for building the distribution.

=item -b, --buildspec

Name of build specification file in YAML format.  The build
specification file will be parsed and supply the necessary options to
the bash script for creating your distribution.  See L</BUILD SPECIFICATION FORMAT>.

=item -c, --cleanup

Cleanup temp directories and files.  The default is to cleanup all
temporary files, use the C<--no-cleanup> option if you want to examine
some of the temporary files.

=item -C, --create-buildspec

Name of a buildspec file to create from the options passed to this
script.

I<Note that this file may need to be modified if the options passed to
the file are not sufficient to create an acceptable buildspec.>

=item -d, --debug

Debug mode. Outputs lot's of diagnostics for debugging the
interpretation of the options passed and the F<Makefile.PL> creation
process.

=item --dryrun

Typically used when calling the bash script directly, this will output
the command to be executed and all of the options to
F<make-cpan-dist.pl>.

=item -h, --help

Print the options to F<make-cpan-dist.pl> to STDOUT. For more help try
C<make-cpan-dist -h> for the options to the bash script.

Additional information can be found
L<here|https://github.com/rlauer/make-cpan-dist>

=item -l, --log-level

Log level.

Valid values: error|warn|info|debug

default: error

=item -m, --module

Name of the Perl module to package.

=item -M, --min-perl-version

The minium version of perl to consider core when resolving dependencies.

=item -P, --pager, --no-pager

Use a pager for help.

default: --pager

=item --pl-files

Path to the PL_FILE list.

From: https://metacpan.org/pod/ExtUtils::MakeMaker

I<MakeMaker can run programs to generate files for you at build time. By
default any file named *.PL (except Makefile.PL and Build.PL) in the
top level directory will be assumed to be a Perl program and run
passing its own basename in as an argument. This basename is actually
a build target, and there is an intention, but not a requirement, that
the *.PL file make the file passed to to as an argument. For
example...>

 perl foo.PL foo

=item --postamble

Name of a file that contains the C<Makefile.PL> postamble section.

=item -p, --project-root

Root of the project to use when looking for files to package.

default: current working directory

=item --recurse

Recurse sub-directories when looking for files to package.

=item -r, --requires

Name of a file that contains the list of dependencies if other than F<requires>.

default: requires

=item -R, --require-versions, --no-require-versions

Whether to add version numbers to dependencies.

default: --require-versions

=item -s, --scandeps

Use F<scandeps.pl> for dependency checking instead of
F<scandeps-static.pl> (L<Module::ScanDeps::Static>).

default: F<scandeps-static.pl>

=item --scripts-path

Path to the file containing a list of script files.

=item -t, --test-requires

Name of the file that contains the dependencies for running tests included in your distribution if other than F<test-requires>.

default: test-requires

=item --tests-path

Path to the file containing a list of test files.

=item -V, --verbose

Verbose output.

=item -v, --version

Returns the version of this script.

=item --version-from

Name of the module that provides the package version. Defaults to the
main module being packaged.

=back


=head1 BUILD SPECIFICATION FORMAT

Example:

  version: 1.5.46
  project:
    git: https://github.com/rlauer6/perl-Amazon-Credentials
    description: "AWS credentials discoverer"
    author:
      name: Rob Lauer
      mailto: rlauer6@comcast.net
  pm_module: Amazon::Credentials
  include-version: no
  dependencies:
    resolver: scandeps
    requires: requires
    test_requires: test-requires
    required_modules: no
  path:
    recurse: yes
    pm_module: src/main/perl/lib
    tests: src/main/perl/t
    exe_files: src/main/perl/bin
  exclude_files: exclude_files
  extra: extra-files
  extra-files:
    - file
    - /usr/local/share/my-project:
      - file
  provides: provides
  postamble: postamble
  resources:
    homepage: 'http://github.com/rlauer6/perl-Amazon-API'
    bugtracker:
      web: 'http://github.com/rlauer6/perl-Amazon-API/issues'
      mailto: rlauer6@comcast.net
    repository:
      url: 'git://github.com/rlauer6/perl-Amazon-API.git'
      web: 'http://github.com/rlauer6/perl-Amazon-API'
      type: 'git'

The sections are described below:

=over 10

=item version

The version of of the specification format.  This should correspond
with the version of C<CPAN::Maker> that supports the format. It may be
used in future versions to validate the specification file.

=item project

=over 15

=item git

The path to a C<git> project. If this is included in the buildspec
then the bash script will clone that repo and use that repo as the
target of the build.  If the cloned repo includes a F<configure.ac>
file root directory the script will attempt to build the repo as a
autoconfiscated project.

 autoconf -i --force
 ./configure
 make

If F<configure.ac> is not found, the project will simply be cloned and
it will be assumed the Perl modules and artifacts to be packaged are
somewhere to be found in the project tree (as described in your
buildspec file). You should make sure that you set the C<path> section
accordingly so that the utility knows were to find your Perl modules.

I<I'm actually not sure how useful this feature is. I'm guessing that
the scenario for use might be if you have the buildspec file somewhere
other than the repo you wish to build or you don't own or don't want
to fork a project but want to build a CPAN distribution from it?>

=item description

The description of the module as it will be appear in the CPAN
repository.

=item author

The I<author> section should contain a name and email address.

=over 20

=item name

The author's name.

=item mailto

The author's email address.

=back

=back

=item pm_module

The name of the Perl module.

=item postamble

The name of a file that contains additional C<makefile> statements
that are appended to the F<Makefile> created by
F<Makefile.PL>. Typically, this will look something like:

 postamble ::

 install::
        # do something

=item include-version

If dependencies are resolved automatically, include the version
number. To disable this set this value to 'no'.

default: yes

=item dependencies

The I<dependencies> section, if present may contain the fully
qualified path to a file that contains a list of dependencies. If
the name of the file is F<cpanfile>, then the file is assumed to be in
I<cpanfile> format, otherwise the file should be a simple list of Perl
module names optionally followed by a version number.

 Amazon::Credentials 1.15

By default, the script will look for F<scandeps-static.pl> as the
dependency resolver, however you can override this by specifying the
name of program that will produce a list of modules.  If you specify
the special name I<scandeps>, the scripts will use F<scandeps.pl>.

I<NOTE: F<scandeps-static.pl> is provided by
L<Module::ScanDeps::Static> and is (at least by this author to be a
bit superior to F<scandeps.pl>.>

=over 15

=item requires

Fully qualified path to a dependency list for module.

=item test_requires

Fully qualified path to a dependency list for tests.

=item build_requires

Fully qualified path to a dependency list for build.

=item resolver (optional)

Name of a program that will provide a list of depenencies when passed
a module name. Use the special name C<scandeps> to use Perl's
C<scandeps.pl>.  When using C<scandeps.pl>, the C<-R> option will be
used to prevent C<scandeps.pl> from recursing. Neither
C</usr/lib/rpm/perl.req> or C<scandeps.pl> are completely
reliable. Your methodology might be to use these to get a good start
on a file containing dependencies and then add/subtract as required
for your use case.

When preparing the list of files to list as requirements in the
C<PREREQ_PM> section of the C<Makefile.PL>, the script will
automatically remove any modules that are already included with Perl.

=item required_modules

If the resolver should look for modules that are C<required>d by your
scripts and modules.

default: yes

=back

=item path (optional)

=over 15

=item pm_module

The path where the Perl module to be packaged can be found.  By
default, the current working directory will be searched or the root of
the search if the C<recurse> value is set to 'yes'.

default: current working directory

=item recurse (optional)

Specifies whether to or not to look in subdirectories of the path
specified by C<pm_module> for additional modules to package.

default: yes

=item tests (optional)

The path where tests to be specified in the F<Makefile.PL> will be
found.

=item exe_files

Path where executable Perl modules will be found. Files that are to be
included in the distribution must have executable permissions.

Examples:

 src/main/perl/bin
 bin/

=item scripts

Path where executable scripts (e.g. bash) will be found. Files that are to be
included in the distribution must have executable permissions.

Examples:

 src/main/bash/bin
 bin/

=back

=item provides (optional)

By default the package will specify the primary module to be packaged
and any additional modules that were found if the C<recurse> option
was set to 'yes'.

=item resources (optional)

Values to add to the I<resources> section of the META_MERGE argument
passed to L<ExtUtils::MakeMaker> when creating the F<Makefile.PL>
file.

See L<https://metacpan.org/pod/CPAN::Meta::Spec> for more details.

=item extra (optional)

Name of a file that contains a list of files to be included in the
package. These files are included in the package but not installed.

=item extra-files (optional)

List of files to be included in package.

Example:

 extra-files:
   - ChangeLog
   - README
   - examples:
     - src/examples

 extra-files:
   - ChangeLog
   - README
   - examples:
      - src/examples/foo.pl
      - src/examples/boo.pl

If you include in your C<extra-files> specification, a 'share'
directory, then that directory will be installed as part of the
distribution. The location of those files will be relative to the
distribution's share directory and can be found like this:

 perl -MFile::ShareDir=dist_dir -e 'print dist_dir("CPAN::Maker");'

The specification...

 extra-files:
   - share:
     - resources/foo.cfg

...would package the file F<foo.cg> from your project's F<resources>
directory to the distribution's share directory. While this specification...

 extra-files:
   - share/resources:
     - resources/foo.cfg

...would package the file F<foo.cfg> in the distribution's share
directory under the F<resources> directory.

I<All other files in the C<extra-files> section will be relative to
the root of the tarball but will not be installed.>

=item scripts

Array of script names or a path to the scripts that should be included in the distribution. Files should be relative to the project root.

=item exe_files

Array of Perl script names or a path to the scripts that should be included
in the distribution. Files should be relative to the project root.

=back

=head1 DEPENDENCIES

By default the script will look for dependencies in files named
F<requires> and F<test-requires>.  These can be created automatically
generated by the C<bash> script (C<make-cpan-dist>) or you can provide
them.

You can specify a different name for the files with the C<-r> and
C<-t> options.

B<You must however have a file that contains the dependency list.>

Again, if you use the C<bash> script that invokes this utility or are
calling this utility with a F<buildspec.yml> file, these files can be
I<automatically> created for you based on your options.  If you
provide your own F<requires> or F<test-requires> file, modules should
be specified as shown below unless the name of the dependency file is
L<C<cpanfile>|/"dependencies">.

  module-name version

Example:

 AWS::Signature4 1.02
 ...

=head1 AUTHOR

Rob Lauer - <rlauer6@comcast.net>

=cut

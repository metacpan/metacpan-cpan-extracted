#!perl -wT
# Copyright Dominique Quatravaux 2006 - Licensed under the same terms as Perl itself

use strict;
use warnings;
use 5.006; # "our" keyword

=head1 NAME

My::Module::Build - Helper for releasing my (DOMQ's) code to CPAN

=head1 SYNOPSIS

This module works mostly like L<Module::Build> with a few differences
highlighted below. Put this in Build.PL:

=for My::Tests::Below "synopsis" begin

  use strict;
  use warnings;

  ## Replace
  # use Module::Build;
  ## with
  use FindBin; use lib "$FindBin::Bin/inc";
  use My::Module::Build;

  ## Replace
  # my $builder = Module::Build->new(
  ## With
  my $builder = My::Module::Build->new(
     ## ... Use ordinary Module::Build arguments here ...
     build_requires =>    {
           'Acme::Pony'    => 0,
           My::Module::Build->requires_for_build(),
     },
     add_to_no_index => { namespace => [ "My::Private::Stuff" ] },
  );

  ## The remainder of the script works like with stock Module::Build

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

DOMQ is a guy who releases CPAN packages from time to time - you are
probably frobbing into one of them right now.

This module is a subclass to L<Module::Build> by Ken Williams, and a
helper that supports DOMQ's coding style for Perl modules so as to
facilitate relasing my code to the world.

=head2 How to use My::Module::Build for a new CPAN package

This part of the documentation is probably only useful to myself,
but hey, you never know - Feel free to share and enjoy!

=over

=item 1.

If not already done, prepare a skeletal CPAN module that uses
L<Module::Build> as its build support class. L<Module::Starter> and
its companion command C<module-starter(1)> is B<highly> recommended
for this purpose, e.g.

   module-starter --mb --module=Main::Screen::Turn::On \
     --author='Dominique Quatravaux' --email='domq@cpan.org' --force

=item 2.

create an C<inc/> subdirectory at the CPAN module's top level and drop
this file there. (While you are there, you could put the rest of the
My:: stuff along with it, and the t/maintainer/ test cases - see L<SEE
ALSO>.)

=item 3.

Amend the Build.PL as highlighted in the L</SYNOPSIS>.

=item 4.

B<VERY IMPORTANT!> Arrange for My::Module::Build and friends to
B<not> be indexed on the CPAN, lest the Perl deities' wrath fall upon
you. This is done by adding the following lines to the META.yml file:

=for My::Tests::Below "META.yml excerpt" begin

 no_index:
   directory:
     - examples
     - inc
     - t

=for My::Tests::Below "META.yml excerpt" end

(indentation is meaningful - "no_index:" must start at the very first
column and the indenting quantum is exactly 2 spaces, B<no tabs
allowed>)

If you prefer the META.yml file to be built automatically, do a

=for My::Tests::Below "distmeta" begin

   ./Build manifest
   ./Build distmeta

=for My::Tests::Below "distmeta" end

and the aforementioned no_index exclusions will be set up
automatically (but B<please double-check nevertheless>).

=back

=head2 Coding Style and Practices supported by this module

No, I don't want to go into silly regulations regarding whether I
should start a new line before the opening bracket in a sub
declaration. This would be coding syntax, or coding grammar. The stuff
here is about style, and only the subset thereof that is somehow under
control of the CPAN build process.

=head3 Unit tests

A large fraction of the unit tests are written as perlmodlib-style
__END__ documents attached directly to the module to test. See
L<My::Tests::Below> for details. My::Module::Build removes the test
footer at build time so as not to waste any resources on the install
target platform.

=head3 Extended C<test> action

The C<./Build test> action allows one to specify a list of individual
test scripts to run, in a less cumbersome fashion than straight
L<Module::Build>:

   ./Build test t/sometest.t lib/Foo/Bar.pm

For the developper's comfort, if only one test is specified in this
way, I<ACTION_test> assumes that I<verbose> mode is wanted (see
L<Module::Build/test>). This DWIM can be reversed on the command line:

   ./Build test verbose=0 t/sometest.t

In the case of running a single test, I<ACTION_test> also
automatically detects that we are running under Emacs' perldb mode and
runs the required test script under the Perl debugger. Running a
particular test under Emacs perldb is therefore as simple as typing:

   M-x perldb <RET> /path/to/CPAN/module/Build test MyModule.pm

If a relative path is passed (as shown), it is interpreted relative to
the current directory set by Emacs (which, except under very bizarre
conditions, will be the directory of the file currently being
edited). The verbose switch above applies here by default,
conveniently causing the test script to run in verbose mode in the
debugger.

Like the original L<Module::Build/test>, C<./Build test> accepts
supplemental key=value command line switches, as exemplified above
with C<verbose>.  Additional switches are provided by
I<My::Module::Build>:

=over

=item I<< use_blib=0 >>

Load modules from the B<source> directory (e.g. C<lib>) instead of the
build directories (e.g. C<blib/lib> and C<blib/arch>).  I use this to
debug L<Inline::C> code in a tight tweak-run-tweak-run loop, a
situation in which the MD5-on-C-code feature of L<Inline> saves a lot
of rebuilds.

=item I<full_debugging=1>

Sets the FULL_DEBUGGING environment variable to 1 while running
C<./Build test>, in addition to any environment customization already
performed by L</customize_env>.  Packages of mine that use L<Inline>
enable extra debugging when this environment variable is set.

=back

=head3 Dependent Option Graph

This feature wraps around L<Module::Build/prompt>,
L<Module::Build/get_options> and L<Module::Build/notes> to streamline
the programming of optional features into a ./Build.PL script. Here is
a short synopsis for this feature:

=for My::Tests::Below "option-graph" begin

   my $class = My::Module::Build->subclass(code => <<'CODE');

   sub install_everything: Config_Option {
       question => "Install everything",
       default => 1;
   }

   sub install_module_foo: Config_Option(type="boolean") {
       my $build = shift;
       return (default => 1) # Don't even bother asking the question
          if $build->option_value("install_everything");
       question => "Install module foo",
       default => 0;
   }

   CODE

   my $builder = $class->new(...) # See SYNOPSIS

=for My::Tests::Below "option-graph" end

Options can then be fed from the command line (e.g. C<< ./Build.PL
--gender=f >>) or by answering the questions interactively on the
terminal. I<My::Module::Build> will ask the questions at L</new>
time, in the correct order if they depend on each other (as shown in
the example), detect circular dependencies, and die if a mandatory
question does not get an appropriate answer.

=head3 Syntax

As shown above, options are methods in a subclass to
I<My::Module::Build> with a subroutine attribute of the form C<<
Config_Option(key1=value1, ...) >>. Right now the
following keys are defined:

=over

=item        I<type>

The datatype of this option, either as a word (e.g. "boolean", "integer" or
"string") or as a L<GetOpt::Long> qualifier (e.g. "!", "=s" or "=i").

The default is to guess from the name of the option: "install_foo" and
"enable_bar" are supposed to be booleans, "baz_port" an integer, and
everything else a string.

=back

The name of the method is the internal key for the corresponding
option (e.g. for L</option_value>). It is also the name of the
corresponding command-line switch, except that all underscores are
converted to dashes.

The method shall return a (key, value) "flat hash" with the following
keys recognized:

=over

=item        I<question>

The question to ask, as text. A question mark is appended
automatically for convenience if there isn't already one. If no
question is set, I<My::Module::Build> will not ask anything for this
question even in interactive mode, and will attempt to use the default
value instead (see below).

=item        I<default>

In batch mode, the value to use if none is available from the command
line or the persisted answer set from previous attempts to run
./Build.PL. In interactive mode, the value to offer to the user as the
default.

=item       I<mandatory>

A Boolean indicating whether answering the question with a non-empty
value is mandatory (see also L</prompt> for a twist on what
"non-empty" exactly means). The default mandatoryness is 1 if
I<default> is not returned, 0 if I<default> is returned (even with an
undef value).

=back

=head1 REFERENCE

=cut

package My::Module::Build;
use strict;
use warnings;
use base "Module::Build";

use IO::File;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile catdir splitpath splitdir);
use File::Basename qw(dirname);
use File::Spec::Unix ();
use File::Find;

=begin internals

=head2 Global variables

=head3 $running_under_emacs_debugger

Set by L</_massage_ARGV> if (you guessed it) we are currently running
under the Emacs debugger.

=cut

our $running_under_emacs_debugger;

=head2 Constants

=head3 is_win32

Your usual bugware-enabling OS checks.

=cut

use constant is_win32 => scalar($^O =~ /^(MS)?Win32$/);

=head2 read_file($file)

=head2 write_file($file, @lines)

Like in L<File::Slurp>.

=cut

sub read_file {
  my ($filename) = @_;
  defined(my $file = IO::File->new($filename, "<")) or die <<"MESSAGE";
Cannot open $filename for reading: $!.
MESSAGE
  return wantarray? <$file> : join("", <$file>);
}

sub write_file {
  my ($filename, @contents) = @_;
  defined(my $file = IO::File->new($filename, ">")) or die <<"MESSAGE";
Cannot open $filename for writing: $!.
MESSAGE
  ($file->print(join("", @contents)) and $file->close()) or die <<"MESSAGE";
Cannot write into $filename: $!.
MESSAGE
}

=end internals

=head2 Constructors and Class Methods

These are intended to be called directly from Build.PL

=over

=item I<new(%named_options)>

Overloaded from parent class in order to call
L</check_maintainer_dependencies> if L</maintainer_mode_enabled> is
true.  Also sets the C<recursive_test_files> property to true by
default (see L<Module::Build/test_files>), since I like to store
maintainer-only tests in C<t/maintainer> (as documented in
L</find_test_files>).

In addition to the %named_options documented in L<Module::Build/new>,
I<My::Module::Build> provides support for the following switches:

=over

=item I<< add_to_no_index => $data_structure >>

Appends the aforementioned directories and/or namespaces to the list
that L</ACTION_distmeta> stores in META.yml.  Useful to hide some of
the Perl modules from the CPAN index.

=back

=cut

sub new {
    my ($class, %opts) = @_;
    $opts{recursive_test_files} = 1 if
        (! defined $opts{recursive_test_files});
    my $self = $class->SUPER::new(%opts);
    if ($self->maintainer_mode_enabled()) {
        print "Running specific maintainer checks...\n";
        $self->check_maintainer_dependencies();
    }
    $self->_process_options;
    $self;
}

=item I<requires_for_build()>

Returns a list of packages that are required by I<My::Module::Build>
itself, and should therefore be appended to the C<build_requires> hash
as shown in L</SYNOPSIS>.

=cut

sub requires_for_build {
       ('IO::File'              => 0,
        'File::Path'            => 0,
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'File::Spec::Unix'      => 0,
        'File::Find'            => 0,
        'Module::Build'         => 0,
        'Module::Build::Compat' => 0,
        'FindBin'               => 0, # As per L</SYNOPSIS>

        # The following are actually requirements for tests:
        'File::Temp' => 0,  # for tempdir() in My::Tests::Below
        'Fatal' => 0, # Used to cause tests to die early if fixturing
                      # fails, see sample in this module's test suite
                      # (at the bottom of this file)
       );
}

{
    no warnings "once";
    *requires_for_tests = \&requires_for_build; # OBSOLETE misnomer
}

=item I<maintainer_mode_enabled()>

Returns true iff we are running "./Build.PL" or "./Build" off a
revision control system of some kind. Returns false in all other
situations, especially if we are running on an untarred package
downloaded from CPAN.

=cut

sub maintainer_mode_enabled {
    my $self = shift;
    foreach my $vc_dir (qw(CVS .svn .hg .git)) {
        return 1 if -d catdir($self->base_dir, $vc_dir);
    }
   
    my $full_cmd = sprintf("yes n | svk info '%s' 2>%s",
                           catdir($self->base_dir, "Build.PL"),
                           File::Spec->devnull);
    `$full_cmd`; return 1 if ! $?;

    return 0;
}

=item I<check_maintainer_dependencies()>

Checks that the modules required for B<modifying> the CPAN package are
installed on the target system, and displays a friendly, non-fatal
message otherwise. This method is automatically run from L</new> if
appropriate (that is, if L</maintainer_mode_enabled> is true).

=cut

sub check_maintainer_dependencies {
    my $self = shift;
    unless ($self->check_installed_status('YAML', 0)->{ok})
        { $self->show_warning(<<"MESSAGE"); }

The YAML module from CPAN is missing on your system.

YAML is required for the "./Build distmeta" operation. You have to run
that command to regenerate META.yml every time you add a new .pm,
change dependencies or otherwise alter the namespace footprint of this
CPAN package. You will therefore only be able to contribute small
bugfixes until you install YAML.

MESSAGE
    foreach my $testmod (qw(Test::NoBreakpoints
                            Test::Pod Test::Pod::Coverage)) {
        unless ($self->check_installed_status($testmod, 0)->{ok})
            { $self->show_warning(<<"MESSAGE")};

The $testmod module from CPAN is missing on your system.

One of the tests in t/maintainer will fail because of that.  Please
install the corresponding module to run the full test suite.

MESSAGE
    }
}

=item I<show_warning($message)>

Displays a multi-line message $message to the user, and prompts
him/her to "Press RETURN to continue".

=cut

sub show_warning {
    my ($self, $message) = @_;
    $message = "\n$message" until ($message =~ m/^\n\n/);
    $message .= "\n" until ($message =~ m/\n\n$/);
    warn $message;
    $self->prompt("Press RETURN to continue");
    1;
}

=item I<show_fatal_error($message)>

Like L</show_warning>, but throws an exception after displaying
$message.

=cut

sub show_fatal_error {
    my ($self, $message) = @_;
    $self->show_warning($message);
    die "Fatal error, bailing out.\n";
}

=back

=head2 Methods

These are intended to be called directly from Build.PL

=over

=item I<topir>

Returns the directory in which C<Build.PL> resides.

=cut

sub topdir {
    # TODO: probably not good enough in some cases.
    require FindBin;
    no warnings "once";
    return $FindBin::Bin;
}

=item I<package2filename($packagename)>

Converts $packagename (e.g. C<Foo::Bar>) into its OS-specific notation
(e.g. C<Foo/Bar.pm>).

=cut

sub package2filename {
    my ($self, $package) = @_;
    my @components = split m/::/, $package;
    $components[$#components] .= ".pm";
    return catfile(@components);
}

=item I<process_Inline_C_file($filename, @preload_modules)>

Arranges for L<Inline::C> code contained in $filename to be compiled
into .bs's and .so's.  @preload_modules is a list of Perl packages (in
Perl C<use> notation, eg C<Foo::Bar> instead of C<Foo/Bar.pm>) that
should be loaded with C<use> before starting the L<Inline> install
process.  Uses a stamp file in C<blib/stamp> to avoid compiling anew
if neither $filename nor @preload_modules changed.

=cut

sub process_Inline_C_file {
    my ($self, $filename, @preload_modules) = @_;

    my $stampfile = do {
        my ($volume, $dir, $base) = splitpath($filename);
        catfile(qw(blib stamp Inline-C),
                 join("_", splitdir($dir), $base));
    };
    return if $self->up_to_date
                ([$filename,
                  map { catfile("lib", $self->package2filename($_)) }
                  @preload_modules], [$stampfile]);

    # Remove any leftovers from a (failed) previous run.
    do { unlink($_) or die "Cannot unlink($_): $!" } for glob("*.inl");

    # And now some ugly kludge to make everything hold together.
    # Inline::C wants to use MakeMaker; we don't.  So let's call it in
    # a sub-Perl.
    my $version = $self->dist_version;
    my $module_name = $self->module_name;

    my $script = <<"SET_VERSION";
BEGIN { \$${module_name}::VERSION = '$version' ; }
SET_VERSION
    $script .= "use $_; " foreach (@preload_modules);
    $script .= <<"ACTIVATE_INLINE_COMPILE";
use Inline qw(_INSTALL_);
require "$filename";
ACTIVATE_INLINE_COMPILE
    $script =~ s/\n/ /g;

    my @cmdline = ($^X, "-I" => catdir($self->topdir, "lib"),
                   -e => $script, $version, catdir(qw(blib arch)));
    warn(join(" ", @cmdline, "\n"));
    local %ENV = $self->customize_env(%ENV);
    system(@cmdline);
    die "Command exited with status " . ($? >> 8) if $?;

    # Remove the leftovers again.
    do { unlink($_) or die "Cannot unlink($_): $!" } for glob("*.inl");
    rmdir("arch");

    # Update timestamp
    if (! -d (my $stampdir = dirname($stampfile))) {
        mkpath($stampdir, 0, 0777)
            or die "cannot create directory $stampdir: $!";
    }
    local *STAMP;
    open(STAMP, ">>", $stampfile)
        or die "cannot create or update timestamp file $stampfile: $!";
    close(STAMP);
    utime((time) x 2, $stampfile);
}

=item I<use_blib()>

=item I<use_blib($boolean)>

Returns false if the user specified C<use_blib=0> on the command line,
and true otherwise.  See L</Extended C<test> action> for details.  The
form with a parameter allows one to set the value that will
subsequently be returned by I<use_blib>, thereby overriding the
command line.

=cut

sub use_blib {
    my $self = shift;
    if (! @_) {
        return 1 if (! exists $self->{args}->{use_blib});
        return ! ! $self->{args}->{use_blib};
    } else {
        $self->{args}->{use_blib} = ! ! shift;
    }
}

=back

=head2 Dependent Option Graph Methods

=cut

# These "use" statements are specific to the dependent option graph
# to facilitate refactoring.
use Getopt::Long;
use Carp;
use overload; # for overload::StrVal

=over

=item I<option_value($optionname)>

Returns the value selected for the option $optionname. From within an
option declaration sub, this call may result in the question for
$optionname (and its own dependencies, recursively) being asked on
the terminal at once. If a loop is detected so doing,
I<option_value()> will die with a messsage that starts with the word
"RECURSION".

Answers to questions are persisted using Module::Build's I<< ->notes
>> mechanism: outside the option declaration subs,
I<option_value("foo-bar")> is therefore an alias for
I<notes("option:foo_bar")>.

=cut

sub option_value {
    my ($self, $key) = @_;
    $key =~ s/-/_/g;
    my $noteskey = "option:$key";
    my $cached = $self->notes($noteskey);
    return $cached if defined $cached;
    my $answer = $self->_option_value_nocache($key);
    $self->notes($noteskey, $answer);
    return $answer;
}

=begin internals

=item I<MODIFY_CODE_ATTRIBUTES($package, $coderef, @attrs)>

Automatically invoked by Perl when parsing subroutine attributes (see
L</attributes>); parses and stores the C<Config_Option> attributes
described in L</Syntax for the option declarations>.

=cut

our %declared_options; our %option_type;
sub MODIFY_CODE_ATTRIBUTES {
    my ($package, $coderef, @attrs) = @_;
    $coderef = overload::StrVal($coderef);
    my @retval;
    ATTRIBUTE: foreach my $attr (@attrs) {
        unless ($attr =~ m/^\s*Config_Option\s*(?:|\(([^()]*)\))\s*$/) {
            push @retval, $attr; # Pass to downstream handlers
            next ATTRIBUTE;
        }
        $declared_options{$coderef}++;
        next ATTRIBUTE if ! defined $1; # No keys / values
        foreach my $keyval (split qr/\s*,\s*/, $1) {
            if ($keyval =~ m/^type\s*=\s*(\S+)\s*$/) {
                my $type = $1;
                $type =~ s/^"(.*)"$/$1/s;
                $type =~ s/^'(.*)'$/$1/s;
                my %canonicaltype =
                    ( (map { $_ => "string"  } qw(=s string)),
                      (map { $_ => "integer" } qw(=i int integer)),
                      (map { $_ => "boolean" } qw(! bool boolean)),
                    );
                defined ($option_type{$coderef} = $canonicaltype{$type})
                    or die qq'Bad type "$type" in attribute "$attr"';
            } else {
                die qq'Unknown key "$keyval" in attribute "$attr"';
            }
        }
    }
    return @retval;
}

=item I<_option_value_nocache($key)>

The workhorse behind L</option_value>, which is just a caching wrapper.

=cut

sub _option_value_nocache {
    my ($self, $key) = @_;

    # return $self->_option_default_value($key) if
    #         ($self->_option_phase($key) ne $self->{phase});

    do { # Look at command line
        my $keyopt = lc($key); $keyopt =~ s/_/-/g;

        my %type2getopt = ("string" => "=s", "integer" => "=i",
                           "boolean" => "!");
        my $getopt = new Getopt::Long::Parser(config => [qw(pass_through)]);
        my $type = $self->_option_type($key);
        my $retval;
        $getopt->getoptions($keyopt . $type2getopt{$type} => \$retval)
        or die "Bad value for --$keyopt command-line option".
            " (expected $type)\n";
        if (defined $retval) {
            $self->_option_check_value($key, \$retval);
            return $retval;
        }
    };

    my $default = $self->_option_default_value($key);

    if (defined(my $question = $self->_option_question($key))) { # Ask user
        if ($self->_option_type($key) eq "boolean") {
            $default = $default ? "yes" : "no";
        }

        ASK_AGAIN: {
            my $answer = $self->prompt($question, $default);
            my $problem = $self->_option_check_value($key, \$answer);
            return $answer if (! $problem);

            if (-t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT))) {
                warn $problem;
                redo ASK_AGAIN;
            } else {
                die $problem;
            }
        }
    };
    return $default;
}

=item I<_option_type($key)>

Returns the type for option $key (either "boolean", "integer" or
"string"), or undef if no such option exists.

=cut

sub _option_type {
    my ($self, $key) = @_;
	croak "Unknown question $key" unless (my $meth = $self->can($key));
    my $type = $option_type{overload::StrVal($meth)};
    $type ||= $key =~ m/^(install_|enable_)/ ? "boolean" :
              $key =~ m/(_port)$/ ? "integer" :
              "string";
    return $type;
}

=item I<_option_is_mandatory($key)>

Returns true if a value is mandatory for $key; always false in the
case of a boolean.

=cut

sub _option_is_mandatory {
    my ($self, $key) = @_;
    return if $self->_option_type eq "boolean";
    my $t = $self->_option_compute_template($key);
    return $t->{mandatory} if exists $t->{mandatory};
    return (exists $t->{default});
}

=item I<_option_default_value($key)>

Returns the option's default value, taken either from the answers from
the previous run of Build.PL (if available) or from the option
template method's return value.

=cut

sub _option_default_value {
    my ($self, $key) = @_;
    my $previousrun = $self->notes("option:$key");
    return $previousrun if defined $previousrun;
    return $self->_option_compute_template($key)->{default};
}

=item I<_option_question($key)>

Returns the question to ask interactively in order to get a value for
option $key. The return value may be undef, indicating that the
question shall not be asked interactively.

=cut

sub _option_question {
    my ($self, $key) = @_;
    my $question = $self->_option_compute_template($key)->{question};
    return if ! defined $question;
    $question .= '?' unless ($question =~ m/\?/);
    return $question;
}

=item I<_option_compute_template($key)>

Returns a reference to a hash with keys C<mandatory>, C<default> and
C<question> according to what the option template method
returned. Arranges to run the template method only once.

=cut

sub _option_compute_template {
    my ($self, $key) = @_;

    return $self->{"option_template"}->{$key} if
        (exists $self->{"option_template"}->{$key});

	croak "Unknown question $key" unless (my $meth = $self->can($key));
    return ($self->{"option_template"}->{$key} =  { $meth->($self) });
}

=pod

=item I<_option_check_value($key, $answerref)>

Checks that the answer pointed to by $answerref matches the relevant
invariants (namely type and mandatoryness). $$answerref may not be
undef. It is canonicalized through in-place modification if need be
(e.g. "yes" becomes 1 for booleans). In scalar context, returns undef
if all went well or a warning message as text. In void context and in
case of a problem, raises this same warning message as an exception.

=cut

sub _option_check_value {
    my ($self, $key, $answerref) = @_;
    my $problem;
    my $type = $self->_option_type($key);
    if (! defined $$answerref) {
        $problem = "Internal error: \$\$answerref may not be undef";
    } elsif ($type eq "boolean") {
        $$answerref = 0 if (! $$answerref);
        $$answerref =~ s/(yes|y|true)/1/i;
        $$answerref =~ s/(no|n|false)/0/i;
        $problem = "Option $key expects a boolean value"
            unless ($$answerref =~ m/^\s*(0|1)\s*$/);
        $$answerref = $1;
    } elsif (! length $$answerref) {
        $problem = "Option $key is mandatory" if
            $self->_option_is_mandatory($key);
    } elsif ($type eq "integer") {
        $problem = "Option $key expects an integer"
            unless ($$answerref =~ m/^\s*(-?\d+)\s*$/);
        $$answerref = $1;
    }
    die $problem if ($problem && ! defined wantarray);
    return $problem;
}

=item I<_process_options()>

Runs L</option_value> for all known options, which in turn causes the
command line switches to be processed and/or all appropriate
interactive questions to be asked and answered.

=cut

sub _process_options {
    my ($self) = @_;

    # Walks @ISA looking for the names of all methods that are
    # command-line options. Inspired from DB::methods_via in
    # perl5db.pl
    my $walk_isa; $walk_isa = sub {
        my ($class, $seenref, $resultref) = @_;
        return if $seenref->{$class}++;
        my $symtab = do { no strict "refs"; \%{"${class}::"}; };
        push @$resultref, grep {
            my $symbol = $symtab->{$_};
            ref(\$symbol) eq "GLOB" && defined(*{$symbol}{CODE}) &&
              $declared_options{overload::StrVal(*{$symbol}{CODE})};
        } (keys %$symtab);

        no strict "refs";
        $walk_isa->($_, $seenref, $resultref) foreach @{"${class}::ISA"};
    };
    my @alloptions; $walk_isa->( (ref($self) or $self), {}, \@alloptions);
    $self->option_value($_) foreach @alloptions;
    return @alloptions;
}

=end internals

=back

=head2 Other Public Methods

Those methods will be called automatically from within the generated
./Build, but on the other hand one probably shouldn't call them
directly from C<Build.PL> .  One may wish to overload some of them in
a package-specific subclass, however.

=over

=item I<ACTION_build>

Overloaded to add L</ACTION_buildXS> as a dependency.

=cut

sub ACTION_build {
    my $self = shift;

    $self->depends_on("buildXS");
    $self->SUPER::ACTION_build(@_);
}

=item I<ACTION_dist>

Overloaded so that typing C<./Build dist> does The Right Thing and
regenerates everything that is needed in order to create the
distribution tarball. This includes the C<Makefile.PL> if so requested
(see L<Module::Build::Compat/create_makefile_pl>) and the C<MANIFEST>
file (see L<Module::Build/manifest>).  On the other hand, the
C<META.yml> file is not regenerated automatically, so that the author
has the option of maintaining it by hand.

=cut

sub ACTION_dist {
    my $self = shift;

    $self->do_create_makefile_pl if $self->create_makefile_pl;
    $self->do_create_readme if $self->create_readme;
    $self->depends_on("manifest");

    $self->SUPER::ACTION_dist(@_);
}

=item I<ACTION_buildXS>

Does nothing.  Intended for overloading by packages that have XS code,
which e.g. may want to call L</process_Inline_C_file> there.

=cut

sub ACTION_buildXS { }

=item I<ACTION_test>

Overloaded to add t/lib and t/inc to the test scripts' @INC (we
sometimes put helper test classes in there), and also to implement the
features described in L</Extended C<test> action>.  See also
L</_massage_ARGV> for more bits of the Emacs debugger support code.

=cut

sub ACTION_test {
    my $self = shift;

    # Tweak @INC (done this way, works regardless of whether we'll be
    # doing the harnessing ourselves or not)
    local @INC = (@INC, catdir($self->base_dir, "t", "lib"),
                  catdir($self->base_dir, "t", "inc"));

    # use_blib feature, part 1:
    $self->depends_on("buildXS") if $self->use_blib;

    my @files_to_test = map {
        our $initial_cwd; # Set at BEGIN time, see L<_startperl>
        File::Spec->rel2abs($_, $initial_cwd)
    } (@{$self->{args}->{ARGV} || []});

    if ($running_under_emacs_debugger && @files_to_test == 1) {
        # We want to run this script under a slave_editor debugger, so
        # as to implement the documented trick. The simplest way
        # (although inelegant) is to bypass Module::Build and
        # Test::Harness entirely, and run the child Perl
        # ourselves. Most of the code below was therefore cobbled
        # together from the real T::H version 2.40 and M::B 0.26
        $self->depends_on('code'); # As in original ACTION_test

        # Compute adequate @INC for sub-perl:
        my @inc = do { my %inc_dupes; grep { !$inc_dupes{$_}++ } @INC };
        if (is_win32) { s/[\\\/+]$// foreach @inc; }
        # Add blib/lib and blib/arch like the original ACTION_test does:
        if ($self->use_blib) {
            unshift @inc, catdir($self->base_dir(), $self->blib, 'lib'),
                catdir($self->base_dir(), $self->blib, 'arch');
        } else {
            unshift @inc, catdir($self->base_dir(), 'lib');
        }
        # Parse shebang line to set taintedness properly:
        local *TEST;
        open(TEST, $files_to_test[0]) or die
            "Can't open $files_to_test[0]. $!\n";
        my $shebang = <TEST>;
        close(TEST) or print "Can't close $files_to_test[0]. $!\n";
        my $taint = ( $shebang =~ /^#!.*\bperl.*\s-\w*([Tt]+)/ );
        my ($perl) = ($^X =~ m/^(.*)$/); # Untainted
        system($perl, "-d",
               ($taint ? ("-T") : ()),
               (map { ("-I" => $_) } @inc),
               $files_to_test[0], "-emacs");
        return;
    }

    # Localize stuff in order to fool our superclass for fun & profit

    local %ENV = $self->customize_env(%ENV);

    local $self->{FORCE_find_test_files_result}; # See L</find_test_files>
    $self->{FORCE_find_test_files_result} = \@files_to_test if
        @files_to_test;
    # DWIM for ->{verbose} (see POD)
    local $self->{properties} = { %{$self->{properties}} };
    if (@files_to_test == 1) {
        $self->{properties}->{verbose} = 1 if
            (! defined $self->{properties}->{verbose});
    }

    # use_blib feature, cont'd:
    no warnings "once";
    local *blib = sub {
        my $self = shift;

        return File::Spec->curdir if ! $self->use_blib;
        return $self->SUPER::blib(@_);
    };


    $self->SUPER::ACTION_test(@_);
}

=item I<ACTION_distmeta>

Overloaded to ensure that .pm modules in inc/ don't get indexed and
that the C<add_to_no_index> parameter to L</new> is honored.

=cut

sub ACTION_distmeta {
    my $self = shift;

    eval { require YAML } or die ($@ . <<"MESSAGE");

YAML is required for distmeta to produce accurate results. Please
install it and re-run this command.

MESSAGE

    # Steals a reference to the YAML object that will be constructed
    # by the parent class (duhh)
    local our $orig_yaml_node_new = \&YAML::Node::new;
    local our $node;
    no warnings "redefine";
    local *YAML::Node::new = sub {
        $node = $orig_yaml_node_new->(@_);
    };

    my $retval = $self->SUPER::ACTION_distmeta;
    die "Failed to steal the YAML node" unless defined $node;

    $node->{no_index} = $self->{properties}->{add_to_no_index} || {};
    $node->{no_index}->{directory} ||= [];
    unshift(@{$node->{no_index}->{directory}}, qw(examples inc t),
            (map { File::Spec::Unix->catdir("lib", split m/::/) }
             (@{$node->{no_index}->{namespace} || []})));

    foreach my $package (keys %{$node->{provides}}) {
        delete $node->{provides}->{$package} if
            (grep {$package =~ m/^\Q$_\E/}
             @{$node->{no_index}->{namespace} || []});
        delete $node->{provides}->{$package} if
            (grep {$package eq $_}
             @{$node->{no_index}->{package} || []});
    }

    my $metafile =
        $self->can("metafile") ? # True as of Module::Build 0.2805
            $self->metafile() : $self->{metafile};
    # YAML API changed after version 0.30
    my $yaml_sub =
        ($YAML::VERSION le '0.30' ? \&YAML::StoreFile : \&YAML::DumpFile);
    $yaml_sub->($metafile, $node)
        or die "Could not write to $metafile: $!";
;
}

=item I<customize_env(%env)>

Returns a copy of %env, an environment hash, modified in a
package-specific fashion.  To be used typically as

   local %ENV = $self->customize_env(%ENV);

The default implementation sets PERL_INLINE_BUILD_NOISY to 1 and also
sets FULL_DEBUGGING if so directed by the command line (see L</
ACTION_test>).

=cut

sub customize_env {
    my ($self, %env) = @_;
    delete $env{FULL_DEBUGGING};

    $env{PERL_INLINE_BUILD_NOISY} = 1;
    $env{FULL_DEBUGGING} = 1 if ($self->{args}->{full_debugging});
    return %env;
}

=item I<process_pm_files>

Called internally in Build to convert lib/**.pm files into their
blib/**.pm counterpart; overloaded here to remove the test suite (see
L</Unit tests>) and standardize the copyright of the files authored by
me.

=cut

sub process_pm_files {
    no warnings "once";
    local *copy_if_modified = \*process_pm_file_if_modified;
    my $self = shift;
    return $self->SUPER::process_pm_files(@_);
}

=item I<process_pm_file_if_modified(%args)>

Does the same as L<copy_file_if_modified> (which it actually replaces
while L<process_pm_files> runs), except that the L</new_pm_filter> is
applied instead of performing a vanilla copy as L<Module::Build> does.

=cut

sub process_pm_file_if_modified {
    my ($self, %args) = @_;
    my ($from, $to) = @args{qw(from to)};
    return if $self->up_to_date($from, $to); # Already fresh

    mkpath(dirname($to), 0, 0777);

    # Do a filtering copy
    print "$from -> $to\n" if $args{verbose};
    die "Cannot open $from for reading: $!\n" unless
        (my $fromfd = new IO::File($from, "r"));
    die "Cannot open $to for writing: $!\n" unless
        (my $tofd = new IO::File($to, "w"));

    my $filter = $self->new_pm_filter;
    while(my $line = <$fromfd>) {
        my $moretext = $filter->filter($line);
        if (defined($moretext) && length($moretext)) {
            $tofd->print($moretext) or
                die "Cannot write to $to: $!\n";
        }
        last if $filter->eof_reached();
    }
    $tofd->close() or die "Cannot close to $to: $!\n";
}

=item I<new_pm_filter>

Creates and returns a fresh filter object (see
L</My::Module::Build::PmFilter Ancillary Class>) that will be used by
L</process_pm_file_if_modified> to process the text of the .pm files.
Subclasses may find it convenient to overload I<new_pm_filter> in
order to provide a different filter.  The filter object should obey
the API set forth in L</My::Module::Build::PmFilter Ancillary Class>,
although it need not inherit from same.

=cut

sub new_pm_filter { My::Module::Build::PmFilter->new }

=item I<find_test_files()>

Overloaded from parent class to treat all .pm files in C<lib/> and
C<t/lib/> as unit tests if they use L<My::Tests::Below>, to look for
C<.t> files in C<examples/>, and to retain C<.t> test files in
C<t/maintainer> if and only if L</maintainer_mode_enabled> is true.

=cut

sub find_test_files {
    my $self = shift;

    # Short-cut activated by L</ACTION_test>:
    return $self->{FORCE_find_test_files_result} if
        (defined $self->{FORCE_find_test_files_result});

    my @tests = @{$self->SUPER::find_test_files(@_)};
    # Short-cut activated by putting a 'test_files' key in the constructor
    # arguments:
    return @tests if $self->{test_files};

    @tests = grep { ! m/^t.maintainer/ } @tests unless
        ($self->maintainer_mode_enabled());

    File::Find::find
        ({no_chdir => 1, wanted => sub {
              push(@tests, $_) if $self->find_test_files_predicate();
          }}, $self->find_test_files_in_directories);

    return \@tests;
}

=item I<find_test_files_predicate()>

=item I<find_test_files_in_directories()>

Those two methods are used as callbacks by L</find_test_files>;
subclasses of I<My::Module::Build> may therefore find it convenient to
overload them.  I<find_test_files_in_directories> should return a list
of the directories in which to search for test files.
I<find_test_files_predicate> gets passed the name of each file found
in these directories in the same way as a L<File::Find> C<wanted> sub
would (that is, using $_ and B<not> the argument list); it should
return a true value iff this file is a test file.

=cut

sub find_test_files_predicate {
    my ($self) = @_;
    return 1 if m/My.Tests.Below\.pm$/;
    return if m/\b[_.]svn\b/; # Subversion metadata
    return 1 if m/\.t$/;
    my $module = catfile($self->base_dir, $_);
    local *MODULE;
    unless (open(MODULE, "<", $module)) {
        warn "Cannot open $module: $!";
        return;
    }
    return 1 if grep {
        m/^require\s+My::Tests::Below\s+unless\s+caller/
    } (<MODULE>);
    return;
}

sub find_test_files_in_directories {
    grep { -d } ("lib", catdir("t", "lib"), "examples");
}

=back

=begin internals

=head1 INTERNAL DOCUMENTATION

This section describes how My::Module::Build works internally. It
should be useful only to people who intend to modify it.

=over

=item I<My::Module::Build::do_create_makefile_pl>

=item I<My::Module::Build::HowAreYouGentlemen::fake_makefile>

Overloaded respectively from L<Module::Build::Base> and
L<Module::Build::Compat> so that typing

=for My::Tests::Below "great justice" begin

   perl Makefile.PL
   make your time

=for My::Tests::Below "great justice" end

produces a helpful message in packages that have a Makefile.PL (see
L<Module::Build/create_makefile_pl> for how to do that). You won't get
signal if you use a "traditional" style Makefile.PL (but on the other
hand the rest of I<My::Module::Build> will not work either, so don't
do that).

This easter egg was a feature of an old GNU-make based build framework
that I created in a former life.  So there.

=cut

sub do_create_makefile_pl {
  my ($self, %args) = @_;
  warn("Cannot take off any Zig, sorry"),
      return $self->SUPER::do_create_makefile_pl(%args) if ($args{fh});
  $args{file} ||= 'Makefile.PL';
  my $retval = $self->SUPER::do_create_makefile_pl(%args);
  my $MakefilePL = read_file($args{file});
  $MakefilePL = <<'PREAMBLE' . $MakefilePL;
use FindBin qw($Bin);
use lib "$Bin/inc";
PREAMBLE
  $MakefilePL =~ s|Module::Build::Compat->write_makefile|My::Module::Build::HowAreYouGentlemen->write_makefile|;
  write_file($args{file}, $MakefilePL);
  return $retval;
}

{
    package My::Module::Build::HowAreYouGentlemen;
    our @ISA=qw(Module::Build::Compat); # Do not explicitly load it because
    # Makefile.PL will set up us the Module::Build::Compat itself (and
    # also we want to take off every zig of bloat when
    # My::Module::Build is loaded from elsewhere). Moreover, "use
    # base" is not yet belong to us at this time.

    sub fake_makefile {
        my $self = shift;
        return $self->SUPER::fake_makefile(@_). <<'MAIN_SCREEN_TURN_ON';
# In 2101 AD war was beginning...
your:
	@echo
	@echo -n "     All your codebase"

time:
	@echo " are belong to us !"
	@echo

MAIN_SCREEN_TURN_ON
    }
}

=head2 Overloaded Internal Methods

Yeah I know, that's a pretty stupid thing to do, but that's the best I
could find to get Module::Build to do my bidding.

=over

=item I<subclass(%named_arguments)>

Overloaded from L<Module::Build::Base> to set @ISA at compile time and
to the correct value in the sub-classes generated from the C<< code >>
named argument. We need @ISA to be set up at compile-time so that the
method attributes work correctly; also we work around a bug present in
Module::Build 0.26 and already fixed in the development branch whence,
ironically, ->subclass does not work from a subclass.

=cut

sub subclass {
    my ($pack, %opts) = @_;

    $opts{code} = <<"KLUDGE_ME_UP" if defined $opts{code};
# Kludge inserted by My::Module::Build to work around some brokenness
# in the \@ISA setup code above:
use base "My::Module::Build";
our \@ISA;
BEGIN { our \@ISAorig = \@ISA; }
\@ISA = our \@ISAorig;

$opts{code}
KLUDGE_ME_UP

    return $pack->SUPER::subclass(%opts);
}

=item I<_startperl>

Overloaded from parent to attempt a chdir() into the right place in
./Build during initialization. This is an essential enabler to the
Emacs debugger support (see L</ACTION_test>) because we simply cannot
tell where Emacs will be running us from.

=cut

sub _startperl {
    my $self = shift;
    my $basedir = $self->base_dir;
    $basedir = Win32::GetShortPathName($basedir) if is_win32;
    return $self->SUPER::_startperl(@_) . <<"MORE";

# Hack by My::Module::Build to give the Emacs debugger one
# more chance to work:
use Cwd;
BEGIN {
  \$My::Module::Build::initial_cwd = \$My::Module::Build::initial_cwd =
    Cwd::cwd;
  chdir("$basedir") || 1;
}
MORE
}

=item I<_packages_inside($file)>

Returns a list of Perl packages to be found inside $file. Overloaded
from the parent class so as to refrain from parsing after the __END__
marker.

=cut

sub _packages_inside {
    # Copied 'n modified from the parent class, doubleplusshame on me!
    my ($self, $file) = @_;
    my $fh = IO::File->new($file) or die "Can't read $file: $!";
    my @packages;

    while(my (undef, $p) = $self->_next_code_line
          ($fh, qr/^(?:__END__$|__DATA__$|[\s\{;]*package\s+([\w:]+))/)) {
        last if ! defined $p;
        push @packages, $p;
    }
    return @packages;
}

=back

=head2 Other Private Methods

=over

=item I<_massage_ARGV($ref_to_ARGV)>

Called as part of this module's startup code, in order to debogosify
the @ARGV array (to be passed as a reference) when we are invoked from
Emacs' M-x perldb. L</ACTION_test> will afterwards be able to take
advantage of the Emacs debugger we run under, by bogosifying the
command line back before invoking the script to test.

=cut

_massage_ARGV(\@ARGV);
sub _massage_ARGV {
    my ($argvref) = @_;
    my @argv = @$argvref;

    return unless ($ENV{EMACS} && (grep {$_ eq "-emacs"} @argv));

    $running_under_emacs_debugger = 1;

    @argv = grep { $_ ne "-emacs" } @argv;
    shift @argv if $argv[0] eq "-d"; # Was gratuitously added by former Emacsen

    # XEmacs foolishly assumes that the second word in the perldb
    # line is a filename and turns it into e.g. "/my/path/test":
     (undef, undef, $argv[0]) = File::Spec->splitpath($argv[0]);

    @$argvref = @argv;
}

=back

=head2 My::Module::Build::PmFilter Ancillary Class

This ancillary class, serving both as an object-oriented interface and
as a default implementation thereof, is the workhorse behind
L</process_pm_files> and L</process_pm_file_if_modified>. It consists
of a very simple filter API to transform the text of .pm files as they
are copied over from lib/ to blib/ during the build process. The
base-class implementation simply replaces copyright placeholders of
the form "(C) DOMQ" with appropriate legalese, and removes the
L<My::Tests::Below> test suite if one is found.

Subclasses of I<My::Module::Build> need only overload
L</new_pm_filter> in order to provide a different implementation of
this .pm filter. The object returned by said overloaded
I<new_pm_filter> needs only obey the API documented below for methods
I<filter> and I<eof_reached>; it may or may not elicit to inherit from
I<My::Module::Build::PmFilter> in order to do so.

=over

=cut

package My::Module::Build::PmFilter;

=item I<new()>

Object constructor. Does nothing in the base class.

=cut

sub new { bless {}, shift }

=item I<filter($line)>

Given $line, a line read from a .pm file in lib, returns a piece of
text that L</process_pm_file_if_modified> should replace this line
with.  Note that it is perfectly appropriate for a filter
implementation to buffer stuff, and therefore not always return
something from I<filter>.

The base class does not buffer. Rather, it substitutes standard
copyright stanzas, and detects the end-of-file on behalf of
L</eof_reached>.

=cut

sub filter {
    my $self = shift;
    local $_ = shift;

    return "" if $self->eof_reached;

    my $copyrightstring =
        sprintf( "Copyright Dominique Quatravaux %d -".
                 " Licensed under the same terms as Perl itself",
                 (localtime(time))[5] + 1900 );

    s/^ (.*)                  # Leading cruft (e.g. comment markers)
      (?:\(C\)|\x{A9})      # "copyright" sign
      (?:[ -])    .*        # spacer
      (?i:DOMQ|Quatravaux)   # Yours truly (case insensitive)
      /$1$copyrightstring/x;
    if (m/^require My::Tests::Below unless caller/) {
        $self->eof_reached(1);
        return "1;\n";
    } else {
        return $_;
    }
}

=item I<eof_reached()>

Shall return true iff the end-of-file is reached and calling
L</process_pm_line> further would just be a waste of time. Called
exactly once by L</process_pm_file_if_modified> after each call to
I<process_pm_line>.

In the base class, I<eof_reached()> is just a passive accessor whose
value is set by L</filter>.

=cut

sub eof_reached {
    my $self = shift;
    if (@_) {
        $self->{eof} = shift;
    } else {
        return $self->{eof};
    }
}

=back

=end internals

=head1 BUGS

The zero-wing easter egg only works through the Makefile.PL
compatibility mode. On the other hand, "./Build your time" would not
sound quite right, would it?

Perhaps the L</Dependent Option Graph> features should be repackaged
as a standalone Module::Build plug-in.

=head1 SEE ALSO

L<My::Tests::Below>

t/maintainer/*.t

=cut

require My::Tests::Below unless caller;

1;

__END__

use Test::More "no_plan";

########### Dependent graph stuff ################

# We keep the tests in a separate package so that if we later decide
# to refactor the dependent graph stuff into a standalone
# Module::Build plug-in, a simple cut-n-paste operation will do the
# job.
do {
    # We re-route the process of creating a Module::Build object to
    # a fake package, so as not to make Module::Build itself part
    # of the tests over the dependent graph stuff:
    local @My::Module::Build::ISA=qw(Fake::Module::Build);

    package Fake::Module::Build;

    sub new { bless {}, shift }

    # Various stuff that is being called by My::Module::Build as part
    # of this test, and that we therefore need to stub out:
    no warnings "redefine";
    local *My::Module::Build::maintainer_mode_enabled = sub { 0 };
    local *My::Module::Build::subclass = sub {
        my ($self, %opts) = @_;
        eval <<'HEADER' . $opts{code}; die $@ if $@;

package Fake::Subclass;
BEGIN { our @ISA=qw(My::Module::Build); }

HEADER
        return "Fake::Subclass";
    };

    sub notes {
        my ($self, $k, @v) = @_;
        if (@v) { $self->{notes}->{$k} = $v[0]; }
        return $self->{notes}->{$k};
    }

    # "batch" version of ->prompt()
    our %answers = ("Install module foo?" => 1);
    sub prompt {
        my ($self, $question) = @_;
        die "Unexpected question $question" if
            (! exists $answers{$question});
        return delete $answers{$question}; # Will not answer twice
        # the same question
    }

    package main_screen; # Do not to pollute the namespace of "main" with
    # the "use" directives below - Still keeping refactoring in mind.

    BEGIN { *write_file = \&My::Module::Build::write_file;
            *read_file  = \&My::Module::Build::read_file; }

    use Test::More;
    use Fatal qw(mkdir chdir);

    local @ARGV = qw(--noinstall-everything);

    my $define_options =
        My::Tests::Below->pod_code_snippet("option-graph");
    $define_options =~ s/\.\.\.//g;
    my $builder = eval $define_options; die $@ if $@;

    isa_ok($builder, "Fake::Module::Build",
           "construction of builder successful");

    is(scalar keys %My::Module::Build::declared_options,
       2, "Number of declarations seen");

    is(scalar(keys %answers), 0, "All questions have been asked");
    ok(! $builder->notes("option:install_everything"),
          "note install_everything");
    ok($builder->notes("option:install_module_foo"),
          "note install_module_foo");
    ok(! $builder->option_value("install_everything"),
          "install_everything");
    ok($builder->option_value("install_module_foo"),
          "install_module_foo");

    # Some whitebox testing here:
    is($builder->_option_type("install_everything"), "boolean",
       "implicit typing");
    is($builder->_option_type("install_module_foo"), "boolean",
       "explicit typing");
}; # End of fixture for option graph tests

####################### Main test suite ###########################

use File::Copy qw(copy);
use File::Spec::Functions qw(catfile catdir);
use IO::Pipe;
BEGIN { *write_file = \&My::Module::Build::write_file;
        *read_file  = \&My::Module::Build::read_file; }

# Probably wise to add this in real test suites too:
use Fatal qw(mkdir chdir copy);

mkdir(my $fakemoduledir = My::Tests::Below->tempdir() . "/Fake-Module");

my $sample_Build_PL = My::Tests::Below->pod_code_snippet("synopsis");

$sample_Build_PL =~ s/^(.*Acme::Pony.*)$/#$1/m; # As we say in french,
    # faut pas _que_ deconner non plus.
my $ordinary_arguments = <<'ORDINARY_ARGUMENTS';
      module_name         => 'Fake::Module',
      license             => 'perl',
      dist_author         => 'Octave Hergebelle <hector@tdlgb.org>',
      dist_version_from   => 'lib/Fake/Module.pm',
      dist_abstract       => 'required for Module::Build 0.2805, sheesh',
      requires            => {
        'Module::Build' => 0,
      },
      create_makefile_pl  => 'passthrough',
ORDINARY_ARGUMENTS
ok($sample_Build_PL =~
   s/^(.*##.*ordinary.*arguments.*)$/$ordinary_arguments/m,
   "substitution 1 in synopsis");
my $remainder = <<'REMAINDER';
$builder->create_build_script();
1;
REMAINDER
ok($sample_Build_PL =~ s/^(.*##.*remainder.*)$/$remainder/m,
   "Substitution 2 in synopsis");
write_file("$fakemoduledir/Build.PL", $sample_Build_PL);

mkdir("$fakemoduledir/lib");
mkdir("$fakemoduledir/lib/Fake");

=begin this_pod_is_not_mine

=cut

my $fakemodule = <<'FAKE_MODULE';
#!perl -w

# (C) DOMQ

use strict;
package Fake::Module;

our $VERSION = '0.42';

=head1 NAME

Fake::Module - This module is for testing My::Module::Build.pm

=head1 SYNOPSIS

Hey, gimme a break, this is a *bogus* package for Pete's sake!

=sorry, you're right

=cut the schizoid POD freakiness now will you? This is not M-x doctor!

# Good.

package Fake::Module::Ancillary::Class;

1;

__END__

package This::Package::Should::Not::Be::Reported::In::METAyml;

FAKE_MODULE

=end this_pod_is_not_mine

=cut

write_file("$fakemoduledir/lib/Fake/Module.pm", $fakemodule);

mkdir("$fakemoduledir/$_") foreach
    (qw(inc inc/My inc/My/Module
        lib/My lib/My/Private lib/My/Private/Stuff));

use FindBin qw($Bin $Script);
copy(catfile($Bin, $Script),
            "$fakemoduledir/inc/My/Module/Build.pm");
write_file(catfile($fakemoduledir, qw(lib My Private Stuff Indeed.pm)),
           <<"BOGON");
#!perl -w

package My::Private::Stuff::Indeed;
use strict;

1;

BOGON

my ($perl) = ($^X =~ m/^(.*)$/); # Untainted
chdir($fakemoduledir);

my $pipe = new IO::Pipe();
$pipe->reader($perl, "$fakemoduledir/Build.PL");
my $log = join('', <$pipe>);
$pipe->close(); is($?, 0, "Running Build.PL");
like($log, qr/version.*0.42/, "Build.PL found the version string");

SKIP: {
    skip "Not testing Build distmeta (YAML not available)", 2
        unless eval { require YAML };

    my $snippet = My::Tests::Below->pod_data_snippet("distmeta");
    my $errfile = "$fakemoduledir/meta-yml-error.log";
    my $script = <<"SCRIPT";
exec > "$errfile" 2>&1
set -x
cd "$fakemoduledir"
$snippet
SCRIPT
    system($script);
    is($?, 0, "creating META.yml using documented procedure")
        or diag($script . read_file($errfile));
    my $META_yml = read_file("$fakemoduledir/META.yml");
    my $excerpt = My::Tests::Below->pod_data_snippet("META.yml excerpt");
    $excerpt =~ s/\n+/\n/gs; $excerpt =~ s/^\n//s;
    like($META_yml, qr/\Q$excerpt\E/,
        "META.yml contains provisions against indexing My::* modules");
    like($META_yml, qr|My\b.*\bPrivate\b.*\bStuff|,
        "these provisions can be customized");
    like($META_yml, qr/\bFake::Module\b/,
        "Fake::Module is indexed");
    like($META_yml, qr/\bFake::Module::Ancillary::Class\b/,
        "Fake::Module::Ancillary::Class is indexed");
    unlike($META_yml, qr/This::Package::Should::Not::Be::Reported/,
        "META.yml should not index stuff that is after __END__");
    unlike($META_yml, qr/Indeed/,
        "META.yml should not index stuff that is in add_to_no_index");
}

# You have no chance to survive...
test_Makefile_PL_your_time($_) for
    ($sample_Build_PL, <<'SUBCLASSED_BUILD_PL');
use strict;
use warnings;

use FindBin; use lib "$FindBin::Bin/inc";
use My::Module::Build;

my $subclass = My::Module::Build->subclass(code => "");

my $builder = $subclass->new(
      module_name         => 'Fake::Module',
      license             => 'perl',
      dist_author         => 'Octave Hergebelle <hector@tdlgb.org>',
      dist_version_from   => 'lib/Fake/Module.pm',
      dist_abstract       => 'required for Module::Build 0.2805, sheesh',
      requires            => {
        'Module::Build' => 0,
      },
      create_makefile_pl  => 'passthrough',

   build_requires =>    {
#         'Acme::Pony'    => 0,
         My::Module::Build->requires_for_build(),
   },
);

$builder->create_build_script();
1;


SUBCLASSED_BUILD_PL

sub test_Makefile_PL_your_time {
    my ($Build_PL_contents) = @_;
    write_file("$fakemoduledir/Build.PL", $Build_PL_contents);
    system($perl, "$fakemoduledir/Build.PL");
    is($?, 0, "Running Build.PL");
    system("$fakemoduledir/Build", "dist");
    is($?, 0, "Running Build dist");
    unlink("$fakemoduledir/Fake-Module-0.42.tar.gz");
    write_file("$fakemoduledir/test.sh",
           <<"PREAMBLE",
set -e
cd $fakemoduledir
PREAMBLE
               My::Tests::Below->pod_data_snippet("great justice"));
    $pipe = new IO::Pipe;
    $pipe->reader("/bin/sh", "$fakemoduledir/test.sh");
    my $text = join('', <$pipe>);
    $pipe->close();
    is($?, 0, "You are on the way to destruction")
        or warn $text;
    like($text, qr/belong/, "Still first hit on Google, after all these years!");
}


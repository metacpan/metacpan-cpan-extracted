#!perl -w
use strict;
use warnings;

=head1 NAME

dependencies.t - Checks that B<Build.PL> lists all required CPAN modules.

=head1 DESCRIPTION

This test looks at the dependencies listed in the C<requires> keys in
B<Build.PL>, and matches them against the actual run-time dependencies
of the distribution's codebase.  It then combines the dependencies
listed in the C<requires> and C<build_requires> keys, and matches them
against the actual compile-time dependencies.  If any module is listed
in C<Build.PL> and not an actual dependency or vice versa (barring a
well-known list of false positives and "pervasive" modules), the test
fails.

This tests uses L<Module::ScanDeps>, whose guts it rearranges in a
creative fashion so as to eliminate most false positives and be able
to pinpoint lines of source code in case the test fails.  This does
result in a somewhat quirky implementation.

=cut

BEGIN {
    my $errors;
    foreach my $use (qw(Test::More File::Spec
                        File::Find Module::ScanDeps IO::File)) {
        $errors .= $@ unless eval "use $use; 1";
    }
    if ($errors) {
        plan(skip_all => "Some modules are missing "
             . "in order to run this test");
        warn $errors if $ENV{DEBUG};
        exit;
    }
}

plan tests => 3;

=pod

=head1 TWEAKABLES

=head2 %is_subpackage_of

A hash table that associates dependent packages
(e.g. C<DBIx::Class::Schema>, C<Catalyst::Controller>) to the
canonical top-level package in their distribution
(e.g. C<DBIx::Class>, C<Catalyst>).  Requirements and dependencies
that name a key in %is_subpackage_of will be treated as though they
were the corresponding value instead.

=cut

# TODO: use Module::Depends or some such to compute this
# automatically.
our %is_subpackage_of =
    ( "Catalyst::Controller" => "Catalyst",
      "Catalyst::View"       => "Catalyst",
      "Catalyst::Model"      => "Catalyst",
      "Catalyst::Runtime"    => "Catalyst",
      "Catalyst::Utils"      => "Catalyst",
      "Catalyst::Action"     => "Catalyst",
      "Catalyst::Test"       => "Catalyst",
      "DBIx::Class::Schema"  => "DBIx::Class",
      "DateTime::Duration"   => "DateTime",
    );

=head2 @pervasives

The list of modules that can be assumed to always be present
regardless of the version of Perl, and need not be checked for.  By
default only pragmatic modules (starting with a lowercase letter) and
modules that already were in 5.000 according to L<Module::CoreList>
are listed.

=cut

our @pervasives = qw(base warnings strict overload utf8 vars constant
                     Config Exporter Data::Dumper Carp
                     Getopt::Std Getopt::Long
                     DynaLoader ExtUtils::MakeMaker
                     POSIX Fcntl Cwd Sys::Hostname
                     IO::File IPC::Open2 IPC::Open3
                     File::Basename File::Find
                     UNIVERSAL);

=head2 @maintainer_dependencies

The list of modules that are used in C<t/maintainer>, and for which
there should be provisions to bail out cleanly if they are missing (as
demonstrated at the top of this very test script).  Provided such
modules are not listed as dependencies outside of C<t/maintainer>,
they will be ignored.  (Incidentally this means that dependencies in
C<t/maintainer> are actually accounted for and not just thrown out, as
it may be the case that I'm not the B<only> maintainer of a given
module.)

=cut

our @maintainer_dependencies =
  qw(Pod::Text Pod::Checker Test::Pod Test::Pod::Coverage
     Test::NoBreakpoints Module::ScanDeps
     Test::Kwalitee Module::CPANTS::Analyse Module::CPANTS::Kwalitee::Files);

=head2 @sunken_dependencies

Put in there any modules that can get required without our crude
source code parser being able to spot them.

=cut

our @sunken_dependencies =
    ("Catalyst::Engine::Apache", # Required by simply running under mod_perl
    );


=head2 @ignore

Put any other modules that cause false positives in there.  Consider
adding them to Build.PL instead, or rewriting your source code in a
more contrived way so that L<Module::ScanDeps> won't spot them
anymore.

=cut

our @ignore = ("IO",  # False positive by Module::ScanDeps
              );

=head1 IMPLEMENTATION

We load the C<Build> script so as to be able to enumerate the
dependencies and call I<<find_pm_files()> and I<<find_test_files()>>
on it.

=cut

my $buildcode = read_file("Build");
die "Cannot read Build: $!" if ! defined $buildcode;
$buildcode =~ s|\$build->dispatch|\$build|g;
our $build = do {
    local @INC = @INC; # lest Module::Build mess with it
    eval <<"STUFF" or die $@;
no warnings "redefine";
local *Module::Build::Base::up_to_date = sub {1}; # Shuts warning
$buildcode
STUFF
};
ok($build->isa("Module::Build"));

=pod

The run-time dependencies are examined in the C<blib> directory, as
the Build script will often muck around with .pm files e.g. to remove
the test suites.

=cut

my @blib_files; find({no_chdir => 1, wanted => sub {
  return unless m|\.pm$|; # Also takes care of /.svn/ files
  push @blib_files, $_;
}}, "blib") if (-d "blib");

compare_dependencies_ok(list_deps(@blib_files),
                        [keys %{$build->requires}],
                        "runtime dependencies");

=pod

On the other hand, we look for test dependencies everywhere, including
in the footer of .pm files after the __END__ block (see details in
inc/My/Tests/Below.pm)

=cut

compare_dependencies_ok
    (list_deps(@blib_files,
               keys %{$build->find_pm_files},
               @{$build->find_test_files},
               "Build.PL"),
     [ keys(%{$build->requires}),
       keys(%{$build->build_requires}) ],
     "compile-time dependencies");

exit; ##############################################################

=head1 TEST LIBRARY

=head2 file2mod ($filename)

Turns $filename into a module name (e.g. C<Foo/Bar.pm> becomes
C<Foo::Bar>) and returns it.

=cut

sub file2mod {
    local $_ = shift;
    s|/|::|g; s|\.pm$||;
    return $_;
}

=head2 mod2file ($filename)

The converse of L</file2mod>.

=cut

sub mod2file {
    local $_ = shift;
    s|::|/|g; $_ .= ".pm";
    return $_;
}

=head2 read_file

Same foo as L<File::Slurp/read_file>, sans the dependency on same.

=cut

sub read_file {
    my ($path) = @_;
    local *FILE;
    open FILE, $path or die $!;
    return wantarray ? <FILE> : join("", <FILE>);
}

=head2 write_to_temp_file($string)

Writes $string into a newly created temporary file, and return its
path.

=cut

sub write_to_temp_file {
    use File::Temp;
    my ($fh, $filename) = File::Temp::tempfile( UNLINK => 1 );
    unless ($fh->print(shift) &&
            $fh->close()) {
        die "cannot write to $filename: $!\n";
    }
    return $filename;
}

=head2 list_deps(@files)

List dependencies found in @files, and returns them as a reference to
a hash whose keys are module names and values are references to lists
of hashes of the form

    {
      line => $line,
      file => $file,
    }

pointing at the precise location in the source code where the
dependency was found.  Only dependencies against a real C<.pm> file
are accounted for (not C<.so>, not C<.bs>); also,
L</@maintainer_dependencies> are not listed if found in
C<t/maintainer>.

=cut

sub list_deps {
    my $retval;
    foreach my $file (@_) {
        die "Cannot open $file: $!" unless defined
            (my $fd = IO::File->new($file, "<"));
        # Here we go again with a run-off-the-mill half-assed Perl parser...
        LINE: while(my $line = $fd->getline) {
            CHUNK: foreach my $pm (Module::ScanDeps::scan_line($line),
                                   scan_line_some_more($line, $file, $fd)) {
                next LINE if skip_pod($file, $fd, $pm);

                next CHUNK unless ($pm =~ m/\.pm$/);
                my $module = file2mod($pm);
                next CHUNK if
                    ($file =~ m/\bt\b\W+\bmaintainer\b/ &&
                     grep { $module eq $_ } @maintainer_dependencies);
                # Works around bug #25547 on rt.cpan.org:
                next CHUNK if ($module eq "File::Glob") &&
                    ($line !~ m/Glob/);

                # Now ask Module::ScanDeps to find the actual module
                # on disk.  If not found (or found within our own
                # distribution), then count as a false positive.
                my %rv;
                Module::ScanDeps::add_deps(rv => \%rv, modules => [ $pm ]);
                next CHUNK unless (exists($rv{$pm}) &&
                                   exists($rv{$pm}->{file}));
                next CHUNK if is_our_own_file($rv{$pm}->{file});

                push(@{$retval->{$module}},
                     { file => $file,
                       line => $fd->input_line_number });
            }
            skip_here_document($file, $fd, $line);
        }
    }
    return $retval;
}

=head2 skip_pod ($filename, $fd, $pm)

=head2 skip_here_document ($filename, $fd, $line)

Both functions advance $fd, an instance of L<IO::Handle>, to skip past
non-Perl source code constructs, and return true if they indeed did
skip something (or throw an exception if they tried and failed).  $pm
is a token returned by L<Module::ScanDeps/scan_line>; $line is a line
of the Perl source file. $filename is only used to construct the text
of error messages.

=cut

sub skip_pod {
    my ($file, $fd, $pm) = @_;
    return unless $pm eq '__POD__';
    my $podline = $fd->input_line_number;
    while (<$fd>) { return 1 if (/^=cut/) }
    die <<"MESSAGE";
Could not find end of POD at $file line $podline
MESSAGE
}

sub skip_here_document {
    my ($file, $fd, $line) = @_;
    # Regex mostly lifted from Emacs' cperl-mode.el, which may or may
    # not be accurate.  The case of multiple here-docs on the same
    # line is not accounted for.
    $line =~ s/#.*$//g; # Snip comments
    return unless
        ($line =~ m/  (.*)
                      <<  \s*
                      (?: '(.*?)' | "(.*?)" | ([A-Za-z][A-Za-z0-9_]*) )
                      /x);
    my $leadingstuff = $1;
    my $heredelim = $2 || $3 || $4;
    # Eval'ed here-docs don't count, they are treated as real code (yow!):
    return if ($leadingstuff =~ m/eval\s*$/);
    my $hereline = $fd->input_line_number;
    while (<$fd>) { return 1 if (/^\Q$heredelim\E/) }
    die <<"MESSAGE";
Could not find end of here document ($heredelim) at $file line $hereline
MESSAGE
}

=head2 scan_line_some_more ($line, $filename, $fd)

Works like L<Module::ScanDeps/scan_line>, and works around the
limitations thereof by detecting more forms of dependencies.  $fd is
available in case the code wants to slurp more lines in order to get
hold of a complete Perl statement.  $filename is only used to generate
error messages.

=cut

sub scan_line_some_more {
    local $_ = shift;
    my ($file, $fd) = @_;

    my $lineno = $fd->input_line_number;
    my @retval;

    # Catalyst mojo constructs:
    if (m|use \s+ Catalyst \s+ |x) {
        until (m/ use \s+ Catalyst \s+ (.*);/sx) {
            my $nextline = <$fd>;
            die <<"MESSAGE" if ! defined $nextline;
End of file reached while looking for end of ``use Catalyst'' construct
at $file line $lineno.
MESSAGE
            $_ .= $nextline;
        }
        push(@retval, map { mod2file("Catalyst::Plugin::$_") }
             (m/[A-Z][A-Z0-9:_]*/gi));
    }
    if (m|ActionClass.*?(?i)([A-Z][A-Z0-9:_]*)|) {
        push(@retval, mod2file("Catalyst::Action::$1"));
    }


    return @retval;
}

=head2 is_our_own_file ($path)

Returns true iff $path is one of the files in this package, and
therefore should not be counted as a dependency.

=cut

sub is_our_own_file {
    my ($filename) = @_;
    index($filename, $build->base_dir) == 0;
}

=head2 compare_dependencies_ok ($gothashref, $expectedlistref)

As the name implies.  For each key in $gothashref which is not in
$expectedlistref, shows the file name(s) and line number(s) of the
chunk(s) that caused the dependency to be added.  Conversely, for each
entry in $expectedlistref which is not a key in $gothashref, warns
about a spurious dependency in Build.PL.

=cut

sub compare_dependencies_ok {
    my ($gothashref, $expectedlistref, @testname) = @_;

    my @required_for_build = qw(Module::Build);
    push(@required_for_build, $build->requires_for_build()) if
      $build->can("requires_for_build");

    # Note that @required_for_build modules are dealt with as though
    # they were pervasive, as we are not enumerating dependencies in
    # the build system and therefore cannot check them for accuracy.
    my @expected = filter_and_canonicalize
      ([@pervasives, @required_for_build,
        @maintainer_dependencies, @sunken_dependencies],
       @$expectedlistref);

    my @got = filter_and_canonicalize
      ([@pervasives, @required_for_build, @ignore],
       keys %$gothashref);

    # Poor man's L<Array::Compare> rolled as a test assertion:

    my %expected = map { ( $_ => 1 ) } @expected;
    my %got = map { ( $_ => 1 ) } @got;
    return if &is(join(" ", sort keys %got),
                  join(" ", sort keys %expected), @testname);

    foreach my $notfound (grep {! $expected{$_}} (keys %got)) {
        foreach my $match (@{$gothashref->{$notfound}}) {
            diag(sprintf("%s seems to be be referenced in %s line %d\n",
                         $notfound, $match->{file}, $match->{line}));
        }
    }
    foreach my $spurious (grep { ! $got{$_}} (keys %expected)) {
        diag("$spurious seems to be a spurious prerequisite in Build.PL");
    }
}

=head2 filter_and_canonicalize ($exceptions, @packagenames)

Processes @packagenames, a list of Perl package names, by eliminating
entries that are in $exceptions (a reference to a list) and converting
packages to their canonical name using L</%is_subpackage_of>.

=cut

sub filter_and_canonicalize {
    my ($exceptions, @packages) = @_;
    my %exceptions_set = map { ($_ => 1) } @$exceptions;
    return map { $is_subpackage_of{$_} || $_ }
      (grep { ! exists $exceptions_set{$_} } @packages);
}

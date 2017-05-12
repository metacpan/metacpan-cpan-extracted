#!perl -Tw
# Copyright Dominique Quatravaux 2006 - Licensed under the same terms as Perl itself

use strict;
use warnings;
use 5.006; # "our" keyword

=head1 NAME

B<My::Tests::Below> - invoke a test suite at the end of a module.

=head1 SYNOPSIS

 package MyPackage;

 <the text of the package goes here>

 require My::Tests::Below unless caller();

 1;

 __END__

 use MyPackage;


 # And there you go with your test suite

=head1 DESCRIPTION

DOMQ is a guy who releases CPAN packages from time to time - you are
probably frobbing into one of them right now.

This package is a helper that supports my coding style for unit tests
so as to facilitate relasing my code to the world.

=head2 How it works

The test code is written in L<perlmodlib> style, that is, at the
bottom of the Perl module to test, after an __END__ marker. This way
of organizing test code is not unlike L<Test::Inline>, by Adam Kennedy
et al, in that it keeps code, documentation and tests in the same
place, encouraging developers to modify all three at once.

I like to use L<Test::Group> for the unit perlmodlib-style unit tests,
because counting and recounting my tests drives me nuts :-). However
C<My::Tests::Below> itself is testing-framework agnostic (its own
self-test suite, for instance, uses only plain old L<Test::More>).

Invoking C<require My::Tests::Below> from anywhere (the idiomatic form
is shown in L</SYNOPSIS>) results in the block of code after the
__END__ marker being run at once. Due to the way this construct abuses
the Perl module mechanism, My::Tests::Below cannot be require()d or
use()d for any other purpose, hence the funny name.

=head3 Why not use Test::Inline then?

Well, for a variety of reasons:

=over

=item *

modules written with tests at the end syntax-highlight almost
perfectly under Emacs :-), which is far from being the case for tests
written in the POD

=item *

removing the My::Tests::Below altogether from the installed version
of a package is straightforward and does not alter line
numbering. (See L<My::Module::Build>)

=item *

no pre-processing step (e.g. C<inline2test>) and no temporary file
creation is required with My::Tests::Below. This goes a long ways
towards shortening the debugging cycle (no need to re-run "./Build
code" nor "make" each time)

=item *

L<Test::Inline> has a lot of dependencies, and using it would cause
the installation of small modules to become unduly burdensome.

=back

=cut "

package My::Tests::Below;

use strict;
use File::Temp ();

our $VERSION = 2.0;

## This is done at the top level, not in a sub, as "require
## My::Tests::Below" is what gets the ball rolling:
our $singleton = __PACKAGE__->_parse(\*main::DATA, caller(0));
unless (defined $singleton) {
    die "My::Tests::Below invoked, but no tests were found below!";
}
close(main::DATA);
$singleton->run();

## Creates an instance of My::Tests::Below from a source file
## that has tests at the bottom.
sub _parse {
    my ($class, $fd, $package, $packfilename, $packline) = @_;

    if (!defined $package) { # Handle self-testing case
        $package="My::Tests::Below";
        $0 =~ m/^(.*)$/; $packfilename = $1;
    }

    my $self = bless {
                      package => $package,
                      packfilename => $packfilename
                     }, $class;

    $self->{testsuite} = do { no warnings; scalar <$fd> };
    return undef if ! defined $self->{testsuite};
    $self->{testsuite} .= join('',<$fd>); # The rest of it

=head2 Comfort features

Unlike the C<< eval >> form recommended in L<perlmodlib>,
My::Tests::Below provides a couple of comfort features that help
making the system smooth to use for tests.

=over

=item I<Support for code and data snippets in the POD>

A mechanism similar to the now-deprecated L<Pod::Tests> is proposed to
test documented examples such as code fragments in the SYNOPSIS. See
L</CLASS METHODS> below.

=cut

    ## Parse the whole source file again in order to provide said
    ## features.  Yes, seeking to start also works on main::DATA!
    ## Gotta love Perl :-)
    seek($fd, 0, 0) or die $!; $. = 0;
    my $insnippet;
    SOURCELINE: while(<$fd>) {
        if (m/^=for\s+My::Tests::Below\s+"([^"]*)"(.*)$/) {
            my $snipkey = $1; my @args = split m/\s+/, $2;
            if (grep { lc($_) eq "end" } @args) {
                die qq'Not in an "=for My::Tests::Below" directive'.
                    qq' at line $.\n' unless (defined $insnippet);
                die qq'Badly nested "=for My::Tests::Below" directives'.
                    qq' at line $.\n' unless ($insnippet eq $snipkey);
                undef $insnippet;
            } else { # Assume "begin" for compatibility with old tests
                die qq'Duplicate "=for My::Tests::Below" directive'.
                    qq' for label $snipkey at line $.\n' if
                        (exists $self->{podsnippets}{$snipkey});
                die qq'Badly nested "=for My::Tests::Below" directives'.
                    qq' at line $.\n' if (defined $insnippet);
                $self->{podsnippets}{$snipkey}->{lineno} = $. + 1;
                $insnippet = $snipkey;
            }
        } elsif (m/^=for\s+My::Tests::Below/) {
            die qq'Parse error in "=for My::Tests::Below"'.
                qq' directive at line $.\n';
        } else {
            $self->{podsnippets}{$insnippet}->{text} .= $_ if (defined $insnippet);
        };

        next if (defined($packline) && $. <= $packline); # Be sure to
        # catch the first marker *after* the require directive, and
        # mind the self-test case too.

        next SOURCELINE unless (m/^__(END|DATA)__\s+$/);

=item I<Line counting for the debugger>

You can step through the test using a GUI debugger (e.g. perldb in
Emacs) because the line numbers are appropriately translated.

=cut

        $self->{testsuite}="#line ".($.+1)." \"$self->{packfilename}\"\n".
            $self->{testsuite};
        last SOURCELINE;
    }

=item I<Tests always start in package main>

The perlmodlib idiomatics puts you either in C<main> or in the package
where the eval was called from, depending on the version of Perl.

=cut

    $self->{testsuite}="package main;\n" . $self->{testsuite};

    return $self;
}

## Actually runs the test suite in an eval.
sub run {
    my ($self) = @_;

=item I<Tested package is available for "use">

As shown in L</SYNOPSIS>, one can invoke "use MyPackage;" at the top
of the test suite and this will not cause the package under test to be
reloaded from the filesystem. The import() semantics of MyPackage, if
any, will work as normal.

=cut

    local %INC = %INC;
    if (defined $self->{package} && defined $self->{packfilename}) {
        # Heuristics needed here. $self->{packfilename} is a filename,
        # say /path/to/lib/Foo/Bar.pm, and we want to set
        # $INC{"Foo/Bar.pm"} so we must weed out /path/to/lib
        # wisely. $self->{package} is "Foo::Bar" most of the time but
        # may also be "Foo::Bar::SubPackage", "Foo" (if Foo::Bar is a
        # mixin to Foo) or even "Un::Related". In the latter case
        # we're out of luck and we leave %INC unmolested.
        for(my $package = $self->{package};
            $package; $package =~ s/(::|^)[^:]*$//) {
            my $filename = $package;
            $filename =~ s|::|/|g;
#warn "Considering $filename against $self->{packfilename}";
            next unless ($self->{packfilename} =~
                         m{(\Q$filename\E(?:/.*|\.pm)$)});
#warn "Inhibiting load of $1";
            $INC{$1} = $self->{packfilename}; last;
        }
    };


=item I<%ENV is standardized>

When running under C<require My::Tests::Below>, %ENV is reset to a
sane value to avoid freaky side effects when eg the locales are weird
and this influences some shell tool fired up by the test suite.  The
original contents of %ENV is stashed away in %main::ENVorig in case it
is actually needed.

=cut

    local %main::ENVorig; %main::ENVorig = %ENV;
    $ENV{PATH} =~ m|^(.*)$|; # Untaints
    local %ENV = (
            "PATH"  => $1,
            "DEBUG" => $ENV{"DEBUG"} ? 1 : 0,
           );

    eval $self->{testsuite};

    die $@ if $@;
}

=back

=head1 CLASS METHODS

=over

=item I<tempdir()>

This class method returns the path of a temporary test directory
created using L<File::Temp/tempdir>. This directory is set to be
destroyed when the test finishes, except if the DEBUG environment
variable is set. This class method is idempotent: calling it several
times in a row always returns the same directory.

=cut

{
    my $cached;
    sub tempdir {
        return $cached if defined $cached;
        return ($cached = File::Temp::tempdir
                ("perl-My-Tests-Below-XXXXXX",
                 TMPDIR => 1, ($ENV{DEBUG} ? () : (CLEANUP => 1))));
    }
}

=item I<pod_data_snippet($snippetname)>

This class method allows the test code to grab an appropriately marked
section of the POD in the class being tested, for various
test-oriented purposes (such as eval'ing it, storing it in a
configuration file, etc.).  The return value has the same number of
lines as the original text in the source file, but it is ragged to the
left by suppressing a constant number of space characters at the
beginning of each line.

For example, consider the following module:

=for My::Tests::Below "reflection is a fun thing" begin

  #!/usr/bin/perl -w

  package Zoinx;
  use strict;

  =head1 NAME

  Zoinx!

  =head1 SYNOPSIS

  =for My::Tests::Below "create-zoinx" begin

  my $zoinx = new Zoinx;

  =for My::Tests::Below "create-zoinx" end

  =cut

  package Zoinx;

  sub new {
      bless {}, "Zoinx";
  }

  require My::Tests::Below unless caller;

=for My::Tests::Below "reflection is a fun thing" end

=for great "justice"

  __END__

then C<< My::Tests::Below->pod_data_snippet("create-zoinx") >> would
return "\nmy $zoinx = new Zoinx;\n\n".

The syntax of the C<=for My::Tests::Below> POD markup lines obeys the
following rules:

=over

=item *

the first token after C<My::Tests::Below> is a double-quoted string
that contains the unique label of the POD snippet (passed as the first
argument to I<pod_data_snippet()>);

=item *

the second token is either C<begin> and C<end>, which denote the start
and end of the snippet as shown above. Nesting is forbidden (for now).

=back

=cut

sub pod_data_snippet {
	my ($self, $name)=@_; $self = $singleton if ! ref $self;

	local $_ = $self->{podsnippets}{$name}->{text};
	return unless defined;

    my $ragamount;
    foreach my $line (split m/\n/s) {
        next if $line =~ m/^\t/; # tab width is treated as infinite to
        # cut through the whole mess
        next if $line eq ""; # Often authors leave empty lines to
        # delimit paragraphs in SYNOPSIS, count them as undefined
        # length as well

        $line =~ m/^( *)/; my $spaceamount = length($1);
        $ragamount = $spaceamount if ((!defined $ragamount) ||
                                       ($ragamount > $spaceamount));
    }

    s/^[ ]{$ragamount}//gm;
	m/^(.*)$/s; return $1; # Untainted
}

=item I<pod_code_snippet($snippetname)>

Works like L</pod_data_snippet>, except that an adequate #line is
prepended for the benefit of the debugger. You can thus single-step
inside your POD documentation, yow! Using the above sample .pm file
(see L</pod_data_snippet>), you could do something like this in the
test trailer:

=for My::Tests::Below "POD testing example" begin

  my $snippet = My::Tests::Below->pod_code_snippet("create-zoinx");

  # Munging $snippet a bit before running it (e.g. with regexp
  # replaces) is par for the course.

  my $zoinx = eval $snippet;
  die $@ if $@; # If snippet fails, we want to know

  # Optionally proceed to test the outcome of the snippet:

  is(ref($zoinx), "Zoinx", '$zoinx is a Zoinx');

=for My::Tests::Below "POD testing example" end

=cut

sub pod_code_snippet {
    my ($self, $name) = @_; $self = $singleton if ! ref $self;
    return "#line " . $self->{podsnippets}{$name}->{lineno} .
        " \"$self->{packfilename}\"\n" .
            $self->pod_data_snippet($name);
}

=back

=head1 SEE ALSO

L<My::Module::Build> knows how to remove I<My::Tests::Below>
suites at "make" or "./Build code" time, so as not to burden the
compiled package with the test suite.

While I am (obviously) partial to putting tests at the bottom of the
package, I also occasionally make use of classic C<t/*.t> tests; in
particular I use the same C<t/maintainer/*.t> tests in all my CPAN
modules.

=head1 BUGS

The purpose of this package is mostly a duplicate of L<Test::Inline>
and/or L<Pod::Tests>, but I cannot join either of these efforts in the
current state of CPAN affairs (I<Pod::Tests> is not maintained, and as
stated L<above|/"Why not use Test::Inline then?"> I<Test::Inline> is
not adequate for many reasons). What I could do, however, is to
standardize on similar POD markup for snippets - but the corresponding
features are being reimplemented in I<Test::Inline> as of version
2.103 (see
F<http://search.cpan.org/~adamk/Test-Inline-2.103/lib/Test/Inline.pm#TO_DO>).
So I'll just wait and see.

=cut

1;

__END__

# Yes, even this module has a
######################## TEST SUITE ###################################

use strict;
use Test::More tests => 11;
use IO::File;
use IO::Handle;
use IPC::Open3;
use File::Spec;
use Fatal qw(mkdir chdir);

=begin internals

=head2 Tests over the __END__ test section for real modules

=head3 run_perl($filename)

Runs Perl on $filename, returning what we got on stdout / stderr.
$? is also set.

=cut

sub run_perl {
    my ($filename) = @_;
    my ($stdin, $stdout) = map { new IO::Handle } (1..2);
    my ($perl) = ($^X =~ m/^(.*)$/); # Untainted
    my $pid = open3($stdin, $stdout, $stdout,
          $perl, (map { -I => $_ } @INC), '-Tw', $filename);
    $stdin->close();
    my $retval = join('', <$stdout>);
    $stdout->close();
    waitpid($pid, 0); # Sets $?
    return $retval;
}

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

=cut

my $fakemoduledir = My::Tests::Below->tempdir() . "/Fake-Module";
mkdir($fakemoduledir);

mkdir(File::Spec->catdir($fakemoduledir, "Fake"));
my $fakemodule = File::Spec->catfile($fakemoduledir, "Fake", "Module.pm");
write_file($fakemodule, <<'FAKEMODULE');
#!perl -Tw

package Fake::Module;
use strict;

use base 'Exporter';
our @EXPORT = qw(zoinx);

sub zoinx {1}

package Fake::Module::Sub;

require My::Tests::Below unless (caller());

1;

__END__

use Fake::Module;

print "1..2\n";
if (__PACKAGE__ eq "main") {
   print "ok 1 # In package 'main' for tests\n";
} else {
   print "not ok 1 # Package should be main but is ".__PACKAGE__."\n";
}

zoinx();

print "ok 2 # Symbol zoinx is imported\n";

0; # Should not cause suite to fail, unlike perlmodlib
FAKEMODULE

my $result = run_perl($fakemodule);
is($?, 0, "Exited with return code 0\n");
like($result, qr/ok 1/, "Test result #1");
like($result, qr/ok 2/, "Test result #2");

write_file($fakemodule, <<'BUGGY_MODULE_WITH_TEST_MORE');
#!perl -Tw

package Fake::Module;
use strict;

1;

require My::Tests::Below unless (caller());

__END__

use Test::More no_plan => 1;

ok(1);
die;
BUGGY_MODULE_WITH_TEST_MORE

$result = run_perl($fakemodule);
is($?, 255 << 8, "Exited with return code 255\n");
like($result, qr/Looks like your test died just after/, "Test died");

######## POD snippets

my $snippet = My::Tests::Below->pod_data_snippet
        ("reflection is a fun thing");
like($snippet, qr/^package Zoinx/m, "pod_data_snippet");
unlike($snippet, qr/reflection/, "Pod delimiters should be cut out");
like($snippet, qr/^    bless/m, "smart ragging");

eval $snippet; die $@ if $@; pass("Created package Zoinx");

my $testsnippet =
    My::Tests::Below->pod_code_snippet("POD testing example");

no warnings "redefine"; local *My::Tests::Below::pod_code_snippet = sub {
    is($_[1], 'create-zoinx',
       "hijacked sub pod_code_snippet() called as expected");
    # Real men would invoke My::Tests::Below recursively here...
    return <<'LAZY_SHORTCUT';

my $zoinx = new Zoinx;

LAZY_SHORTCUT
};

eval $testsnippet; die $@ if $@; # $testsnippet contains an invocation of
# is(), so the test counter gets incremented by one here.

1;

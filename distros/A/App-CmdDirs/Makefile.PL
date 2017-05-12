=for developers

If you're a developer, Makefile.PL will pack `cmddirs` from
build/cmddirs.PL and then copy that file to `bin/cmddirs`.

You can pretend to be an author by running it with:

  perl Makefile.PL --author

You should install App::FatPacker before doing so.

Do not commit the changes to the `cmddirs` standalone executable. We only
commit changes to this file whenever we tag a new CPAN release.

=cut
use English '-no_match_vars';

my $author = ((grep{ $_ eq '--author' } @ARGV) or -d '.git' && `git remote -v` =~ /git\@github/);
print STDERR "Running in author mode!\n" if $author;

# Author: perl Makefile.PL packs 'build/cmddirs.PL' -> 'cmddirs'
if ($author) {
    shift @ARGV;
    system $EXECUTABLE_NAME, "build/build.PL" and die $?;
}

# perl Makefile.PL (from git repo) copies 'cmddirs' -> 'bin/cmddirs'
if (-e 'cmddirs') {
    print STDERR "Generating bin/cmddirs from cmddirs\n";
    mkdir 'bin';
    rename 'cmddirs', 'bin/cmddirs';
}

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'App::CmdDirs',
    ABSTRACT => 'Perform a command in subdirectories',
    AUTHOR => 'Drew Stephens <drew@dinomite.net>',
    VERSION_FROM => "lib/App/CmdDirs.pm",
    BUILD_REQUIRES => {
        'App::FatPacker' => '0.009006',
        'Perl::Critic' => '1.113',
        'Test::Class' => '0.36',
        'Test::Perl::Critic' => '1.02',
    },
    PREREQ_PM => {
    },
    LICENSE => 'perl',
    EXE_FILES => [ 'bin/cmddirs' ],
);

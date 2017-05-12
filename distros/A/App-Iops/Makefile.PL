use ExtUtils::MakeMaker;

my @proc_fd =
    grep { ! m{/\.\.?$} }
    glob "/proc/$$/fd/*";
unless (`which strace` && @proc_fd ) {
    print <<'STRACE';
App-Iops requires a linux-like /proc/<pid>/fd/* file system and
strace.
STRACE
    exit 0;
}

WriteMakefile(
  ABSTRACT_FROM => 'lib/App/Iops.pm',
  VERSION_FROM => 'lib/App/Iops.pm',
  AUTHOR => 'Josh Jore <jjore@cpan.org>',
  EXE_FILES => ['bin/iops'],
  $ExtUtils::MakeMaker::VERSION >= 6.30
    ? (LICENSE => 'perl')
    : (),
  NAME => 'App::Iops',
);

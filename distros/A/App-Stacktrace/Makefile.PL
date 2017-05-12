use 5.010_000;
use ExtUtils::MakeMaker;

if (! usable_gdb()) {
    print "App::Stacktrace requires gdb. Aborting installation";
    exit 0;
}

WriteMakefile(
  ABSTRACT_FROM => 'lib/App/Stacktrace.pm',
  AUTHOR => 'Josh Jore <jjore@cpan.org>',
  EXE_FILES => [
    'bin/perl-stacktrace'
  ],
  $ExtUtils::MakeMaker::VERSION >= 6.30
      ? (LICENSE => 'perl')
      : (),
  NAME => 'App::Stacktrace',
  VERSION_FROM => 'lib/App/Stacktrace.pm',
);

sub usable_gdb {
    require File::Temp;
    my $fh = File::Temp->new();

    print { $fh } <<SCRIPT;
run -e 1
quit
SCRIPT
    $fh->flush;
    $fh->sync;

    my $fn = $fh->filename;
    return 0 == system "gdb -quiet -batch -nx -x $fn $^X >/dev/null 2>&1 </dev/null";
}

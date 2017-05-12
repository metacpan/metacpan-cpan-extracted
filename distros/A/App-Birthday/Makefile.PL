use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my @scripts = qw( birthday );
my $usrbin = "/usr/bin";
my $installscript = $Config{installscript};

print STDERR <<EOF unless $installscript eq $usrbin;

WARNING: This Makefile will install user accessible scripts.
The location for these scripts is $installscript.
You may consider to pass INSTALLSCRIPT=$usrbin (or some other
convenient location) to "make install".

EOF

WriteMakefile(
    NAME                => 'App::Birthday',
    AUTHOR              => q{Farhad Fouladi <farhad@cpan.org>},
    VERSION_FROM        => 'lib/App/Birthday.pm',
    ABSTRACT_FROM       => 'lib/App/Birthday.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    EXE_FILES		=> [ map { "bin/$_" } @scripts ],
    PREREQ_PM => {
        'Test::More'   => 0,
        'Mail::Sender' => 0,
        'JSON::PP'     => 0,
        'Getopt::Std'  => 0
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Birthday-*' },
);

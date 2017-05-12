# $Id: Makefile.PL 52 2015-07-12 00:49:18Z stro $

use strict;
use warnings;

use ExtUtils::MakeMaker;

my @exe_files = map {"bin/$_"} qw(cpandb);
my $goners = join ' ', qw(
    cpandb.sql
    t/dot-cpan/cpandb.sql
    t/dot-cpan/FTPstats.yml
    t/dot-cpan/CPAN/MyConfig.pm
    t/dot-cpan/cpan_sqlite_log.*
    t/dot-cpan/sources/authors/01mailrc.txt.gz
    t/dot-cpan/sources/modules/02packages.details.txt.gz
    t/dot-cpan/sources/modules/03modlist.data.gz
);

my %opts = (
    'NAME'          => 'CPAN::SQLite',
    'VERSION_FROM'  => 'lib/CPAN/SQLite.pm',
    'EXE_FILES'     => \@exe_files,
    'PL_FILES'      => {},
    'dist'          => {
        'SUFFIX'        => 'gz',
        'COMPRESS'      => 'gzip -9f',
    },
    'clean'         => {
        'FILES'          => $goners
    },
);

my $eu_version = $ExtUtils::MakeMaker::VERSION;
$eu_version =~ s/_//msgx;

if ($eu_version >= 5.43) {
    %opts = (%opts, 
        'ABSTRACT_FROM' => 'lib/CPAN/SQLite.pm',
        'AUTHOR'        => 'Serguei Trouchelle <stro@cpan.org>',
    );
}

my $prereqs = {
    'File::Spec'            => 0,
    'Archive::Tar'          => 1.54,
    'IO::Zlib'              => 0,
    'Compress::Zlib'        => 0,
    'CPAN::DistnameInfo'    => 0.09,
    'DBD::SQLite'           => 1.27, # for REGEXP implementation
    'File::HomeDir'         => 0,
    'HTTP::Tiny'            => 0,
    'CPAN::Index'           => 1.93, # No more false negatives because of CPAN-Index
    'parent'                => 0,
};

if ($ENV{'HARNESS_OPTIONS'}) {
  # Parallel testing requires Test::Harness 3.31
  $prereqs->{'Test::Harness'} = 3.31;
}

WriteMakefile( %opts, 'PREREQ_PM' => $prereqs);

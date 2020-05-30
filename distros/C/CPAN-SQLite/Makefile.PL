# $Id: Makefile.PL 83 2020-05-30 06:14:44Z stro $

use strict;
use warnings;

use ExtUtils::MakeMaker;

if ($ENV{'PERLBREW_ROOT'} && $ENV{'PERLBREW_ROOT'} =~ '/home/opc/perl5/perlbrew') {
    my $honest_answer = ExtUtils::MakeMaker::prompt('This smoker setup is most definitely broken and the author is tired of FP. Please type "Yes. I swear I fixed it. Please continue." to continue: ');
    unless ($honest_answer and $honest_answer eq 'Yes. I swear I fixed it. Please continue.') {
        print 'Kthxbye', $/;
        exit 0;
    }
}


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
    t/cpan-t-06/*
    t/cpan-t-07/*
    t/cpan-t-08/*
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
    'HTTP::Tiny'            => 0.041,
    'CPAN::Index'           => 1.93, # No more false negatives because of CPAN-Index
    'parent'                => 0,
};

my $test_prereqs = {
};

if ($ENV{'HARNESS_OPTIONS'}) {
  # Parallel testing requires Test::Harness 3.31
  $prereqs->{'Test::Harness'} = 3.31;
}

if ($eu_version >= '6.64') {
    %opts = (%opts,
        'PREREQ_PM' => $prereqs,
        'TEST_REQUIRES' => $test_prereqs,
    );
} else {
    %opts = (%opts,
        'PREREQ_PM' => { %{$prereqs}, %{$test_prereqs} },
    );
}

WriteMakefile( %opts );

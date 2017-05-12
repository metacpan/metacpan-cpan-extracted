use ExtUtils::MakeMaker;

require 5.006;
use Apache2::Module;
use mod_perl2;
use ModPerl::MM;
use Apache::TestMM qw(test clean);

# accept the configs from command line
Apache::TestMM::filter_args();

my @scripts = qw(t/TEST);
for (@scripts) {
    Apache::TestMM::generate_script($_);
    push @clean_files, $_;
}

my %require = (
    "Apache::Test" => "1.25", # ipv6 fixes
    "mod_perl"     => "2.000001"
);

ModPerl::MM::WriteMakefile(
    NAME          => "Apache2::DebugFilter",
    VERSION_FROM  => "lib/Apache2/DebugFilter.pm",
    clean         => {
        FILES => "@clean_files",
    },
    ABSTRACT_FROM => 'lib/Apache2/DebugFilter.pm',
    AUTHOR        => 'Philip M. Gollucci',
    PREREQ_PM     => \%require,
    dist          => {
        PREOP        => 'pod2text lib/Apache2/DebugFilter.pm > $(DISTVNAME)/README',
        COMPRESS     => 'gzip -9f',
        SUFFIX       => '.gz',
        ZIP          => 'zip',
        ZIPFLAGS     => '-r',
        DIST_DEFAULT => 'tardist',
    },


);

use strict;
#use warnings;
use warnings FATAL => 'all';
#no warnings 'redefine';

use mod_perl2;

# XXX: need to check that the same perl is used as the one mod_perl
# was built with, otherwise unresolved symbols problems occur:
# e.g. try using mod_perl.so built with blead-perl and build the
# scoreboard with blead-ithreads-perl
#use Apache::Build ();
#my $build = Apache::Build->new;
#use lib qw(../lib ../Apache-Test/lib);

use ModPerl::MM ();

# enable 'make test|clean'
use Apache::TestMM qw(test clean);

# prerequisites
my %require = (
    "Apache::Test" => "1.10", # ipv6 fixes
    "mod_perl"     => "2.00",
);

my @scripts = qw(t/TEST);

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

# get the apr header files, depending on where they are
my $apr_config = `which apr-config 2>/dev/null` || `which apr-1-config 2>/dev/null`;
chomp $apr_config;
my $apr_inc = `$apr_config --includedir`;
chomp $apr_inc;
my $extra_inc;
$extra_inc = "-I$apr_inc"	if ($apr_inc);

ModPerl::MM::build_config();
ModPerl::MM::WriteMakefile(
    NAME         => 'Apache::Scoreboard',
    VERSION_FROM => 'lib/Apache/Scoreboard.pm',
    PREREQ_PM    => \%require,
    clean        => {
        FILES => "@{ clean_files() }",
    },
    INC => join " ", $extra_inc, ModPerl::MM::get_def_opt('INC'),
);

sub clean_files {
    return \@scripts;
}


__END__

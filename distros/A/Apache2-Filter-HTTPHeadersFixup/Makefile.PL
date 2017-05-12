use strict;
use warnings FATAL => 'all';

require 5.006;

use ModPerl::MM ();

# enable 'make test|clean'
use Apache::TestMM qw(test clean);

# prerequisites
my %require = (
    "mod_perl"      => "2.000001",
    "Apache::Test"  => "1.25",
);

my @scripts = qw(t/TEST);

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

ModPerl::MM::WriteMakefile(
    NAME         => 'Apache2::Filter::HTTPHeadersFixup',
    VERSION_FROM => 'lib/Apache2/Filter/HTTPHeadersFixup.pm',
    PREREQ_PM    => \%require,
    clean        => {
        FILES => "@{ clean_files() }",
    }
);

sub clean_files {
    return \@scripts;
}



__END__

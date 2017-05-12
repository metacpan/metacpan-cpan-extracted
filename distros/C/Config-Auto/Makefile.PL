use ExtUtils::MakeMaker;

use strict;
use Getopt::Std;
my $opts = {};
getopts( 'x', $opts );

my $have_xml_simple = eval { require XML::Simple; 1; };

if( !$have_xml_simple and !$opts->{'x'} ) {
    warn qq[Since the 0.04 release, XML::Simple is an optional prerequisite.\n].
         qq[If you'd like to install Config::Auto with XML support, please\n] .
         qq[rerun this Makefile.PL with the '-x' option\n];
}

my $prereqs = {
    'XML::Simple'           => 0,
    'YAML'                  => 0.67,
    'Config::IniFiles'      => 0,
    'File::Spec::Functions' => 0,
    'Test::More'            => 0,
    'Text::ParseWords'      => 0,
    'File::Temp'            => 0,
    'IO::String'            => 0,
};
delete $prereqs->{'XML::Simple'} unless $opts->{'x'};

WriteMakefile1(
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jib/config-auto',
        },
    },
    'NAME'		        => 'Config::Auto',
    'VERSION_FROM'	    => 'lib/Config/Auto.pm', # finds $VERSION
    'PREREQ_PM'		    => $prereqs,
    ABSTRACT_FROM => 'lib/Config/Auto.pm',
    AUTHOR => 'Jos I. Boumans <kane@cpan.org>',
);

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

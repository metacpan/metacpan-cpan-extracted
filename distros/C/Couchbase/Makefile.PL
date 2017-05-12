#!/usr/bin/perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Getopt::Long;
use File::Spec;
use Config;

$ENV{LD_RUN_PATH} ||= "";

GetOptions(
    'incpath=s' => \my $U_IncPath,
    'libpath=s' => \my $U_LibPath) or die <<EOD;
OPTIONS:
--incpath=CPPFLAGS
--libpath=LDFLAGS
EOD

our (@LIBS, $INC);

push @LIBS, $U_LibPath if $U_LibPath;
$INC = $U_IncPath || "";

push @LIBS, '-lcouchbase';

my %MM_Options = (
    INC  => $INC,
    LIBS => [ join(' ', @LIBS) || '' ],);

################################################################################
### Our C Source Files                                                       ###
################################################################################
my @C_Modules  = qw(args async callbacks constants convert operations opcontext query);
my @XS_Modules = qw(Couchbase BucketConfig IO N1QLParams);

foreach (@XS_Modules, @C_Modules) {
    my $obj = $_ . $Config{obj_ext};
    push @{ $MM_Options{OBJECT} }, File::Spec->catfile('xs', $obj);
}

$MM_Options{OBJECT} = join(' ', @{ $MM_Options{OBJECT} });

foreach my $xs (@XS_Modules) {
    $xs = File::Spec->catfile('xs', $xs);
    my $c = "$xs.c";
    $xs = "$xs.xs";
    $MM_Options{XS}->{$xs} = $c;
}

################################################################################
### Check build type and options                                             ###
################################################################################

if ($ENV{PLCB_BUILD_AUTHOR}) {
    $MM_Options{OPTIMIZE} = '-Wdeclaration-after-statement -Werror -std=gnu89';
}
# Extra stuff - add compiler flags here
# $MM_Options{OPTIMIZE} .= ' -Wall';

$MM_Options{NEEDS_LINKING} = 1;

$MM_Options{META_MERGE} = { resources => { repository => 'https://github.com/mnunberg/perl-Couchbase-Client' } };

if (!-f 'Changes') {
    # eek
    system("git log > Changes");
}

# some MakeMaker versions have underscores, like 6.55_02
my ($makemaker_version) = $ExtUtils::MakeMaker::VERSION =~ /^(\d+\.\d+)/;

WriteMakefile(
    NAME          => 'Couchbase',
    AUTHOR        => q{M. Nunberg <mnunberg@haskalah.org>},
    ABSTRACT_FROM => 'lib/Couchbase.pm',
    VERSION_FROM  => 'lib/Couchbase/Core.pm',
    LICENSE       => 'perl_5',
    PREREQ_PM     => {
        'Class::XSAccessor' => 1.11,
        'JSON::MaybeXS'       => '0',
        'URI'               => '0',
        'Constant::Generate'=> '0.16'
    },

    !$makemaker_version || $makemaker_version >= 6.64
    ? ( TEST_REQUIRES => {
            #These modules are needed for tests, but not strictly required for
            #functionality

            'Test::More'  => 0,
            'Test::Class' => 0.36,
            'Log::Fu'     => 0,
            'Dir::Self'   => 0
        })
    : (),

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Couchbase-* COMPILER_FLAGS log.test-*' },
    %MM_Options,);

package MY;
use Config;
use strict;
use warnings;

#thanks rafl!
sub const_cccmd {
    my $ret = shift->SUPER::const_cccmd(@_);
    return q{} unless $ret;
    if ($Config{cc} =~ /^cl\b/i) {
        warn 'you are using MSVC... my condolences.';
        $ret .= ' /Fo$@';
    } else {
        $ret .= ' -o $@';
    }
    return $ret;
}

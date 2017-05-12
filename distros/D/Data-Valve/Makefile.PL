use strict;
use ExtUtils::MakeMaker;

my %config;

for(my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] =~ /^--debugging$/) {
        splice(@ARGV, $i, 1);
        $config{debugging} = 1;
        $i--;
    }
}


my %INFO = (
    ABSTRACT     => 'Yet Another Data Throttler',
    AUTHOR       => 'Daisuke Maki <daisuke@endeworks.jp>',
    DISTNAME     => 'Data-Valve',
    LICENSE      => 'perl',
    NAME         => "Data::Valve",
    OBJECT       => '$(O_FILES)',
    PREREQ_PM    => {
        'Moose' => 0,
        'MooseX::KeyedMutex' => '0.00003',
        'Test::More' => 0,
        'Test::UseAllModules' => 0,
    },
    VERSION_FROM => 'lib/Data/Valve.pm',
);

$INFO{ OPTIMIZE } = '-g' if $config{debugging};


WriteMakefile(%INFO);
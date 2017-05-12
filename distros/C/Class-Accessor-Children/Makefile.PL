use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'Class::Accessor::Children',
    VERSION_FROM        =>  'lib/Class/Accessor/Children.pm',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Class::Accessor'   =>  '0',
    },
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'perl' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );

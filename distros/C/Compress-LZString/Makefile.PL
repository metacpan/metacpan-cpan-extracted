use 5.006;
use utf8;
use ExtUtils::MakeMaker;

my %make = (
    NAME              => 'Compress::LZString',
    VERSION_FROM      => 'lib/Compress/LZString.pm',
    ABSTRACT_FROM     => 'lib/Compress/LZString.pm',
    MIN_PERL_VERSION  => '5.006002',

    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/poppova/lz-string-perl.git',
                web  => 'https://github.com/poppova/lz-string-perl',
            },
            bugtracker => {
                web  => 'https://github.com/poppova/lz-string-perl/issues',
            },
        },
    },
    LICENSE           => 'perl',
    AUTHOR            => 'Lucia Poppová <popp@cpan.org>',
);

my $eumm_ver = $ExtUtils::MakeMaker::VERSION;
delete $make{LICENSE}          if $eumm_ver < 6.31;
delete $make{META_MERGE}       if $eumm_ver < 6.46;
delete $make{MIN_PERL_VERSION} if $eumm_ver < 6.48;

WriteMakefile(%make);

use strict;
use warnings;

use ExtUtils::MakeMaker;

ExtUtils::MakeMaker->VERSION('7.00') unless -f 'META.yml';
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %WriteMakefileArgs = (
    NAME => 'Catalyst::View::TT',
    VERSION_FROM => 'lib/Catalyst/View/TT.pm',
    AUTHOR => 'Sebastian Riedel <sri@cpan.org>',
    LICENSE => 'perl_5',
    MIN_PERL_VERSION => 5.008001,  # catalyst minimum
    PREREQ_PM => {
        'Catalyst'          => '5.7',
        'Template'          => 0,
        'Class::Accessor'   => 0,
        'Template::Timer'   => 0,
        'Path::Class'       => 0,
        'MRO::Compat'       => 0,
        'Data::Dump'        => 0,
    },
    TEST_REQUIRES => {
        'Test::More'        => '0.88',
        'File::Spec'        => '0',
        'List::Util'        => '1.33',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        resources => {
            # r/w: catagits@git.shadowcat.co.uk:Catalyst-View-TT
            # r/o: git://git.shadowcat.co.uk:catagits/Catalyst-View-TT
            # web: http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=catagits/Catalyst-View-TT.git
            repository => {
                url => 'https://github.com/perl-catalyst/Catalyst-View-TT.git',
                web => 'https://github.com/perl-catalyst/Catalyst-View-TT',
                type => 'git',
            },
            bugtracker => {
                mailto => 'bug-Catalyst-View-TT@rt.cpan.org',
                web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-View-TT',
            },
            x_MailingList => 'http://lists.scsys.co.uk/cgi-bin/mailman/listinfo/catalyst',
            x_IRC => 'irc://irc.perl.org/#catalyst',
        },
    },
);

die 'need to do a merge with CPAN::Meta::Requirements!!'
    if !-f 'META.yml' && exists $WriteMakefileArgs{BUILD_REQUIRES};

if (!eval { ExtUtils::MakeMaker->VERSION('6.6303') }) {
    $WriteMakefileArgs{BUILD_REQUIRES} = $WriteMakefileArgs{TEST_REQUIRES};
    delete $WriteMakefileArgs{TEST_REQUIRES};
}

if (!eval { ExtUtils::MakeMaker->VERSION('6.5501') }) {
    @{$WriteMakefileArgs{PREREQ_PM}}{ keys %{$WriteMakefileArgs{BUILD_REQUIRES}} } =
        @{$WriteMakefileArgs{BUILD_REQUIRES}}{ keys %{$WriteMakefileArgs{BUILD_REQUIRES}} };

    delete $WriteMakefileArgs{BUILD_REQUIRES};
}

my %mm_req = (
    LICENCE => 6.31,
    META_MERGE => 6.45,
    META_ADD => 6.45,
    MIN_PERL_VERSION => 6.48,
);
for (keys %mm_req) {
    unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
        warn "$_ $@" if not -f 'Makefile.PL';
        delete $WriteMakefileArgs{$_};
    }
}

WriteMakefile(%WriteMakefileArgs);

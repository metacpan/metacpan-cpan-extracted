use strict;
use warnings;
use ExtUtils::MakeMaker;

my $choice = 'Builder';  # API2 or Builder default prerequisite?
my $debug = 0;  # 1 to just dump contents
my %versions = (  # minimum version for either
    'API2'    => 2.038,
    'Builder' => 3.021,
);

my %WriteMakefileArgs = (
    NAME                => 'CtrlO::PDF',
    AUTHOR              => q{Andy Beverley <andy@andybev.com>},
    VERSION_FROM        => 'lib/CtrlO/PDF.pm',
    ABSTRACT_FROM       => 'lib/CtrlO/PDF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    BUILD_REQUIRES => {
        'Test::MockObject' => 0,
        'Test::More'  => 0,
        'Test::Warn'  => 0,
        'DateTime::Format::SQLite' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Image::Info' => 0,
        'Moo' => 0,
        'MooX::Types::MooseLike::Base' => 0,
        'PDF::Table' => 0,
        'PDF::TextBlock' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CtrlO-PDF*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/ctrlo/CtrlO-PDF',
            bugtracker => 'https://github.com/ctrlo/CtrlO-PDF/issues',
            homepage   => 'https://github.com/ctrlo/CtrlO-PDF/',
        },
    },

);

# if neither PDF::API2 nor PDF::Builder is installed, prereq one of them
my $rc;
$rc = eval {
    require PDF::API2;
    1;
};
if (!defined $rc) { $rc = 0; }
if ($rc) {
    # PDF::API2 installed but not up to date?
    if ($PDF::API2::VERSION < $versions{'API2'}) { $rc = 0; }
}
if (!$rc) {
    # no PDF::API2. try PDF::Builder.
    $rc = eval {
        require PDF::Builder;
        1;
    };
    if (!defined $rc) { $rc = 0; }
    if ($rc) {
        # PDF::Builder installed but not up to date?
        if ($PDF::Builder::VERSION < $versions{'Builder'}) { $rc = 0; }
    }
}
# suitable level of PDF::* not already installed?
if (!$rc) {
    $WriteMakefileArgs{'PREREQ_PM'}{"PDF::$choice"} = $versions{$choice};
}

if ($debug) {
    use Data::Dumper;  # two lines for checking prereq work
    print Dumper(\%WriteMakefileArgs);
} else {
    WriteMakefile(%WriteMakefileArgs);
}

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;
use File::Basename qw(dirname);
use File::Spec;

my $dirname = dirname(__FILE__);
my @required_files = (
    File::Spec->catfile("ruby-money", "config", "currency_backwards_compatible.json"),
    File::Spec->catfile("ruby-money", "config", "currency_iso.json"),
    File::Spec->catfile("ruby-money", "config", "currency_non_iso.json"),
    File::Spec->catfile("ruby-money", "LICENSE"),
    File::Spec->catfile("ruby-money", "README.md"),
);
for my $file (@required_files) {
    my $path = File::Spec->catfile($dirname, $file);
    if (! -e $path) {
        die "Expected file '$path' to exist, have you checked out the submodule?";
    }
}

install_share dist => File::Spec->catfile("ruby-money", "config");

WriteMakefile(
    NAME             => 'Data::MoneyCurrency',
    AUTHOR           => q{David D Lowe <daviddlowe.flimm@gmail.com>},
    VERSION_FROM     => 'lib/Data/MoneyCurrency.pm',
    ABSTRACT_FROM    => 'lib/Data/MoneyCurrency.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        homepage => 'https://github.com/Flimm/perl5-Data-MoneyCurrency',
        bugtracker => {
            web => 'https://github.com/Flimm/perl5-Data-MoneyCurrency/issues',
        },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/Flimm/perl5-Data-MoneyCurrency.git',
                web => 'https://github.com/Flimm/perl5-Data-MoneyCurrency',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
    },
    PREREQ_PM => {
        'File::ShareDir' => 0,
        'JSON' => 0,
        'Types::Serialiser' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-MoneyCurrency-*' },
);

package MY;
use File::ShareDir::Install qw(postamble);

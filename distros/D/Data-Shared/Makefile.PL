use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use lib 'lib';

# MIN_PERL_VERSION only warns; these gates must run before the require below.
if ($] < 5.022) { print "Perl 5.22 or later required\n"; exit 0 }
unless ($^O eq 'linux') { print "OS unsupported: requires Linux\n"; exit 0 }
if ($Config{ivsize} < 8) { print "OS unsupported: requires 64-bit Perl\n"; exit 0 }
require Data::Shared::Registry;

my $version = MM->parse_version('lib/Data/Shared.pm');
my %backends = map {
    my $entry = $_;
    (my $module = $entry->{dist}) =~ s/-/::/g;
    ($module => $entry->{min_version});
} values %{ Data::Shared::Registry::registry() };

WriteMakefile(
    NAME             => 'Data::Shared',
    VERSION_FROM     => 'lib/Data/Shared.pm',
    ABSTRACT_FROM    => 'lib/Data/Shared.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.022',
    PREREQ_PM        => {
        'JSON::PP' => 0,
        "File::Temp" => 0,
        "File::Path" => 0,
    },
    TEST_REQUIRES => {
        'Test::More'      => '0.96',
        'File::Temp'      => 0,
        'File::Path'      => 0,
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        # Recommended only: mounting a type whose dist is missing croaks naming it.
        prereqs => { runtime => { recommends => \%backends } },
        no_index => { directory => [qw(xt eg bench)] },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-data-shared.git',
                web  => 'https://github.com/vividsnow/perl5-data-shared',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-data-shared/issues',
            },
        },
        # xt/manifest.t checks this against MANIFEST.
        provides => {
            map { (my $m = $_) =~ s{^lib/|\.pm\z}{}g; $m =~ s{/}{::}g;
                  ($m => { file => $_, version => $version }) }
                glob('lib/Data/Shared.pm lib/Data/Shared/*.pm lib/Data/Shared/Adapter/*.pm'),
        },
    },
    clean => { FILES => 'MANIFEST.bak' },
);

# Only a checkout regenerates README; a release keeps the one it shipped.
sub MY::postamble {
    return '' unless -e '.git';
    return <<'MAKE';
pure_all :: README
	$(NOECHO) $(NOOP)

create_distdir : README

README : lib/Data/Shared.pm
	$(PERLRUN) -MPod::Text -e 'Pod::Text->new->parse_from_file(@ARGV)' lib/Data/Shared.pm README.tmp
	$(MV) README.tmp README
MAKE
}

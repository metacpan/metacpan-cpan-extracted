use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Build;
use My::Module::Meta;
use My::Module::Recommend;
use Module::Build;
use Config;
use FileHandle;

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %attr = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Class to compute Iridium Classic flares',
    module_name => 'Astro::Coord::ECI::TLE::Iridium',
#   dist_name => 'Astro-Coord-ECI-TLE-Iridium',
    dist_version_from => 'lib/Astro/Coord/ECI/TLE/Iridium.pm',
    requires => $meta->requires(
	perl => $meta->requires_perl(),
    ),
    build_requires => $meta->build_requires(),
    get_options => {y => {}, n => {}},
    dynamic_config => 1,
    license => 'perl',
    add_to_cleanup => [ qw{ cover_db xt/author/optionals } ],
);

$mbv >= 0.28
    and $attr{meta_merge} = $meta->meta_merge();

# Don't require Module::Build if we are making a distribution, since the
# user may choose to use ExtUtils::MakeMaker.
$mbv >= 0.34
    and $attr{auto_configure_requires} = !$meta->distribution();

My::Module::Recommend->recommend();

my $bldr = My::Module::Build->new (%attr);

$bldr->create_build_script ();

# ex: set textwidth=72 :

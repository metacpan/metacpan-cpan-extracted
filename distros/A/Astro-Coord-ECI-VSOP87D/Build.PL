use strict;
use warnings;

use 5.008;

use lib qw{ inc };

use Module::Build;
use My::Module::Build;
use My::Module::Meta;

(my $mbv = Module::Build->VERSION()) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    dist_author => 'Thomas R. Wyant, III F<wyant at cpan dot org>',
    dist_abstract => 'Implement the VSOP87D position model.',
    module_name => 'Astro::Coord::ECI::VSOP87D',
    build_requires => $meta->build_requires(),
    requires => $meta->requires(
	perl => $meta->requires_perl(),
    ),
    license => 'perl',
);

if ( $mbv >= 0.28 ) {
    $args{meta_merge} = $meta->meta_merge();
    $args{meta_add} = {
	no_index	=> {
	    directory	=> [ qw{ inc t xt } ],
	},
    };
}

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new (%args);

$bldr->create_build_script ();

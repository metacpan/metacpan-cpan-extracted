use strict;
use warnings;

use 5.006;

use lib qw{ inc };

use Module::Build;
use My::Module::Build;
use My::Module::Meta;

(my $mbv = Module::Build->VERSION()) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Represent Universal Tracking Data Format (UTDF) data',
    module_name => 'Astro::UTDF',
    build_requires => $meta->build_requires(),
    requires => $meta->requires(
	perl => $meta->requires_perl(),
    ),
    license => 'perl',
);

$mbv >= 0.28
    and $args{meta_merge} = $meta->meta_merge();

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new (%args);

$bldr->create_build_script ();

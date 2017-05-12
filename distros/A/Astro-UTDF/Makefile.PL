use strict;
use warnings;

use 5.006;

use lib qw{ inc };

use ExtUtils::MakeMaker;
use My::Module::Meta;

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    NAME => 'Astro::UTDF',
    VERSION_FROM => 'lib/Astro/UTDF.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    AUTHOR => 'Tom Wyant (wyant at cpan dot org)',
    ABSTRACT => 'Represent Universal Tracking Data Format (UTDF) data',
);

$mmv >= 6.31 and $args{LICENSE} = 'perl';

$mmv >= 6.4501
    and $args{META_MERGE} = $meta->meta_merge();

$mmv >= 6.4701 and $args{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $args{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $args{META_MERGE}{build_requires} = $meta->build_requires();

WriteMakefile (%args);

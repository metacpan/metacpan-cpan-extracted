use 5.22.0;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Astro-Montenbruck',
    license             => 'artistic_1',
    dist_author         => q{Sergey Krushinsky <krushi at cpan.org>},
    dist_version_from   => 'lib/Astro/Montenbruck.pm',
    release_status      => 'stable',
    configure_requires  => {
        'Module::Build' => '0',
    },
    build_requires => {
        'Test::More'    => '1.30',
        'Test::Simple'  => '1.30',
        'Test::Harness' => '3.38',
        'Test::CheckManifest' => '0.9',
        'Test::Pod::Coverage' => '1.08',
        'Pod::Simple::HTMLBatch' => '0',
        'Pod::Simple::XHTML' => '0'
    },
    requires => {
        'Readonly'        => '2.05',
        'Memoize'         => '1.03',
        'Term::ANSIColor' => '1.00',
        'DateTime'        => '1.44',
        'DateTime::Format::Strptime' => '1.76',
        'List::MoreUtils'  => '0.43',
        'Test::Number::Delta' => '1.06',        
    },
    add_to_cleanup        => [ 'Astro-*' ],
);

$builder->create_build_script();

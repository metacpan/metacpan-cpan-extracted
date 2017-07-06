use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Dancer2::Plugin::Locale',
    license           => 'artistic2',
    dist_author       => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    dist_version_from => 'lib/Dancer2/Plugin/Locale.pm',
    requires          => {
        'Test::More'              => 0,
        'Plack::Test'             => 0,
        'HTTP::Request::Common'   => 0,
        'Dancer2::Plugin'         => 0,
        'Locale::Maketext::Utils' => 0,
        'Locales'                 => 0.33,
        'File::Spec'              => 0,
        'File::Path::Tiny'        => 0,
        'Template'                => 0,
    },

    # delete_share => '.', # NYI https://rt.cpan.org/Ticket/Display.html?id=92863
    # install_share => 'share',
    add_to_cleanup => ['Dancer2-Plugin-Locale-*'],
);

$builder->create_build_script();

# package MY;
# use File::ShareDir::Install 0.07 qw(postamble);
# File::ShareDir::Install::delete_share('.');

use inc::Module::Install 0.91;
use strict;
use warnings;
use 5.008006;

BEGIN {
    if ($Module::Install::AUTHOR) {
        require Module::Install::AuthorRequires;
    }
}

license  'perl';

name     'Catalyst-Engine-Stomp';
all_from 'lib/Catalyst/Engine/Stomp.pm';

requires 'Catalyst::Engine::Embeddable'  => '0.0.1';
requires 'Catalyst::Runtime'  => '5.80004';
requires 'Moose' => undef;
requires 'MooseX::Types' => undef;
requires 'MooseX::Workers' => '0.05';
requires 'Net::Stomp' => '0.34';
requires 'YAML::XS' => '0.32';
requires 'YAML' => undef;
requires 'Data::Serializer' => '0.49';
requires 'namespace::autoclean' => '0.05';

test_requires 'Alien::ActiveMQ' => '0.00003';
test_requires 'Catalyst::Plugin::ConfigLoader' => undef;

author_requires 'Test::NoTabs';
author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';
author_requires 'Pod::Coverage';

if ($Module::Install::AUTHOR) {
    darwin_check_no_resource_forks();
}

resources
    'repository' => 'git://github.com/pmooney/catalyst-engine-stomp.git',
    'license' => 'http://dev.perl.org/licenses/';

install_script glob('script/*.pl');
auto_install;
WriteAll;

sub darwin_check_no_resource_forks {
    if ($^O eq 'darwin') {
        my $osx_ver = `/usr/bin/sw_vers -productVersion`;
        chomp $osx_ver;

        # TAR on 10.4 wants COPY_EXTENDED_ATTRIBUTES_DISABLE
        # On 10.5 (Leopard) it wants COPYFILE_DISABLE
        my $attr = $osx_ver =~ /^10.5/ ? 'COPYFILE_DISABLE' : 'COPY_EXTENDED_ATTRIBUTES_DISABLE';

        makemaker_args(dist => { PREOP => qq{\@if [ "\$\$$attr" != "true" ]; then}.
                                          qq{ echo "You must set the ENV variable $attr to true,"; }.
                                          ' echo "to avoid getting resource forks in your dist."; exit 255; fi' });
        }
}


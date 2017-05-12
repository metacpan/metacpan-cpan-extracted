use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use TestUtil;

use Test::More 'no_plan';
use CPAN::Plugin::Sysdeps ();
require_CPAN_Distribution;

sub get_plugin_obj {
    my $opt = shift;
    CPAN::Plugin::Sysdeps->new('batch', 'dryrun', "mapping=$FindBin::RealBin/mapping/sample.pl", $opt);
}

sub get_debian_jessie_plugin_obj {
    get_plugin_obj({ os => 'linux', linuxdistro => 'debian', linuxdistroversion => 8, linuxdistrocodename => 'jessie' });
}

{
    my $cpandist = CPAN::Distribution->new(
					   ID => 'X/XX/XXX/Linux-Only-1.0.tar.gz',
					   CONTAINSMODS => { 'Linux::Only' => undef },
					  );
    is_deeply [get_debian_jessie_plugin_obj()->_map_cpandist($cpandist)], ['libfoo-dev'];
    is_deeply [get_plugin_obj({ os => 'freebsd', osvers => '9.1-RELEASE' })->_map_cpandist($cpandist)], [];
}

{
    my $cpandist = CPAN::Distribution->new(
					   ID => 'X/XX/XXX/FreeBSD-Only-1.0.tar.gz',
					   CONTAINSMODS => { 'FreeBSD::Only' => undef },
					  );
    is_deeply [get_debian_jessie_plugin_obj()->_map_cpandist($cpandist)], [];
    is_deeply [get_plugin_obj({ os => 'freebsd', osvers => '9.1-RELEASE' })->_map_cpandist($cpandist)], ['libfoo'];
}

{
    my $cpandist = CPAN::Distribution->new(
					   ID => 'X/XX/XXX/FreeBSD-Version-1.0.tar.gz',
					   CONTAINSMODS => { 'FreeBSD::Version' => undef },
					  );
    is_deeply [get_debian_jessie_plugin_obj()->_map_cpandist($cpandist)], [];
    is_deeply [get_plugin_obj({ os => 'freebsd', osvers => '0.1-RELEASE' })->_map_cpandist($cpandist)], [];
    is_deeply [get_plugin_obj({ os => 'freebsd', osvers => '9.1-RELEASE' })->_map_cpandist($cpandist)], ['gcc'];
    is_deeply [get_plugin_obj({ os => 'freebsd', osvers => '10.1-RELEASE' })->_map_cpandist($cpandist)], ['clang'];
}

{
    my $cpandist = CPAN::Distribution->new(
					   ID => 'X/XX/XXX/Multi-Packages-1.0.tar.gz',
					   CONTAINSMODS => { 'Multi::Packages' => undef },
					  );
    is_deeply [get_debian_jessie_plugin_obj()->_map_cpandist($cpandist)], ['package-one', 'package-two'];
    is_deeply [get_plugin_obj({ os => 'freebsd', osvers => '10.1-RELEASE' })->_map_cpandist($cpandist)], ['package-one', 'package-two'];
}

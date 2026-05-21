use v5.40;

use Container::Builder;

my $builder = Container::Builder->new(debian_pkg_hostname => 'debian.inf.tu-dresden.de', os_version => 'trixie', enable_packages_cache => 1, packages_file => 'Packages', cache_folder => 'artifacts');
$builder->create_directory('/', 0755, 0, 0);
$builder->create_directory('bin/', 0755, 0, 0);
$builder->create_directory('tmp/', 01777, 0, 0);
$builder->create_directory('root/', 0700, 0, 0);
$builder->create_directory('home/', 0755, 0, 0);
$builder->create_directory('home/larry/', 0700, 1337, 1337);
$builder->create_directory('etc/', 0755, 0, 0);
$builder->create_directory('app/', 0755, 1337, 1337);
# Base
$builder->add_deb_package('base-files');
$builder->add_deb_package('netbase');
$builder->add_deb_package('tzdata');
$builder->add_deb_package('media-types');
my $nsswitch = <<'NSS';
# /etc/nsswitch.conf
#
# Example configuration of GNU Name Service Switch functionality.
# If you have the `glibc-doc-reference' and `info' packages installed, try:
# `info libc "Name Service Switch"' for information about this file.

passwd:         compat
group:          compat
shadow:         compat
gshadow:        files

hosts:          files dns
networks:       files

protocols:      db files
services:       db files
ethers:         db files
rpc:            db files

netgroup:       nis
NSS
$builder->add_file_from_string($nsswitch, '/etc/nsswitch.conf', 0644, 0, 0);

# C dependencies (to run a compiled executable)
$builder->add_deb_package('libc-bin');
$builder->add_deb_package('libc6');
$builder->add_deb_package('gcc-14-base');
$builder->add_deb_package('libgcc-s1');
$builder->add_deb_package('libgomp1');
$builder->add_deb_package('libstdc++6');
$builder->add_deb_package('ca-certificates');
# SSL support
$builder->add_deb_package('libssl3');
# Perl dependencies (to run a basic Perl program)
$builder->add_deb_package('libcrypt1');
$builder->add_deb_package('perl');
# My fatpack expects these to be already installed somehow
$builder->add_deb_package('libtry-tiny-perl');
$builder->add_deb_package('libdevel-stacktrace-perl');
$builder->add_deb_package('libdevel-stacktrace-ashtml-perl');
$builder->add_deb_package('libcrypt-bcrypt-perl');
# html::parser contains xs code so no can do with fatpack
$builder->add_deb_package('libhtml-parser-perl');
# same for Clone 
$builder->add_deb_package('libclone-perl');
$builder->add_group('root', 0);
$builder->add_group('tty', 5);
$builder->add_group('staff', 50);
$builder->add_group('larry', 1337);
$builder->add_group('nobody', 65000);
$builder->add_user('root', 0, 0, '/sbin/nologin', '/root');
$builder->add_user('nobody', 65000, 65000, '/sbin/nologin', '/nohome');
$builder->add_user('larry', 1337, 1337, '/sbin/nologin', '/home/larry');
$builder->runas_user('larry');
$builder->set_env('PATH', '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin');
$builder->set_work_dir('/app');
$builder->add_file('fatpacked.plackup', '/app/plackup', 0755, 1337, 1337);
$builder->set_entry('/app/plackup');
$builder->build('05-plackup-trixie.tar');
say "Now run: podman load -i 05-plackup-trixie.tar";
say "Then run: podman tag " . substr($builder->get_digest(), 0, 12) . " localhost/plackup-trixie:latest";

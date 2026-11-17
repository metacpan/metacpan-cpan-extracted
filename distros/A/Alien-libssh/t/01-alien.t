#!/usr/bin/env perl
use Test2::V0;
use Test::Alien;
use Alien::libssh;

alien_ok 'Alien::libssh';

# Net::LibSSH calls the known-hosts API (ssh_session_is_known_server), which
# libssh only has from 0.9.0 -- the same floor the alienfile probe carries.
my $floor = '0.9.0';

my $version = Alien::libssh->version;
ok defined $version, 'the linked libssh reports a version' or diag 'no version';
diag "linked libssh $version (install type: ", Alien::libssh->install_type, ')';
ok( version->parse($version) >= version->parse($floor), "libssh $version >= $floor" );

if (Alien::libssh->install_type eq 'share') {
    my ($tarball) = glob 'share/libssh-*.tar.xz';
    my ($bundled) = $tarball =~ /libssh-([\d.]+)\.tar\.xz\z/;
    is $version, $bundled, "share build is the bundled libssh $bundled";

    # A static bundle is never updated by the OS, so the tarball itself must
    # not fall behind the first release that carries the 2026 security fixes
    # (0.11.5 on the 0.11 line, 0.12.2 on the 0.12 line).
    my $secure = '0.11.5';
    ok( version->parse($bundled) >= version->parse($secure), "bundled libssh $bundled >= $secure" );
}

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libssh/libssh.h>

MODULE = MyAlienTest PACKAGE = MyAlienTest

const char *
linked_version(klass)
    const char *klass
  CODE:
    RETVAL = ssh_version(0);
  OUTPUT:
    RETVAL

int
has_known_hosts_api(klass)
    const char *klass
  CODE:
    /* taking the addresses makes the link fail, not just the call, on a libssh without them */
    RETVAL = ((void *)ssh_session_is_known_server != NULL
           && (void *)ssh_session_update_known_hosts != NULL) ? 1 : 0;
  OUTPUT:
    RETVAL

int
can_ssh_new(klass)
    const char *klass
  CODE:
    ssh_session s = ssh_new();
    RETVAL = s ? 1 : 0;
    if (s) ssh_free(s);
  OUTPUT:
    RETVAL

END

xs_ok $xs, with_subtest {
    my ($module) = @_;
    ok $module->can_ssh_new, 'ssh_new() works via libssh';
    ok $module->has_known_hosts_api, 'known-hosts API is linked';
    like $module->linked_version, qr/^\d+\.\d+\.\d+/, 'ssh_version() answers from the linked library';
    diag 'ssh_version(): ', $module->linked_version;
};

done_testing;

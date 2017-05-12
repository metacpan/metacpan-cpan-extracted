## t/09-symlink.t
##
## Written 2011 by Scott Hardin for the OpenXPKI project
## Copyright (C) 2010-12 by Scott T. Hardin
##
## This tests the support for symlinks in the git repository
##
## vim: syntax=perl

use Test::More tests => 27;

use strict;
use warnings;
my $gittestdir = qw( t/09-symlink.git );

my $ver1 = '9b8d56e2c292af6d2ce37ac39abfed773aa114f4';
my $ver2 = '590010b5bc646d5744a05c08543db0ff0c5f8b9e';
my $ver3 = 'f222693846e602182b317d50730236542a77429e';

BEGIN {
    my $gittestdir = qw( t/09-symlink.git );

    # remove artifacts from previous run
    use Path::Class;
    use DateTime;
    dir($gittestdir)->rmtree;

    # fire it up!
    use_ok(
        'Config::Versioned',
    );
}

##
## BASIC INIT
##

my $cfg = Config::Versioned->new(
        {
            dbpath      => $gittestdir,
            autocreate  => 1,
            filename    => '09-symlink.conf',
            path        => [qw( t )],
            commit_time => DateTime->from_epoch( epoch => 1240341682 ),
            author_name => 'Test User',
            author_mail => 'test@example.com',
        }
);
ok( $cfg, 'create new config instance' );

# Internals: check that the head really points to a commit object
is( $cfg->_git()->head->kind, 'commit', 'head should be a commit' );

is( $cfg->version, $ver1, 'check version (sha1 hash) of first commit' );

# force a re-load of the configuration file we already used to ensure
# that we don't add a commit when there were no changes
$cfg->parser();
is( $cfg->version, $ver1, 're-import should not create new commit' );

# check the internal helper functions
my ( $s1, $k1 ) = $cfg->_get_sect_key('group1.ldap');
is( $s1, 'group1', "_get_sect_key section" );
is( $k1, 'ldap',   "_get_sect_key section" );

my $obj = $cfg->_findobj('group.ldap');
is( $obj, undef, '_findobj for group.ldap should fail' );

$obj = $cfg->_findobj('group1.ldap1');
is( ref($obj), 'Git::PurePerl::Object::Tree',
    '_findobj for group1.ldap1 should return an object' );
is( $obj->kind, 'tree', "_findobj() returns tree" );

$obj = $cfg->_findobj('group1.ldap1.uri');
is( $obj->kind, 'blob', "_findobj() returns blob" );

is( $cfg->get('group1.ldap1.uri'),
    'ldaps://example1.org', "check single attribute" );

$cfg->parser(
    {
        filename    => '09-symlink-2.conf',
        path        => [qw( t )],
        commit_time => DateTime->from_epoch( epoch => 1240351682 ),
        author_name => 'Test User',
        author_mail => 'test@example.com',
    }
);
is( $cfg->version, $ver2, 'check version of second commit' );

$cfg->parser(
    {
        filename    => '09-symlink-3.conf',
        path        => [qw( t )],
        commit_time => DateTime->from_epoch( epoch => 1240361682 ),
        author_name => 'Test User',
        author_mail => 'test@example.com',
    }
);
is( $cfg->version, $ver3, 'check version of third commit' );

# Try to get different versions of some values
is( $cfg->get('group2.ldap2.user'),
    'openxpkiA', "newest version of group2.ldap2.user" );
is( $cfg->get( 'group2.ldap2.user', $ver1 ),
    'openxpki2', "oldest version of group2.ldap2.user" );

# sort 'em just to be on the safe side
my @attrlist = sort( $cfg->listattr('group1.ldap1') );
is_deeply( \@attrlist, [ sort(qw( uri user password )) ], "check attr list" );

is( $cfg->kind('group1.ldap1'), 'tree', 'kind() returns tree');
is( $cfg->kind('group1.ldap1.user'), 'blob', 'kind() returns blob');

my $sym = $cfg->get('groupsym.ldapsym2');
is( ref($sym), 'SCALAR', 'check value of symlink is anon ref to scalar');
is( ${$sym}, 'conns/c2', 'check target of symlink');
my $sym3 = $cfg->get('groupsym.ldapsym3');
is( ref($sym3), 'SCALAR', 'check value of symlink is anon ref to scalar');
is( ${$sym3}, 'conns/c3', 'check target of symlink');
my $sym4 = $cfg->get('groupsym.ldapsym4');
is( ref($sym4), 'SCALAR', 'check value of symlink is anon ref to scalar');
is( ${$sym4}, 'conns/c4', 'check target of symlink');
my $sym5 = $cfg->get('groupsym.ldap@sym5');
is( ref($sym5), 'SCALAR', 'check value of symlink is anon ref to scalar');
is( ${$sym5}, 'conns/c5', 'check target of symlink');


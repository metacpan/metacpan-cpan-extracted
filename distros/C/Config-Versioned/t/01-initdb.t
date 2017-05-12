## t/01-initdb.t
##
## Written 2011 by Scott Hardin for the OpenXPKI project
## Copyright (C) 2010, 2011 by Scott T. Hardin
##
## vim: syntax=perl

use Test::More tests => 22;

use strict;
use warnings;
my $gittestdir = qw( t/01-initdb.git );
my $gittestdir2 = qw( t/01-initdb-2.git );

my $ver1 = '7dd8415a7e1cd131fba134c1da4c603ecf4974e2';
my $ver2 = 'a573e9bbcaeed0be9329b25e2831a930f5b656ca';
my $ver3 = '3b5047486706e55528a2684daef195bb4f9d0923';

BEGIN {
    my $gittestdir = qw( t/01-initdb.git );

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
            filename    => '01-initdb.conf',
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
        filename    => '01-initdb-2.conf',
        path        => [qw( t )],
        commit_time => DateTime->from_epoch( epoch => 1240351682 ),
        author_name => 'Test User',
        author_mail => 'test@example.com',
    }
);
is( $cfg->version, $ver2, 'check version of second commit' );

$cfg->parser(
    {
        filename    => '01-initdb-3.conf',
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

# When installing our app that depends on Config::Versioned, we like to
# deliver the empty bare repo directory so it has the correct permissions.
# Currently, the initdb fails when this already exists, so we need some
# sort of force option.
dir($gittestdir2)->rmtree;
mkdir $gittestdir2;

ok(-d $gittestdir2, "Check that $gittestdir2 exists");

eval {
    my $cfg = Config::Versioned->new(
        {
            dbpath      => $gittestdir2,
            autocreate  => 1,
            filename    => '01-initdb.conf',
            path        => [qw( t )],
            commit_time => DateTime->from_epoch( epoch => 1240341682 ),
            author_name => 'Test User',
            author_mail => 'test@example.com',
        }
    );
    1;
};
is($@, "", "Results of eval for new() instance");

ok( $cfg, 'create new config instance for second dir' );



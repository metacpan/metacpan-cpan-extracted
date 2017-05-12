use strict;
use warnings;
use Catalyst::Model::SVN;
use Test::More tests => 8;
use Test::Exception;

# Example testing _ra_path in my svn repository (which doesn't live at /)

my $repos_uri = 'http://www.bobtfish.net/svn/repos/';
lives_ok {
    Catalyst::Model::SVN->config(
        repository => $repos_uri,
    );
} 'Setting repos config';

my $m;
lives_ok { $m = Catalyst::Model::SVN->new(); } 'Can construct';

# Note directories can't have a trailing /, or in some situations
# everything will blow up with:
# subversion/libsvn_subr/path.c:115: failed assertion `is_canonical (component, clen)'

is($m->_ra_path( '/' ), '', 'Root dir ""');
is($m->_ra_path( 'README' ), 'README', '/README is correct');
is($m->_ra_path( '//README' ), 'README', '//README is correct');

is($m->_ra_path( $repos_uri ), '', 'full URI Root dir /');
is($m->_ra_path( $repos_uri . 'README' ), 'README', 'full URI /README is correct');
is($m->_ra_path( $repos_uri . '/README' ), 'README', 'full URI //README is correct');



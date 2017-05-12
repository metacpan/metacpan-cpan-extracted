#!perl -T
#
#   Alien::InteractiveBrokers - tests for main module
#
#   Copyright (c) 2010-2012 Jason McManus
#

use Data::Dumper;
use File::Spec::Functions qw( catdir catfile );
use Test::More tests => 12;
use strict;
use warnings;

###
### Vars
###

use vars qw( $TRUE $FALSE $VERSION );
BEGIN {
    $VERSION = '9.6602';
}

*TRUE      = \1;
*FALSE     = \0;

my $obj;

###
### Tests
###

# Uncomment for use tests
BEGIN {
    use_ok( 'Alien::InteractiveBrokers' ) || print "Bail out!";
}

################################################################
# Test: Can instantiate object
# Expected: PASS
isa_ok( $obj = Alien::InteractiveBrokers->new(), 'Alien::InteractiveBrokers' );

# Test object cache is empty
is_deeply( $obj, {}, 'AIB cache: empty' );

################################################################
# Test: all methods
# Expected: PASS

# Set up some junk
my $aib_path = $INC{ join( '/', 'Alien', 'InteractiveBrokers.pm' ) };
$aib_path    =~ s{\.pm$}{};
my $aib_base = catdir( $aib_path, 'IBJts' );

# Check correct version looked up
my $version = get_api_version( $aib_base );
cmp_ok( length( $obj->version() ), '>', 0,      'version()' );
diag( "API Version " . $obj->version() );

# Check correct path
is( $obj->path(), $aib_base,                    'path()' );

# Check correct classpath
my $classpath = catfile( $aib_base, 'jtsclient.jar' );
is( $obj->classpath(), $classpath,     'classpath()' );

# Check correct includes
my @includes = (
    '-I' . catdir( $aib_base, 'cpp', 'Shared' ),
    '-I' . catdir( $aib_base, 'cpp', 'PosixSocketClient' ),
);
is_deeply( [ $obj->includes() ], \@includes, 'includes() array' );
my $incs = join( ' ', @includes );
is( $obj->includes(), $incs,     'includes() scalar' );

################################################################
# Test: Cache working
# Expected: PASS
is( $obj->{version}, $version, 'AIB cache: version' );
is( $obj->{path}, $aib_base, 'AIB cache: path' );
is_deeply( $obj->{includes}, \@includes, 'AIB cache: includes' );
is( $obj->{classpath}, $classpath, 'AIB cache: classpath' );

# Always return true
1;

###
### Utility subs
###

sub get_api_version
{
    my $path = shift;
    return unless( $path );

    my $verfile = catfile( $path, 'API_VersionNum.txt' );
    open my $fd, '<', $verfile or print "Bail out!" and die;
    my $contents = do { local $/; <$fd> };
    close( $fd );

    my( $vernum ) = ( $contents =~ m/API_Version=([\d.]*)/mi );

    return( $vernum );
}

__END__

#
#===============================================================================
#
#         FILE:  10-openlib.t
#
#  DESCRIPTION:  Tests App:;Open
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 06:12:55 AM PDT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More qw(no_plan);
use Test::Exception;

use constant CLASS => 'App::Open';

BEGIN {
    use_ok(CLASS);
    use_ok("App::Open::Config");
    use_ok("App::Open::Backend::Dummy");
    use_ok("App::Open::Backend::YAML");
}

my $tmp;
my $config;
my $filename = "/dev/null";

throws_ok { CLASS->new() } qr/MISSING_ARGUMENT/;
throws_ok { CLASS->new( App::Open::Config->new ) } qr/MISSING_ARGUMENT/; 
throws_ok { CLASS->new( undef, $filename ) } qr/MISSING_ARGUMENT/;
throws_ok { CLASS->new( App::Open::Backend::Dummy->new, $filename ) }
    qr/INVALID_ARGUMENT/;

$config = 't/resource/configs/openlib1.yaml';

lives_ok { $tmp = CLASS->new( App::Open::Config->new($config), $filename ) };
is( $tmp->filename, $filename );
isa_ok( $tmp->config, "App::Open::Config" );

$filename = "/.doesnotexist";

# XXX you never know..
unless ( -e $filename ) {
    throws_ok { CLASS->new( App::Open::Config->new($config), $filename ) }
        qr/FILE_NOT_FOUND/;
}

#
# test extensions()
#

lives_ok {
    $tmp = CLASS->new( App::Open::Config->new($config),
        't/resource/configs/openlib1.yaml' );
};
is_deeply( [ $tmp->extensions ], [qw(yaml)] );

lives_ok {
    $tmp = CLASS->new( App::Open::Config->new($config),
        't/resource/dummy_files/foo.tar.gz' );
};
is_deeply( [ $tmp->extensions ], [qw(tar.gz gz)] );

lives_ok {
    $tmp = CLASS->new(
        App::Open::Config->new($config),
        't/resource/dummy_files/bar.rpm.spec.gz'
    );
};
is_deeply( [ $tmp->extensions ], [qw(rpm.spec.gz spec.gz gz)] );

$filename = 't/resource/dummy_files/this.is.a.lot.of.fucking.extensions';

lives_ok { $tmp = CLASS->new( App::Open::Config->new($config), $filename); };

is_deeply(
    [ $tmp->extensions ],
    [
        qw(is.a.lot.of.fucking.extensions a.lot.of.fucking.extensions lot.of.fucking.extensions of.fucking.extensions fucking.extensions extensions)
    ]
);

#
# test backends()
#

is_deeply( [ map { ref($_) } @{ $tmp->backends } ],
    [qw(App::Open::Backend::Dummy)] );

#
# test lookup_program()
#

is_deeply( [$tmp->lookup_program], ["dummy_file", $filename] );

#
# Test URL support
#

$filename = "http://example.com";

lives_ok {
    $tmp = CLASS->new( App::Open::Config->new($config), $filename );
};

ok($tmp->is_url);
is($tmp->scheme, 'http');
is($tmp->filename, 'http://example.com');
is_deeply([$tmp->lookup_program], ['dummy_url', $filename]);

#
# test it with a real backend....
#

$config = 't/resource/configs/openlib2.yaml';
$filename = 't/resource/dummy_files/foo.tar.gz';

lives_ok {
    $tmp = CLASS->new( App::Open::Config->new($config), $filename );
};

#
# XXX this indirectly tests the %s templating functionality
#

is_deeply( [$tmp->lookup_program], ["gunzip", $filename] );

$filename = 't/resource/dummy_files/this.is.a.lot.of.fucking.extensions';

lives_ok {
    $tmp = CLASS->new( App::Open::Config->new($config), $filename);
};
is_deeply( [$tmp->lookup_program], []);

$filename = "http://example.com";

lives_ok {
    $tmp = CLASS->new( App::Open::Config->new($config), $filename );
};

is_deeply( [$tmp->lookup_program], ["echo", $filename] );


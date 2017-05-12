use 5.6.0;

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 14;
use JSON qw(from_json);
use Test::WWW::Mechanize::Catalyst 'TestDirectoryDispatch';

my $mech = Test::WWW::Mechanize::Catalyst->new;

# Test basic operation
{
    $mech->get_ok('/base/basic');
    my $response = from_json( $mech->content );
    opendir my $dir, ".";
    my $files = [ readdir $dir ];
    closedir $dir;

    is_deeply( $response->{data}, $files, 'correct message returned' );
}

{
    $mech->get_ok('/base/basic/lib');
    my $response = from_json( $mech->content );
    opendir my $dir, "lib";
    my $files = [ readdir $dir ];
    closedir $dir;

    is_deeply( $response->{data}, $files, 'correct message returned' );
}

# Test using a filter
{
    $mech->get_ok('/base/filter');
    my $response = from_json( $mech->content );
    opendir my $dir, ".";
    my $files = [ grep { !/^\./ } readdir $dir ];
    closedir $dir;

    is_deeply( $response->{data}, $files, 'correct message returned' );
}

# Test changing data_root
{
    $mech->get_ok('/base/dataroot');
    my $response = from_json( $mech->content );
    opendir my $dir, ".";
    my $files = [ readdir $dir ];
    closedir $dir;

    is_deeply( $response->{test}, $files, 'correct message returned' );
}

# Test returning full paths
{
    $mech->get_ok('/base/fullpaths');
    my $response = from_json( $mech->content );
    opendir my $dir, ".";
    my $files = [ readdir $dir ];
    closedir $dir;

    $files = [ map { "/$_" } @$files ];

    is_deeply( $response->{data}, $files, 'correct message returned' );
}

{
    $mech->get_ok('/base/fullpaths/lib');
    my $response = from_json( $mech->content );
    opendir my $dir, "lib";
    my $files = [ readdir $dir ];
    closedir $dir;

    $files = [ map { "/lib/$_" } @$files ];

    is_deeply( $response->{data}, $files, 'correct message returned' );
}

# Test post processing
{
    $mech->get_ok('/base/process');
    my $response = from_json( $mech->content );
    opendir my $dir, ".";
    my $files = [ readdir $dir ];
    closedir $dir;

    $files = [ map { "Andy was here: $_" } @$files ];

    is_deeply( $response->{data}, $files, 'correct message returned' );
}

done_testing();

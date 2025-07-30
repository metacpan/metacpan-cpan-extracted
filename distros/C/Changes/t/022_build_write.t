#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use open ':std' => ':utf8';
    use DateTime;
    use Test::More qw( no_plan );
    # 2022-12-08T20:13:09
    use Test::Time time => 1670497989;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes' ) || BAIL_OUT( "Failed to load Changes" );;
};

use strict;
use warnings;

unlink( './t/CHANGES' ) if( -e( './t/CHANGES' ) );
my $c = Changes->new(
    file => './t/CHANGES',
    defaults => {
        spacer1 => '    ',
        spacer2 => ' ',
        group_spacer => '    ',
        # default values for Changes::Release
        format => '%FT%T%z',
        time_zone => 'Asia/Tokyo',
    },
    debug => $DEBUG,
);
isa_ok( $c, 'Changes' );
my $now = DateTime->now;
SKIP:
{
    skip( "Failed to instantiate a Changes object", 8 ) if( !defined( $c ) );
    $c->add_preamble( "Changes history for package Foo::Bar" );
    $c->add_epilogue( 'For more information, visit https://git.example.com/johndoe/Foo-Bar' );
    my $rel1 = $c->add_release(
        version => 'v0.1.0',
        datetime => '-2D',
    );
    isa_ok( $rel1 => 'Changes::Release' );
    skip( "Failed to instantiate a Changes::Release object", 7 ) if( !defined( $rel1 ) );
    # my $change = $rel1->add_change( text => 'Initial release', spacer1 => '    ', spacer2 => ' ' );
    my $change = $rel1->add_change( text => 'Initial release' );
    isa_ok( $change => 'Changes::Change' );
    my $rel2 = $c->add_release(
        version => 'v0.2.0',
        datetime => '-1D',
    );
    isa_ok( $rel2 => 'Changes::Release' );
    skip( "Failed to instantiate a 2nd Changes::Release object", 5 ) if( !defined( $rel2 ) );
    my $group = $rel2->add_group( name => 'Bug fixes' );
    isa_ok( $group => 'Changes::Group' );
    skip( "Failed to instantiate a Changes::Group object", 4 ) if( !defined( $group ) );
    # my $change2 = $group->add_change( text => 'Corrected issue in module Foo::Bar::Baz', spacer1 => '    ', spacer2 => ' ' );
    my $change2 = $group->add_change( text => 'Corrected issue in module Foo::Bar::Baz' );
    isa_ok( $change2 => 'Changes::Change' );
    my $group2 = $rel2->add_group( name => 'Improvements', spacer => "    " );
    isa_ok( $group2 => 'Changes::Group' );
    # my $change3 = $group2->add_change( text => 'Added some goodies', spacer1 => '    ', spacer2 => ' ' );
    my $change3 = $group2->add_change( text => 'Added some goodies' );
    isa_ok( $change3 => 'Changes::Change' );
    # my $change4 = $group2->add_change( text => 'Added more cool stuff', spacer1 => '    ', spacer2 => ' ' );
    my $change4 = $group2->add_change( text => 'Added more cool stuff' );
    isa_ok( $change4 => 'Changes::Change' );
    my $result = $c->as_string;
    my $expect = <<EOT;
Changes history for package Foo::Bar

v0.2.0 2022-12-07T20:13:09+0900
    [Bug fixes]
    - Corrected issue in module Foo::Bar::Baz

    [Improvements]
    - Added some goodies
    - Added more cool stuff

v0.1.0 2022-12-06T20:13:09+0900
    - Initial release

For more information, visit https://git.example.com/johndoe/Foo-Bar
EOT
    chomp( $expect );
    is( $result, $expect, 'as_string' );
    my $rv = $c->write;
    ok( $rv, 'write' );
    ok( -e( './t/CHANGES' ) && !-z( './t/CHANGES' ), 'Changes exists' );
    unlink( './t/CHANGES' ) if( -e( './t/CHANGES' ) );
};

done_testing();

__END__


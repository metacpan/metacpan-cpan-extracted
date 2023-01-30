#!perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use DateTime;
    use Test::More qw( no_plan );
    use Module::Generic::File qw( file );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

BEGIN
{
    use_ok( 'Changes' ) || BAIL_OUT( "Failed to load Changes" );;
};

use strict;
use warnings;

subtest 'basic group' => sub
{
    my $raw_data = <<EOT;
0.01 2010-06-16
 [Group 1]
 - Initial release
EOT
    my $c = Changes->load_data( $raw_data, debug => $DEBUG );
    isa_ok( $c, 'Changes' );
    is( $c->preamble, undef, 'no preamble' );
    is( $c->releases->length, 1, 'No of releases' );
    my $rel = $c->releases->first;
    isa_ok( $rel, 'Changes::Release' );
    my $changes_data = $c->as_string;
    is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
    SKIP:
    {
        skip( 'No release object found.', 10 ) if( !$rel );
        is( $rel->version, '0.01', 'version' );
        is( $rel->datetime, '2010-06-16', 'datetime' );
        is( $rel->groups->length, 1, 'release has 1 group' );
        my $g = $rel->groups->first;
        is( $g->name, 'Group 1', 'group name' );
        is( $g->changes->length, 1, 'group has 1 change' );
        is( $rel->changes->length, 1, 'release has 1 change' );
        skip( "No release change found.", 4 ) if( $rel->changes->is_empty );
        my $ch = $rel->changes->first;
        isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
        is( $ch->text, 'Initial release', 'change text' );
        my $ch2 = $g->changes->first;
        isa_ok( $ch2 => 'Changes::Change', 'groups returned the Changes::Change object' );
        is( $ch2, $ch, 'both changes are indentical' );
    };
};

subtest 'bracketed words, not a group' => sub
{
    my $raw_data = <<EOT;
0.01 2010-06-16
 [Group 1]
 - Initial release
   [not a group], seriously.
 - change
   [also] [not a group]
EOT
    my $c = Changes->load_data( $raw_data, debug => $DEBUG );
    isa_ok( $c, 'Changes' );
    is( $c->preamble, undef, 'no preamble' );
    is( $c->releases->length, 1, 'No of releases' );
    my $rel = $c->releases->first;
    isa_ok( $rel, 'Changes::Release' );
    my $changes_data = $c->as_string;
    is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
    SKIP:
    {
        skip( 'No release object found.', 10 ) if( !$rel );
        is( $rel->version, '0.01', 'version' );
        is( $rel->datetime, '2010-06-16', 'datetime' );
        is( $rel->groups->length, 1, 'release has 1 group' );
        my $g = $rel->groups->first;
        is( $g->name, 'Group 1', 'group name' );
        is( $g->changes->length, 2, 'group has 1 change' );
        is( $rel->changes->length, 2, 'release has 1 change' );
        my $ch = $g->changes->first;
        my $ch2 = $g->changes->second;
        is( $ch->text, "Initial release\n   [not a group], seriously.", 'first change text' );
        is( $ch2->text, "change\n   [also] [not a group]", 'second change text' );
        is( $ch->normalise, "Initial release [not a group], seriously.", 'first change text normalised' );
        is( $ch2->normalise, "change [also] [not a group]", 'second change text normalised' );
    };
};

done_testing();

__END__


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
    use_ok( 'Changes::Change' ) || BAIL_OUT( "Failed to load Changes" );;
};

use strict;
use warnings;

subtest 'preamble' => sub
{
    my $raw_data = <<EOT;
Revision history for perl module Foo::Bar

0.01 2010-06-16
 - Initial release
EOT
    my $c = Changes->load_data( $raw_data, debug => $DEBUG );
    isa_ok( $c, 'Changes' );
    is( $c->preamble, "Revision history for perl module Foo::Bar\n\n", 'preamble' );
    is( $c->releases->length, 1, 'No of releases' );
    my $rel = $c->releases->first;
    isa_ok( $rel, 'Changes::Release' );
    my $changes_data = $c->as_string;
    is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
    SKIP:
    {
        skip( 'No first release object found.', 6 ) if( !$rel );
        is( $rel->version, '0.01', 'version' );
        is( $rel->datetime, '2010-06-16', 'datetime' );
        is( $rel->note, undef, 'note' );
        is( $rel->changes->length, 1, 'release has 1 change' );
        skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
        my $ch = $rel->changes->first;
        isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
        is( $ch->text, "Initial release", 'change text' );
    };
};

subtest 'long preamble' => sub
{
    my $raw_data = <<EOT;
Revision history for perl module Foo::Bar

Yep.

0.01 2010-06-16
 - Initial release
EOT
    my $c = Changes->load_data( $raw_data, debug => $DEBUG );
    isa_ok( $c, 'Changes' );
    is( $c->preamble, "Revision history for perl module Foo::Bar\n\nYep.\n\n", 'long preamble' );
    is( $c->releases->length, 1, 'No of releases' );
    my $rel = $c->releases->first;
    isa_ok( $rel, 'Changes::Release' );
    my $changes_data = $c->as_string;
    is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
    SKIP:
    {
        skip( 'No first release object found.', 6 ) if( !$rel );
        is( $rel->version, '0.01', 'version' );
        is( $rel->datetime, '2010-06-16', 'datetime' );
        is( $rel->note, undef, 'note' );
        is( $rel->changes->length, 1, 'release has 1 change' );
        skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
        my $ch = $rel->changes->first;
        isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
        is( $ch->text, "Initial release", 'change text' );
    };
};

subtest 'epilogue' => sub
{
    my $raw_data = <<EOT;
Revision history for perl module Foo::Bar

0.02 2010-07-12
 - Some improvements

0.01 2010-06-16
 - Initial release

A complete change history is available at https://git.example.com/joe/Foo-Bar
EOT
    my $c = Changes->load_data( $raw_data, debug => $DEBUG );
    isa_ok( $c, 'Changes' );
    is( $c->preamble, "Revision history for perl module Foo::Bar\n\n", 'preamble' );
    is( $c->releases->length, 2, 'No of releases' );
    is( $c->epilogue, "A complete change history is available at https://git.example.com/joe/Foo-Bar\n", 'epilogue' );
};

done_testing();

__END__


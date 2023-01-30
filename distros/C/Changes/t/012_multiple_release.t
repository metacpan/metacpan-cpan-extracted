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

my $raw_data = <<EOT;
0.02 2010-06-17
 - New version

0.01 2010-06-16
 - Initial release
EOT
my $c = Changes->load_data( $raw_data, debug => $DEBUG );
isa_ok( $c, 'Changes' );
is( $c->preamble, undef, 'no preamble' );
is( $c->releases->length, 2, 'No of releases' );
my $rel = $c->releases->first;
isa_ok( $rel, 'Changes::Release' );
my $rel2 = $c->releases->second;
isa_ok( $rel2, 'Changes::Release' );
my $changes_data = $c->as_string;
is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
SKIP:
{
    skip( 'No release object found.', 5 ) if( !$rel );
    is( $rel->version, '0.02', 'version' );
    is( $rel->datetime, '2010-06-17', 'datetime' );
    is( $rel->changes->length, 1, 'release has 1 change' );
    skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
    my $ch = $rel->changes->first;
    isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
    is( $ch->text, "New version", 'change text' );
};

SKIP:
{
    skip( 'No release object found.', 5 ) if( !$rel2 );
    is( $rel2->version, '0.01', 'version' );
    is( $rel2->datetime, '2010-06-16', 'datetime' );
    is( $rel2->changes->length, 1, 'release has 1 change' );
    skip( "No release change found.", 2 ) if( $rel2->changes->is_empty );
    my $ch = $rel2->changes->first;
    isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
    is( $ch->text, "Initial release", 'change text' );
};

done_testing();

__END__


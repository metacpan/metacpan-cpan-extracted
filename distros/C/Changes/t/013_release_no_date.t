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

my $raw_data = <<EOT;
1.01 Note
    - Second

1.00
    - First
EOT
my $c = Changes->load_data( $raw_data, debug => $DEBUG );
isa_ok( $c, 'Changes' );
is( $c->preamble, undef, 'no preamble' );
is( $c->releases->length, 2, 'No of releases' );
my $rel = $c->releases->first;
my $rel2 = $c->releases->second;
isa_ok( $rel, 'Changes::Release' );
isa_ok( $rel2, 'Changes::Release' );
my $changes_data = $c->as_string;
is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
SKIP:
{
    skip( 'No first release object found.', 6 ) if( !$rel );
    is( $rel->version, '1.01', 'version' );
    is( $rel->datetime, undef, 'datetime' );
    is( $rel->note, 'Note', 'note' );
    is( $rel->changes->length, 1, 'release has 1 change' );
    skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
    my $ch = $rel->changes->first;
    isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
    is( $ch->text, 'Second', 'change text' );
};

SKIP:
{  
    skip( 'No second release object found.', 6 ) if( !$rel2 );
    is( $rel2->version, '1.00', 'version' );
    is( $rel2->datetime, undef, 'datetime' );
    is( $rel2->note, undef, 'note' );
    is( $rel2->changes->length, 1, 'release has 1 change' );
    skip( "No release change found.", 2 ) if( $rel2->changes->is_empty );
    my $ch = $rel2->changes->first;
    isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
    is( $ch->text, 'First', 'change text' );
};

done_testing();

__END__


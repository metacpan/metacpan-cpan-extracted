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

subtest 'wrapped line' => sub
{
    my $raw_data = <<EOT;
0.01 2010-06-16
 - Initial release
   This line is part of the first
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
        skip( 'No release object found.', 5 ) if( !$rel );
        is( $rel->version, '0.01', 'version' );
        is( $rel->datetime, '2010-06-16', 'datetime' );
        is( $rel->changes->length, 1, 'release has 1 change' );
        skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
        my $ch = $rel->changes->first;
        isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
        is( $ch->text, "Initial release\n   This line is part of the first", 'change text' );
    };
};

subtest 'wrapping long change line' => sub
{
    my $ch = Changes::Change->new(
        text => 'Mignonne, allons voir si la rose qui ce matin avoit desclose sa robe de pourpre au Soleil',
        max_width => 72,
        spacer1 => "\t",
        spacer2 => ' ',
        debug => $DEBUG,
    );
    is( $ch->as_string, "\t- Mignonne, allons voir si la rose qui ce matin avoit desclose sa robe\n\t  de pourpre au Soleil\n", 'as_string wrapped' );
};

done_testing();

__END__


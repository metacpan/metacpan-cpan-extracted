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

subtest 'load' => sub
{
    SKIP:
    {
        my $f = file( 't/sample/basic.txt' );
        my $c = Changes->load( $f, debug => $DEBUG );
        my $raw_data = $f->load_utf8;
        if( !defined( $raw_data ) && $DEBUG )
        {
            diag( "Error loading Changes file data: ", $f->error );
        }
        &check( $c => \$raw_data );
    };
};

subtest 'load_data' => sub
{
    SKIP:
    {
        my $raw_data = <<EOT;
0.01 2010-06-16
 - Initial release
EOT
        my $c = Changes->load_data( $raw_data );
        &check( $c => \$raw_data );
    };
};

sub check
{
    my( $c, $raw_data ) = @_;
    SKIP:
    {
        isa_ok( $c, 'Changes' );
        skip( "Cannot instantiate Changes object: " . Change->error, 9 ) if( !defined( $c ) );
        is( $c->preamble, undef, 'no preamble' );
        is( $c->releases->length, 1, 'No of releases' );
        my $rel = $c->releases->first;
        isa_ok( $rel, 'Changes::Release' );
        my $changes_data = $c->as_string;
        is( "$changes_data", $$raw_data, 'as_string reproduces same original data' );
        SKIP:
        {
            skip( 'No release object found.', 5 ) if( !$rel );
            is( $rel->version->as_string, '0.01', 'version' );
            is( $rel->datetime, '2010-06-16', 'datetime' );
            is( $rel->changes->length, 1, 'release has 1 change' );
            skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
            my $ch = $rel->changes->first;
            isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
            is( $ch->text, 'Initial release', 'change text' );
        };
    };
}

done_testing();

__END__


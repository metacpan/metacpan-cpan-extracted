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
0.05 Developer Release

0.04 Development Release

0.03 Unknown Release Date

0.02 Not Released

0.01 Unknown
EOT
my $tests =
[
    { version => '0.05', datetime => undef, note => 'Developer Release' },
    { version => '0.04', datetime => undef, note => 'Development Release' },
    { version => '0.03', datetime => undef, note => 'Unknown Release Date' },
    { version => '0.02', datetime => undef, note => 'Not Released' },
    { version => '0.01', datetime => undef, note => 'Unknown' },
];

my $c = Changes->load_data( $raw_data, debug => $DEBUG );
isa_ok( $c, 'Changes' );
is( $c->preamble, undef, 'no preamble' );
is( $c->releases->length, scalar( @$tests ), 'No of releases' );
my $changes_data = $c->as_string;
is( "$changes_data", $raw_data, 'as_string reproduces same original data' );

for( my $i = 0; $i < scalar( @$tests ); $i++ )
{
    my $def = $tests->[$i];
    my $rel = $c->releases->index($i);
    isa_ok( $rel, 'Changes::Release' );
    subtest "Release No " . ( $i + 1 ) => sub
    {
        SKIP:
        {
            skip( 'No release object found.', ( exists( $def->{note} ) ? 4 : 3 ) ) if( !$rel );
            is( $rel->version, $def->{version}, 'version' );
            is( $rel->datetime, $def->{datetime}, 'datetime' );
            if( $def->{note} )
            {
                is( $rel->note, $def->{note}, 'release note' );
            }
            is( $rel->changes->length, 0, 'no release change' );
        };
    };
}

done_testing();

__END__


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

my $raw_data = <<'EOT';
0.03 - 2013-12-11

0.02 == 2013-12-10

0.01 -=\/\/=- 2013-12-09
EOT
my $tests =
[
    { version => '0.03', datetime => '2013-12-11', spacer => ' - ' },
    { version => '0.02', datetime => '2013-12-10', spacer => ' == ' },
    { version => '0.01', datetime => '2013-12-09', spacer => ' -=\/\/=- ' },
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
            skip( 'No release object found.', ( exists( $def->{note} ) ? 5 : 4 ) ) if( !$rel );
            is( $rel->version, $def->{version}, 'version' );
            is( $rel->datetime, $def->{datetime}, 'datetime' );
            if( $def->{note} )
            {
                is( $rel->note, $def->{note}, 'release note' );
            }
            is( $rel->spacer, $def->{spacer}, 'spacer' );
            is( $rel->changes->length, 0, 'no release change' );
        };
    };
}

done_testing();

__END__


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
0.11 2011-04-12T12:00:00+0100
 - W3CDTF, with timezone

0.10 2011-04-14 13:00:00.123
 - Factional Seconds

0.09 2011-04-14 12:00:00 America/Halifax
 - Dist::Zilla style date

0.08 2011-04-13 12:00 Test
 - Datetime w/o T or Z, plus note

0.07 2011-04-12T12:00:00Z # JUNK!
 - W3CDTF, with junk marker

0.06 Mon, 11 Apr 2011 21:40:45 -0300
 - RFC 2822

0.05 2011-04-11 15:14
 - Similar to 0.04, without seconds

0.04 2011-04-11 12:11:10
 - Datetime w/o T or Z

0.03 Fri Mar 25 2011
 - Yet another release

0.02 Fri Mar 25 12:18:36 2011
 - Another release

0.01 Fri Mar 25 12:16:25 ADT 2011
 - Initial release
EOT
my $tests =
[
    { version => '0.11', datetime => '2011-04-12T12:00:00+0100', change => 'W3CDTF, with timezone' },
    { version => '0.10', datetime => '2011-04-14 13:00:00.123', change => 'Factional Seconds' },
    { version => '0.09', datetime => '2011-04-14 12:00:00 America/Halifax', change => 'Dist::Zilla style date' },
    { version => '0.08', datetime => '2011-04-13 12:00', note => 'Test', change => 'Datetime w/o T or Z, plus note' },
    { version => '0.07', datetime => '2011-04-12T12:00:00Z', note => '# JUNK!', change => 'W3CDTF, with junk marker' },
    { version => '0.06', datetime => 'Mon, 11 Apr 2011 21:40:45 -0300', change => 'RFC 2822' },
    { version => '0.05', datetime => '2011-04-11 15:14', change => 'Similar to 0.04, without seconds' },
    { version => '0.04', datetime => '2011-04-11 12:11:10', change => 'Datetime w/o T or Z' },
    { version => '0.03', datetime => 'Fri Mar 25 2011', change => 'Yet another release' },
    { version => '0.02', datetime => 'Fri Mar 25 12:18:36 2011', change => 'Another release' },
    { version => '0.01', datetime => 'Fri Mar 25 12:16:25 ADT 2011', change => 'Initial release' },
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
    subtest "Release No " . ( $i + 1 ) . ": $def->{datetime}" => sub
    {
        SKIP:
        {
            skip( 'No release object found.', 5 ) if( !$rel );
            is( $rel->version, $def->{version}, 'version' );
            is( $rel->datetime, $def->{datetime}, 'datetime' );
            if( $def->{note} )
            {
                is( $rel->note, $def->{note}, 'release note' );
            }
            is( $rel->changes->length, 1, 'release has 1 change' );
            skip( "No release change found.", 2 ) if( $rel->changes->is_empty );
            my $ch = $rel->changes->first;
            isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
            is( $ch->text, $def->{change}, 'change text' );
        };
    };
}

subtest 'bad date' => sub
{
    my $raw_data = <<EOT;
1.1.1    xx.xx.2021
           - Improvements
           - Some new stuff
1.1.0    13.07.2021
           - Initial release
EOT
    my $c = Changes->load_data( $raw_data, debug => $DEBUG );
    isa_ok( $c, 'Changes' );
    is( $c->preamble, undef, 'no preamble' );
    is( $c->releases->length, 2, 'No of releases' );
    my $changes_data = $c->as_string;
    is( "$changes_data", $raw_data, 'as_string reproduces same original data' );
    my $rel = $c->releases->first;
    my $rel2 = $c->releases->second;
    isa_ok( $rel, 'Changes::Release' );
    isa_ok( $rel2, 'Changes::Release' );
    SKIP:
    {
        skip( 'No first release object found.', 7 ) if( !$rel );
        is( $rel->version, '1.1.1', 'version' );
        is( $rel->datetime, undef, 'datetime' );
        is( $rel->note, 'xx.xx.2021', 'note' );
        is( $rel->changes->length, 2, 'release has 2 change' );
        skip( "No release change found.", 3 ) if( $rel->changes->is_empty );
        my $ch = $rel->changes->first;
        isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
        is( $ch->text, 'Improvements', '1st change text' );
        is( $rel->changes->second->text, 'Some new stuff', '2nd change text' );
    };

    SKIP:
    {  
        skip( 'No second release object found.', 6 ) if( !$rel2 );
        is( $rel2->version, '1.1.0', 'version' );
        is( $rel2->datetime, '13.07.2021', 'datetime' );
        is( $rel2->note, undef, 'no note' );
        is( $rel2->changes->length, 1, 'release has 1 change' );
        skip( "No release change found.", 2 ) if( $rel2->changes->is_empty );
        my $ch = $rel2->changes->first;
        isa_ok( $ch => 'Changes::Change', 'change object is a Changes::Change' );
        is( $ch->text, 'Initial release', 'change text' );
    };
};

done_testing();

__END__


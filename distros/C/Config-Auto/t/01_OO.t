use strict;
use warnings;

use Test::More 'no_plan';


my $Class   = 'Config::Auto';
use_ok( $Class );

my @Formats = $Class->formats;
ok( scalar(@Formats),           "Retrieved available formats" );


### try to create some objects using all formats
{   ok( 1,                      "Building object for every format" );
    for my $format (@Formats) {
        my $obj = $Class->new( source => $0, format => $format );

        ok( $obj,               "   Built object from '$format'" );
        isa_ok( $obj, $Class,   "       Object" );
        is( $obj->format, $format,
                                "       Format as expected" );
    }
}

### grab one format, do all the accessor and sanity checks on it
{   ok( 1,                      "Testing data retrieval methods" );
    my $obj = $Class->new( source => $0 );

    ok( $obj,                   "   Object created" );
    isa_ok( $obj, $Class,       "       Object" );
    isa_ok( $obj->data, 'ARRAY',"           Data retrieved" );
    ok( -e $obj->file,          "           Filename found" );
    ok( ref( $obj->fh ),        "           Filehandle found" );
    ok( $obj->as_string,        "           Contents retrieved" );

    my $href = $obj->score;
    ok( $href,                  "       Score computed" );
    isa_ok( $href, 'HASH',      "           Return value" );
    ok( scalar(keys(%$href)),   "           Scores found" );
}

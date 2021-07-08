#!perl

use Chart::GGPlot::Setup qw(:pdl);

use Test2::V0;

use Chart::GGPlot::Types qw(:all);

subtest hjust => sub {
    ok( HJust->check(0),        "number" );

    ok( HJust->check( pdl(0) ), "piddle 0D number" );
    ok( HJust->check( pdl(0, 0, 1) ), "piddle 1D number" );

    for my $enum (qw(left right center middle)) {
        ok( HJust->check($enum), "enum $enum" );
    }
    ok( !( HJust->check("bottom") ), "bad enum" );

    for my $enum (qw(left right center middle)) {
        ok( HJust->check( PDL::SV->new( [$enum] ) ), "pdlsv len=1" );
    }
    ok( HJust->check( PDL::SV->new( [qw(left right center middle)] ) ),
        "pdlsv len>1" );
    ok( !( HJust->check( PDL::SV->new( ["bottom"] ) ) ), "bad pdlsv" );
    ok( !( HJust->check( PDL::SV->new( [qw(left right center top)] ) ) ),
        "bad pdlsv" );
};

subtest vjust => sub {
    ok( VJust->check(0),        "number" );

    ok( VJust->check( pdl(0) ), "piddle 0D number" );
    ok( VJust->check( pdl(0, 0, 1) ), "piddle 1D number" );

    for my $enum (qw(bottom top center middle)) {
        ok( VJust->check($enum), "enum $enum" );
    }
    ok( !( VJust->check("left") ), "bad enum" );

    for my $enum (qw(bottom top center middle)) {
        ok( VJust->check( PDL::SV->new( [$enum] ) ), "pdlsv len=1" );
    }
    ok( VJust->check( PDL::SV->new( [qw(bottom top center middle)] ) ),
        "pdlsv len>1" );
    ok( !( VJust->check( PDL::SV->new( ["left"] ) ) ), "bad pdlsv" );
    ok( !( VJust->check( PDL::SV->new( [qw(bottom top center right)] ) ) ),
        "bad pdlsv" );
};

done_testing;

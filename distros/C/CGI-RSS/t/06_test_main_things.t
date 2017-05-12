# vi:fdm=marker fdl=0 syntax=perl:

use strict;
use CGI::RSS ();
use Test;

my @test_text = qw(this is a test);

my @args = (
    [  @test_text  ],
    [ [@test_text] ],

    [ {test=>'tast'},  @test_text  ],
    [ {test=>'tast'}, [@test_text] ],
);

my @results = (
    "<link>@test_text</link>",
    join("", map("<link>$_</link>", @test_text)),

    "<link test=\"tast\">@test_text</link>",
    join("", map("<link test=\"tast\">$_</link>", @test_text)),
);

plan tests => 2 * @args;

my $obj = CGI::RSS->new;

for( 0 .. $#args ) {
    my @args = @{ $args[$_] };

    my $r1 = CGI::RSS::link( @args );
    my $r2 = $obj->link( @args );

    ok( $r1, $results[$_] );
    ok( $r2, $results[$_] );
}

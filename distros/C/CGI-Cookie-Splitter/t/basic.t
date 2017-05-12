use strict;
use warnings;

use Test::More;

use ok "CGI::Cookie::Splitter";

my @cookie_classes = grep { eval "require $_; 1" } qw/CGI::Simple::Cookie CGI::Cookie/;

my @cases = ( # big numbers are used to mask the overhead of the other fields
    {
        size_limit => 4096,
        num_cookies => 1,
        cookie => {
            -name => "a",
            -value => [ qw/foo bar gorch baz/ ],
            -damain => "www.example.com",
            -path => "/foo",
            -secure => 0,
        },
    },
    {
        size_limit => 1000,
        num_cookies => 11,
        cookie => {
            -name => "b",
            -value => ("a" x 10_000),
        },
    },
    {
        size_limit => 10_000,
        num_cookies => 1,
        cookie => {
            -name => "c",
            -value => "this is a simple value",
        }
    },
    {
        size_limit => 1000,
        num_cookies => 11,
        cookie => {
            -name => "d",
            -domain => ".foo.com",
            -value => [ ("a" x 1000) x 10 ],
        },
    },
    {
        size_limit => 1000,
        num_cookies => 15, # feck
        cookie => {
            -name => "e",
            -path => "/bar/gorch",
            -value => [ ("a" x 10) x 1000 ],
        },
    },
    {
        size_limit => 1000,
        num_cookies => 3,
        cookie => {
            -name => "f",
            -secure => 1,
            -value => { foo => ("a" x 1000), bar => ("b" x 1000) },
        },
    },
);

foreach my $class ( @cookie_classes ) {
    foreach my $case ( @cases ) {
        my ( $size_limit, $num_cookies ) = @{ $case }{qw/size_limit num_cookies/};

        my $big = $class->new(%{ $case->{cookie} });

        can_ok( "CGI::Cookie::Splitter", "new" );

        my $splitter = CGI::Cookie::Splitter->new( size => $size_limit ); # 50 is padding for the other attrs

        isa_ok( $splitter, "CGI::Cookie::Splitter" );

        can_ok( $splitter, "split" );

        my @small = $splitter->split( $big );

        is( scalar(@small), $num_cookies, "returned several smaller cookies" );

        my $i = 0;
        foreach my $cookie ( @small ) {
            cmp_ok( length($cookie->as_string), "<=", $size_limit, "cookie size is under specified limit" );

            if ( $splitter->should_split($big) ) {
                is_deeply( [ $splitter->demangle_name($cookie->name) ], [ $big->name => $i++ ], "name mangling looks good (" . $cookie->name . ")" );
            }
        }

        my @big = $splitter->join( @small );

        is( scalar(@big), 1, "one big cookie from small cookies" );

        foreach my $field ( qw/name value domain path secure/ ) {
            is_deeply( [ $big[0]->$field ], [ $big->$field ], "'$field' is the same" );
        }
    }

    my @all_cookies = map { $class->new( %{ $_->{cookie} } ) } @cases;

    my $splitter = CGI::Cookie::Splitter->new;

    my @split = $splitter->split( @all_cookies );

    foreach my $cookie ( @split ) {
        cmp_ok( length($cookie->as_string), "<=", 4096, "cookie size is under specified limit" );
    };

    my @all_joined = $splitter->join( @split );

    is( scalar(@all_joined), scalar(@all_cookies), "count is the same after join" );

    @all_joined = sort { $a->name cmp $b->name } @all_joined;

    while( @all_joined and my($joined, $orig) = ( shift @all_joined, shift @all_cookies ) ) {
        foreach my $field ( qw/name value domain path secure/ ) {
            is_deeply( [ eval { $joined->$field } ], [ eval { $orig->$field } ], "'$field' is the same" );
        }
    }
}

done_testing;

#!/usr/local/bin/perl
BEGIN
{
    use lib './lib';
    use Test::More qw( no_plan );
    require( "./t/functions.pl" ) || BAIL_OUT( "Unable to find library \"functions.pl\"." );
};

my $tests = 
[
    q{$HTTP_COOKIE = /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/} => q{${HTTP_COOKIE} =~ /lang\%22\%3A\%22([a-zA-Z]+\-[a-zA-Z]+)\%22\%7D;?/},
    q{!$CONTENT_LANGUAGE} => q{!( ${CONTENT_LANGUAGE} )},
    q{${HTTPS} = 'on'} => q{${HTTPS} eq 'on'},
    q{${SERVER_PORT} -ne 443} => q{${SERVER_PORT} != 443},
    q{${SERVER_PORT} -ne 80} => q{${SERVER_PORT} != 80},
    q{${HTTP_HOST} = /^([a-zA-Z]+\.)?(exmaple\..*)$/} => q{${HTTP_HOST} =~ /^([a-zA-Z]+\.)?(exmaple\..*)$/},
    q{! $DOMAIN_NAME} => q{!( ${DOMAIN_NAME} )},
    q{${TITLES}} => q{${TITLES}},
    q{-z ${TITLE}} => q{!length( ${TITLE} )},
    q{md5("Some string", 'and', "one more")} => q{$self->parse_func_md5( "Some string", 'and', "one more" )},
    q{$CONTENT_LANGUAGE = /^en\-GB$/} => q{${CONTENT_LANGUAGE} =~ /^en\-GB$/},
    q{My uri is ${REQUEST_URI}} => q{qq{My uri is ${REQUEST_URI}}},
    q{My uri is \${REQUEST_URI}} => q{qq{My uri is \${REQUEST_URI}}},
    q{My uri is %{REQUEST_URI}} => q{qq{My uri is ${REQUEST_URI}}},
    q{192.168.1.10 in split( /\,/, $ip_list )} => q{scalar( grep( '192.168.1.10' eq $_, split(/\,/, ${ip_list}) ) )},
];

my $ssi = Apache2::SSI->new( document_root => './t/htdocs', document_uri => '/dummy', legacy => 1 ) || 
BAIL_OUT( Apache2::SSI->error );
for( my $i = 0; $i < scalar( @$tests ); $i += 2 )
{
    my $test  = $tests->[$i];
    my $check = $tests->[$i + 1];
    my $label = sprintf( "Test No. %d (%s)", $i + 1, $tests->[$i] );
    my $res = '';
    if( !defined( $res = $ssi->parse_expr( $test ) ) )
    {
        if( $ENV{AUTHOR_TESTING} )
        {
            print( "$label: $test => error: ", $ssi->error, "\n" );
        }
        else
        {
            diag( $ssi->error );
            fail( $label );
        }
    }
    else
    {
        if( $ENV{AUTHOR_TESTING} )
        {
            print( "    q\{${test}\} => q\{${res}\},\n" );
        }
        else
        {
            ok( $res eq $check, $label );
        }
    }
}

__END__


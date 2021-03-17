#!/usr/local/bin/perl
# To test only this, run:
# HAS_APACHE_TEST=1 ./t/TEST -start
# HAS_APACHE_TEST=1 ./t/TEST -run-tests ./t/50.apache.t
# ./t/TEST -stop
BEGIN
{
    use strict;
    use lib './lib';
    use warnings;
    # use warnings FATAL => 'all';
    no warnings 'redefine';
    use Test::More;
    use URI::file;
    our $DEBUG = 0;
    use constant HAS_APACHE_TEST => $ENV{HAS_APACHE_TEST};
    # use Devel::Confess;
    # use constant HAS_APACHE_TEST => 0;
    our $BASE_URI = '/ssi';
    our $DOC_ROOT = URI::file->new_abs( './t/htdocs' )->file;
    use_ok( 'Apache2::SSI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    use_ok( 'Apache2::SSI::URI' ) || BAIL_OUT( "Unable to load Apache2::SSI" );
    if( HAS_APACHE_TEST )
    {
        require_ok( 'Apache::Test' ) || BAIL_OUT( "Unable to load Apache::Test" );
        use_ok( 'Apache::TestUtil' ) || BAIL_OUT( "Unable to load Apache::TestUtil" );
        use_ok( 'Apache::TestRequest' ) || BAIL_OUT( "Unable to load Apache::TestRequest" );
        use_ok( 'Apache2::Const', '-compile', qw( :common :http ) ) || BAIL_OUT( "Unable to load Apache2::Cons" );
    }
};

{
    diag( "Using document root \"${DOC_ROOT}\" and base uri at \"${BASE_URI}\". HAS_APACHE_TEST is set to '", HAS_APACHE_TEST, "'" ) if( $DEBUG );
    if( HAS_APACHE_TEST && !$ENV{APACHE_TEST_INITIALISED} )
    {
        my( $config, $hostport, $resp, $html );
        $config   = Apache::Test::config();
        Apache::TestRequest::user_agent( reset => 1, agent => 'Apache2-SSI' );
        $hostport = Apache::TestRequest::hostport( $config ) || '';
        diag( "connecting to $hostport" ) if( $DEBUG );
        $ENV{APACHE_TEST_INITIALISED}++;
    }
}

sub run_tests
{
    my $tests = shift( @_ );
    my $opts  = {};
    $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
    ## Regular round, offline
    ## When running Apache tests, we check for the return code and for the resulting html, so 2 checks for each test
    ## The 5 tests above in the BEGIN block
    my $total_tests = 2 + ( HAS_APACHE_TEST ? 4 : 0 ) + ( exists( $opts->{total_tests} ) ? int( $opts->{total_tests} ) : 0 );
    $total_tests += ( scalar( @$tests ) * ( HAS_APACHE_TEST ? 3 : 1 ) );
    $opts->{debug} = $ENV{AUTHOR_TESTING} if( exists( $ENV{AUTHOR_TESTING} ) );
    ## plan tests => $total_tests;
    &execute_tests( $tests, $opts );
    ## Same test, but for Apache this time, if enabled
    $opts->{with_apache} = 1;
    if( HAS_APACHE_TEST )
    {
        diag( "Executing ", scalar( @$tests ), " test for Apache mod_perl2." ) if( $opts->{debug} > 1 );
        &execute_tests( $tests, $opts );
    }
    done_testing( $total_tests );
}

sub execute_tests
{
    my $tests = shift( @_ );
    # no warnings qw( experimental::vlb );
    my $opts  = {};
    $opts = shift( @_ ) if( ref( $_[0] ) eq 'HASH' );
    eval( "use warnings 'Apache2::SSI';" ) if( $opts->{debug} );
    no warnings 'uninitialized';
    for( my $i = 0; $i < scalar( @$tests ); $i++ )
    {
        my $def    = $tests->[$i];
        my $text   = exists( $def->{text} ) ? $def->{text} : '';
        my $expect = $def->{expect};
        $def->{quiet} = 0 if( !exists( $def->{quiet} ) );
        $def->{no_warning} = 0 if( !exists( $def->{no_warning} ) );
        $def->{legacy} = 0 if( !exists( $def->{legacy} ) );
        $def->{trunk} = 0 if( !exists( $def->{trunk} ) );
        if( !length( $text ) )
        {
            die( "Missing \"uri\" property for test $def->{type} No $i !\nTest data is: ", $ap->dump( $def ) ) if( !$def->{uri} );
            my $u = Apache2::SSI::URI->new(
                document_uri => $def->{uri},
                document_root => $DOC_ROOT,
            ) || die( Apache2::SSI::URI->error );
            if( $u->code != 200 && !$def->{fail} )
            {
                warn( "Unable to get the file at uri \"$def->{uri}\". Is it missing or mispelled?\n" );
                fail( $def->{name} );
                next;
            }
            my $file = $u->filepath;
            diag( "Reading file \"$file\" based on uri '$def->{uri}' and document root '$DOC_ROOT'." ) if( $opts->{debug} > 1 );
            $text = $u->slurp_utf8;
        }
        if( !length( $expect ) && !$def->{fail} )
        {
            die( "Missing \"expect\" property for test $def->{type} No $i !\nTest data is: ", $ap->dump( $def ) );
        }
        diag( "Checking uri $def->{uri} with legacy '$opts->{legacy}'" ) if( $opts->{debug} > 1 );
        my $ap = Apache2::SSI->new(
            debug => $opts->{debug},
            #document_root => $doc_root,
            #document_uri  => $doc_uri,
            document_root => $DOC_ROOT,
            document_uri => $def->{uri},
            legacy => ( $def->{legacy} ? 1 : 0 ),
            trunk => ( $def->{trunk} ? 1 : 0 ),
        ) || die( "Unable to instantiate a Apache2::SSI object: ", Apache2::SSI->error );
        $ap->remote_ip( $def->{remote_ip} ) if( exists( $def->{remote_ip} ) );
        
        SKIP:
        {
            if( $def->{with_apache} && !$def->{uri} )
            {
                skip( "Missing \"uri\" property to run Apache test.", 1 );
            }
            elsif( ( $opts->{with_apache} && !HAS_APACHE_TEST ) ||
                   ( $def->{requires} eq 'mod_perl' && !$opts->{with_apache} ) )
            {
                skip( "mod_perl is not enabled. Skipping Apache test" . ( $def->{name} ? " for $def->{name}" : '' ) . ".", 1 );
            }
            elsif( length( $def->{skip} ) )
            {
                skip( $def->{skip} . " Skipping test" . ( $def->{name} ? " for $def->{name}" : '' ) . ".", 1 );
            }
        
            if( exists( $def->{sub} ) &&
                ref( $def->{sub} ) eq 'CODE' )
            {
                $def->{sub}->( $ap );
            }
        
            if( $def->{fail} || $def->{no_warning} )
            {
                $ap->quiet( 1 );
            }
        
            my $result = '';
            my $code;
            if( $opts->{with_apache} )
            {
                my $resp = GET( $def->{uri}, ( scalar( keys( %{$def->{headers}} ) ) ? %{$def->{headers}} : () ) );
                $code = $resp->code;
                $result = Encode::decode( 'utf8', $resp->content );
            }
            else
            {
                $ENV{REQUEST_URI} = $def->{uri};
                $ENV{REQUEST_METHOD} = 'GET';
                $ENV{HTTPS} = 'off';
                $ENV{DOCUMENT_ROOT} = $DOC_ROOT;
                if( exists( $def->{headers} ) && ref( $def->{headers} ) eq 'HASH' && scalar( keys( %{$def->{headers}} ) ) )
                {
                    while( my( $header, $value ) = each( %{$def->{headers}} ) )
                    {
                        if( $header eq 'Cookie' )
                        {
                            $ENV{HTTP_COOKIE} = $value;
                        }
                        elsif( $header eq 'Agent' )
                        {
                            $ENV{HTTP_USER_AGENT} = $value;
                        }
                        elsif( $header eq 'Host' )
                        {
                            $ENV{HTTP_HOST} = $value;
                        }
                        elsif( $header eq 'DNT' )
                        {
                            $ENV{HTTP_DNT} = $value;
                        }
                    }
                }
                $result = $ap->parse( $text );
            }
        
            $ap->quiet( 0 );
            diag( "Checking result '$result' ", ( $opts->{with_apache} ? "and code '$code' from uri $def->{uri} " : '' ), "against expected result '$expect'", ( $opts->{with_apache}  ? "and code '$def->{code}'" : '' ), "." ) if( $opts->{debug} > 1 );
            ok( $code == $def->{code}, 'Response code' ) if( $opts->{with_apache} );
            my $check = ( ref( $expect ) eq 'Regexp' ? ( $result =~ /$expect/ ) : ( $result eq $expect ) );
            if( $check )
            {
                ok( $check, sprintf( "$opts->{type} test No %d%s", $i + 1, ( length( $def->{name} ) ? " ($def->{name})" : '' ) . ( $opts->{with_apache} ? ' (using mod_perl2)' : '' ) ) );
            }
            elsif( $def->{fail} )
            {
                pass( sprintf( "$opts->{type} test No %d%s", $i + 1, ( length( $def->{name} ) ? " ($def->{name})" : '' ) . ( $opts->{with_apache} ? ' (using mod_perl2)' : '' ) ) );
            }
            else
            {
                if( $ENV{AUTHOR_TESTING} )
                {
                    diag( "Failed: result found: '$result'. I was expecting '$expect'" );
                }
                fail( sprintf( "$opts->{type} test No %d%s", $i + 1, ( length( $def->{name} ) ? " ($def->{name})" : '' ) . ( $opts->{with_apache} ? ' (using mod_perl2)' : '' ) ) );
            }
        }
    }
}

1;

__END__

